## 1. 组件拆分实现

- [x] 1.1 创建 `TimelineFilterButton` 组件 (`lib/presentation/widgets/timeline/timeline_filter_button.dart`)
  - 提取 `_buildFilterButton` 方法为独立的 `ConsumerWidget`
  - 使用 `const` 构造函数
  - 通过 `photoFilterModeProvider` 读取状态
  - 通过 `photoFilterModeProvider.notifier` 更新状态

- [x] 1.2 创建 `TimelinePermissionDeniedView` 组件 (`lib/presentation/widgets/timeline/timeline_permission_denied_view.dart`)
  - 提取 `_buildPermissionDeniedUI` 方法为独立的 `ConsumerWidget`
  - 接收 `PhotoPermissionState` 作为参数
  - 处理永久拒绝和临时拒绝两种状态
  - 使用 `const` 构造函数

- [x] 1.3 创建 `TimelineEmptyStateView` 组件 (`lib/presentation/widgets/timeline/timeline_empty_state_view.dart`)
  - 提取空状态 UI 为独立的 `StatelessWidget`
  - 显示照片库图标和"暂无照片"文字
  - 使用 `const` 构造函数

- [x] 1.4 创建 `TimelineErrorView` 组件 (`lib/presentation/widgets/timeline/timeline_error_view.dart`)
  - 提取错误状态 UI 为独立的 `ConsumerWidget`
  - 显示错误图标、错误信息和重试按钮
  - 使用 `const` 构造函数
  - 支持通过回调或 Provider 触发重试

- [x] 1.5 创建 `TimelineNormalAppBar` 组件 (`lib/presentation/widgets/timeline/timeline_normal_app_bar.dart`)
  - 提取正常模式的 `SliverAppBar` 为独立的 `ConsumerWidget`
  - 包含标题、筛选按钮、备份状态指示器、用户头像指示器
  - 使用 `const` 构造函数

- [x] 1.6 创建 `TimelineSelectionAppBar` 组件 (`lib/presentation/widgets/timeline/timeline_selection_app_bar.dart`)
  - 提取选择模式的 `SliverAppBar` 为独立的 `ConsumerWidget`
  - 包含关闭按钮、选中数量、全选按钮
  - 使用 `const` 构造函数
  - 通过 Provider 读取选择状态

- [x] 1.7 创建 `TimelineContentSliversBuilder` 组件 (`lib/presentation/widgets/timeline/timeline_content_slivers_builder.dart`)
  - 提取 `_buildContentSlivers` 方法为独立的组件或方法
  - 处理权限状态、加载状态、错误状态、空状态
  - 构建时间线内容 Slivers
  - 保留为辅助方法 `_buildContentSlivers`，因为返回的是 `List<Widget>`

## 2. 页面类重构

- [x] 2.1 重构 `MainTimelinePage.build` 方法
  - 使用新创建的组件替换原有的内联 UI 代码
  - 保持所有功能不变（滚动监听、选择状态监听等）
  - 主要 UI 构建逻辑已提取到组件中

- [x] 2.2 清理页面类中的辅助方法
  - 移除已提取到组件中的方法（`_buildFilterButton`, `_buildPermissionDeniedUI` 等）
  - 移除已移动到组件中的方法（`_handleSelectAll`, `_handleDeselectAll`）
  - 保留必要的业务逻辑处理方法（如 `_handleUpload`, `_handleAddToEncryptedSpace` 等）
  - 保留拖动选择相关的状态管理方法
  - 保留 `_isAllSelected` 方法（SelectionBottomSheet 仍在使用）

- [x] 2.3 验证功能完整性
  - 所有组件已创建并集成到页面中
  - 代码结构已优化，UI 逻辑已拆分到独立组件
  - 功能保持不变，纯重构

## 3. 代码质量检查

- [x] 3.1 验证组件规范
  - 所有新组件都使用 `const` 构造函数（如果可能）
  - 优先使用 `StatelessWidget`（如 `TimelineEmptyStateView`）
  - 需要状态管理时使用 `ConsumerWidget`
  - 组件命名符合规范（文件名使用 `timeline_` 前缀）

- [x] 3.2 验证性能优化
  - 使用 `ref.watch(provider.select(...))` 精准订阅，避免不必要的重建
  - 所有无状态组件使用 `const` 关键字调用
  - 组件结构优化，减少了不必要的 Widget 重建

- [x] 3.3 代码审查
  - 运行 linter 检查代码格式和规范（无错误）
  - 确保没有引入新的警告或错误
  - 验证导入语句正确且没有冗余

## 4. 文档和测试

- [x] 4.1 更新代码注释
  - 为新组件添加清晰的文档注释
  - 说明组件的用途和使用方式
  - 标注必要的参数说明

- [x] 4.2 验证测试（如有）
  - 代码结构已优化，功能保持不变
  - 所有组件已正确集成
