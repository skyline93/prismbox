# Change: 添加远程资产删除事件同步

## Why

当前远程资产同步机制存在数据不一致问题：当设备A删除资产后，设备B无法通过同步知道该资产已被删除。虽然UI不显示（因为查询时过滤了已删除资产），但设备B的本地数据库中仍然保留该资产的记录，`deletedAt` 字段不会被更新，导致数据不一致。

根本原因：
1. 后端同步服务只返回未删除的资产（`deleted = false`），已删除的资产不会出现在同步结果中
2. 后端没有发送删除事件（`asset_delete_v1`），虽然前端代码已支持处理该事件
3. 永久删除后记录已不存在，无法通过常规同步机制通知其他设备

## What Changes

- **ADDED**: 后端同步服务在增量同步时查询并发送软删除事件
  - 新增 `GetDeletedAssetsSince` 方法查询在时间范围内被软删除的资产
  - 在流式同步中发送 `asset_delete_v1` 事件，包含已删除资产的ID列表
  - 前端收到删除事件后调用 `softDeleteAsset` 更新本地数据库的 `deletedAt` 字段

- **ADDED**: 后端永久删除时发送删除事件（如果资产之前未被软删除）
  - 在 `PurgeMedia` 方法中，如果资产之前未被软删除（`deleted = false`），先发送删除事件再执行永久删除
  - 确保其他设备能够及时知道资产已被删除

- **MODIFIED**: 远程资产同步规范，明确删除事件的处理机制
  - 明确删除事件只处理软删除
  - 明确永久删除的处理方式

## Impact

- **Affected specs**: `remote-asset-sync`
- **Affected code**:
  - `backend/internal/repository/sync.go` - 新增查询已删除资产的方法
  - `backend/internal/service/sync/service.go` - 在流式同步中发送删除事件
  - `backend/internal/service/media/service.go` - 永久删除前发送删除事件
  - `prismbox_mobile/lib/features/remote_sync/services/remote_sync_service.dart` - 已有处理逻辑，无需修改

