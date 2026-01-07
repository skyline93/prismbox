## 1. 创建 AssetService
- [x] 1.1 创建 `mobile/lib/services/asset/` 目录
- [x] 1.2 创建 `mobile/lib/services/asset/asset_service.dart` 文件
- [x] 1.3 定义 `AssetService` 类，接收 `LocalAssetDao` 和 `RemoteAssetDao` 依赖
- [x] 1.4 添加 `getAspectRatio` 异步方法，接收 `BaseAsset` 参数，返回 `Future<double>`
- [x] 1.5 实现 `_getLocalAssetDimensions` 方法：
  - 如果 width/height 为 null，从数据库获取（使用 `LocalAssetDao.getAssetById`）
  - 使用 orientation 计算 isFlipped（Android 上 90°/270° 需要交换）
  - 返回宽高和 isFlipped 标志
- [x] 1.6 实现 `_getRemoteAssetDimensions` 方法：
  - 如果 width/height 为 null，从数据库获取（使用 `RemoteAssetDao.getAssetById`）
  - 当前阶段简化处理：不考虑 orientation，直接使用 width/height
  - 返回宽高和 isFlipped 标志（当前阶段为 false）
- [x] 1.7 在 `getAspectRatio` 中根据 isFlipped 计算宽高比：
  - 如果 isFlipped 为 true，返回 height / width
  - 否则返回 width / height
  - 如果 width/height 为 null 或 height 为 0，返回默认值 1.0

## 2. 创建 Riverpod Provider
- [x] 2.1 检查是否已有 Provider 文件（如 `mobile/lib/providers/asset_providers.dart`）
- [x] 2.2 如果不存在，创建 Provider 文件（已存在 `asset_providers.dart`，在其中添加）
- [x] 2.3 创建 `assetServiceProvider`，注入 `LocalAssetDao` 和 `RemoteAssetDao` 依赖
- [x] 2.4 确保 Provider 能够访问 `AppDatabase`（通过 `databaseProvider`）

## 3. 修改 ViewerVideoPage
- [x] 3.1 在 `ViewerVideoPage` 中添加对 `AssetService` 的依赖（通过 ConsumerStatefulWidget 和 ref）
- [x] 3.2 在 `initState` 中，如果 `asset.aspectRatio` 为 null，异步调用 `assetService.getAspectRatio(asset)`
- [x] 3.3 在获取到宽高比后，更新 `_aspectRatio` 并调用 `setState`
- [x] 3.4 确保在宽高比获取完成前，使用临时宽高比（16/9）显示 `NativeVideoPlayerView`
- [x] 3.5 添加错误处理：如果获取失败，使用默认宽高比 1.0 或保持临时宽高比

## 4. 测试与验证
- [ ] 4.1 测试 width/height 为 null 的情况（LocalAsset）
- [ ] 4.2 测试 width/height 为 null 的情况（RemoteAsset）
- [ ] 4.3 测试 orientation 为 null 的情况（RemoteAsset）
- [ ] 4.4 测试异步获取宽高比的逻辑
- [ ] 4.5 验证视频预览时不再被拉伸（竖屏视频 9:16、横屏视频 16:9）
- [ ] 4.6 验证在宽高比获取完成前，视频能够正常显示（使用临时宽高比）

## 5. 代码清理
- [x] 5.1 运行代码格式化（`dart format`）
- [x] 5.2 运行静态分析（`flutter analyze`）
- [x] 5.3 检查是否有未使用的导入（已确认无未使用的导入）
- [x] 5.4 更新相关代码注释（已在代码中添加注释说明）

## 6. 修复 iOS 视频拉伸问题（基于 Immich 实现）
- [x] 6.1 方案1：在 iOS 上存储时强制 orientation = 0（`local_sync_service.dart`）
  - 导入 `dart:io` 以使用 `Platform.isIOS`
  - 修改 `_convertToEntity` 方法，iOS 上强制 `orientation = 0`（与 Immich 一致）
  - 添加注释说明：iOS Photos framework 已经预校正了尺寸
- [x] 6.2 方案3：移除 `viewer_video_page.dart` 中的空 `setState` 调用
  - 移除 `_onPlaybackStatusChanged` 中的空 `setState` 调用
  - 移除 `_onPlaybackPositionChanged` 中的空 `setState` 调用
  - 添加注释说明：避免频繁重建
- [x] 6.3 运行代码格式化和静态分析验证
- [x] 6.4 方案2：在 iOS 上使用 AssetEntity 的宽高（修复旧数据问题）
  - 修改 `AssetService._getLocalAssetDimensions` 方法
  - iOS 上，如果 `assetEntity` 可用，直接使用其 `width/height`（已预校正）
  - 如果 `assetEntity` 为 null，异步加载它（从数据库创建的 LocalAsset 可能没有 assetEntity）
  - 这样可以修复数据库中已存在的旧数据（在方案1修改之前同步的）
  - 添加日志记录以便调试
  - 导入 `photo_manager` 的 `AssetEntity` 类
- [x] 6.5 强制对齐 Immich：修改 `BaseAsset.isFlipped` getter
  - iOS 上返回 `null` 而不是 `false`（与 Immich 一致）
  - 这样 `orientatedWidth/Height` 在 iOS 上返回 `null`
  - `aspectRatio` 在 iOS 上返回 `null`，强制使用 `AssetService.getAspectRatio`
  - 确保 iOS 上使用数据库中已预校正的 `width/height`
  - 如果数据错误，会立即暴露问题，而不是被隐藏
- [x] 6.6 强制对齐 Immich：修改 `BaseAsset.orientatedWidth/Height` getter
  - iOS 上，如果 `isFlipped` 为 `null`，返回 `null`（与 Immich 一致）
  - 之前返回 `width/height`，导致 `aspectRatio` 仍然使用错误的宽高计算
  - 现在返回 `null`，确保 `aspectRatio` 在 iOS 上返回 `null`，强制使用 `AssetService.getAspectRatio`

