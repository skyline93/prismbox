# Design: 修复文件上传数据流重复写入问题

## Context

在 `backend-calculate-hash` 改动中，Service 层添加了从临时文件读取文件头用于 MIME 类型检测的逻辑。实现中使用了 `wrapDataReader` 函数将文件头缓冲区（headBuf）和临时文件（tempFile）组合为 `io.MultiReader`，导致文件数据重复写入。

**问题代码**：
```go
// 4. 读取文件头用于 MIME 类型检测
tempFile.Seek(0, 0)
headBuf, err := readHead(tempFile, sniffBufferSize)

// 5. 重置文件指针，准备传递给存储层
tempFile.Seek(0, 0)
dataReader := wrapDataReader(tempFile, headBuf)  // 问题：MultiReader 导致重复

func wrapDataReader(data io.Reader, head []byte) io.Reader {
    return io.MultiReader(bytes.NewReader(head), data)  // head + data = 重复数据
}
```

**问题分析**：
- `headBuf` 是从 `tempFile` 读取的前 8192 字节
- `MultiReader` 先读取 `headBuf`（8192 字节），再读取 `tempFile`（完整文件，包含前 8192 字节）
- 结果：最终文件 = 8192字节（重复）+ 完整文件 = 文件被破坏

## Goals / Non-Goals

### Goals
- 修复文件上传数据流处理，确保文件完整存储
- 符合分层架构设计原则：Service 层负责业务逻辑（MIME 检测），Storage 层只负责数据存储
- 保持代码简洁，避免不必要的抽象

### Non-Goals
- 不修改文件头读取逻辑（MIME 检测功能正常）
- 不修改存储层接口（接口设计正确）
- 不引入新的抽象层或工具函数

## Decisions

### Decision 1: 直接传递临时文件给存储层

**What**: 移除 `wrapDataReader` 调用，直接将 `tempFile` 传递给存储层的 `Put` 方法。

**Why**:
1. **职责分离**：MIME 类型检测是 Service 层的业务逻辑职责，存储层只需要完整的文件数据流
2. **数据流清晰**：文件数据应该只传递一次，不应该有重复，符合架构文档中的数据流设计原则
3. **接口契约正确**：Storage 接口的 `data io.Reader` 应该是一个完整的、正确的数据流，`size int64` 是数据流的实际大小
4. **代码简洁**：直接传递 `tempFile` 更简单、直观，符合"设计简洁，不过度设计"的原则
5. **性能最优**：无额外内存开销，无重复读取

**Implementation**:
```go
// 4. 读取文件头用于 MIME 类型检测
tempFile.Seek(0, 0)
headBuf, err := readHead(tempFile, sniffBufferSize)
if err != nil {
    return nil, err
}

mimeType := detectMimeType(headBuf, normalizedExt, ext)

// 5. 重置文件指针，直接传递给存储层
tempFile.Seek(0, 0)
// 直接传递 tempFile，存储层只需要完整的文件数据
if err := s.storageManager.Put(ctx, storageKey, tempFile, actualSize, putOpts); err != nil {
    return nil, fmt.Errorf("upload to storage: %w", err)
}
```

**Alternatives considered**:

1. **修复 wrapDataReader 实现**（使用 io.SectionReader 或 io.LimitReader）：
   - ❌ 增加复杂性，需要理解何时应该使用 MultiReader（只有当 head 和 data 是不同来源时）
   - ❌ 在当前场景下，head 就是从 data 读取的，使用 MultiReader 本身就是设计错误
   - ❌ 不符合 YAGNI 原则：不要过度设计

2. **修改存储层接口**：
   - ❌ 接口设计是正确的，问题在于 Service 层的使用方式
   - ❌ 违反接口契约原则

3. **在存储层处理重复数据**：
   - ❌ 将业务逻辑下沉到存储层，违反职责分离原则
   - ❌ 存储层不应该知道数据来源和格式

## Risks / Trade-offs

### Risks
- **无重大风险**：这是一个 bug fix，恢复预期行为
- **向后兼容**：不影响 API 接口，只修复内部实现

### Trade-offs
- **简化 vs 抽象**：选择简化方案（直接传递 tempFile），移除不必要的抽象（wrapDataReader）
- **性能 vs 灵活性**：选择性能最优方案（无额外开销），如果将来需要组合不同来源的数据流，再引入适当的抽象

## Migration Plan

**无需迁移**：这是 bug fix，不涉及数据迁移或 API 变更。

## Open Questions

无。问题明确，解决方案清晰。

