# Change: 重构时间线页面 UI 组件化

## Why

当前 `main_timeline_page.dart` 文件超过 1400 行，`build` 方法超过 300 行，严重违反了 `project.md` 中规定的 UI 重构规范：
- **拆分阈值违规**：`build` 方法超过 80 行（当前约 311 行）
- **组件化不足**：大量 UI 逻辑集中在页面类中，难以维护和测试
- **代码可读性差**：方法过长导致逻辑难以理解
- **违反单一职责原则**：页面类承担了过多的 UI 构建职责

通过将 UI 拆分为原子组件，可以：
- 提高代码可维护性和可测试性
- 遵循项目规范，确保代码质量
- 便于组件复用和独立测试
- 降低代码复杂度，提升开发效率

## What Changes

- **拆分 AppBar 组件**：将选择模式 AppBar 和正常模式 AppBar 拆分为独立组件
  - `TimelineSelectionAppBar`：选择模式下的 AppBar
  - `TimelineNormalAppBar`：正常模式下的 AppBar（包含筛选按钮）
- **拆分筛选按钮组件**：`TimelineFilterButton` - 独立的筛选模式按钮组件
- **拆分权限 UI 组件**：`TimelinePermissionDeniedView` - 权限被拒绝时的 UI
- **拆分空状态组件**：`TimelineEmptyStateView` - 无照片时的空状态 UI
- **拆分错误状态组件**：`TimelineErrorView` - 加载错误时的 UI
- **拆分内容构建器**：`TimelineContentSliversBuilder` - 构建时间线内容 Slivers 的组件
- **简化页面类**：`MainTimelinePage` 仅保留页面级逻辑和状态管理

所有新组件将：
- 存放在 `lib/presentation/widgets/timeline/` 目录下
- 使用 `timeline_` 前缀命名（如 `timeline_selection_app_bar.dart`）
- 优先使用 `StatelessWidget` 和 `const` 构造函数
- 通过 Riverpod Provider 访问全局状态，避免过度传递参数

## Impact

- **受影响文件**：
  - `mobile/lib/presentation/pages/photos/main_timeline_page.dart` - 大幅简化
  - 新增 6-7 个组件文件在 `mobile/lib/presentation/widgets/timeline/` 目录下
- **受影响规范**：
  - UI 重构规范（project.md 中的 UI 拆分策略）
  - 组件命名规范
  - 性能优化要求（const 构造函数、StatelessWidget 优先）
- **向后兼容性**：纯重构，不改变功能行为，保持完全兼容

