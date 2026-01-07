# Change: 修复视频预览宽高比计算问题

## Why

当前 PrismBox 在视频预览时存在宽高比计算错误的问题，导致手机拍摄的竖屏视频（9:16）被错误拉伸。根本原因是：

1. **缺少 orientation 处理**：`BaseAsset` 没有考虑图片/视频的 orientation（旋转角度），直接使用 `width / height` 计算宽高比
2. **竖屏视频被错误计算**：手机竖屏拍摄的视频，如果 orientation 是 90° 或 270°，需要交换宽高来计算正确的宽高比
3. **初始宽高比不准确**：`ViewerVideoPage` 在初始化时使用 `asset.width / asset.height`，没有考虑 orientation，导致初始显示时拉伸

参考 Immich 的实现，需要在 `BaseAsset` 中添加考虑 orientation 的宽高比计算逻辑，确保视频预览时使用正确的宽高比。

## What Changes

- 在 `BaseAsset` 中添加 `aspectRatio` getter，考虑 orientation 计算宽高比
- 添加 `isFlipped` getter，判断是否需要交换宽高（Android 上 90°/270° 需要交换）
- 添加 `orientatedWidth` 和 `orientatedHeight` getter，返回考虑 orientation 后的宽高
- 修改 `LocalAsset`，实现 `orientation` getter（使用私有字段避免命名冲突）
- 修改 `RemoteAsset`，实现 `orientation` getter（返回 null，远程资产需要从 EXIF 获取）
- 修改 `ViewerVideoPage`，使用 `asset.aspectRatio` 作为初始宽高比
- 如果 `asset.aspectRatio` 为 null，使用临时宽高比（16/9）显示 `NativeVideoPlayerView`，等待 `videoInfo` 准备好后更新为真实宽高比

## Impact

- **Affected specs**: `media-viewer`
- **Affected code**:
  - `mobile/lib/domain/entities/base_asset.dart`
  - `mobile/lib/domain/entities/local_asset.dart`
  - `mobile/lib/domain/entities/remote_asset.dart`
  - `mobile/lib/presentation/widgets/viewer/viewer_video_page.dart`
- **Breaking changes**: 无
- **New dependencies**: 无（仅使用 `dart:io` 的 `Platform` 类）

