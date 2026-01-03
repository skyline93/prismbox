# timeline-page Specification

## Purpose
TBD - created by archiving change refactor-timeline-page-components. Update Purpose after archive.
## Requirements
### Requirement: 时间线页面 UI 组件结构
时间线页面（MainTimelinePage）的 UI 组件 SHALL 遵循原子组件拆分原则，将大型 UI 逻辑拆分为独立的、可复用的组件。业务逻辑 SHALL 从页面类中提取到独立的控制器类和管理器中，遵循单一职责原则。

#### Scenario: 页面 build 方法符合行数限制
- **WHEN** 查看 MainTimelinePage 的 build 方法
- **THEN** build 方法的代码行数 SHALL 不超过 80 行
- **AND** UI 构建逻辑 SHALL 通过独立的组件实现
- **AND** 业务逻辑 SHALL 通过独立的控制器类实现

#### Scenario: 事件监听逻辑提取
- **WHEN** 实现时间线页面的事件监听功能
- **THEN** 所有 Stream 事件监听逻辑 SHALL 位于 `lib/presentation/pages/photos/listeners/timeline_event_listeners.dart`
- **AND** 类名 SHALL 为 `TimelineEventListeners`
- **AND** 类 SHALL 负责管理数据源切换、上传完成、远程同步完成等事件监听
- **AND** 类 SHALL 不监听 checksum 匹配完成事件（已移除）
- **AND** 类 SHALL 提供 `start()` 方法启动所有监听
- **AND** 类 SHALL 提供 `dispose()` 方法清理所有订阅
- **AND** 页面类 SHALL 在 `initState()` 中初始化监听器，在 `dispose()` 中清理监听器

#### Scenario: 拖动选择逻辑提取
- **WHEN** 实现时间线页面的拖动选择功能
- **THEN** 拖动选择逻辑 SHALL 位于 `lib/presentation/pages/photos/controllers/timeline_drag_selection_controller.dart`
- **AND** 类名 SHALL 为 `TimelineDragSelectionController`
- **AND** 类 SHALL 负责管理拖动选择状态（锚点索引、拖动状态、已拖动资产 ID）
- **AND** 类 SHALL 提供 `handleDragStart()` 方法处理拖动开始
- **AND** 类 SHALL 提供 `handleDragAssetEnter()` 方法处理拖动进入资产（包含矩形/行选择算法）
- **AND** 类 SHALL 提供 `handleDragEnd()` 方法处理拖动结束
- **AND** 类 SHALL 提供 `handleDragScroll()` 方法处理拖动滚动
- **AND** 矩形/行选择算法 SHALL 提取为独立方法 `_calculateSelectedAssets()`
- **AND** 页面类 SHALL 将拖动选择事件委托给控制器处理

#### Scenario: 捏合手势逻辑提取
- **WHEN** 实现时间线页面的捏合手势功能
- **THEN** 捏合手势处理逻辑 SHALL 位于 `lib/presentation/pages/photos/mixins/timeline_pinch_gesture_handler.dart`
- **AND** Mixin 名 SHALL 为 `TimelinePinchGestureHandler`
- **AND** Mixin SHALL 负责管理捏合手势状态（上次列数、最后更新时间）
- **AND** Mixin SHALL 提供 `onScaleStart()` 方法处理手势开始
- **AND** Mixin SHALL 提供 `onScaleUpdate()` 方法处理手势更新（包含防抖逻辑）
- **AND** Mixin SHALL 提供 `onScaleEnd()` 方法处理手势结束
- **AND** Mixin SHALL 提供 `_calculateTargetColumns()` 方法计算目标列数
- **AND** 页面类 SHALL 使用该 Mixin 处理捏合手势

#### Scenario: 滚动位置管理提取
- **WHEN** 实现时间线页面的滚动位置管理功能
- **THEN** 滚动位置管理逻辑 SHALL 位于 `lib/presentation/pages/photos/controllers/timeline_scroll_position_manager.dart`
- **AND** 类名 SHALL 为 `TimelineScrollPositionManager`
- **AND** 类 SHALL 负责管理保存的滚动位置
- **AND** 类 SHALL 提供 `saveScrollOffset()` 方法保存当前滚动位置
- **AND** 类 SHALL 提供 `restoreScrollOffset()` 方法恢复滚动位置（使用多个 postFrameCallback 确保布局稳定）
- **AND** 类 SHALL 提供 `clearSavedOffset()` 方法清除保存的位置
- **AND** 页面类 SHALL 在长按进入选择模式时保存滚动位置，在进入选择模式后恢复滚动位置

