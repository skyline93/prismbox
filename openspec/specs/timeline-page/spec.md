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

时间线页面 SHALL 独立展示本地资产和远程资产，不进行自动关联去重。系统 SHALL 支持过滤选项，允许用户选择查看方式。系统 SHALL 支持删除功能，根据当前过滤模式决定删除行为。

#### Scenario: 独立数据合并
- **WHEN** 获取时间线数据
- **THEN** 系统 SHALL 并行查询本地资产表和远程资产表
- **AND** 系统 SHALL 先添加所有远程资产（RemoteAsset）到列表
- **AND** 系统 SHALL 再添加所有本地资产（LocalAsset）到列表
- **AND** 系统 SHALL 不进行基于 checksum 的关联
- **AND** 系统 SHALL 不建立本地-远程资产关联
- **AND** 系统 SHALL 按创建时间降序排序

#### Scenario: 过滤选项支持
- **WHEN** 用户选择"全部"过滤模式
- **THEN** 系统 SHALL 仅展示本地媒体资源（LocalAsset）
- **AND** 系统 SHALL 包括已上传的本地媒体资源
- **AND** 系统 SHALL 包括上传失败的本地媒体资源
- **AND** 系统 SHALL 包括未上传的本地媒体资源
- **AND** 系统 SHALL 不展示远程媒体资源（RemoteAsset）

- **WHEN** 用户选择"已备份"过滤模式
- **THEN** 系统 SHALL 仅展示已上传过的本地媒体资源（LocalAsset）
- **AND** 系统 SHALL 判断已上传状态的依据为：本地资产表的 `isUploaded` 字段为 `true`
- **AND** 系统 SHALL 不展示未上传的本地媒体资源（`isUploaded == false`）
- **AND** 系统 SHALL 不展示远程媒体资源（RemoteAsset）
- **AND** 系统 SHALL 不查询上传任务表来判断上传状态

- **WHEN** 用户选择"未备份"过滤模式
- **THEN** 系统 SHALL 仅展示未上传的本地媒体资源（LocalAsset）
- **AND** 系统 SHALL 判断未上传状态的依据为：本地资产表的 `isUploaded` 字段为 `false`
- **AND** 系统 SHALL 不区分"从未上传"和"上传失败"两种情况（都视为未上传）
- **AND** 系统 SHALL 不展示已成功上传的本地媒体资源（`isUploaded == true`）
- **AND** 系统 SHALL 不展示远程媒体资源（RemoteAsset）
- **AND** 系统 SHALL 不查询上传任务表来判断上传状态

- **WHEN** 用户选择"仅云端"过滤模式
- **THEN** 系统 SHALL 仅展示远程服务端的媒体资源（RemoteAsset）
- **AND** 系统 SHALL 不展示本地媒体资源（LocalAsset）

- **WHEN** 用户切换过滤模式
- **THEN** 系统 SHALL 通过 `TimelineFilterButton` 组件提供过滤选项
- **AND** 系统 SHALL 支持循环切换（全部 → 已备份 → 未备份 → 仅云端 → 全部）
- **AND** 系统 SHALL 实时更新过滤结果

#### Scenario: 数据源选择
- **WHEN** 选择时间线数据源
- **THEN** 系统 SHALL 检查是否有远程资产
- **AND** 如果存在远程资产，系统 SHALL 使用数据库数据源（需要合并显示）
- **AND** 如果不存在远程资产，系统 SHALL 根据本地资产数量选择数据源（数据库或 photo_manager）

#### Scenario: 上传状态判断基于本地资产表
- **WHEN** 过滤本地资产时判断上传状态
- **THEN** 系统 SHALL 仅使用本地资产表的 `isUploaded` 字段判断上传状态
- **AND** 系统 SHALL 不查询上传任务表来判断上传状态
- **AND** 系统 SHALL 在创建 `LocalAsset` 实体时，从数据库实体中读取 `isUploaded` 字段并存储
- **AND** 系统 SHALL 在过滤时直接使用 `LocalAsset` 实体的 `isUploaded` 字段，无需额外查询

#### Scenario: 删除功能支持
- **WHEN** 用户在选择模式下选择资产并点击删除按钮
- **THEN** 系统 SHALL 根据当前过滤模式决定删除行为
- **AND** 如果当前过滤模式为"全部"、"已备份"或"未备份"，系统 SHALL 仅支持删除本地资源
- **AND** 如果当前过滤模式为"仅云端"，系统 SHALL 仅支持删除远程资源
- **AND** 系统 SHALL 在选择模式下显示删除按钮
- **AND** 系统 SHALL 在执行删除前显示确认对话框
- **AND** 系统 SHALL 在执行删除后刷新时间线数据

#### Scenario: 本地资源删除
- **WHEN** 用户在"全部"、"已备份"或"未备份"模式下删除本地资源
- **THEN** 系统 SHALL 执行本地资源软删除操作
- **AND** 系统 SHALL 将文件从系统相册复制到应用私有回收站空间
- **AND** 系统 SHALL 删除系统相册中的原文件
- **AND** 系统 SHALL 更新本地资产表的软删除字段（`deletedAt`, `originalPath`, `trashPath`）
- **AND** 系统 SHALL 不删除远程资产（如果存在对应的远程资产）

