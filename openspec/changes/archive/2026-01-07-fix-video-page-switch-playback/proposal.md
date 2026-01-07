# Change: 修复视频页面切换后无法播放的问题

## Why

当用户在预览页面播放视频时，滑动切换到下一个视频播放后，再滑动切换回上一个视频时，上一个视频无法播放。用户需要重新从照片页面点击缩略图再次进入预览才能播放。

问题根因：
1. 当前实现使用 `ViewerVideoManager` 的 `_currentVideoAssetId` 管理当前视频状态，但这不是响应式的
2. `ViewerVideoPage` 仅在 `didUpdateWidget` 中检查状态变化，但 PageView 可能复用 Widget 实例，导致 `didUpdateWidget` 不触发
3. 即使 `_handlePageChanged` 调用了 `playController`，但 `ViewerVideoPage` 无法响应式地感知状态变化并自动播放

参考 Immich 的实现，他们使用 Riverpod Provider 管理当前资产状态，并通过 `ref.listen` 响应式地通知所有视频页面状态变化。

## What Changes

- **添加响应式状态管理**：创建 `currentVideoAssetIdProvider` 来管理当前视频资产 ID
- **在 MediaViewerPage 中同步更新 Provider**：页面切换时同时更新 `ViewerVideoManager` 和 Provider
- **在 ViewerVideoPage 中使用 ref.listen**：响应式地监听当前视频状态变化，自动播放
- **增强 `_onPlaybackReady` 和 `_initializeVideo`**：确保只有当前视频才自动播放
- **修复视频切换回放问题**：确保切换回上一个视频时能够自动播放

## Impact

- **Affected specs**: `media-viewer`
- **Affected code**:
  - `mobile/lib/presentation/widgets/viewer/viewer_video_page.dart`
  - `mobile/lib/presentation/pages/viewer/media_viewer_page.dart`
  - 新增：`mobile/lib/presentation/widgets/viewer/viewer_video_state_provider.dart`
- **Breaking changes**: 无
- **New dependencies**: 无（使用现有的 Riverpod）