#### Scenario: 上传处理逻辑提取
- **WHEN** 实现时间线页面的上传功能
- **THEN** 上传处理逻辑 SHALL 位于 `lib/presentation/pages/photos/controllers/timeline_upload_handler.dart`
- **AND** 类名 SHALL 为 `TimelineUploadHandler`
- **AND** 类 SHALL 负责处理上传业务逻辑（获取用户信息、启动备份服务、显示提示）
- **AND** 类 SHALL 提供 `handleUpload()` 方法处理上传
- **AND** 页面类 SHALL 将上传事件委托给处理器处理

#### Scenario: 页面类职责简化
- **WHEN** 查看 MainTimelinePage 类
- **THEN** 页面类代码行数 SHALL 不超过 400 行
- **AND** 页面类 SHALL 仅负责页面级协调逻辑和 UI 构建
- **AND** 页面类 SHALL 不包含复杂的业务逻辑（事件监听、拖动选择算法、上传处理等）
- **AND** 页面类 SHALL 通过控制器类和管理器处理业务逻辑
- **AND** 页面类 SHALL 在 `initState()` 中初始化所有控制器和管理器
- **AND** 页面类 SHALL 在 `dispose()` 中清理所有控制器和管理器

#### Scenario: 筛选按钮为独立组件
- **WHEN** 使用 TimelineFilterButton 组件
- **THEN** 该组件 SHALL 位于 `lib/presentation/widgets/timeline/timeline_filter_button.dart`
- **AND** 组件类名 SHALL 为 `TimelineFilterButton`
- **AND** 组件 SHALL 使用 `ConsumerWidget` 读取 `photoFilterModeProvider`
- **AND** 组件 SHALL 提供 `const` 构造函数
- **AND** 组件 SHALL 支持循环切换筛选模式（全部 → 已备份 → 未备份 → 仅云端 → 全部）

#### Scenario: 权限拒绝 UI 为独立组件
- **WHEN** 使用 TimelinePermissionDeniedView 组件
- **THEN** 该组件 SHALL 位于 `lib/presentation/widgets/timeline/timeline_permission_denied_view.dart`
- **AND** 组件类名 SHALL 为 `TimelinePermissionDeniedView`
- **AND** 组件 SHALL 接收 `PhotoPermissionState` 作为参数
- **AND** 组件 SHALL 使用 `StatelessWidget` 或 `ConsumerWidget`
- **AND** 组件 SHALL 提供 `const` 构造函数
- **AND** 组件 SHALL 显示权限请求提示和授权按钮

#### Scenario: 空状态 UI 为独立组件
- **WHEN** 使用 TimelineEmptyStateView 组件
- **THEN** 该组件 SHALL 位于 `lib/presentation/widgets/timeline/timeline_empty_state_view.dart`
- **AND** 组件类名 SHALL 为 `TimelineEmptyStateView`
- **AND** 组件 SHALL 使用 `StatelessWidget`
- **AND** 组件 SHALL 提供 `const` 构造函数
- **AND** 组件 SHALL 显示照片库图标和"暂无照片"文字

#### Scenario: 错误状态 UI 为独立组件
- **WHEN** 使用 TimelineErrorView 组件
- **THEN** 该组件 SHALL 位于 `lib/presentation/widgets/timeline/timeline_error_view.dart`
- **AND** 组件类名 SHALL 为 `TimelineErrorView`
- **AND** 组件 SHALL 使用 `ConsumerWidget` 以支持重试功能
- **AND** 组件 SHALL 提供 `const` 构造函数
- **AND** 组件 SHALL 显示错误图标、错误信息和重试按钮

#### Scenario: 正常模式 AppBar 为独立组件
- **WHEN** 使用 TimelineNormalAppBar 组件
- **THEN** 该组件 SHALL 位于 `lib/presentation/widgets/timeline/timeline_normal_app_bar.dart`
- **AND** 组件类名 SHALL 为 `TimelineNormalAppBar`
- **AND** 组件 SHALL 返回 `SliverAppBar`
- **AND** 组件 SHALL 使用 `ConsumerWidget` 读取必要的 Provider
- **AND** 组件 SHALL 包含标题、"照片"文字、筛选按钮、备份状态指示器、用户头像指示器
- **AND** 组件 SHALL 提供 `const` 构造函数（如果可能）

#### Scenario: 选择模式 AppBar 为独立组件
- **WHEN** 使用 TimelineSelectionAppBar 组件
- **THEN** 该组件 SHALL 位于 `lib/presentation/widgets/timeline/timeline_selection_app_bar.dart`
- **AND** 组件类名 SHALL 为 `TimelineSelectionAppBar`
- **AND** 组件 SHALL 返回 `SliverAppBar`
- **AND** 组件 SHALL 使用 `ConsumerWidget` 读取选择状态
- **AND** 组件 SHALL 包含关闭按钮、选中数量显示、全选按钮
- **AND** 组件 SHALL 提供 `const` 构造函数（如果可能）

