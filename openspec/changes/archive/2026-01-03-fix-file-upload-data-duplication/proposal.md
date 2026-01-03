# Change: 修复文件上传数据流重复写入问题

## Why

在 `backend-calculate-hash` 改动中，引入了文件上传数据流处理的 bug。问题在于：

1. **文件数据重复写入**：在 `service.go` 中使用 `wrapDataReader` 将文件头缓冲区（headBuf）和临时文件（tempFile）组合为 `MultiReader`，导致文件的前 8192 字节被写入两次
2. **文件损坏**：重复写入导致存储的文件结构被破坏，ImageMagick 无法读取，报告 "JPEG datastream contains no image" 错误
3. **架构设计缺陷**：`wrapDataReader` 的使用不符合职责分离原则，Service 层的 MIME 检测逻辑不应该影响传递给 Storage 层的数据格式

通过修复这个问题，可以：
- 恢复文件上传的正常功能，确保文件完整存储
- 符合分层架构设计原则：Service 层负责业务逻辑，Storage 层只负责数据存储
- 简化代码逻辑，提高可维护性

## What Changes

- 修复 `backend/internal/service/media/service.go` 中的文件上传数据流处理逻辑
- 移除不必要的 `wrapDataReader` 调用，直接传递临时文件给存储层
- 确保存储层接收到的是完整的、未重复的文件数据流

## Impact

- **Affected specs**: 
  - 修改 `asset-upload` 能力规范（修复文件流处理实现）
- **Affected code**: 
  - `backend/internal/service/media/service.go` - 修复 `UploadMedia` 方法中的数据流处理
- **Bug Fix**: 
  - 修复文件上传后图片处理失败的问题（ImageMagick 无法读取损坏的文件）
  - 恢复文件上传功能的正常行为

