# Change: 添加异步宽高比获取服务以彻底修复视频拉伸问题

## Why

之前的修复（`fix-video-aspect-ratio`）在 `BaseAsset` 中添加了 `aspectRatio` getter，但存在一个关键问题：当 `asset.aspectRatio` 为 null 时（例如 width/height 未加载、RemoteAsset 没有 orientation），我们直接使用了临时宽高比（16/9），导致视频仍然被拉伸。

参考 Immich 的实现，当 `asset.aspectRatio` 为 null 时，需要异步从数据库获取 width/height/orientation，然后重新计算宽高比。这是彻底解决视频拉伸问题的关键。

**根本原因**：
1. `asset.aspectRatio` 可能为 null（width/height 未加载、orientation 为 null 等）
2. 缺少异步获取宽高比的机制（类似 Immich 的 `AssetService.getAspectRatio`）
3. 直接使用临时宽高比 16/9 导致拉伸

## What Changes

- 创建 `AssetService` 或扩展现有服务，提供 `getAspectRatio` 异步方法
- `getAspectRatio` 方法需要：
  - 对于 LocalAsset：如果 width/height 为 null，从数据库获取；使用 orientation 计算宽高比
  - 对于 RemoteAsset：如果 width/height 为 null，从数据库获取；从 EXIF 获取 orientation（如果可用，当前阶段可简化）；计算宽高比
- 修改 `ViewerVideoPage`，在 `initState` 中如果 `asset.aspectRatio` 为 null，异步调用 `getAspectRatio` 获取
- 确保在获取到宽高比后更新 `_aspectRatio`，避免使用临时宽高比
- 在宽高比获取完成前，使用临时宽高比（16/9）显示 `NativeVideoPlayerView`，避免死锁

## Impact

- **Affected specs**: `media-viewer`
- **Affected code**:
  - 新建服务类：`mobile/lib/services/asset/asset_service.dart`
  - `mobile/lib/presentation/widgets/viewer/viewer_video_page.dart`
  - 需要访问数据库 DAO（`LocalAssetDao`、`RemoteAssetDao`）
- **Breaking changes**: 无
- **New dependencies**: 无

