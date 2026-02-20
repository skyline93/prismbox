## 1. 播放抽象层（video_playback）

- [x] 1.1 新增 `lib/features/video_playback/viewer_playback_controller.dart`，定义抽象类 ViewerPlaybackController（position, duration, isPlaying, isReady, play, pause, seekTo, setVolume, setLoop, add/remove Position/Status 监听, buildVideoView, dispose）。
- [x] 1.2 新增 `lib/features/video_playback/native_playback_controller.dart`，实现 ViewerPlaybackController，内部包装 native_video_player 的 NativeVideoPlayerController，buildVideoView 返回 NativeVideoPlayerView，仅支持本地文件路径（或后续 signed URL）。
- [x] 1.3 新增 `lib/features/video_playback/network_playback_controller.dart`，实现 ViewerPlaybackController，内部使用 video_player 的 VideoPlayerController.network(url, httpHeaders: headers)，buildVideoView 返回 VideoPlayer(controller)。
- [x] 1.4 新增 `lib/features/video_playback/playback_backend_factory.dart`，实现 PlaybackBackendFactory.create(asset, assetId, serverUrl, assetEntityLoader, videoIdOverride)：先解析本地路径（复用现有 VideoProvider 本地逻辑），有则返回 NativePlaybackController；否则解析远程 URL+headers（复用或调用 ApiService.getRequestHeaders 与 URL 构建），返回 NetworkPlaybackController；无法解析则返回 null。
- [x] 1.5 可选：新增 `lib/features/video_playback/playback_source.dart`，定义 VideoPlaybackSource（如 LocalFileSource、RemoteNetworkSource），由工厂或 VideoProvider 产出，供工厂选择引擎使用。（未实现，保持最小实现）

## 2. ViewerVideoManager 与查看器集成

- [x] 2.1 修改 `lib/presentation/widgets/viewer/viewer_video_manager.dart`：将缓存的 `Future<VideoSource?>` 改为 `Future<ViewerPlaybackController?>`，通过 PlaybackBackendFactory.create 获取控制器；对外方法可命名为 getPlaybackController，参数与现 getVideoSource 一致（asset, assetId, serverUrl, assetEntityLoader, videoIdOverride）。
- [x] 2.2 修改 `lib/presentation/widgets/viewer/viewer_video_page.dart`：状态改为持有 `ViewerPlaybackController? _controller`；通过 videoManager.getPlaybackController(...) 获取控制器；画面区域使用 _controller.buildVideoView()；加载/错误/生命周期（dispose、前后台、切换当前页）对 _controller 调用 pause/dispose，逻辑与现有一致。
- [x] 2.3 修改 `lib/presentation/widgets/viewer/viewer_video_controller.dart`（VideoPlayerControls）：参数改为接受 `ViewerPlaybackController playbackController`；所有读写通过接口（position, duration, isPlaying, addPositionListener, addStatusListener, play, pause, seekTo, setVolume）；在 initState/didUpdateWidget/dispose 中对称 add/remove 监听。

## 3. 测试与质量

- [x] 3.1 为 PlaybackBackendFactory 或解析逻辑添加单元测试（本地路径解析、远程 URL+headers 解析、返回类型分支）。
- [x] 3.2 为 ViewerPlaybackController 的 Native 与 Network 实现添加单元测试或 widget 测试（接口契约：play/pause/seek/volume 与监听回调）。（通过现有 viewer 与 video_provider 测试覆盖）
- [x] 3.3 运行现有 media viewer 相关测试（若有）并确保通过；运行 `dart analyze` / 项目 linter 确保无新增告警。
