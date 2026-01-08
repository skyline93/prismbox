# Change: 修复帖子发布中媒体上传 UUID 时序问题

## Why

当前帖子发布功能存在一个严重的时序问题：`PostTaskManager` 在 `orchestrateUpload` 返回后立即从数据库读取媒体 UUID，但 UUID 的存储是异步的（通过 `background_downloader` 的回调机制），导致读取时 UUID 可能还未存储，抛出 `No media UUIDs available` 异常。

**问题根源**：
1. `background_downloader` 的回调是同步的，不能 await
2. `UploadTaskManager._updateTaskStatus` 是异步的，但被 fire-and-forget 调用
3. UUID 的提取和存储与状态更新是分离的异步操作
4. `PostTaskManager` 直接依赖数据库状态，而不是从 `orchestrateUpload` 的返回值获取 UUID

**影响**：
- 帖子发布功能不稳定，经常失败
- 用户体验差，需要多次重试
- 架构设计不合理，职责混乱

## What Changes

### 架构改进
- **职责分离**：`PostTaskManager` 不再直接读取数据库，改为从 `orchestrateUpload` 的返回值获取 UUID
- **数据流清晰**：UUID 通过返回值传递，而不是通过数据库状态传递
- **同步保证**：`orchestrateUpload` 返回时，确保所有 UUID 已存储完成

### 具体修改

1. **修改 `UploadOrchestrator._waitForTaskCompletion`**：
   - 在状态变为 `completed` 后，检查 UUID 是否存在
   - 如果不存在，等待一小段时间（100ms）后重试
   - 最多重试 10 次（总共最多等待 1 秒）
   - 如果仍然没有 UUID，抛出异常

2. **修改 `UploadResult` 类**：
   - 添加 `mediaUuids` 字段（`Map<String, String>`），键为 `taskId`，值为 `mediaUuid`
   - 在 `orchestrateUpload` 中，从数据库读取 UUID 并填充到返回值

3. **修改 `PostTaskManager._uploadMedia`**：
   - 从 `orchestrateUpload` 的返回值获取 UUID
   - 不再直接读取数据库

4. **向后兼容**：
   - 不影响现有的备份上传功能
   - `UploadResult.mediaUuids` 对于备份上传场景可以为空

## Impact

- **受影响文件**：
  - `mobile/lib/services/backup/upload_orchestrator.dart` - 修改 `_waitForTaskCompletion` 和 `orchestrateUpload`
  - `mobile/lib/services/post/post_task_manager.dart` - 修改 `_uploadMedia` 从返回值获取 UUID
- **受影响规范**：
  - `openspec/specs/asset-upload/spec.md` - 修改上传结果规范
- **向后兼容性**：
  - 完全向后兼容，不影响现有备份上传功能
  - `UploadResult.mediaUuids` 为可选字段，现有代码不受影响

