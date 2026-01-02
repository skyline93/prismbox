# Change: 重构媒体查看器页面组件化

## Why

当前 `media_viewer_page.dart` 文件超过 1087 行，严重违反了 `project.md` 中规定的 UI 重构规范，存在以下问题：

- **代码规模过大**：单文件 1087 行，`_MediaViewerPageState` 类承担过多职责
- **违反单一职责原则**：同时负责页面状态管理、图片查看器构建、视频播放器管理、手势处理、动画控制、UI 控制栏等多个职责
- **状态管理复杂**：包含 12+ 个状态变量，状态分散难以追踪和管理
- **性能风险**：频繁的 `setState` 调用（特别是在动画回调中），视频控制器管理逻辑复杂且分散
- **可维护性差**：方法职责不清，难以进行单元测试，代码可读性差

通过将 UI 拆分为原子组件并提取业务逻辑，可以：
- 提高代码可维护性和可测试性
- 遵循项目规范，确保代码质量
- 便于组件复用和独立测试
- 降低代码复杂度，提升开发效率
- 优化性能，减少不必要的 Widget 重建

## What Changes

- **提取视频播放器管理器**：创建 `ViewerVideoManager` 类，负责视频控制器的创建、缓存、释放和状态管理
  - 封装视频控制器缓存逻辑
  - 管理视频播放状态（播放/暂停、静音状态等）
  - 处理可见页面范围的资源管理
- **提取手势处理组件**：创建 `ViewerDismissGesture` Widget，负责下滑退出预览的手势和动画处理
  - 封装垂直拖动手势识别
  - 处理退出动画（执行和重置）
  - 隔离手势逻辑，避免影响主页面状态
- **提取控制栏组件**：创建 `ViewerControlsBar` Widget，包含顶部 AppBar 和底部控制栏
  - 顶部 AppBar：返回、分享、更多操作
  - 底部控制栏：收藏、信息、编辑等功能按钮
- **提取图片查看页面组件**：创建 `ViewerImagePage` Widget，负责图片查看器的构建
  - 封装 PhotoView 相关逻辑
  - 处理图片加载和错误状态
  - 处理缩放状态回调
- **提取视频查看页面组件**：创建 `ViewerVideoPage` Widget，负责视频播放器的构建
  - 封装 VideoPlayer 相关逻辑
  - 集成视频控制器 UI
  - 处理视频加载和错误状态
- **拆分视频控制器 UI**：将 `_VideoPlayerControls` 移动到独立文件 `viewer_video_controller.dart`
  - 保持现有功能不变
  - 独立文件便于维护
- **简化页面类**：`MediaViewerPage` 仅保留页面级逻辑和状态管理，代码行数从 1087 行减少到约 200-300 行

所有新组件将：
- 存放在 `lib/presentation/widgets/viewer/` 目录下
- 使用 `viewer_` 前缀命名（如 `viewer_image_page.dart`）
- 优先使用 `StatelessWidget` 和 `const` 构造函数
- 通过 Riverpod Provider 或参数传递访问必要的状态和数据

## Impact

- **受影响文件**：
  - `prismbox_mobile/lib/presentation/pages/viewer/media_viewer_page.dart` - 大幅简化（从 1087 行减少到约 200-300 行）
  - 新增 6-7 个组件/类文件在 `prismbox_mobile/lib/presentation/widgets/viewer/` 目录下
    - `viewer_video_manager.dart` - 视频播放器管理器类
    - `viewer_dismiss_gesture.dart` - 下滑退出手势处理组件
    - `viewer_controls_bar.dart` - 控制栏组件
    - `viewer_image_page.dart` - 图片查看页面组件
    - `viewer_video_page.dart` - 视频查看页面组件
    - `viewer_video_controller.dart` - 视频控制器 UI（从现有代码拆分）
- **受影响规范**：
  - UI 重构规范（project.md 中的 UI 拆分策略）
  - 组件命名规范
  - 性能优化要求（const 构造函数、StatelessWidget 优先）
- **向后兼容性**：纯重构，不改变功能行为，保持完全兼容

