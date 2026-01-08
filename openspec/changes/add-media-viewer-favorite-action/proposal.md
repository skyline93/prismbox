# Change: 添加媒体预览页面收藏操作和显示

## Why

当前媒体预览页面（MediaViewerPage）的底部控制栏已有收藏按钮占位，但未实现实际功能。用户无法在预览页面中：
1. 查看当前媒体资源的收藏状态
2. 添加或取消收藏

这导致用户体验不完整，无法在预览媒体时直接管理收藏状态。参考 Immich 的实现，我们需要在预览页面提供完整的收藏功能，包括状态显示和操作。

**设计原则**：Prismbox 中的收藏操作仅更新 Prismbox 数据库，不修改系统相册。系统相册的收藏状态仅用于读取同步（在同步流程中从系统相册读取到 Prismbox 数据库）。

## What Changes

- **移除之前修改系统相册的代码**：
  - 移除 Pigeon 接口中的 `setIsFavorite` 方法
  - 移除 iOS 和 Android 原生实现中的 `setIsFavorite` 方法
  - 移除测试文件
  - 更新 `AssetFavoriteService`，移除对 `AssetNativeApi` 的依赖
- **创建资产收藏服务**（AssetFavoriteService），封装收藏状态切换逻辑（仅更新数据库）
- **更新 ViewerControlsBar 组件**，根据收藏状态显示不同图标（实心/空心）
- **在 MediaViewerPage 中集成收藏功能**，实现状态显示和切换操作
- **修复状态显示不一致问题**：确保 `_assetMap` 响应式更新，使用 `Consumer` 包装 `ViewerControlsBar` 直接响应 `timelineAssetsProvider` 更新
- **确保数据库和 UI 状态保持一致**，预览页面收藏按钮状态与照片页面缩略图状态一致

## Impact

- **受影响的 specs**:
  - `media-viewer`: 添加收藏功能需求
  - `asset-favorite`: 新增资产收藏服务能力（ADDED）
- **受影响的代码**:
  - `mobile/pigeon/asset_native_api.dart`: 移除 `setIsFavorite` 方法
  - `mobile/ios/Runner/Assets/AssetNativeApiImpl.swift`: 移除 `setIsFavorite` 方法实现
  - `mobile/android/app/src/main/kotlin/app/prismbox/assets/AssetNativeApiImpl.kt`: 移除 `setIsFavorite` 方法实现
  - `mobile/lib/services/asset/asset_favorite_service.dart`: 修改服务，移除对 `AssetNativeApi` 的依赖，仅更新数据库
  - `mobile/lib/providers/infrastructure/asset_providers.dart`: 更新 Provider，移除 `AssetNativeApi` 依赖
  - `mobile/lib/presentation/widgets/viewer/viewer_controls_bar.dart`: 更新收藏按钮显示
  - `mobile/lib/presentation/pages/viewer/media_viewer_page.dart`: 集成收藏功能，修复状态响应式更新
  - `mobile/lib/data/database/daos/local_asset_dao.dart`: 使用现有的 `updateAsset` 方法更新收藏状态
  - `mobile/test/services/asset/asset_favorite_service_test.dart`: 删除测试文件
- **性能影响**: 收藏操作仅涉及数据库更新，操作频率低，影响可忽略
- **兼容性**: 无平台兼容性问题，所有平台均支持数据库更新

