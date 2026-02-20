# Design: 视频播放抽象与远程播放修复

## Context

- 媒体查看器当前使用 native_video_player 播放所有视频，通过 VideoProvider 产出 native_video_player 的 VideoSource（本地 file 或 network+headers）。远程播放失败因原生层未将 headers 带入 HTTP 请求。
- 项目已依赖 `video_player`，其 `VideoPlayerController.network(url, httpHeaders: ...)` 支持自定义头，适合仅远程场景。
- 需保持本地播放体验（含 HDR、本地 Live Photo motion），并便于未来扩展（签名 URL、新播放器）。

## Goals / Non-Goals

- **Goals**: 远程视频可正常播放（带认证）；播放引擎与播放源解耦；统一控制接口；源与引擎选择集中；易于扩展新引擎或新源类型。
- **Non-Goals**: 不替换本地播放的 native_video_player；不在此变更中实现服务端签名 URL（仅预留扩展点）。

## Decisions

- **统一控制器接口 ViewerPlaybackController**：抽象 position、duration、isPlaying、isReady、play()、pause()、seekTo()、setVolume()、setLoop()、add/remove Position/Status 监听、buildVideoView()、dispose()。ViewerVideoPage 与 VideoPlayerControls 只依赖此接口，不依赖具体播放器类型。
- **双引擎实现**：NativePlaybackController 包装 native_video_player，用于本地文件（及未来可选 signed URL）；NetworkPlaybackController 包装 video_player 的 VideoPlayerController.network，用于仅远程（URL + headers）。两者均实现 ViewerPlaybackController。
- **工厂集中选择**：PlaybackBackendFactory 根据 asset、serverUrl、assetEntityLoader、videoIdOverride 先解析「是否有本地文件」；有则返回 NativePlaybackController（本地路径）；无则解析远程 URL+headers，返回 NetworkPlaybackController。Live Photo 逻辑（本地 motion 优先、远程 fallback）在工厂或与 VideoProvider 协作中完成。
- **播放源类型（可选但推荐）**：引入 VideoPlaybackSource 密封类型（LocalFileSource(path)、RemoteNetworkSource(url, headers)），由工厂或 VideoProvider 产出，便于后续扩展 SignedUrlSource 等而不改调用方。
- **ViewerVideoManager**：由缓存 `Future<VideoSource?>` 改为缓存 `Future<ViewerPlaybackController?>`，通过 PlaybackBackendFactory 创建；对外仍可保留 getVideoSource 名称改为 getPlaybackController 或兼容旧名。

**Alternatives considered**

- 仅用 video_player 播所有视频：会失去本地 HDR 与部分原生优化，故不采用。
- 后端签名 URL：可彻底避免客户端带 header，但需后端改动；本设计预留扩展，不在此实现。
- 不抽象、仅在 ViewerVideoPage 内 if 分支：不利于扩展与测试，故采用抽象接口 + 工厂。

## Risks / Trade-offs

- **双引擎行为差异**：进度/缓冲等可能略有差异，通过统一接口与相同控制栏 UI 弱化差异。
- **video_player 能力**：远程 HDR 等能力可能不如 native，可接受；若未来需要可再引入支持 header 的其它插件。

## Migration Plan

1. 实现 video_playback 层（接口、Native 实现、Network 实现、工厂、可选 Source 类型）。
2. ViewerVideoManager 改为通过工厂返回 ViewerPlaybackController，保留按 assetId 的缓存语义。
3. ViewerVideoPage 改为持有 ViewerPlaybackController，画面区使用 controller.buildVideoView()，控制栏传入 controller。
4. VideoPlayerControls 改为接受 ViewerPlaybackController，内部用接口的 position/duration/play/pause/seek/volume 与监听。
5. 验证本地视频与本地 Live Photo 行为不变，远程视频可播放。
- **Rollback**: 保留原 VideoProvider/ViewerVideoManager 返回 VideoSource 的路径可配置或分支回退，直至验证通过后移除旧路径。

## Open Questions

- 无；实现阶段若发现 VideoProvider 与工厂职责边界需微调，在代码内注释说明即可。
