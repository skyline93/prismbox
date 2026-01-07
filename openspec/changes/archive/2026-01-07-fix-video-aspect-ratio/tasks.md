## 1. BaseAsset 修改
- [x] 1.1 在 `mobile/lib/domain/entities/base_asset.dart` 中添加 `dart:io` 导入（用于 `Platform` 类）
- [x] 1.2 添加 `orientation` getter（抽象方法，由子类实现）
- [x] 1.3 添加 `isFlipped` getter，判断是否需要交换宽高（Android 上 90°/270° 需要交换）
- [x] 1.4 添加 `orientatedWidth` getter，返回考虑 orientation 后的宽度
- [x] 1.5 添加 `orientatedHeight` getter，返回考虑 orientation 后的高度
- [x] 1.6 添加 `aspectRatio` getter，使用 `orientatedWidth` 和 `orientatedHeight` 计算宽高比

## 2. LocalAsset 修改
- [x] 2.1 在 `mobile/lib/domain/entities/local_asset.dart` 中将 `orientation` 字段改为私有字段 `_orientation`
- [x] 2.2 实现 `orientation` getter，返回 `_orientation`
- [x] 2.3 更新 `LocalAsset.fromData` 工厂方法，使用 `_orientation` 字段

## 3. RemoteAsset 修改
- [x] 3.1 在 `mobile/lib/domain/entities/remote_asset.dart` 中实现 `orientation` getter，返回 `null`（远程资产需要从 EXIF 获取，当前阶段不实现）

## 4. ViewerVideoPage 修改
- [x] 4.1 在 `mobile/lib/presentation/widgets/viewer/viewer_video_page.dart` 的 `initState` 方法中，使用 `asset.aspectRatio` 作为初始宽高比
- [x] 4.2 如果 `asset.aspectRatio` 为 null，使用临时宽高比（16/9）来显示 `NativeVideoPlayerView`
- [x] 4.3 在 `_onPlaybackReady` 方法中，移除 10% 差异限制，确保使用 `videoInfo` 的真实宽高比（已在之前的修改中完成）
- [x] 4.4 在 `_buildVideoPlayerWidget` 方法中，使用 `_aspectRatio ?? 16 / 9` 作为 `AspectRatio` 的值，确保 `NativeVideoPlayerView` 能被创建

## 5. 测试与验证
- [ ] 5.1 测试竖屏视频（9:16）的预览，确保不被拉伸
- [ ] 5.2 测试横屏视频（16:9）的预览，确保正常显示
- [ ] 5.3 测试不同 orientation 的视频（0°、90°、180°、270°）
- [ ] 5.4 测试 Android 平台的视频预览
- [ ] 5.5 测试 iOS 平台的视频预览
- [ ] 5.6 验证视频预览时宽高比计算的日志输出

## 6. 代码清理
- [x] 6.1 运行代码格式化（`dart format`）
- [x] 6.2 运行静态分析（`flutter analyze`）
- [x] 6.3 检查是否有未使用的导入（已确认无未使用的导入）
- [x] 6.4 更新相关代码注释（已在代码中添加注释说明）

