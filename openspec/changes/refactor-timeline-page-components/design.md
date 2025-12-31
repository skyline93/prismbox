## Context

当前 `main_timeline_page.dart` 文件超过 1400 行，其中 `build` 方法超过 300 行，严重违反了项目规范中"任何 `build` 方法如果超过 80 行，必须拆分"的规定。该页面承担了过多的 UI 构建职责，需要将 UI 逻辑拆分为独立的原子组件。

## Goals / Non-Goals

### Goals
- 将 `MainTimelinePage.build` 方法控制在 80 行以内
- 将 UI 逻辑拆分为独立的、可复用的组件
- 遵循项目规范：组件命名、目录结构、性能优化要求
- 保持功能完全不变，纯重构不改变行为
- 提高代码可维护性和可测试性

### Non-Goals
- 不改变现有的业务逻辑和功能
- 不改变现有的状态管理方式（继续使用 Riverpod）
- 不进行性能优化以外的架构调整
- 不修改现有的 Provider 定义

## Decisions

### 决策 1：组件拆分策略
**决定**：按照 UI 功能边界拆分组件，每个组件负责一个明确的 UI 功能模块。

**理由**：
- 遵循单一职责原则，每个组件职责清晰
- 便于独立测试和维护
- 符合项目规范中的原子组件要求

**考虑的替代方案**：
- 按数据流拆分：但会导致组件职责不清晰
- 按状态类型拆分：但当前状态管理已经通过 Riverpod 统一管理

### 决策 2：组件类型选择
**决定**：优先使用 `StatelessWidget`，需要读取 Provider 时使用 `ConsumerWidget`。

**理由**：
- 项目规范要求优先使用 `StatelessWidget`
- 只有需要读取全局状态时才使用 `ConsumerWidget`
- 避免不必要的状态管理复杂度

**示例**：
- `TimelineEmptyStateView`：纯展示，使用 `StatelessWidget`
- `TimelineFilterButton`：需要读取和更新 `photoFilterModeProvider`，使用 `ConsumerWidget`

### 决策 3：组件位置和命名
**决定**：所有新组件存放在 `lib/presentation/widgets/timeline/` 目录下，使用 `timeline_` 前缀命名。

**理由**：
- 遵循项目规范的目录结构要求
- `timeline` 是功能模块标识，便于查找和维护
- 文件名前缀与类名保持一致（如 `timeline_filter_button.dart` → `TimelineFilterButton`）

### 决策 4：状态访问方式
**决定**：组件通过 Riverpod Provider 直接访问状态，避免通过构造函数传递超过 2 层的数据。

**理由**：
- 项目规范禁止 Prop Drilling（超过 2 层传递数据）
- Riverpod 提供了类型安全的状态管理
- 使用 `ref.watch(provider.select(...))` 可以精准订阅，避免不必要的重建

### 决策 5：内容构建器处理方式
**决定**：`TimelineContentSliversBuilder` 保持为辅助类或静态方法，不强制转换为 Widget。

**理由**：
- `_buildContentSlivers` 返回 `List<Widget>`，不是单个 Widget
- 作为辅助方法更符合其用途
- 避免不必要的 Widget 包装

## Risks / Trade-offs

### 风险 1：组件过度拆分导致代码碎片化
**风险**：拆分为过多小文件可能导致代码查找困难。

**缓解措施**：
- 按照功能模块合理拆分，每个组件有明确的职责
- 使用清晰的命名和目录结构
- 在文件头部添加文档注释说明组件用途

### 风险 2：状态管理复杂度增加
**风险**：多个组件访问同一个 Provider 可能导致状态同步问题。

**缓解措施**：
- 继续使用现有的 Provider 定义，不改变状态管理逻辑
- 使用 `ref.watch(provider.select(...))` 精准订阅，避免不必要的重建
- 保持页面类中的关键状态监听逻辑不变

### 风险 3：重构过程中引入 bug
**风险**：重构过程中可能遗漏某些功能或引入错误。

**缓解措施**：
- 逐步重构，每次提取一个组件并验证功能
- 保持功能完全不变，只改变代码组织结构
- 进行充分的功能测试

## Migration Plan

### 步骤 1：准备阶段
- 分析现有代码结构，确定需要拆分的组件
- 创建提案和设计文档（当前阶段）

### 步骤 2：组件实现阶段
- 按顺序创建各个组件（从最简单的开始）
- 每个组件创建后立即在页面中使用，验证功能

### 步骤 3：页面重构阶段
- 在 `MainTimelinePage` 中使用新组件替换原有代码
- 逐步移除已提取的方法
- 确保 `build` 方法控制在 80 行以内

### 步骤 4：验证和清理阶段
- 全面测试所有功能
- 运行 linter 检查代码规范
- 清理不必要的代码和注释

### 回滚计划
如果重构过程中发现严重问题，可以：
- 恢复原有代码（Git 版本控制）
- 逐步回滚已提取的组件
- 保持原有代码结构不变

## Open Questions

无。重构方案清晰，技术决策明确。

