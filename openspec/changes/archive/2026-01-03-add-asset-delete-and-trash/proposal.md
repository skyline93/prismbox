# Change: 添加媒体资源删除和回收站功能

## Why

当前系统缺少媒体资源的删除和回收站功能，用户无法：
1. 删除本地或远程媒体资源
2. 恢复误删的资源
3. 管理已删除的资源（查看、恢复、永久删除）

通过添加删除和回收站功能，可以：
- 提供完整的媒体资源生命周期管理
- 支持误删恢复（软删除机制）
- 分离本地和远程资源的删除逻辑（符合现有架构设计）
- 提供统一的回收站管理界面

## What Changes

- **ADDED**: 照片页面支持删除功能，根据过滤模式（全部/已备份/未备份/仅云端）决定删除行为
- **ADDED**: 本地资产表添加软删除字段（`deletedAt`, `originalPath`, `trashPath`）
- **ADDED**: 回收站页面，支持展示、恢复和永久删除
- **ADDED**: 本地资源删除服务，实现文件移动到应用私有回收站空间
- **MODIFIED**: 远程资产表已支持软删除（`deletedAt` 字段），无需修改
- **MODIFIED**: 远程资源删除通过调用后端 API 实现（后端已支持）
- **ADDED**: 回收站数据查询和展示逻辑
- **ADDED**: 回收站恢复和永久删除功能

## Impact

- **Affected specs**: 
  - 修改 `timeline-page` 能力规范（添加删除功能）
  - 新增 `trash` 能力规范（回收站功能）
- **Affected code**: 
  - `lib/data/database/tables/local_asset_entity.dart` - 添加软删除字段
  - `lib/data/database/daos/local_asset_dao.dart` - 添加软删除相关查询方法
  - `lib/presentation/pages/photos/main_timeline_page.dart` - 添加删除操作
  - `lib/presentation/widgets/selection/selection_bottom_sheet.dart` - 添加删除按钮
  - `lib/services/trash/` - 新增回收站服务（本地资源删除、恢复、永久删除）
  - `lib/presentation/pages/trash/trash_page.dart` - 新增回收站页面
  - `lib/features/trash/providers/trash_providers.dart` - 新增回收站数据 Provider
  - `lib/presentation/routing/app_router.dart` - 添加回收站路由
  - 后端 API（已存在，无需修改）：`DELETE /api/v1/media/:uuid`, `POST /api/v1/media/:uuid/restore`, `DELETE /api/v1/media/:uuid/purge`
- **Migration**: 
  - 数据库迁移：在 `local_asset_entity` 表中添加 `deletedAt`, `originalPath`, `trashPath` 字段
  - 现有数据：所有字段初始化为 `NULL`（表示未删除）

