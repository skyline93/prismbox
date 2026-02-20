# video-playback Specification (Delta)

## ADDED Requirements

### Requirement: 播放控制器抽象

系统 SHALL 提供统一的视频播放控制器抽象（ViewerPlaybackController），供媒体查看器与控制栏使用，不依赖具体播放引擎实现。该接口 SHALL 暴露播放状态与控制能力，并负责提供用于渲染视频画面的 Widget。

#### Scenario: 接口提供状态与控制方法

- **WHEN** 使用 ViewerPlaybackController 抽象
- **THEN** 接口 SHALL 提供 position、duration、isPlaying、isReady 的读取
- **AND** 接口 SHALL 提供 play()、pause()、seekTo(Duration)、setVolume(double)、setLoop(bool) 方法
- **AND** 接口 SHALL 提供 addPositionListener/removePositionListener、addStatusListener/removeStatusListener 用于进度与状态变化通知
- **AND** 接口 SHALL 提供 buildVideoView() 返回用于显示视频画面的 Widget
- **AND** 接口 SHALL 提供 dispose() 用于释放资源

#### Scenario: 查看器与控制栏仅依赖该接口

- **WHEN** ViewerVideoPage 或视频控制栏组件使用播放控制器
- **THEN** 二者 SHALL 仅依赖 ViewerPlaybackController 类型
- **AND** 不得依赖 native_video_player 或 video_player 的具体控制器类型

### Requirement: 本地与远程引擎分工

系统 SHALL 对「本地可用的视频文件」使用基于 native_video_player 的引擎实现，对「仅远程可用的视频」使用支持自定义 HTTP 头的引擎实现（如 Flutter video_player），以确保远程请求携带认证头并可正常播放。

#### Scenario: 本地文件使用原生引擎

- **WHEN** 播放源为本地文件路径（含本地 Live Photo motion 文件）
- **THEN** 系统 SHALL 使用实现 ViewerPlaybackController 的本地引擎（如 NativePlaybackController）
- **AND** 该引擎 SHALL 基于 native_video_player 加载本地路径

#### Scenario: 仅远程使用支持自定义头的引擎

- **WHEN** 无本地文件且存在远程媒体 URL 与认证头
- **THEN** 系统 SHALL 使用实现 ViewerPlaybackController 的网络引擎（如 NetworkPlaybackController）
- **AND** 该引擎 SHALL 使用支持 httpHeaders 的 API（如 VideoPlayerController.network(url, httpHeaders: headers)）发起请求
- **AND** 请求 SHALL 携带与现有 API 一致的认证头（如 x-prismbox-user-token）

### Requirement: 播放源与引擎选择集中

系统 SHALL 在单一工厂（如 PlaybackBackendFactory）中根据资产与上下文解析「本地路径」或「远程 URL+headers」，并据此选择并创建对应的 ViewerPlaybackController 实现，避免在查看器页面内分散 if/else 分支。

#### Scenario: 工厂根据资产解析并返回控制器

- **WHEN** 调用工厂方法并传入 asset、assetId、serverUrl、assetEntityLoader、videoIdOverride
- **THEN** 工厂 SHALL 优先尝试解析本地可播放文件路径（含 Live Photo 本地 motion）
- **AND** 若存在本地路径，SHALL 返回基于本地引擎的 ViewerPlaybackController
- **AND** 若无本地路径，SHALL 解析远程 URL 与请求头并返回基于网络引擎的 ViewerPlaybackController
- **AND** 若无法解析任何可用源，SHALL 返回 null

#### Scenario: 扩展新引擎或新源类型

- **WHEN** 未来需要支持新播放引擎或新源类型（如签名 URL）
- **THEN** 系统 SHALL 通过新增 ViewerPlaybackController 实现或新源类型并在工厂中增加分支完成
- **AND** ViewerVideoPage 与控制栏 SHALL 无需修改

### Requirement: 远程视频可播放

媒体查看器在播放「仅远程」视频资产时，SHALL 使用支持自定义 HTTP 头的播放路径，使请求 `/api/v1/media/:uuid/download/original` 时携带认证头，从而能够正常返回 200 并播放。

#### Scenario: 仅远程视频能成功加载并播放

- **WHEN** 用户在媒体查看器中打开仅远程存在的视频资产（无本地文件）
- **THEN** 系统 SHALL 使用带认证头的 HTTP 请求加载视频 URL
- **AND** 用户 SHALL 能够看到视频画面并进行播放、暂停、进度与音量控制
- **AND** 播放失败时 SHALL 显示错误状态并可恢复浏览（与现有错误处理一致）
