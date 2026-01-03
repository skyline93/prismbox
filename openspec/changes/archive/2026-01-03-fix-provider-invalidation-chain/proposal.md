# Change: 修复照片页面和回收站页面删除/恢复后不立即更新的问题

## Why

当前系统存在两个 UI 更新问题：

1. **删除照片后照片页面不立即更新**：删除照片后，照片页面仍显示已删除的照片，需要重启 app 后才正常不显示
2. **恢复照片后回收站页面不立即更新**：在回收站恢复照片后，回收站页面仍显示已恢复的照片

**根本原因**：Riverpod Provider 依赖链刷新不完整。当只 invalidate 上层 provider 时，下层依赖的 provider 可能仍返回缓存数据，导致 UI 显示旧数据。

**依赖链结构**：
- `timelineSectionsProvider` → `timelineAssetsProvider()` → 数据库查询
- `trashSectionsProvider` → `trashAssetsProvider` → 数据库查询

**历史参考**：项目中之前已解决过类似的"上传状态图标不更新问题"（`doc/issue/上传状态图标不更新问题排查总结.md`），根本原因和解决方案相同。

## What Changes

- **MODIFIED**: 修复 `TimelineDeleteHandler.handleDelete()` 方法，删除操作完成后同时 invalidate `timelineAssetsProvider()` 和 `timelineSectionsProvider`
- **MODIFIED**: 修复 `TrashPage._handleRestore()` 方法，恢复操作完成后同时 invalidate `trashAssetsProvider` 和 `trashSectionsProvider`
- **MODIFIED**: 修复 `TrashPage._handlePurge()` 方法，永久删除操作完成后同时 invalidate `trashAssetsProvider` 和 `trashSectionsProvider`
- **MODIFIED**: 更新相关能力规范，明确要求同时 invalidate 依赖链上的所有 provider

## Impact

- **Affected specs**: 
  - 修改 `timeline-page` 能力规范（明确删除后刷新要求）
  - 修改 `trash` 能力规范（明确恢复和永久删除后刷新要求）
- **Affected code**: 
  - `lib/presentation/pages/photos/controllers/timeline_delete_handler.dart` - 修复删除后刷新逻辑
  - `lib/presentation/pages/trash/trash_page.dart` - 修复恢复和永久删除后刷新逻辑
- **Breaking changes**: 无
- **Migration**: 无

