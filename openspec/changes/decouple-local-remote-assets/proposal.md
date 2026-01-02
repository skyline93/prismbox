# Change: 本地资源与远程资源完全解耦

## Why

当前系统中，本地资产和远程资产通过 checksum（文件哈希）进行关联，存在以下问题：

1. **跨平台不可靠**：Android 和 iOS 上计算的 checksum 可能不一致，导致关联失败
2. **架构耦合**：本地同步和远程同步通过 checksum 匹配服务产生耦合
3. **维护复杂**：需要维护 checksum 计算、匹配、关联等复杂逻辑
4. **性能开销**：本地同步时需要计算 checksum，增加计算开销
5. **数据不一致风险**：checksum 计算失败或错误时，导致关联不准确

通过完全解耦本地资源和远程资源，可以：
- 简化架构，提高可维护性
- 消除跨平台 checksum 不一致问题
- 提升性能（前端不再计算 hash）
- 实现本地和远程资产的独立管理

## What Changes

- **BREAKING**: 在本地资产表中添加 `isUploaded` 字段，用于标识上传状态
- **BREAKING**: 移除 checksum 匹配服务（ChecksumMatchingService）
- **BREAKING**: 重构上传去重逻辑，基于 `isUploaded` 字段而非 checksum
- **BREAKING**: 重构时间线合并逻辑，本地和远程资产完全独立展示
- **BREAKING**: 重构上传状态标识逻辑，基于 `isUploaded` 字段
- **BREAKING**: 前端不再计算文件 hash，由后端统一计算
- 移除基于 checksum 的本地-远程资产关联逻辑
- 时间线支持过滤选项（全部/仅本地/仅远程）

## Impact

- **Affected specs**: 
  - 新增 `local-asset-sync` 能力规范（本地资产同步）
  - 新增 `remote-asset-sync` 能力规范（远程资产同步）
  - 新增 `asset-upload` 能力规范（资产上传）
  - 修改 `timeline-page` 能力规范（时间线展示）
- **Affected code**: 
  - `lib/data/database/tables/local_asset_entity.dart` - 添加 `isUploaded` 字段，移除 `checksum` 字段
  - `lib/features/local_sync/services/checksum_matching_service.dart` - 删除
  - `lib/features/local_sync/services/sync_coordinator.dart` - 移除 checksum 匹配逻辑
  - `lib/features/local_sync/services/timeline_provider_service.dart` - 重构合并逻辑
  - `lib/services/backup/upload_orchestrator.dart` - 重构上传去重逻辑
  - `lib/services/backup/providers/asset_upload_status_provider.dart` - 重构状态判断逻辑
  - `lib/infrastructure/asset/checksum_service.dart` - 删除
- **Migration**: 
  - 数据库迁移：添加 `isUploaded` 字段（默认值为 `false`），移除 `checksum` 字段
  - 现有数据：所有本地资产的 `isUploaded` 初始化为 `false`
  - 代码迁移：完全移除 checksum 相关代码和字段

