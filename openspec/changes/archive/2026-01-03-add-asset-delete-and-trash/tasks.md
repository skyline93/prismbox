## 1. 数据库迁移

- [x] 1.1 在 `local_asset_entity` 表中添加 `deletedAt` 字段（DateTime, Nullable, 默认 NULL）
- [x] 1.2 在 `local_asset_entity` 表中添加 `originalPath` 字段（Text, Nullable, 默认 NULL）
- [x] 1.3 在 `local_asset_entity` 表中添加 `trashPath` 字段（Text, Nullable, 默认 NULL）
- [x] 1.4 创建数据库迁移脚本
- [x] 1.5 运行数据库迁移验证（代码已实现，运行时验证）

## 2. 数据库 DAO 层扩展

- [x] 2.1 在 `LocalAssetDao` 中添加查询软删除资源的方法（`getDeletedAssets()`）
- [x] 2.2 在 `LocalAssetDao` 中添加更新软删除字段的方法（`softDeleteAsset()`, `restoreAsset()`）
- [x] 2.3 在 `RemoteAssetDao` 中确认已有查询软删除资源的方法（`deletedAt IS NOT NULL`）
- [x] 2.4 添加软删除相关的查询索引（如需要）

## 3. 回收站存储服务

- [x] 3.1 创建 `TrashStorageService` 类（`lib/services/trash/trash_storage_service.dart`）
- [x] 3.2 实现 `moveToTrash()` 方法（将文件复制到回收站，删除原文件）
- [x] 3.3 实现 `restoreFromTrash()` 方法（从回收站复制文件回原始路径）
- [x] 3.4 实现 `deleteFromTrash()` 方法（删除回收站文件）
- [x] 3.5 实现回收站目录结构管理（按日期分组）
- [x] 3.6 添加错误处理和日志记录

## 4. 删除服务

- [x] 4.1 创建 `LocalAssetDeleteService` 类（`lib/services/trash/local_asset_delete_service.dart`）
- [x] 4.2 实现本地资源软删除逻辑（文件移动、数据库更新）
- [x] 4.3 创建 `RemoteAssetDeleteService` 类（`lib/services/trash/remote_asset_delete_service.dart`）
- [x] 4.4 实现远程资源软删除逻辑（调用后端 API、更新本地数据库）
- [x] 4.5 添加删除操作的错误处理和重试机制

## 5. 照片页面删除功能

- [x] 5.1 在 `SelectionBottomSheet` 中添加删除按钮（根据过滤模式显示）
- [x] 5.2 创建 `TimelineDeleteHandler` 控制器类（`lib/presentation/pages/photos/controllers/timeline_delete_handler.dart`）
- [x] 5.3 实现删除处理逻辑（根据过滤模式调用对应的删除服务）
- [x] 5.4 在 `MainTimelinePage` 中集成删除处理器
- [x] 5.5 添加删除确认对话框
- [x] 5.6 添加删除后的数据刷新逻辑

## 6. 回收站数据 Provider

- [x] 6.1 创建 `TrashSectionsProvider`（`lib/features/trash/providers/trash_providers.dart`）
- [x] 6.2 实现回收站数据查询和分组逻辑
- [x] 6.3 创建 `TrashFilterModeProvider`（支持全部/仅本地/仅远程过滤）
- [x] 6.4 实现过滤逻辑（根据过滤模式过滤本地/远程资源）

## 7. 回收站页面

- [x] 7.1 创建 `TrashPage` 页面类（`lib/presentation/pages/trash/trash_page.dart`）
- [x] 7.2 复用照片页面的展示组件（`SelectableTimelineSliverList`, AppBar 等）
- [x] 7.3 实现回收站数据展示逻辑
- [x] 7.4 添加过滤按钮（复用 `TimelineFilterButton` 样式）
- [x] 7.5 实现选择模式支持
- [x] 7.6 添加预览功能（导航到媒体查看器）

## 8. 回收站操作功能

- [x] 8.1 创建 `TrashSelectionBottomSheet` 组件（或扩展 `SelectionBottomSheet`）
- [x] 8.2 添加恢复按钮和永久删除按钮
- [x] 8.3 创建 `TrashRestoreService` 类（`lib/services/trash/trash_restore_service.dart`）
- [x] 8.4 实现本地资源恢复逻辑
- [x] 8.5 实现远程资源恢复逻辑（调用后端 API）
- [x] 8.6 创建 `TrashPurgeService` 类（`lib/services/trash/trash_purge_service.dart`）
- [x] 8.7 实现本地资源永久删除逻辑
- [x] 8.8 实现远程资源永久删除逻辑（调用后端 API）
- [x] 8.9 添加确认对话框（永久删除）
- [x] 8.10 添加批量操作支持

## 9. 路由配置

- [x] 9.1 在 `app_router.dart` 中添加回收站路由（`TrashRoute`）
- [x] 9.2 运行路由代码生成
- [x] 9.3 在导航栏或设置页面添加入口（已在相册页面和设置页面添加）

## 10. 错误处理和用户体验

