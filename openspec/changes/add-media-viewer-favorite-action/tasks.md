# 实现任务清单

## 0. 移除之前修改系统相册的代码

- [x] 0.1 移除 Pigeon 接口中的 `setIsFavorite` 方法
  - [x] 0.1.1 在 `mobile/pigeon/asset_native_api.dart` 中移除 `setIsFavorite` 方法定义
  - [x] 0.1.2 重新生成 Pigeon 代码（iOS Swift、Android Kotlin、Dart）
- [x] 0.2 移除 iOS 原生实现
  - [x] 0.2.1 在 `mobile/ios/Runner/Assets/AssetNativeApiImpl.swift` 中移除 `setIsFavorite` 方法实现
- [x] 0.3 移除 Android 原生实现
  - [x] 0.3.1 在 `mobile/android/app/src/main/kotlin/app/prismbox/assets/AssetNativeApiImpl.kt` 中移除 `setIsFavorite` 方法实现
- [x] 0.4 移除测试文件
  - [x] 0.4.1 删除 `mobile/test/services/asset/asset_favorite_service_test.dart` 文件

## 1. 创建资产收藏服务

- [x] 1.1 修改 `AssetFavoriteService` 类（`lib/services/asset/asset_favorite_service.dart`）
  - [x] 1.1.1 移除对 `AssetNativeApi` 的依赖
  - [x] 1.1.2 更新构造函数，只接收 `LocalAssetDao` 参数
  - [x] 1.1.3 移除 `import 'package:prismbox/platform/asset_native_api.g.dart';`
- [x] 1.2 修改 `toggleFavorite` 方法
  - [x] 1.2.1 从数据库获取当前收藏状态
  - [x] 1.2.2 计算新的收藏状态（取反）
  - [x] 1.2.3 移除对原生 API 的调用，直接更新数据库中的收藏状态
  - [x] 1.2.4 更新注释，移除原生 API 相关的说明
- [x] 1.3 修改 `setFavorite` 方法
  - [x] 1.3.1 移除对 `_assetNativeApi.setIsFavorite` 的调用
  - [x] 1.3.2 直接更新数据库中的收藏状态
  - [x] 1.3.3 更新注释，说明仅更新数据库，不修改系统相册
- [x] 1.4 更新 Provider
  - [x] 1.4.1 在 `mobile/lib/providers/infrastructure/asset_providers.dart` 中移除 `AssetNativeApi` 的依赖
  - [x] 1.4.2 更新 `assetFavoriteServiceProvider`，只注入 `LocalAssetDao`
  - [x] 1.4.3 移除 `import 'package:prismbox/platform/asset_native_api.g.dart';`

## 2. 更新 ViewerControlsBar 组件

- [x] 2.1 修改 `ViewerControlsBar` 组件（`lib/presentation/widgets/viewer/viewer_controls_bar.dart`）
  - [x] 2.1.1 添加 `isFavorite` 参数（`bool?`，可选，默认为 `null`）
  - [x] 2.1.2 更新构造函数，接收 `isFavorite` 参数
  - [x] 2.1.3 根据 `isFavorite` 状态显示不同图标：
    - `true`: `Icons.favorite`（实心）
    - `false` 或 `null`: `Icons.favorite_border`（空心）
  - [x] 2.1.4 保持 `onFavorite` 回调不变
- [x] 2.2 确保组件符合性能优化要求
  - [x] 2.2.1 保持 `const` 构造函数（如果可能）
  - [x] 2.2.2 使用 `StatelessWidget`
  - [x] 2.2.3 避免不必要的重建

## 3. 更新 MediaViewerPage

- [x] 3.1 在 `MediaViewerPage` 中集成收藏功能（`lib/presentation/pages/viewer/media_viewer_page.dart`）
  - [x] 3.1.1 监听当前页面的资产 ID（通过 `PageController` 和 `onPageChanged`）
  - [x] 3.1.2 从 `timelineAssetsProvider` 获取当前资产的 `isFavorite` 状态
  - [x] 3.1.3 创建 `AssetFavoriteService` 实例（通过依赖注入或 Provider）
- [x] 3.2 实现收藏切换逻辑
  - [x] 3.2.1 创建 `_handleFavoriteToggle` 方法
  - [x] 3.2.2 调用 `assetFavoriteService.toggleFavorite(assetId)`（仅更新数据库）
  - [x] 3.2.3 实现乐观更新：先更新本地状态，再更新数据库
  - [x] 3.2.4 如果操作成功，刷新 `timelineAssetsProvider` 或更新本地状态
  - [x] 3.2.5 如果操作失败，显示错误提示并回滚 UI 状态
- [x] 3.3 更新 `ViewerControlsBar` 调用
  - [x] 3.3.1 使用 `Consumer` 包装 `ViewerControlsBar`，直接从 `timelineAssetsProvider` 获取当前资产的收藏状态
  - [x] 3.3.2 传递 `_handleFavoriteToggle` 作为 `onFavorite` 回调
- [x] 3.4 处理页面切换时的状态更新
  - [x] 3.4.1 在 `_handlePageChanged` 中更新当前资产的收藏状态
  - [x] 3.4.2 确保 UI 响应式更新
- [x] 3.5 修复状态响应式更新问题
  - [x] 3.5.1 修改 `_assetMap` 更新逻辑，去掉 `??=` 操作符，每次 `allAssets` 更新时都重新构建映射
  - [x] 3.5.2 确保预览页面收藏按钮状态与照片页面缩略图状态一致
  - [x] 3.5.3 确保预览页面收藏按钮状态与数据库状态一致

## 4. 错误处理和用户体验

- [x] 4.1 添加错误提示
  - [x] 4.1.1 捕获数据库更新异常
  - [x] 4.1.2 捕获资产不存在异常
  - [x] 4.1.3 显示友好的错误提示（使用 SnackBar 或 Dialog）
- [x] 4.2 添加加载状态
  - [x] 4.2.1 在收藏操作进行中禁用按钮（可选）
  - [x] 4.2.2 显示加载指示器（可选）
- [x] 4.3 处理并发操作
  - [x] 4.3.1 防止快速连续点击（使用防抖或禁用按钮）
  - [x] 4.3.2 确保操作完成后从数据库重新加载状态

## 5. 文档和注释

- [x] 5.1 在 `AssetFavoriteService` 中更新中文注释，说明服务职责和使用方法（仅更新数据库）
- [x] 5.2 在 `MediaViewerPage` 中添加中文注释，说明收藏功能集成逻辑
- [x] 5.3 在文档中说明收藏操作仅更新 Prismbox 数据库，不修改系统相册
