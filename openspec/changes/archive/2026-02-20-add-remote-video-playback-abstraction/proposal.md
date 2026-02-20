# Change: 远程视频可播放与播放层抽象

## Why

远程资产视频当前无法播放。根因是 native_video_player 在 iOS/Android 上对自定义 HTTP 头支持不足，请求 `/api/v1/media/:uuid/download/original` 时未携带认证头（如 `x-prismbox-user-token`），导致服务端返回 401。同时，播放逻辑与单一引擎（native_video_player）强耦合，不利于后续扩展（如签名 URL、新播放器）与维护。

## What Changes

- 引入**播放控制器抽象**（ViewerPlaybackController）：统一 play/pause、position/duration、音量、seek、监听与画面 Widget，使 ViewerVideoPage 与控制栏仅依赖该接口。
- 引入**播放源与引擎分离**：源解析（本地路径 vs 远程 URL+headers）与引擎选择集中在一处（PlaybackBackendFactory）；本地/merged 优先用本地文件并继续使用 native_video_player，仅远程使用支持自定义头的引擎（Flutter video_player）。
- **远程视频播放**：仅远程（无本地文件）时使用 `video_player` 的 `VideoPlayerController.network(url, httpHeaders: headers)` 播放，保证请求带认证头，修复远程视频无法播放的问题。
- 新增能力规格 **video-playback**：定义播放源类型、控制器接口、工厂选择策略及远程/本地引擎分工。
- 更新 **media-viewer** 规格：ViewerVideoPage 使用抽象控制器与工厂获取控制器；控制栏依赖 ViewerPlaybackController 接口；明确远程视频必须可播放。

## Impact

- Affected specs: video-playback (new), media-viewer (modified)
- Affected code:
  - New: `mobile/lib/features/video_playback/`（viewer_playback_controller.dart, native_playback_controller.dart, network_playback_controller.dart, playback_backend_factory.dart, playback_source.dart）
  - Modified: `mobile/lib/presentation/widgets/viewer/viewer_video_page.dart`, `viewer_video_manager.dart`, `viewer_video_controller.dart` (VideoPlayerControls)
  - Modified: `mobile/lib/features/media_loading/video_provider.dart`（可选：产出 PlaybackSource 或仅被工厂/管理器调用）