- [x] 10.1 添加删除/恢复/永久删除操作的错误提示
- [ ] 10.2 添加操作进度提示（大文件操作时）（未来增强功能）
- [x] 10.3 添加操作成功提示
- [ ] 10.4 实现错误重试机制（未来增强功能，当前已有基本错误处理）
- [x] 10.5 添加空状态 UI（回收站为空时）

## 11. 代码质量检查

- [x] 11.1 运行代码格式化
- [x] 11.2 运行 linter 检查（已修复所有错误）
- [x] 11.3 运行数据库迁移验证（代码已实现，运行时验证）
- [x] 11.4 检查类型安全（无编译错误，已修复所有 linter 错误）

## 12. Bug 修复

### 12.1 修复删除系统相册文件失败问题

**问题描述**：
- 删除本地资源时，文件已复制到回收站，但删除系统相册中的原文件失败
- 错误信息：`PathNotFoundException: Cannot delete file, path = '/storage/emulated/0/Download/IMG_2136.JPG' (OS Error: No such file or directory, errno = 2)`
- 原因：直接删除文件路径在 Android 上无效，需要使用 `photo_manager` 的删除 API

**修复任务**：
- [x] 12.1.1 修改 `TrashStorageService.deleteFromSystemAlbum()` 方法
- [x] 12.1.2 使用 `PhotoManager.editor.deleteWithIds()` 方法替代直接删除文件
- [x] 12.1.3 添加错误处理和日志记录
- [ ] 12.1.4 验证删除操作在 Android 和 iOS 上都能正常工作

**相关文件**：
- `lib/services/trash/trash_storage_service.dart`

### 12.2 修复重启后回收站资源不可见问题

**问题描述**：
- 删除资源后，回收站资源可见
- 重启 app 后，回收站资源不可见
- 原因：本地同步服务的 `_detectDeletedAssets()` 方法可能误删已软删除的记录

**修复任务**：
- [x] 12.2.1 修改 `LocalSyncService._detectDeletedAssets()` 方法
- [x] 12.2.2 在检测已删除资产时，显式跳过已软删除的记录（`deletedAt != null`）
- [x] 12.2.3 确保 `getAllAssets()` 方法已正确过滤已软删除的记录（验证现有实现）
- [x] 12.2.4 添加日志记录，便于调试
- [ ] 12.2.5 验证修复后，重启 app 后回收站资源仍然可见

**相关文件**：
- `lib/features/local_sync/services/local_sync_service.dart`
- `lib/data/database/daos/local_asset_dao.dart`（验证 `getAllAssets()` 实现）

### 12.3 修复回收站中无法显示缩略图和预览图问题

**问题描述**：
- 删除本地照片后，回收站中无法显示缩略图和预览图，只显示占位符
- 原因：删除后，`AssetEntity.fromId()` 返回 `null`（文件已从系统相册删除），导致 `LocalThumbProvider` 和 `LocalFullImageProvider` 无法加载图片
- 文件已复制到回收站（`trashPath`），但当前图片加载逻辑依赖 `AssetEntity`，无法从文件路径直接加载

**修复任务**：
- [x] 12.3.1 创建 `FilePathThumbProvider` 类（从文件路径加载缩略图）
- [x] 12.3.2 创建 `FilePathFullProvider` 类（从文件路径加载完整图片）
- [x] 12.3.3 修改 `LocalAsset` 实体，添加 `trashPath` 字段（可选）
- [x] 12.3.4 修改 `trash_providers.dart`，在创建 `LocalAsset` 时传入 `trashPath`
- [x] 12.3.5 修改 `ResourceSelectionStrategy`，检测已删除的本地资产并使用文件路径提供者
- [ ] 12.3.6 验证回收站中能正确显示缩略图和预览图

**相关文件**：
- `lib/features/media_loading/providers/file_path_thumb_provider.dart`（新建）
- `lib/features/media_loading/providers/file_path_full_provider.dart`（新建）
- `lib/domain/entities/local_asset.dart`
- `lib/features/trash/providers/trash_providers.dart`
- `lib/features/media_loading/strategies/resource_selection_strategy.dart`

### 12.4 修复恢复时需要更新 assetId 问题

**问题描述**：
- 恢复本地资源时，文件从回收站复制回系统相册，会生成新的 `AssetEntity`（包含新的 `assetId`）
- 当前实现没有更新数据库中的 `assetId`，导致恢复后的资源无法通过旧的 `assetId` 访问
- 需要使用 `PhotoManager.editor.saveImage()` 或 `saveVideo()` 将文件添加回系统相册，并获取新的 `assetId`

**修复任务**：
- [x] 12.4.1 修改 `TrashRestoreService.restoreLocalAsset()` 方法
- [x] 12.4.2 使用 `PhotoManager.editor.saveImage()` 或 `saveVideo()` 将文件添加回系统相册
- [x] 12.4.3 获取新的 `AssetEntity` 和 `assetId`
- [x] 12.4.4 修改 `LocalAssetDao.restoreAsset()` 方法，支持更新 `assetId`（先删除旧记录，再插入新记录）
- [x] 12.4.5 更新数据库中的 `assetId`、`path`，并清空软删除字段
- [ ] 12.4.6 验证恢复后的资源能正常显示和访问

**相关文件**：
- `lib/services/trash/trash_restore_service.dart`
- `lib/data/database/daos/local_asset_dao.dart`

