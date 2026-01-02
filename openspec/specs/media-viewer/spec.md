# media-viewer Specification

## Purpose
TBD - created by archiving change refactor-media-viewer-page. Update Purpose after archive.
## Requirements
### Requirement: 媒体查看器页面 UI 组件结构
媒体查看器页面（MediaViewerPage）的 UI 组件 SHALL 遵循原子组件拆分原则，将大型 UI 逻辑拆分为独立的、可复用的组件和业务逻辑类。

#### Scenario: 页面代码行数符合规范
- **WHEN** 查看 MediaViewerPage 文件
- **THEN** 页面文件代码行数 SHALL 不超过 300 行
- **AND** `build` 方法的代码行数 SHALL 不超过 80 行
- **AND** UI 构建逻辑 SHALL 通过独立的组件实现

#### Scenario: 视频播放器管理器为独立类
- **WHEN** 使用 ViewerVideoManager 类
- **THEN** 该类 SHALL 位于 `lib/presentation/widgets/viewer/viewer_video_manager.dart`
- **AND** 类名 SHALL 为 `ViewerVideoManager`
- **AND** 类 SHALL 封装视频控制器的创建、缓存、释放逻辑
- **AND** 类 SHALL 管理视频播放状态（播放/暂停、静音状态等）
- **AND** 类 SHALL 处理可见页面范围的资源管理
- **AND** 类 SHALL 提供创建、获取、释放、暂停、播放等管理方法

#### Scenario: 手势处理为独立组件
- **WHEN** 使用 ViewerDismissGesture 组件
- **THEN** 该组件 SHALL 位于 `lib/presentation/widgets/viewer/viewer_dismiss_gesture.dart`
- **AND** 组件类名 SHALL 为 `ViewerDismissGesture`
- **AND** 组件 SHALL 使用 `StatefulWidget`（需要动画控制器）
- **AND** 组件 SHALL 封装垂直拖动手势识别
- **AND** 组件 SHALL 处理退出动画（执行和重置）
- **AND** 组件 SHALL 通过回调函数通知父组件退出事件
- **AND** 组件 SHALL 接收 `child`、`isZoomed`、`onDismiss` 参数

#### Scenario: 控制栏为独立组件
- **WHEN** 使用 ViewerControlsBar 组件
- **THEN** 该组件 SHALL 位于 `lib/presentation/widgets/viewer/viewer_controls_bar.dart`
- **AND** 组件类名 SHALL 为 `ViewerControlsBar`
- **AND** 组件 SHALL 使用 `StatelessWidget`
- **AND** 组件 SHALL 提供 `const` 构造函数
- **AND** 组件 SHALL 包含顶部 AppBar（返回按钮、分享按钮、更多操作按钮）
- **AND** 组件 SHALL 包含底部控制栏（收藏、信息、编辑等功能按钮）
- **AND** 组件 SHALL 通过回调函数处理用户交互事件

#### Scenario: 图片查看页面为独立组件
- **WHEN** 使用 ViewerImagePage 组件
- **THEN** 该组件 SHALL 位于 `lib/presentation/widgets/viewer/viewer_image_page.dart`
- **AND** 组件类名 SHALL 为 `ViewerImagePage`
- **AND** 组件 SHALL 使用 `StatelessWidget`
- **AND** 组件 SHALL 提供 `const` 构造函数（如果可能）
- **AND** 组件 SHALL 接收 `asset`、`assetId`、`serverUrl`、`assetEntityLoader` 等参数
- **AND** 组件 SHALL 通过回调函数处理 `onTap` 和 `onScaleStateChanged` 事件
- **AND** 组件 SHALL 封装 PhotoView 配置和逻辑
- **AND** 组件 SHALL 处理图片加载和错误状态

#### Scenario: 视频查看页面为独立组件
- **WHEN** 使用 ViewerVideoPage 组件
- **THEN** 该组件 SHALL 位于 `lib/presentation/widgets/viewer/viewer_video_page.dart`
- **AND** 组件类名 SHALL 为 `ViewerVideoPage`
- **AND** 组件 SHALL 使用 `StatefulWidget`（需要处理视频加载状态）
- **AND** 组件 SHALL 接收 `asset`、`assetId`、`videoManager`、`serverUrl`、`assetEntityLoader` 等参数
- **AND** 组件 SHALL 通过回调函数处理 `showControls`、`onToggleControls`、`onMuteChanged` 事件
- **AND** 组件 SHALL 使用 `ViewerVideoManager` 管理视频控制器
- **AND** 组件 SHALL 封装 VideoPlayer 相关逻辑
- **AND** 组件 SHALL 处理视频加载和错误状态
- **AND** 组件 SHALL 集成视频控制器 UI

#### Scenario: 视频控制器 UI 为独立组件
- **WHEN** 使用视频控制器 UI 组件
- **THEN** 该组件 SHALL 位于 `lib/presentation/widgets/viewer/viewer_video_controller.dart`
- **AND** 组件类名 SHALL 为 `_VideoPlayerControls`（私有类，保持现有命名）
- **AND** 组件 SHALL 使用 `StatefulWidget`
- **AND** 组件 SHALL 封装视频播放控制逻辑（播放/暂停、进度条、静音等）
- **AND** 组件 SHALL 使用 `ValueListenableBuilder` 优化性能
- **AND** 组件 SHALL 使用 `RepaintBoundary` 隔离绘制边界

#### Scenario: 组件命名和目录规范
- **WHEN** 创建新的媒体查看器相关组件
- **THEN** 组件文件 SHALL 存放在 `lib/presentation/widgets/viewer/` 目录下
- **AND** 文件名 SHALL 使用 `viewer_` 前缀，使用 snake_case 命名（如 `viewer_image_page.dart`）
- **AND** 类名 SHALL 与文件名对应，使用 PascalCase 命名（如 `ViewerImagePage`）

#### Scenario: 组件性能优化要求
- **WHEN** 实现新的 UI 组件
- **THEN** 无状态组件 SHALL 优先使用 `StatelessWidget`
- **AND** 需要状态管理时 SHALL 使用 `StatefulWidget`
- **AND** 所有组件 SHALL 提供 `const` 构造函数（如果可能）
- **AND** 组件调用时 SHALL 使用 `const` 关键字（如果可能）
- **AND** 保持现有的性能优化措施（如 `ValueListenableBuilder`、`RepaintBoundary`）

#### Scenario: 状态管理规范
- **WHEN** 组件需要访问状态或数据
- **THEN** 页面级状态（如 `showControls`、`isZoomed`）SHALL 由页面类管理
- **AND** 视频管理器状态 SHALL 由 `ViewerVideoManager` 类内部管理
- **AND** 组件 SHALL 通过构造函数参数接收必要的数据
- **AND** 组件 SHALL 通过回调函数通知父组件用户交互事件
- **AND** 避免过度抽象，保持参数传递的简洁性

#### Scenario: 功能保持完整
- **WHEN** 重构完成后
- **THEN** 所有原有功能 SHALL 保持不变
- **AND** 图片查看功能 SHALL 正常工作（缩放、平移、加载等）
- **AND** 视频播放功能 SHALL 正常工作（播放、暂停、进度控制、静音等）
- **AND** 手势退出功能 SHALL 正常工作（下滑退出、动画等）
- **AND** 控制栏功能 SHALL 正常工作（显示/隐藏、操作按钮等）
- **AND** 页面切换功能 SHALL 正常工作（左右滑动切换媒体）