#### Scenario: 批量删除本地资产系统相册确认
- **WHEN** 用户批量删除多个本地资产
- **THEN** 系统 SHALL 先批量处理文件复制和数据库更新操作（不涉及系统相册删除）
- **AND** 系统 SHALL 收集所有成功处理的资产 ID
- **AND** 系统 SHALL 统一调用系统相册删除 API 删除所有资产
- **AND** 系统 SHALL 只弹出一次系统确认对话框
- **AND** 系统 SHALL 记录删除结果（成功和失败的资产 ID）
- **AND** 如果系统相册删除部分失败，系统 SHALL 记录失败的资产 ID（但文件已复制到回收站，可以从回收站恢复）

#### Scenario: 远程资源删除
- **WHEN** 用户在"仅云端"模式下删除远程资源
- **THEN** 系统 SHALL 调用后端 API 执行远程资源软删除
- **AND** 系统 SHALL 调用 `DELETE /api/v1/media/:uuid` 接口
- **AND** 系统 SHALL 更新本地远程资产表的 `deletedAt` 字段
- **AND** 系统 SHALL 不删除本地资产（如果存在对应的本地资产）

#### Scenario: 删除操作错误处理
- **WHEN** 删除操作失败
- **THEN** 系统 SHALL 显示错误提示
- **AND** 系统 SHALL 不更新数据库记录（如果文件操作失败）
- **AND** 系统 SHALL 允许用户重试删除操作

### Requirement: 收藏图标展示

时间线页面的资产缩略图 SHALL 在左下角显示收藏图标，用于指示资产是否被标记为收藏。收藏图标 SHALL 仅在资产的 isFavorite 属性为 true 时显示。

#### Scenario: 收藏图标组件定义

- **WHEN** 定义收藏图标组件（FavoriteIndicator）
- **THEN** 组件 SHALL 位于 lib/presentation/widgets/timeline/favorite_indicator.dart
- **AND** 组件类名 SHALL 为 FavoriteIndicator
- **AND** 组件 SHALL 使用 StatelessWidget
- **AND** 组件 SHALL 提供 const 构造函数
- **AND** 组件 SHALL 接收 isFavorite 布尔参数

#### Scenario: 收藏图标仅在收藏时显示

- **WHEN** 资产的 isFavorite 属性为 true
- **THEN** 系统 SHALL 在缩略图左下角显示心形图标
- **AND** 心形图标 SHALL 使用填充样式（实心）
- **AND** 心形图标颜色 SHALL 为白色或红色
- **WHEN** 资产的 isFavorite 属性为 false
- **THEN** 系统 SHALL 不显示收藏图标

#### Scenario: 收藏图标视觉样式

- **WHEN** 显示收藏图标
- **THEN** 图标 SHALL 位于缩略图的左下角
- **AND** 图标大小 SHALL 为 16-20 像素
- **AND** 图标 SHALL 有半透明黑色圆形背景（opacity 0.5-0.7）
- **AND** 图标距离左边缘 SHALL 为 4-8 像素
- **AND** 图标距离底边缘 SHALL 为 4-8 像素
- **AND** 图标背景 SHALL 提供足够对比度，确保在任何照片背景下可见

#### Scenario: 集成到时间线缩略图

- **WHEN** 渲染时间线中的资产缩略图
- **THEN** 缩略图 SHALL 使用 Stack 布局容器
- **AND** FavoriteIndicator 组件 SHALL 作为 Stack 的子组件
- **AND** FavoriteIndicator SHALL 位于 Stack 的顶层（不被其他元素遮挡）
- **AND** FavoriteIndicator SHALL 接收 asset.isFavorite 作为参数
- **AND** 其他 UI 元素（如选择框、视频时长标识）SHALL 不与收藏图标重叠

#### Scenario: 组件性能要求

- **WHEN** 使用 FavoriteIndicator 组件
- **THEN** 组件 SHALL 提供 const 构造函数
- **AND** 组件 SHALL 避免不必要的重建
- **AND** 组件 SHALL 使用 const 定义静态图标和样式
- **AND** 组件渲染 SHALL 不影响时间线滚动性能

#### Scenario: 收藏图标在选择模式下的显示

- **WHEN** 时间线进入选择模式
- **THEN** 收藏图标 SHALL 继续显示
- **AND** 收藏图标 SHALL 不影响选择框的显示和交互
- **AND** 收藏图标的层级 SHALL 低于选择框

#### Scenario: 收藏状态更新后的 UI 刷新

- **WHEN** 资产的收藏状态在本地数据库中更新
- **THEN** 时间线 UI SHALL 自动刷新显示最新状态
- **AND** 如果收藏状态从 false 变为 true，SHALL 显示收藏图标
- **AND** 如果收藏状态从 true 变为 false，SHALL 隐藏收藏图标

