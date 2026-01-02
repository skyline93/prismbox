## 1. 视频管理器提取

- [x] 1.1 创建 `ViewerVideoManager` 类 (`lib/presentation/widgets/viewer/viewer_video_manager.dart`)
  - 定义类结构，包含视频控制器缓存、静音状态、可见页面索引等字段
  - 实现 `createController` 方法：创建视频控制器并初始化
  - 实现 `getController` 方法：获取已存在的控制器
  - 实现 `disposeController` 方法：释放单个控制器
  - 实现 `disposeAllControllers` 方法：释放所有控制器
  - 实现 `pauseController` 方法：暂停控制器播放
  - 实现 `playController` 方法：播放控制器
  - 实现 `setMuted` 方法：设置静音状态
  - 实现 `updateVisibleIndices` 方法：更新可见页面索引并释放不可见资源
  - 添加必要的文档注释

- [x] 1.2 迁移视频控制器管理逻辑到 `ViewerVideoManager`
  - 从 `_MediaViewerPageState` 中提取视频控制器相关字段到管理器
  - 迁移 `_disposeAllVideoControllers` 方法逻辑
  - 迁移 `_disposeVideoController` 方法逻辑
  - 迁移 `_pauseAndReleaseVideo` 方法逻辑
  - 迁移 `_releaseInvisibleResources` 方法逻辑
  - 迁移 `_playVideo` 方法逻辑
  - 迁移 `_createVideoPlayer` 方法中控制器创建逻辑

- [x] 1.3 更新 `MediaViewerPage` 使用 `ViewerVideoManager`
  - 在 `_MediaViewerPageState` 中创建 `ViewerVideoManager` 实例
  - 替换所有视频控制器相关操作，改为调用管理器方法
  - 更新 `initState` 和 `dispose` 方法使用管理器
  - 更新 `_handlePageChanged` 方法使用管理器
  - 更新 `_buildVideoPlayer` 和 `_buildVideoPlayerWidget` 方法使用管理器

## 2. 手势处理组件提取

- [x] 2.1 创建 `ViewerDismissGesture` 组件 (`lib/presentation/widgets/viewer/viewer_dismiss_gesture.dart`)
  - 定义 `ViewerDismissGesture` 为 `StatefulWidget`
  - 包含 `child`、`isZoomed`、`onDismiss` 参数
  - 实现 `_ViewerDismissGestureState`，包含动画控制器和手势状态
  - 实现 `_dismissWithAnimation` 方法：执行退出动画
  - 实现 `_resetDismissAnimation` 方法：重置动画
  - 实现 `_animationListener` 方法：动画监听回调
  - 实现垂直拖动手势识别（onVerticalDragStart、onVerticalDragUpdate、onVerticalDragEnd）
  - 在 `build` 方法中包装子组件，应用 Transform 和 Opacity
  - 添加必要的文档注释

- [x] 2.2 迁移手势和动画逻辑到 `ViewerDismissGesture`
  - 从 `_MediaViewerPageState` 中提取垂直拖动相关字段
  - 迁移 `_dismissWithAnimation` 方法逻辑
  - 迁移 `_resetDismissAnimation` 方法逻辑
  - 迁移 `_animationListener` 方法逻辑
  - 迁移手势处理回调逻辑

- [x] 2.3 更新 `MediaViewerPage` 使用 `ViewerDismissGesture`
  - 在 `_buildGallery` 方法中使用 `ViewerDismissGesture` 包装 PageView
  - 移除页面类中的手势相关字段和方法
  - 移除动画控制器相关代码（保留必要的状态如 `isZoomed`）
  - 通过回调函数处理退出逻辑

## 3. 控制栏组件提取

- [x] 3.1 创建 `ViewerControlsBar` 组件 (`lib/presentation/widgets/viewer/viewer_controls_bar.dart`)
  - 定义 `ViewerControlsBar` 为 `StatelessWidget`
  - 包含 `showControls`、`onToggleControls` 等参数
  - 实现顶部 AppBar（返回按钮、分享按钮、更多操作按钮）
  - 实现底部控制栏（收藏、信息、编辑等功能按钮）
  - 使用 `Stack` 和 `Positioned` 布局
  - 添加必要的文档注释

- [x] 3.2 迁移控制栏 UI 代码到 `ViewerControlsBar`
  - 从 `_buildControls` 方法中提取顶部 AppBar 代码
  - 从 `_buildControls` 方法中提取底部控制栏代码
  - 保持 UI 样式和行为不变

- [x] 3.3 更新 `MediaViewerPage` 使用 `ViewerControlsBar`
  - 在 `_buildGallery` 方法中使用 `ViewerControlsBar` 替换 `_buildControls` 调用
  - 移除 `_buildControls` 方法
  - 通过参数传递必要的状态和回调

## 4. 图片查看页面组件提取

- [x] 4.1 创建 `ViewerImagePage` 组件 (`lib/presentation/widgets/viewer/viewer_image_page.dart`)
  - 定义 `ViewerImagePage` 为 `StatelessWidget`
  - 包含 `asset`、`assetId`、`serverUrl`、`assetEntityLoader` 等参数
  - 包含 `onTap`、`onScaleStateChanged` 等回调参数
  - 实现 `PhotoView` 配置（initialScale、minScale、maxScale）
  - 实现 `errorBuilder` 和 `loadingBuilder`
  - 使用 `getFullImageProvider` 获取图片提供者
  - 添加必要的文档注释

