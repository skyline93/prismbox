# Change: 批量删除系统相册资产统一确认

## Why

当前批量删除本地资产时，系统会为每个资产弹出独立的确认对话框，导致用户体验不佳。用户删除多个资产时（如 10 个），需要确认 10 次，严重影响操作效率。

根本原因：`LocalAssetDeleteService.softDeleteAssets()` 循环调用 `softDeleteAsset()`，每个资产都单独调用 `PhotoManager.editor.deleteWithIds([assetId])`，触发多次系统确认。

## What Changes

- **新增** `TrashStorageService.deleteMultipleFromSystemAlbum()` 方法，支持批量删除系统相册资产
- **优化** `LocalAssetDeleteService.softDeleteAssets()` 方法，改为先批量处理文件复制和数据库更新，最后统一调用系统删除 API
- **保持** `softDeleteAsset()` 方法不变，确保单个删除场景不受影响

**关键改进**：
- 批量删除时，系统相册删除操作统一执行，只弹出一次确认对话框
- 提升批量删除操作的效率和用户体验

## Impact

- **受影响规范**：`specs/timeline-page/spec.md`
- **受影响代码**：
  - `mobile/lib/services/trash/trash_storage_service.dart`
  - `mobile/lib/services/trash/local_asset_delete_service.dart`
- **用户体验改进**：批量删除操作从多次确认优化为单次确认

