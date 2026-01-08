# Design: 修复帖子发布中媒体上传 UUID 时序问题

## Context

当前帖子发布功能存在时序问题：`PostTaskManager` 在 `orchestrateUpload` 返回后立即从数据库读取媒体 UUID，但 UUID 的存储是异步的，导致读取时 UUID 可能还未存储。

**问题流程**：
1. `PostTaskManager` 调用 `orchestrateUpload`
2. `orchestrateUpload` 通过轮询等待任务完成（`_waitForTaskCompletion`）
3. 当状态变为 `completed` 时，`_waitForTaskCompletion` 返回
4. 但 UUID 的存储是异步的（`_updateTaskStatus` 是 fire-and-forget）
5. `PostTaskManager` 立即读取数据库，UUID 可能还未存储

**架构问题**：
- 职责混乱：`PostTaskManager` 需要了解上传服务的实现细节
- 时序依赖：依赖于数据库状态，而不是明确的返回值
- 耦合度高：帖子发布功能与上传服务的实现细节耦合

## Goals / Non-Goals

### Goals
- 解决 UUID 时序问题，确保 `orchestrateUpload` 返回时 UUID 已就绪
- 改善架构设计，职责清晰，数据流明确
- 保持向后兼容，不影响现有备份上传功能
- 简单实现，避免过度设计

### Non-Goals
- 不引入复杂的事件驱动机制（Stream）
- 不修改 `background_downloader` 的回调机制
- 不改变现有的上传任务状态管理逻辑

## Decisions

### Decision 1: 在 `orchestrateUpload` 中等待 UUID 存储

**选择**：在 `_waitForTaskCompletion` 中，当状态变为 `completed` 后，检查 UUID 是否存在；如果不存在，等待一小段时间后重试。

**理由**：
- 简单直接，易于理解和维护
- 性能好，等待时间短（通常 < 100ms）
- 职责清晰：`UploadOrchestrator` 负责完整的上传结果（包括 UUID）
- 符合单一职责原则：`PostTaskManager` 不需要了解上传服务的实现细节

**实现要点**：
- 在状态变为 `completed` 后，检查 UUID 是否存在
- 如果不存在，等待 100ms 后重试
- 最多重试 10 次（总共最多等待 1 秒）
- 如果仍然没有 UUID，抛出异常

### Decision 2: 通过返回值传递 UUID

**选择**：修改 `UploadResult` 类，添加 `mediaUuids` 字段，在 `orchestrateUpload` 中从数据库读取 UUID 并填充到返回值。

**理由**：
- 数据流清晰：UUID 通过返回值传递，而不是通过数据库状态传递
- 职责清晰：`PostTaskManager` 从返回值获取 UUID，不直接读取数据库
- 向后兼容：`mediaUuids` 为可选字段，现有代码不受影响

**实现要点**：
- `UploadResult.mediaUuids` 类型为 `Map<String, String>`，键为 `taskId`，值为 `mediaUuid`
- 在 `orchestrateUpload` 中，从数据库读取 UUID 并填充到返回值
- `PostTaskManager` 从返回值获取 UUID，不再直接读取数据库

### Decision 3: 保持简单，避免过度设计

**选择**：使用简单的轮询等待机制，而不是引入复杂的事件驱动机制（Stream）。

**理由**：
- 符合 YAGNI 原则：当前只需要等待 UUID 存储完成，不需要复杂的事件处理
- 符合 KISS 原则：简单实现，易于维护
- 性能好：等待时间短（< 100ms），比 Stream 更高效

**替代方案考虑**：
- **方案2（Stream）**：虽然更"现代"，但当前场景下属于过度设计，会增加复杂度和维护成本
- **方案3（状态机同步存储）**：已证明不可行，因为 `background_downloader` 的回调是同步的

## Risks / Trade-offs

### Risk 1: UUID 存储超时

**风险**：如果 UUID 存储时间超过 1 秒（10 次重试 × 100ms），会抛出异常。

**缓解措施**：
- UUID 存储只是数据库写入操作，通常 < 100ms
- 如果超时，说明系统有问题，应该抛出异常而不是静默失败
- 可以记录日志，便于排查问题

### Risk 2: 性能影响

**风险**：等待 UUID 存储会增加少量延迟（通常 < 100ms）。

**缓解措施**：
- 等待时间很短，对用户体验影响可忽略
- 这是必要的同步点，确保数据一致性
- 比 Stream 机制更高效

### Risk 3: 向后兼容性

**风险**：修改 `UploadResult` 可能影响现有代码。

**缓解措施**：
- `mediaUuids` 为可选字段，现有代码不受影响
- 备份上传场景不需要 UUID，`mediaUuids` 可以为空
- 不改变现有 API 签名

## Migration Plan

### Phase 1: 修改 `UploadOrchestrator`
1. 修改 `_waitForTaskCompletion`：在状态变为 `completed` 后，检查 UUID 是否存在
2. 修改 `orchestrateUpload`：从数据库读取 UUID 并填充到返回值
3. 修改 `UploadResult` 类：添加 `mediaUuids` 字段

### Phase 2: 修改 `PostTaskManager`
1. 修改 `_uploadMedia`：从 `orchestrateUpload` 的返回值获取 UUID
2. 移除直接读取数据库的代码

### Phase 3: 测试和验证
1. 测试帖子发布功能，确保 UUID 正确获取
2. 测试备份上传功能，确保不受影响
3. 测试边界情况（UUID 存储超时等）

## Open Questions

- 是否需要支持 UUID 存储超时的重试机制？
  - **决定**：不需要，如果超时说明系统有问题，应该抛出异常
- 是否需要为备份上传场景优化（跳过 UUID 等待）？
  - **决定**：不需要，等待时间很短，对性能影响可忽略

