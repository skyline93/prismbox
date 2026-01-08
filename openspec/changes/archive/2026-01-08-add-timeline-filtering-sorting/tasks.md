## 1. 创建数据模型

- [x] 1.1 创建 `mobile/lib/features/local_sync/models/timeline_content_filter_config.dart` 文件
- [x] 1.2 实现 `TimelineContentFilterConfig` 类，包含 `favoriteOnly` 和 `videoOnly` 可选参数
- [x] 1.3 添加工厂方法：`favoriteOnly()`, `videoOnly()`, `none()`
- [x] 1.4 添加 `hasContentFilter` getter 判断是否有内容过滤
- [x] 1.5 创建 `mobile/lib/features/local_sync/models/timeline_sort_config.dart` 文件
- [x] 1.6 实现 `TimelineSortField` 枚举（`createdAt`, `updatedAt`）
- [x] 1.7 实现 `SortOrder` 枚举（`asc`, `desc`）
- [x] 1.8 实现 `TimelineSortConfig` 类，包含 `sortBy` 和 `order` 参数
- [x] 1.9 添加工厂方法：`recentlyAdded()`, `defaultSort()`

## 2. 创建 Provider

- [x] 2.1 创建 `mobile/lib/providers/timeline/timeline_content_filter_provider.dart` 文件
- [x] 2.2 实现 `TimelineContentFilterConfigProvider`（使用 `family` 参数区分页面）
- [x] 2.3 提供设置方法：`setFavoriteOnly()`, `setVideoOnly()`, `clear()`
- [x] 2.4 创建 `mobile/lib/providers/timeline/timeline_sort_provider.dart` 文件
- [x] 2.5 实现 `TimelineSortConfigProvider`（使用 `family` 参数区分页面）
- [x] 2.6 提供设置方法：`setSortBy()`, `setSortOrder()`, `setRecentlyAdded()`

## 3. 扩展 Service 层

- [x] 3.1 修改 `TimelineProviderService.getTimelineAssets()` 方法签名，添加 `contentFilter` 和 `sortConfig` 参数
- [x] 3.2 实现 `_filterByContent()` 方法，处理收藏和视频过滤
- [x] 3.3 实现 `_applySort()` 方法，处理排序逻辑
- [x] 3.4 修改 `getTimelineAssets()` 方法，按顺序应用本地/远程隔离、内容过滤、排序
- [x] 3.5 更新 `_getFromDatabase()` 和 `_getFromPhotoManager()` 的调用，传递过滤和排序参数

## 4. 扩展 Provider 层

- [x] 4.1 修改 `timelineSectionsProvider`，读取 `TimelineContentFilterConfigProvider`（使用 `family` 参数）
- [x] 4.2 修改 `timelineSectionsProvider`，读取 `TimelineSortConfigProvider`（使用 `family` 参数）
- [x] 4.3 修改 `timelineSectionsProvider`，读取 `PhotoFilterModeProvider`（本地/远程隔离，全局共享）
- [x] 4.4 修改 `timelineSectionsProvider`，按顺序应用过滤和排序
- [x] 4.5 更新 `_filterAssets()` 方法，保留现有本地/远程隔离逻辑

## 5. 创建时间线页面组件

- [x] 5.1 创建 `mobile/lib/presentation/pages/collections/favorite_timeline_page.dart` 文件
- [x] 5.2 实现 `FavoriteTimelinePage`，设置内容过滤为仅收藏
- [x] 5.3 确保页面显示 `TimelineFilterButton`（本地/远程切换）
- [x] 5.4 创建 `mobile/lib/presentation/pages/collections/video_timeline_page.dart` 文件
- [x] 5.5 实现 `VideoTimelinePage`，设置内容过滤为仅视频
- [x] 5.6 确保页面显示 `TimelineFilterButton`（本地/远程切换）
- [x] 5.7 创建 `mobile/lib/presentation/pages/collections/recently_added_timeline_page.dart` 文件
- [x] 5.8 实现 `RecentlyAddedTimelinePage`，设置排序为按更新时间降序
- [x] 5.9 确保页面显示 `TimelineFilterButton`（本地/远程切换）

## 6. 更新合集页面

- [x] 6.1 修改 `AlbumsPage`，为"收藏"按钮绑定导航到 `FavoriteTimelinePage`
- [x] 6.2 修改 `AlbumsPage`，为"视频"按钮绑定导航到 `VideoTimelinePage`
- [x] 6.3 修改 `AlbumsPage`，为"最近添加"按钮绑定导航到 `RecentlyAddedTimelinePage`

## 7. 路由配置

- [x] 7.1 在 `app_router.dart` 中添加 `FavoriteTimelineRoute`
- [x] 7.2 在 `app_router.dart` 中添加 `VideoTimelineRoute`
- [x] 7.3 在 `app_router.dart` 中添加 `RecentlyAddedTimelineRoute`

## 8. 代码审查和文档

- [x] 8.1 更新相关注释和文档
- [x] 8.2 确保所有新类都有适当的文档注释
- [x] 8.3 在代码注释中说明扩展接口的预留位置

