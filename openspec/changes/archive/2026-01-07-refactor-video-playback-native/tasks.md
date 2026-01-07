## 1. 依赖管理
- [x] 1.1 在 `mobile/pubspec.yaml` 中添加 `native_video_player` 依赖（GitHub 源：`https://github.com/immich-app/native_video_player`）
- [x] 1.2 运行 `flutter pub get` 安装依赖（需要网络连接）
- [x] 1.3 验证依赖安装成功，检查是否有编译错误

## 2. VideoProvider 重构
- [x] 2.1 更新 `mobile/lib/features/media_loading/video_provider.dart` 的导入，添加 `native_video_player` 包
- [x] 2.2 修改 `VideoProvider.getVideoSource` 方法签名，返回类型改为 `Future<native_video_player.VideoSource?>`
- [x] 2.3 重构 `_getLocalVideoSource` 方法，使用 `VideoSource.init(path: filePath, type: VideoSourceType.file)` 创建本地视频源
- [x] 2.4 重构 `_getRemoteVideoSource` 方法，使用 `VideoSource.init(path: url, type: VideoSourceType.network, headers: ...)` 创建远程视频源
- [x] 2.5 添加请求头支持（用于远程视频认证），参考 Immich 的 `ApiService.getRequestHeaders()` 实现
- [x] 2.6 移除自定义 `VideoSource` 和 `VideoSourceType` 类定义（使用 `native_video_player` 的类型）
- [x] 2.7 更新错误处理和日志记录

## 3. ViewerVideoManager 重构
- [x] 3.1 更新 `mobile/lib/presentation/widgets/viewer/viewer_video_manager.dart` 的导入，添加 `native_video_player` 包
- [x] 3.2 将内部 `Map<String, VideoPlayerController>` 替换为 `Map<String, NativeVideoPlayerController>`
- [x] 3.3 重构控制器创建逻辑：
  - 添加 `getVideoSource` 方法获取视频源
  - 添加 `registerController` 方法注册由 `NativeVideoPlayerView` 创建的控制器
  - 使用 `controller.loadVideoSource(source)` 加载视频源
  - 设置初始状态（静音、循环播放等）
- [x] 3.4 更新 `getController` 方法返回类型为 `NativeVideoPlayerController?`
- [x] 3.5 重构 `pauseController` 方法，使用 `NativeVideoPlayerController.pause()`
- [x] 3.6 重构 `playController` 方法，使用 `NativeVideoPlayerController.play()`
- [x] 3.7 重构 `setMuted` 方法，使用 `NativeVideoPlayerController.setVolume(muted ? 0.0 : 1.0)`
- [x] 3.8 重构 `disposeController` 方法，使用 `NativeVideoPlayerController.stop()` 和 `dispose()`
- [x] 3.9 更新 `disposeAllControllers` 方法，遍历所有控制器并释放资源
- [x] 3.10 更新 `updateVisibleIndices` 和 `pauseAndReleaseVideo` 方法为 async

## 4. ViewerVideoPage 重构
- [x] 4.1 更新 `mobile/lib/presentation/widgets/viewer/viewer_video_page.dart` 的导入，添加 `native_video_player` 包
- [x] 4.2 将 `VideoPlayerController?` 类型替换为 `NativeVideoPlayerController?`
- [x] 4.3 重构视频加载逻辑：
  - 使用 `ViewerVideoManager.getController` 获取 `NativeVideoPlayerController`
  - 检查控制器是否已初始化（通过 `playbackInfo` 判断）
  - 使用 `NativeVideoPlayerView` 的 `onViewReady` 回调初始化控制器
- [x] 4.4 重构 `_buildVideoPlayerWidget` 方法：
  - 将 `VideoPlayer` widget 替换为 `NativeVideoPlayerView`
  - 使用 `NativeVideoPlayerView` 的 `onViewReady` 回调初始化控制器
  - 保持 `AspectRatio` 和布局逻辑不变
  - **修复死锁问题**：移除 `controller != null` 检查，只要 `isCurrent` 就显示 `NativeVideoPlayerView`（参考 Immich 实现）
- [x] 4.5 更新状态监听逻辑：
  - 使用 `controller.onPlaybackReady` 监听播放就绪
  - 使用 `controller.onPlaybackStatusChanged` 监听播放状态变化
  - 使用 `controller.onPlaybackPositionChanged` 监听播放进度
  - 使用 `controller.onPlaybackEnded` 监听播放结束
- [x] 4.6 更新错误处理，使用 `NativeVideoPlayerController` 的错误信息
- [x] 4.7 保持 UI 和交互逻辑不变（控制栏、手势等）
- [x] 4.8 **修复视频拉伸问题**：优先使用 `videoInfo` 的真实宽高比，移除初始宽高比计算（避免 orientation 问题），移除 10% 差异限制，确保使用正确的宽高比

## 5. ViewerVideoController 重构
- [x] 5.1 更新 `mobile/lib/presentation/widgets/viewer/viewer_video_controller.dart` 的导入
- [x] 5.2 将 `VideoPlayerController` 类型替换为 `NativeVideoPlayerController`
- [x] 5.3 更新播放控制逻辑：
  - 使用 `controller.play()` 和 `controller.pause()` 控制播放
  - 使用 `controller.seekTo(position)` 控制进度
  - 使用 `controller.setVolume(volume)` 控制音量