- [x] 4.2 迁移图片查看器逻辑到 `ViewerImagePage`
  - 从 `_buildImageViewer` 方法中提取所有逻辑
  - 从 `_getImageProvider` 方法中提取图片提供者逻辑
  - 保持功能不变

- [x] 4.3 更新 `MediaViewerPage` 使用 `ViewerImagePage`
  - 在 `PageView.builder` 的 `itemBuilder` 中使用 `ViewerImagePage` 替换 `_buildImageViewer` 调用
  - 移除 `_buildImageViewer` 和 `_getImageProvider` 方法
  - 通过参数传递必要的状态和回调

## 5. 视频查看页面组件提取

- [x] 5.1 创建 `ViewerVideoPage` 组件 (`lib/presentation/widgets/viewer/viewer_video_page.dart`)
  - 定义 `ViewerVideoPage` 为 `StatefulWidget`
  - 包含 `asset`、`assetId`、`videoManager`、`serverUrl`、`assetEntityLoader` 等参数
  - 包含 `showControls`、`onToggleControls`、`onMuteChanged` 等参数
  - 实现 `_ViewerVideoPageState`，处理视频加载和播放逻辑
  - 使用 `FutureBuilder` 加载视频源
  - 集成 `_VideoPlayerControls`（暂时保持内联，后续移动到独立文件）
  - 实现视频播放器 Widget 构建
  - 添加必要的文档注释

- [x] 5.2 迁移视频查看器逻辑到 `ViewerVideoPage`
  - 从 `_buildVideoPlayer` 方法中提取逻辑
  - 从 `_buildVideoPlayerWidget` 方法中提取逻辑
  - 从 `_createVideoPlayer` 方法中提取逻辑
  - 使用 `ViewerVideoManager` 管理视频控制器
  - 保持功能不变

- [x] 5.3 更新 `MediaViewerPage` 使用 `ViewerVideoPage`
  - 在 `PageView.builder` 的 `itemBuilder` 中使用 `ViewerVideoPage` 替换 `_buildVideoPlayer` 调用
  - 移除 `_buildVideoPlayer`、`_buildVideoPlayerWidget`、`_createVideoPlayer` 方法
  - 移除 `_getBottomBarHeight` 方法（如果不再需要）
  - 通过参数传递必要的状态和回调

## 6. 视频控制器 UI 拆分

- [x] 6.1 创建 `viewer_video_controller.dart` 文件 (`lib/presentation/widgets/viewer/viewer_video_controller.dart`)
  - 将 `_VideoPlayerControls` 类移动到新文件
  - 将 `_VideoPlayerControlsState` 类移动到新文件
  - 保持类名不变（私有类，使用下划线前缀）
  - 添加必要的 import 语句
  - 添加文件头注释说明组件用途

- [x] 6.2 更新 `MediaViewerPage` 和 `ViewerVideoPage` 引用
  - 在 `MediaViewerPage` 中移除 `_VideoPlayerControls` 相关代码
  - 在 `ViewerVideoPage` 中 import 新的文件
  - 确保功能正常

## 7. 页面类清理和优化

- [x] 7.1 清理 `MediaViewerPage` 中的冗余代码
  - 移除已提取到组件中的方法
  - 移除不再使用的字段
  - 简化 `build` 方法，仅保留页面级逻辑
  - 保持必要的状态管理（如 `showControls`、`isZoomed`、`_currentPageIndex`）

- [x] 7.2 优化页面类结构
  - 确保 `build` 方法简洁清晰
  - 使用新创建的组件组装页面
  - 保持页面级状态管理逻辑
  - 保持页面切换逻辑（`_handlePageChanged`）

- [x] 7.3 更新导入语句
  - 添加新组件的 import 语句
  - 移除不再需要的 import
  - 确保导入路径正确

## 8. 代码质量检查

- [x] 8.1 验证组件规范
  - 所有新组件都使用 `const` 构造函数（如果可能）
  - 优先使用 `StatelessWidget`（如 `ViewerImagePage`、`ViewerControlsBar`）
  - 需要状态管理时使用 `StatefulWidget`（如 `ViewerVideoPage`、`ViewerDismissGesture`）
  - 组件命名符合规范（文件名使用 `viewer_` 前缀）

- [x] 8.2 验证性能优化
  - 使用 `const` 关键字调用无状态组件
  - 保持现有的 `ValueListenableBuilder` 和 `RepaintBoundary` 优化
  - 避免不必要的 Widget 重建

- [x] 8.3 运行代码检查工具
  - 运行 `flutter analyze` 检查代码格式和规范
  - 确保没有引入新的警告或错误
  - 验证导入语句正确且没有冗余

## 9. 文档更新

- [x] 9.1 更新代码注释
  - 为新组件添加清晰的文档注释
  - 说明组件的用途和使用方式
  - 标注必要的参数说明
  - 更新 `MediaViewerPage` 的注释

- [x] 9.2 验证代码可读性
  - 确保代码结构清晰
  - 确保方法命名清晰
  - 确保变量命名清晰

