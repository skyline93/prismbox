## MODIFIED Requirements

### Requirement: 视频查看页面为独立组件
媒体查看器页面（MediaViewerPage）的 UI 组件 SHALL 遵循原子组件拆分原则，将大型 UI 逻辑拆分为独立的、可复用的组件和业务逻辑类。

#### Scenario: 视频查看页面为独立组件
- **WHEN** 使用 ViewerVideoPage 组件
- **THEN** 该组件 SHALL 位于 `lib/presentation/widgets/viewer/viewer_video_page.dart`
- **AND** 组件类名 SHALL 为 `ViewerVideoPage`
- **AND** 组件 SHALL 使用 `StatefulWidget`（需要处理视频加载状态）
- **AND** 组件 SHALL 接收 `asset`、`assetId`、`videoManager`、`serverUrl`、`assetEntityLoader` 等参数
- **AND** 组件 SHALL 通过回调函数处理 `showControls`、`onToggleControls`、`onMuteChanged` 事件
- **AND** 组件 SHALL 使用 `ViewerVideoManager` 管理视频控制器
- **AND** 组件 SHALL 使用 `NativeVideoPlayerView` 渲染视频（基于 `native_video_player` 插件）
- **AND** 组件 SHALL 处理视频加载和错误状态
- **AND** 组件 SHALL 集成视频控制器 UI
- **AND** 组件 SHALL 支持 HDR 视频自动识别和渲染

## ADDED Requirements

### Requirement: 视频播放器使用原生播放器
视频播放功能 SHALL 使用 `native_video_player` 插件，基于平台原生播放器（Android ExoPlayer、iOS AVPlayer），以支持 HDR 视频格式。

#### Scenario: 使用 native_video_player 插件
- **WHEN** 播放视频时
- **THEN** 系统 SHALL 使用 `native_video_player` 插件进行视频播放
- **AND** Android 平台 SHALL 使用 ExoPlayer 作为底层播放器
- **AND** iOS 平台 SHALL 使用 AVPlayer 作为底层播放器
- **AND** 系统 SHALL 自动识别并启用 HDR 渲染（支持 HEVC/H.265、VP9、AV1 等格式）
- **AND** 系统 SHALL 无需额外配置即可支持 HDR 视频播放

#### Scenario: VideoProvider 返回原生视频源
- **WHEN** 获取视频源时
- **THEN** `VideoProvider.getVideoSource` 方法 SHALL 返回 `native_video_player.VideoSource` 类型
- **AND** 本地视频 SHALL 使用 `VideoSource.init(path: filePath, type: VideoSourceType.file)` 创建
- **AND** 远程视频 SHALL 使用 `VideoSource.init(path: url, type: VideoSourceType.network, headers: ...)` 创建
- **AND** 远程视频 SHALL 支持自定义请求头（用于认证）

#### Scenario: ViewerVideoPage 独立管理 controller（对齐 Immich）
- **WHEN** 管理视频播放器时
- **THEN** 每个 `ViewerVideoPage` Widget SHALL 独立管理自己的 `NativeVideoPlayerController`（对齐 Immich 的 `controller.value`）
- **AND** `ViewerVideoManager` SHALL 不缓存 controller，只提供视频源缓存和可见页面范围管理功能
- **AND** 控制器创建 SHALL 在 `initController` 中直接使用 `VideoSource` 通过 `loadVideoSource` 方法加载视频
- **AND** 播放控制 SHALL 在 `ViewerVideoPage` 中直接调用 `controller.play()`、`controller.pause()` 等方法
- **AND** 音量控制 SHALL 在 `ViewerVideoPage` 中直接调用 `controller.setVolume()` 方法
- **AND** 状态监听 SHALL 使用 `onPlaybackReady`、`onPlaybackStatusChanged`、`onPlaybackPositionChanged`、`onPlaybackEnded` 回调
- **AND** 资源释放 SHALL 在 `dispose` 中使用 `controller.stop()` 方法

#### Scenario: 视频播放功能完整性
- **WHEN** 播放视频时
- **THEN** 系统 SHALL 支持播放/暂停控制
- **AND** 系统 SHALL 支持进度控制（拖拽进度条）
- **AND** 系统 SHALL 支持音量控制（静音/取消静音）
- **AND** 系统 SHALL 支持循环播放（根据用户设置）
- **AND** 系统 SHALL 支持自动播放（根据用户设置）
- **AND** 系统 SHALL 支持本地和远程视频播放
- **AND** 系统 SHALL 支持视频切换（左右滑动切换视频）
- **AND** 系统 SHALL 正确处理视频加载错误（文件不存在、网络错误等）

#### Scenario: 应用生命周期管理
- **WHEN** 应用进入后台时
- **THEN** 正在播放的视频 SHALL 自动暂停
- **AND** 应用恢复前台时 SHALL 根据状态决定是否继续播放
- **WHEN** 视频播放时
- **THEN** 系统 SHALL 启用唤醒锁防止屏幕关闭
- **AND** 视频暂停或结束时 SHALL 禁用唤醒锁

#### Scenario: 资源管理
- **WHEN** 视频不在可见范围内时
- **THEN** 系统 SHALL 释放视频控制器资源
- **AND** 系统 SHALL 保持可见页面范围（当前页 ± 1）内的视频控制器
- **AND** 系统 SHALL 在页面销毁时正确释放所有视频控制器

#### Scenario: Controller 生命周期管理对齐 Immich
- **WHEN** 初始化视频控制器时
- **THEN** `initController` 方法 SHALL 只检查本地 `_controller` 状态，不检查从 `ViewerVideoManager` 获取的 controller
- **AND** 方法 SHALL 直接调用 `nc.loadVideoSource(source)` 加载视频源
- **AND** 方法 SHALL 在加载完成后设置本地 `_controller` 状态
- **AND** 方法 SHALL 使用 `NativeVideoPlayerView(key: ValueKey(assetId), ...)` 确保 assetId 改变时 Widget 被销毁并重新创建
- **AND** 方法 SHALL 不通过 `ViewerVideoManager` 注册或缓存 controller（每个 Widget 独立管理）
- **WHEN** 响应视频切换时
- **THEN** `ref.listen` 方法 SHALL 使用本地状态跟踪当前视频
- **AND** 方法 SHALL 延迟更新（200ms 后检查），确保切换动画完成后再播放
- **AND** 当视频不再是当前视频时，方法 SHALL 调用 `removeListeners` 移除监听器（对齐 Immich）
- **WHEN** 视频播放就绪时
- **THEN** `onPlaybackReady` 方法 SHALL 开头检查 `isCurrent`，只有当前视频才执行播放逻辑
- **AND** 如果视频不是当前视频，方法 SHALL 直接返回
- **AND** 播放控制 SHALL 直接调用本地 `controller.play()`，不通过 `ViewerVideoManager`
- **WHEN** Widget 被销毁时
- **THEN** `dispose` 方法 SHALL 调用 `removeListeners` 移除所有监听器（对齐 Immich 的 useEffect cleanup）
- **AND** 方法 SHALL 调用 `controller.stop()` 停止播放（对齐 Immich 的 useEffect cleanup）
- **AND** 方法 SHALL 不通过 `ViewerVideoManager` 清理 controller（每个 Widget 独立管理）
- **WHEN** `NativeVideoPlayerView` 被销毁时
- **THEN** controller 的底层原生实现 SHALL 由 `NativeVideoPlayerView` 自动管理
- **AND** 本地 `_controller` 状态 SHALL 与 Widget 生命周期同步（Widget 销毁时 controller 也被清理）

