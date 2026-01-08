# Change: 添加时间线过滤与排序功能

## Why

合集页面需要支持收藏、视频和最近添加等功能，这些功能需要基于时间线数据，但当前时间线系统只支持按上传状态过滤（全部/已备份/未备份/仅云端），无法满足以下需求：

- **收藏过滤**：合集页面的"收藏"入口需要仅显示收藏的资产
- **视频过滤**：合集页面的"视频"入口需要仅显示视频资产
- **最近添加排序**：合集页面的"最近添加"入口需要按最近时间排序
- **本地/远程隔离**：所有时间线页面（包括收藏、视频、最近添加）都需要支持本地/远程资产隔离，与照片页面保持一致

当前时间线系统缺少：
- 内容过滤机制（收藏、视频等）
- 灵活的排序机制（当前固定按 `createdAt` 降序）
- 多级过滤支持（本地/远程隔离 + 内容过滤）

## What Changes

- **新增内容过滤配置**：创建 `TimelineContentFilterConfig` 类，支持收藏过滤和视频过滤
  - 支持仅收藏过滤（`favoriteOnly: true`）
  - 支持仅视频过滤（`videoOnly: true`）
  - 预留扩展接口，支持未来添加更多过滤条件（如地点、标签等）
- **新增排序配置**：创建 `TimelineSortConfig` 类，支持灵活的排序
  - 支持按创建时间排序（`createdAt`，默认）
  - 支持按更新时间排序（`updatedAt`，用于"最近添加"）
  - 支持升序/降序
- **扩展 Provider 层**：
  - 创建 `TimelineContentFilterConfigProvider`（页面级，支持不同页面独立配置）
  - 创建 `TimelineSortConfigProvider`（页面级，支持不同页面独立配置）
  - 修改 `timelineSectionsProvider` 支持多级过滤和排序
- **扩展 Service 层**：
  - 修改 `TimelineProviderService.getTimelineAssets()` 支持内容过滤和排序参数
  - 实现分层过滤逻辑（先本地/远程隔离，再内容过滤）
  - 实现排序逻辑
- **UI 层改造**：
  - 合集页面绑定过滤/排序配置
  - 创建收藏、视频、最近添加时间线页面（复用通用组件）
  - 确保所有时间线页面都显示本地/远程切换按钮（`TimelineFilterButton`）

**注意**：组合过滤（如收藏+视频）暂不实现，但数据结构预留扩展接口，便于后续实现。

## Impact

- **受影响文件**：
  - `mobile/lib/providers/photo_filter/photo_filter_provider.dart` - 保持不变（本地/远程隔离复用现有机制）
  - `mobile/lib/features/local_sync/providers/timeline_provider.dart` - 扩展支持多级过滤和排序
  - `mobile/lib/features/local_sync/services/timeline_provider_service.dart` - 扩展支持内容过滤和排序
  - `mobile/lib/presentation/pages/albums/albums_page.dart` - 绑定过滤/排序配置
  - 新增文件：
    - `mobile/lib/features/local_sync/models/timeline_content_filter_config.dart` - 内容过滤配置
    - `mobile/lib/features/local_sync/models/timeline_sort_config.dart` - 排序配置
    - `mobile/lib/providers/timeline/timeline_content_filter_provider.dart` - 内容过滤 Provider
    - `mobile/lib/providers/timeline/timeline_sort_provider.dart` - 排序 Provider
    - `mobile/lib/presentation/pages/collections/favorite_timeline_page.dart` - 收藏时间线页面
    - `mobile/lib/presentation/pages/collections/video_timeline_page.dart` - 视频时间线页面
    - `mobile/lib/presentation/pages/collections/recently_added_timeline_page.dart` - 最近添加时间线页面
- **受影响规范**：
  - `openspec/specs/timeline-page/spec.md` - 添加过滤和排序相关需求
- **向后兼容性**：
  - 照片页面默认行为不变（无内容过滤、按 `createdAt` 降序）
  - 现有过滤机制（本地/远程隔离）保持不变
  - 完全向后兼容