#### Scenario: 内容构建器提取
- **WHEN** 构建时间线内容 Slivers
- **THEN** `_buildContentSlivers` 方法 SHALL 被提取为辅助方法或类
- **AND** 内容构建逻辑 SHALL 使用上述独立组件（TimelinePermissionDeniedView、TimelineEmptyStateView、TimelineErrorView 等）
- **AND** 方法 SHALL 处理权限状态、加载状态、错误状态、空状态和时间线数据展示

#### Scenario: 组件命名和目录规范
- **WHEN** 创建新的时间线相关组件
- **THEN** UI 组件文件 SHALL 存放在 `lib/presentation/widgets/timeline/` 目录下
- **AND** 业务逻辑控制器文件 SHALL 存放在 `lib/presentation/pages/photos/controllers/` 目录下
- **AND** 事件监听器文件 SHALL 存放在 `lib/presentation/pages/photos/listeners/` 目录下
- **AND** Mixin 文件 SHALL 存放在 `lib/presentation/pages/photos/mixins/` 目录下
- **AND** 文件名 SHALL 使用 `timeline_` 前缀（UI 组件）或功能描述（控制器），使用 snake_case 命名
- **AND** 类名 SHALL 与文件名对应，使用 PascalCase 命名

#### Scenario: 组件性能优化要求
- **WHEN** 实现新的 UI 组件
- **THEN** 无状态组件 SHALL 优先使用 `StatelessWidget`
- **AND** 需要读取 Provider 的组件 SHALL 使用 `ConsumerWidget`
- **AND** 所有组件 SHALL 提供 `const` 构造函数（如果可能）
- **AND** 组件调用时 SHALL 使用 `const` 关键字（如果可能）
- **AND** 使用 `ref.watch(provider.select(...))` 精准订阅，避免不必要的 Widget 重建

#### Scenario: 状态管理规范
- **WHEN** 组件需要访问全局状态
- **THEN** 组件 SHALL 通过 Riverpod Provider 直接访问，而不是通过构造函数传递
- **AND** 禁止通过构造函数传递超过 2 层的数据（避免 Prop Drilling）
- **AND** 局部 UI 状态（如开关、折叠状态）SHALL 使用 `StateProvider` 或本地状态管理
- **AND** 控制器类 SHALL 通过构造函数接收 WidgetRef，通过 Provider 访问状态

#### Scenario: 控制器类可测试性
- **WHEN** 实现业务逻辑控制器类
- **THEN** 控制器类 SHALL 可以独立测试，不依赖 Widget 生命周期
- **AND** 控制器类 SHALL 通过构造函数接收必要的依赖（WidgetRef、ScrollController 等）
- **AND** 控制器类 SHALL 不持有状态，状态由 Riverpod Provider 管理
- **AND** 控制器类 SHALL 提供清晰的公共接口，便于测试

### Requirement: 时间线数据合并和展示

时间线页面 SHALL 独立展示本地资产和远程资产，不进行自动关联去重。系统 SHALL 支持过滤选项，允许用户选择查看方式。

#### Scenario: 独立数据合并
- **WHEN** 获取时间线数据
- **THEN** 系统 SHALL 并行查询本地资产表和远程资产表
- **AND** 系统 SHALL 先添加所有远程资产（RemoteAsset）到列表
- **AND** 系统 SHALL 再添加所有本地资产（LocalAsset）到列表
- **AND** 系统 SHALL 不进行基于 checksum 的关联
- **AND** 系统 SHALL 不建立本地-远程资产关联
- **AND** 系统 SHALL 按创建时间降序排序

#### Scenario: 过滤选项支持
- **WHEN** 用户选择过滤模式
- **THEN** 系统 SHALL 支持"全部"模式（显示本地+远程资产）
- **AND** 系统 SHALL 支持"仅本地"模式（只显示本地资产）
- **AND** 系统 SHALL 支持"仅远程"模式（只显示远程资产）
- **AND** 系统 SHALL 支持"已备份"模式（显示 `isUploaded = true` 的本地资产）
- **AND** 系统 SHALL 支持"未备份"模式（显示 `isUploaded = false` 的本地资产）
- **AND** 系统 SHALL 通过 `TimelineFilterButton` 组件提供过滤选项

#### Scenario: 数据源选择
- **WHEN** 选择时间线数据源
- **THEN** 系统 SHALL 检查是否有远程资产
- **AND** 如果存在远程资产，系统 SHALL 使用数据库数据源（需要合并显示）
- **AND** 如果不存在远程资产，系统 SHALL 根据本地资产数量选择数据源（数据库或 photo_manager）

