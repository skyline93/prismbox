# Change: 重构视频播放以支持 HDR

## Why

当前 PrismBox 使用 `video_player` 插件进行视频播放，该插件不支持 HDR 视频格式（HEVC/H.265、VP9、AV1 等）。为了提供更好的视频播放体验，特别是支持 HDR 视频，需要替换为基于原生播放器的 `native_video_player` 插件，该插件在 Android 上基于 ExoPlayer，在 iOS 上基于 AVPlayer，原生支持 HDR 格式。

参考 Immich 移动端的实现方案，采用相同的技术栈可以确保稳定性和兼容性。

## What Changes

- **BREAKING**: 替换 `video_player` 为 `native_video_player` 插件
- 重构 `VideoProvider`：返回 `native_video_player` 的 `VideoSource` 类型
- 重构 `ViewerVideoManager`：管理 `NativeVideoPlayerController` 而非 `VideoPlayerController`
- 重构 `ViewerVideoPage`：使用 `NativeVideoPlayerView` 渲染视频
- 添加 `native_video_player` 依赖（GitHub 源）
- 更新视频播放控制逻辑以适配新的 API
- 支持 HDR 视频自动识别和渲染
- **修复视频切换播放问题**：对齐 Immich 的实现，修复 controller 生命周期同步问题
- **移除全局 controller 缓存**：每个 Widget 独立管理 controller，完全对齐 Immich 的架构

## Additional Fixes Required

由于实现后发现视频切换时存在 `MissingPluginException` 和黑屏问题，需要额外修复以完全对齐 Immich 的实现：

- **移除全局 controller 缓存**：`ViewerVideoManager` 不再缓存 controller，每个 `ViewerVideoPage` Widget 独立管理自己的 controller（对齐 Immich）
- **修复 controller 生命周期同步问题**：确保 controller 与 `NativeVideoPlayerView` 的生命周期同步
- **对齐 initController 逻辑**：参考 Immich，直接加载视频源，不通过 `ViewerVideoManager`
- **对齐 ref.listen 逻辑**：使用本地状态延迟更新，确保切换动画完成后再播放
- **修复 onPlaybackReady 检查**：开头就检查 `isCurrent`，只有当前视频才执行播放逻辑
- **修复 dispose 和 ref.listen**：正确清理监听器和停止播放，对齐 Immich 的 useEffect cleanup

## Impact

- **Affected specs**: `media-viewer`
- **Affected code**:
  - `mobile/lib/features/media_loading/video_provider.dart`
  - `mobile/lib/presentation/widgets/viewer/viewer_video_manager.dart`（移除 controller 缓存相关功能）
  - `mobile/lib/presentation/widgets/viewer/viewer_video_page.dart`（独立管理 controller）
  - `mobile/lib/presentation/widgets/viewer/viewer_video_controller.dart`
  - `mobile/lib/presentation/pages/viewer/media_viewer_page.dart`（移除对 ViewerVideoManager controller 操作的调用）
  - `mobile/pubspec.yaml`
- **Breaking changes**: 
  - `VideoProvider.getVideoSource` 返回类型从自定义 `VideoSource` 改为 `native_video_player.VideoSource`
  - `ViewerVideoManager` 移除 controller 缓存相关方法（`registerController`, `registerControllerOnly`, `getController`, `playController`, `pauseController`, `setMuted`, `isMuted`）
  - `ViewerVideoManager` 只保留视频源缓存和可见页面范围管理功能
  - `ViewerVideoPage` 使用 `NativeVideoPlayerView` 替代 `VideoPlayer`，并独立管理 controller
  - `ViewerVideoPage` 不再依赖 `ViewerVideoManager` 进行播放控制，直接操作本地 controller
- **New dependencies**: `native_video_player` (GitHub: `https://github.com/immich-app/native_video_player`)

