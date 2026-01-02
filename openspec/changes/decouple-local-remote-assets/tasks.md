## 1. 数据库迁移

- [ ] 1.1 在 `local_asset_entity` 表中添加 `isUploaded` 字段（Boolean，默认 false）
- [ ] 1.2 从 `local_asset_entity` 表中移除 `checksum` 字段
- [ ] 1.3 创建数据库迁移脚本

## 2. 移除 Checksum 匹配服务

- [ ] 2.1 删除 `ChecksumMatchingService` 类
- [ ] 2.2 从 `SyncCoordinator` 中移除 `_startChecksumMatchingTask()` 方法
- [ ] 2.3 移除 `SyncCoordinator.checksumMatchCompleteStream`
- [ ] 2.4 从 `TimelineEventListeners` 中移除 checksum 匹配完成监听
- [ ] 2.5 从相关 Provider 中移除 ChecksumMatchingService 依赖

## 3. 重构上传去重逻辑

- [ ] 3.1 修改 `UploadOrchestrator.filterUploadedAssets()` 方法
- [ ] 3.2 将基于 checksum 的去重逻辑改为基于 `isUploaded` 字段
- [ ] 3.3 移除 `_calculateChecksums()` 方法调用
- [ ] 3.4 移除 `_checkExistingAssets()` 方法中的 checksum 查询逻辑
- [ ] 3.5 添加基于 `isUploaded` 的过滤逻辑

## 4. 重构上传成功回调

- [ ] 4.1 修改 `UploadOrchestrator._waitForTaskCompletion()` 方法
- [ ] 4.2 在任务状态为 `completed` 时，更新本地资产的 `isUploaded = true`
- [ ] 4.3 确保更新操作的原子性和错误处理
- [ ] 4.4 添加更新失败的日志记录

## 5. 移除前端 Hash 计算

- [ ] 5.1 从 `UploadOrchestrator._executeUpload()` 中移除 checksum 计算逻辑
- [ ] 5.2 移除上传表单中的 `hash` 字段（如果后端不需要）
- [ ] 5.3 删除 `ChecksumService` 类及相关代码
- [ ] 5.4 从 `LocalSyncService` 中移除 checksum 计算逻辑

## 6. 重构时间线合并逻辑

- [ ] 6.1 修改 `TimelineProviderService._getFromDatabase()` 方法
- [ ] 6.2 移除基于 checksum 的本地-远程资产关联逻辑
- [ ] 6.3 改为简单合并：先添加所有远程资产，再添加所有本地资产
- [ ] 6.4 移除 `_getLocalAssetsOnly()` 中的 checksum 关联逻辑
- [ ] 6.5 移除 `_getFromPhotoManager()` 中的批量查询远程资产逻辑

## 7. 重构上传状态标识逻辑

- [ ] 7.1 修改 `AssetUploadStatusProvider` 的状态判断逻辑
- [ ] 7.2 优先检查 `isUploaded` 字段
- [ ] 7.3 移除基于 checksum 查询远程资产表的逻辑
- [ ] 7.4 保留上传任务状态查询（用于显示上传进度）
- [ ] 7.5 更新状态监听逻辑

## 8. 实现时间线过滤选项

- [ ] 8.1 在 `TimelineProviderService` 中添加过滤参数
- [ ] 8.2 实现过滤逻辑（全部/仅本地/仅远程）
- [ ] 8.3 在 UI 层添加过滤选项控件

## 9. 更新数据源选择器

- [ ] 9.1 修改 `DataSourceSelector` 的逻辑
- [ ] 9.2 移除基于远程资产存在性的强制数据库切换逻辑
- [ ] 9.3 保留基于本地资产数量的数据库切换逻辑

## 10. 清理废弃代码和文档

- [ ] 10.1 清理所有 checksum 相关的注释
- [ ] 10.2 更新相关文档（README、设计文档等）
- [ ] 10.3 移除不再使用的导入和依赖
- [ ] 10.4 运行代码质量检查（linter）