- [x] 5.4 更新状态监听：
  - 使用 `controller.playbackInfo` 和 `controller.videoInfo` 获取播放信息（位置、状态、时长等）
  - 使用 `controller.onPlaybackPositionChanged` 监听进度变化
  - 使用 `controller.onPlaybackStatusChanged` 监听状态变化
- [x] 5.5 更新进度条显示逻辑，使用 `playbackInfo.position` 和 `videoInfo.duration`
- [x] 5.6 保持 UI 组件结构不变

## 6. 生命周期和资源管理
- [x] 6.1 添加应用生命周期监听（进入后台时暂停播放，恢复时继续播放）
- [x] 6.2 确保视频控制器在页面销毁时正确释放资源（已在 dispose 中处理）
- [x] 6.3 通过代码审查确保可见页面范围的资源管理逻辑正确实现（ViewerVideoManager 已实现）
- [x] 6.4 添加唤醒锁支持（播放时防止屏幕关闭），参考 Immich 的 `wakelock_plus` 使用

## 7. 单元测试
- [x] 7.1 为 `VideoProvider.getVideoSource` 编写单元测试（本地和远程视频源创建）
- [x] 7.2 为 `ViewerVideoManager` 的核心方法编写单元测试（创建、获取、释放控制器）
- [x] 7.3 为视频播放控制逻辑编写单元测试（播放、暂停、进度、音量 - 基础结构已创建）
- [x] 7.4 为资源管理逻辑编写单元测试（可见页面范围管理、资源释放）

## 8. 代码清理
- [ ] 8.1 移除 `video_player` 依赖（在确认新实现稳定后，需要先运行测试验证）
- [x] 8.2 清理未使用的导入和代码（已确认所有 video_player 引用已替换）
- [x] 8.3 更新代码注释和文档（已更新 VideoProvider、ViewerVideoManager、VideoPlayerControls 的注释）
- [x] 8.4 运行代码格式化（`dart format`）
- [x] 8.5 运行静态分析（`flutter analyze` - 已修复所有错误和警告）

## 9. 修复视频切换播放问题（对齐 Immich）
- [x] 9.1 修复 `initController`：移除从 `ViewerVideoManager` 获取 controller 的检查，只检查本地 `_controller` 状态（参考 Immich：`if (controller.value != null || !context.mounted) return;`）
- [x] 9.2 修复 `_initializeVideo`：移除重用已存在 controller 的逻辑，每次都让 `NativeVideoPlayerView` 创建新的 controller
- [x] 9.3 修复 `initController` 的视频源加载：直接调用 `nc.loadVideoSource(source)`，而不是通过 `registerController`（但 `registerControllerOnly` 仍需要调用，用于缓存 controller 到 `ViewerVideoManager`）
- [x] 9.4 修复 `ref.listen`：使用本地状态跟踪当前视频（使用 `_currentVideoId` 跟踪），延迟更新（200ms 后检查），完全对齐 Immich 的逻辑
- [x] 9.5 修复 `onPlaybackReady`：开头检查 `isCurrent`，如果不是当前视频直接返回（参考 Immich：`if (!isCurrent) return;`）
- [x] 9.6 修复 controller 生命周期：确保当 `NativeVideoPlayerView` 被销毁时，通过 `_isControllerValid` 检查确保不继续使用无效的 controller（controller 的底层原生实现由 `NativeVideoPlayerView` 管理，`ViewerVideoManager` 只缓存引用）
- [x] 9.7 修复 `dispose`：在 dispose 中调用 `removeListeners` 和 `controller.stop()`，对齐 Immich 的 useEffect cleanup 逻辑
- [x] 9.8 修复 `ref.listen`：当视频不再是当前视频时，调用 `removeListeners`，对齐 Immich 的 ref.listen 逻辑

## 10. 移除全局 controller 缓存（完全对齐 Immich 架构）
- [x] 10.1 从 `ViewerVideoManager` 中移除 controller 缓存相关代码：移除 `_controllers` Map、`registerController`、`registerControllerOnly`、`getController`、`playController`、`pauseController`、`setMuted`、`isMuted`、`_mutedStates`、`disposeController` 的 controller 相关部分
- [x] 10.2 更新 `ViewerVideoPage`：移除对 `ViewerVideoManager.registerControllerOnly`、`videoManager.playController`、`videoManager.pauseController`、`videoManager.setMuted`、`videoManager.isMuted` 的调用
- [x] 10.3 在 `ViewerVideoPage` 中独立管理 controller：直接操作本地 `_controller`，不使用 `ViewerVideoManager`
- [x] 10.4 在 `ViewerVideoPage` 中独立管理静音状态：移除对 `ViewerVideoManager.isMuted` 的依赖，使用本地 `_isMuted` 状态
- [x] 10.5 更新 `MediaViewerPage`：移除对 `_videoManager.playController` 的调用，播放控制通过 Provider 通知 `ViewerVideoPage` 完成
- [x] 10.6 更新 `ViewerVideoPage` 的播放控制：在 `onPlaybackReady` 中直接调用 `controller.play()`，不通过 `ViewerVideoManager`
- [x] 10.7 更新 `ViewerVideoPage` 的静音控制：在 `onMuteChanged` 中直接调用 `controller.setVolume()`，不通过 `ViewerVideoManager`
- [x] 10.8 验证 `ViewerVideoManager` 保留的功能：确保 `getVideoSource`、`calculateVisibleIndices`、`updateVisibleIndices`、`setCurrentVideoAssetId`、`getCurrentVideoAssetId` 仍然可用

