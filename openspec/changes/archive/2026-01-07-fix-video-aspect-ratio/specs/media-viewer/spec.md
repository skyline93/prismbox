## MODIFIED Requirements

### Requirement: 视频查看页面为独立组件
媒体查看器页面（MediaViewerPage）的视频查看页面组件（ViewerVideoPage）SHALL 遵循原子组件拆分原则，正确处理视频宽高比计算，确保视频预览时不被拉伸。

#### Scenario: 视频查看页面为独立组件
- **WHEN** 使用 ViewerVideoPage 组件
- **THEN** 该组件 SHALL 位于 `lib/presentation/widgets/viewer/viewer_video_page.dart`
- **AND** 组件类名 SHALL 为 `ViewerVideoPage`
- **AND** 组件 SHALL 使用 `StatefulWidget`（需要处理视频加载状态）
- **AND** 组件 SHALL 接收 `asset`、`assetId`、`videoManager`、`serverUrl`、`assetEntityLoader` 等参数
- **AND** 组件 SHALL 通过回调函数处理 `showControls`、`onToggleControls`、`onMuteChanged` 事件
- **AND** 组件 SHALL 使用 `ViewerVideoManager` 管理视频控制器
- **AND** 组件 SHALL 封装 NativeVideoPlayer 相关逻辑
- **AND** 组件 SHALL 处理视频加载和错误状态
- **AND** 组件 SHALL 集成视频控制器 UI

#### Scenario: 视频宽高比计算正确
- **WHEN** ViewerVideoPage 初始化视频
- **THEN** 组件 SHALL 使用 `asset.aspectRatio` 作为初始宽高比（已考虑 orientation）
- **AND** 如果 `asset.aspectRatio` 为 null，组件 SHALL 使用临时宽高比（16/9）来显示 `NativeVideoPlayerView`
- **AND** 在 `_onPlaybackReady` 回调中，组件 SHALL 使用 `videoInfo` 的真实宽高比更新宽高比
- **AND** 组件 SHALL 确保视频预览时不被拉伸（竖屏视频 9:16、横屏视频 16:9 等）

#### Scenario: 视频播放器正确显示
- **WHEN** 视频加载完成
- **THEN** 视频 SHALL 使用正确的宽高比显示（不被拉伸）
- **AND** 竖屏视频（9:16）SHALL 正确显示为竖屏
- **AND** 横屏视频（16:9）SHALL 正确显示为横屏
- **AND** 不同 orientation 的视频 SHALL 都能正确显示

