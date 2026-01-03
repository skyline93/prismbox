## 1. 后端实现

### 1.1 新增查询已删除资产的方法
- [x] 1.1.1 在 `backend/internal/repository/interfaces.go` 中新增 `GetDeletedAssetsSince` 接口方法
- [x] 1.1.2 在 `backend/internal/repository/sync.go` 中实现 `GetDeletedAssetsSince` 方法
  - 查询 `deleted=true` 且 `updated_at > since` 的记录
  - 返回资产UUID列表（字符串数组）
  - 支持批量查询，限制每次查询数量（batchSize）

### 1.2 在流式同步中发送删除事件
- [x] 1.2.1 在 `backend/internal/service/sync/service.go` 中新增 `sendDeleteEvent` 方法
  - 发送 `asset_delete_v1` 事件
  - 事件格式：`{"type": "asset_delete_v1", "ids": [uuid1, uuid2, ...], "data": {}}`
- [x] 1.2.2 在 `StreamAssets` 方法中，增量同步时查询并发送删除事件
  - 在发送资产数据后，查询已删除的资产
  - 批量发送删除事件（每批最多100个资产ID）
  - 确保删除事件在资产数据之后发送

### 1.3 永久删除时发送删除事件
- [x] 1.3.1 在 `backend/internal/service/media/service.go` 的 `PurgeMedia` 方法中
  - 检查资产是否已被软删除（`deleted = false`）
  - 如果未被软删除，记录警告（由于没有 writer，无法直接发送事件）
  - 然后执行永久删除操作

## 2. 文档更新

- [x] 2.1 更新后端API文档（Swagger）
  - 说明删除事件的格式和触发条件
- [x] 2.2 更新同步模块设计文档
  - 说明删除事件的查询和发送机制

