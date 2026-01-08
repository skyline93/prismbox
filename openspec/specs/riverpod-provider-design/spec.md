# riverpod-provider-design Specification

## Purpose
TBD - created by archiving change add-riverpod-provider-design-principles. Update Purpose after archive.
## Requirements
### Requirement: Provider build() Method Must Load Data

Provider 的 `build()` 方法 SHALL 直接加载数据，而不是返回占位值（空列表、null 等）。

#### Scenario: Provider initialization loads data
- **WHEN** Provider 被首次 watch 或 read
- **THEN** `build()` 方法 SHALL 被调用
- **AND** `build()` 方法 SHALL 直接执行数据加载逻辑（如 API 调用、数据库查询等）
- **AND** `build()` 方法 SHALL 返回加载的数据，而不是占位值

#### Scenario: Provider initialization error handling
- **WHEN** `build()` 方法中的数据加载失败
- **THEN** `build()` 方法 SHALL 抛出异常
- **AND** Provider 状态 SHALL 变为 `AsyncValue.error()`
- **AND** UI SHALL 能够通过 `when(error: ...)` 显示错误状态

### Requirement: Unconditional Provider Watch at Top Level

所有需要的 Provider SHALL 在 Widget 的 `build()` 方法顶层无条件 watch，避免在条件渲染中 watch。

#### Scenario: Provider watch at top level
- **WHEN** Widget 需要访问多个 Provider
- **THEN** 所有 Provider SHALL 在 `build()` 方法顶层使用 `ref.watch()` 访问
- **AND** Provider 的 watch SHALL 不依赖于其他条件（如其他 Provider 的状态）
- **AND** Provider SHALL 在 Widget 初始化时立即开始加载数据

#### Scenario: Avoid conditional provider watch
- **WHEN** Provider 在条件渲染的 Widget 中被 watch（如 `when(data: ...)` 回调中）
- **THEN** 这 SHALL 被视为反模式
- **AND** Provider SHALL 被移动到顶层无条件 watch
- **AND** 条件逻辑 SHALL 仅用于 UI 渲染，不用于控制 Provider 的初始化

### Requirement: Parallel Loading Strategy

多个 Provider SHALL 在顶层并行 watch，实现并行加载，提升性能。

#### Scenario: Parallel provider initialization
- **WHEN** Widget 需要多个 Provider 的数据
- **THEN** 所有 Provider SHALL 在 `build()` 方法顶层并行 watch
- **AND** Provider SHALL 独立初始化，不相互依赖
- **AND** UI SHALL 能够分别处理每个 Provider 的加载状态

#### Scenario: Avoid serial loading
- **WHEN** Provider B 的初始化依赖于 Provider A 的数据
- **THEN** 这 SHALL 被视为反模式
- **AND** Provider SHALL 设计为可以独立初始化
- **AND** 如果确实需要依赖关系，SHALL 使用 Provider 的 `ref.watch()` 在 `build()` 中访问依赖的 Provider

### Requirement: Consistent State Management Pattern

所有 Provider SHALL 遵循相同的设计模式和错误处理策略。

#### Scenario: Consistent initialization pattern
- **WHEN** 创建新的 Provider
- **THEN** Provider SHALL 在 `build()` 方法中直接加载数据
- **AND** Provider SHALL 使用相同的错误处理策略（抛出异常）
- **AND** Provider SHALL 遵循相同的命名和代码组织规范

#### Scenario: Consistent error handling
- **WHEN** Provider 加载数据失败
- **THEN** Provider SHALL 抛出异常，而不是返回占位值
- **AND** 所有 Provider SHALL 使用相同的错误处理方式
- **AND** UI SHALL 能够通过统一的方式处理错误状态

### Requirement: Provider Refresh and Reload

Provider SHALL 提供 `refresh()` 或 `load()` 方法用于手动刷新数据，但这些方法 SHALL 不用于初始化。

#### Scenario: Provider refresh method
- **WHEN** Provider 需要手动刷新数据
- **THEN** Provider SHALL 提供 `refresh()` 或 `load()` 方法
- **AND** 这些方法 SHALL 检查当前状态，避免重复加载
- **AND** 这些方法 SHALL 用于刷新已初始化的 Provider，而不是用于初始化

#### Scenario: Provider initialization vs refresh
- **WHEN** Provider 首次被访问
- **THEN** 数据 SHALL 通过 `build()` 方法自动加载
- **AND** 不需要手动调用 `load()` 或 `refresh()` 进行初始化
- **AND** `load()` 或 `refresh()` 方法 SHALL 仅用于用户主动刷新或数据更新

