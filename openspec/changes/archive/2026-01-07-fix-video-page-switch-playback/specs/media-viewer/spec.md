## MODIFIED Requirements

### Requirement: 视频查看页面为独立组件
视频查看页面（ViewerVideoPage）组件 SHALL 使用 `ConsumerStatefulWidget`，通过 Riverpod Provider 响应式地监听当前视频状态变化，确保页面切换时视频播放状态正确同步。

#### Scenario: 响应式状态管理
- **WHEN** 用户在预览页面播放视频 A
- **AND** 滑动切换到视频 B 并播放
- **AND** 再滑动切换回视频 A
- **THEN** 视频 A SHALL 自动开始播放
- **AND** 视频播放状态 SHALL 通过 `currentVideoAssetIdProvider` Provider 管理
- **AND** `ViewerVideoPage` SHALL 使用 `ref.listen(currentVideoAssetIdProvider, ...)` 监听状态变化
- **AND** 状态变化时 SHALL 延迟 300ms 后自动播放，确保切换动画完成

#### Scenario: 只有当前视频才自动播放
- **WHEN** 视频页面的视频不是当前视频（`widget.assetId != currentVideoAssetIdProvider`）
- **THEN** 视频 SHALL 不会自动播放
- **AND** `_onPlaybackReady` 方法中 SHALL 检查是否为当前视频，只有当前视频才调用 `playController`
- **AND** `_initializeVideo` 方法中找到已存在的控制器时，SHALL 检查是否为当前视频

#### Scenario: 状态同步更新
- **WHEN** 用户在 `MediaViewerPage` 中切换页面（`_handlePageChanged`）
- **AND** 切换到视频页面
- **THEN** `MediaViewerPage` SHALL 同时更新 `ViewerVideoManager.setCurrentVideoAssetId` 和 `currentVideoAssetIdProvider` 的状态
- **AND** 两个状态 SHALL 保持同步
- **AND** 当切换到非视频页面时，Provider 状态 SHALL 设置为 null

## ADDED Requirements

### Requirement: 当前视频状态 Provider
系统 SHALL 提供 `currentVideoAssetIdProvider` Provider 用于响应式地管理当前视频资产 ID。

#### Scenario: Provider 定义
- **WHEN** 使用 `currentVideoAssetIdProvider`
- **THEN** Provider SHALL 定义为 `StateProvider<String?>`
- **AND** Provider SHALL 位于 `mobile/lib/presentation/widgets/viewer/viewer_video_state_provider.dart`
- **AND** Provider 的初始值 SHALL 为 `null`
- **AND** Provider SHALL 用于在 `MediaViewerPage` 和 `ViewerVideoPage` 之间传递当前视频状态

#### Scenario: 状态变化通知
- **WHEN** `currentVideoAssetIdProvider` 的状态发生变化
- **THEN** 所有订阅该 Provider 的 Widget SHALL 收到通知
- **AND** `ViewerVideoPage` SHALL 通过 `ref.listen` 响应状态变化
- **AND** 状态变化时 SHALL 执行相应的播放逻辑（如果该视频变成了当前视频）

