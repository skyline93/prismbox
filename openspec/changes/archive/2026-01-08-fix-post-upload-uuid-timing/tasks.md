## 1. 修改 UploadResult 类
- [x] 1.1 在 `UploadResult` 类中添加 `mediaUuids` 字段（`Map<String, String>?`，可选）
- [x] 1.2 更新 `UploadResult` 构造函数，添加 `mediaUuids` 参数（可选）

## 2. 修改 UploadOrchestrator._waitForTaskCompletion
- [x] 2.1 在状态变为 `completed` 后，检查 UUID 是否存在
- [x] 2.2 如果 UUID 不存在，实现等待重试逻辑（100ms 间隔，最多 10 次）
- [x] 2.3 如果等待超时（1 秒后仍无 UUID），抛出异常并记录日志
- [x] 2.4 添加日志记录，便于排查问题

## 3. 修改 UploadOrchestrator.orchestrateUpload
- [x] 3.1 在 `orchestrateUpload` 中，收集所有成功任务的 UUID
- [x] 3.2 从数据库读取每个成功任务的 UUID（此时应该已经存储）
- [x] 3.3 创建 `Map<String, String>`，键为 `taskId`，值为 `mediaUuid`
- [x] 3.4 在返回 `UploadResult` 时，填充 `mediaUuids` 字段

## 4. 修改 PostTaskManager._uploadMedia
- [x] 4.1 从 `orchestrateUpload` 的返回值获取 `mediaUuids`
- [x] 4.2 移除直接读取数据库的代码（第 257-274 行）
- [x] 4.3 从 `mediaUuids` Map 中提取 UUID 列表
- [x] 4.4 验证 UUID 数量与媒体文件数量一致
- [x] 4.5 更新错误处理逻辑，使用新的数据源

## 5. 测试和验证
- [x] 5.1 测试帖子发布功能，确保 UUID 正确获取
- [x] 5.2 测试备份上传功能，确保不受影响（`mediaUuids` 可以为空）
- [x] 5.3 测试边界情况：UUID 存储超时、网络延迟等
- [x] 5.4 验证日志记录是否正确

