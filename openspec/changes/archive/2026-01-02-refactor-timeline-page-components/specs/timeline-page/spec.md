## ADDED Requirements

### Requirement: 时间线页面 UI 组件结构
时间线页面（MainTimelinePage）的 UI 组件 SHALL 遵循原子组件拆分原则，将大型 UI 逻辑拆分为独立的、可复用的组件。

#### Scenario: 页面 build 方法符合行数限制
- **WHEN** 查看 MainTimelinePage 的 build 方法
- **THEN** build 方法的代码行数 SHALL 不超过 80 行
- **AND** UI 构建逻辑 SHALL 通过独立的组件实现

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
- **THEN** 组件文件 SHALL 存放在 `lib/presentation/widgets/timeline/` 目录下
- **AND** 文件名 SHALL 使用 `timeline_` 前缀，使用 snake_case 命名（如 `timeline_filter_button.dart`）
- **AND** 类名 SHALL 与文件名对应，使用 PascalCase 命名（如 `TimelineFilterButton`）

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

