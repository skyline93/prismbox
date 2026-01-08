# Design: Riverpod Provider Design Principles

## Context

Riverpod 是 Flutter 应用的状态管理框架，采用懒加载机制。Provider 只有在被 `watch` 或 `read` 时才会初始化，`build()` 方法在初始化时被调用。

在开发过程中，我们遇到了以下问题：

1. **时序竞争问题**：`build()` 返回占位值，手动调用 `load()` 时，状态可能仍在 `loading`，导致 `load()` 被跳过
2. **条件渲染死锁**：Provider 在条件渲染的 Widget 中被 watch，如果条件不满足，Provider 永远不会初始化
3. **状态管理不一致**：不同 Provider 采用不同的初始化策略

## Goals

- 建立清晰的 Riverpod Provider 设计原则
- 避免时序竞争和初始化死锁问题
- 确保状态管理的一致性和可维护性
- 提供明确的错误处理策略

## Non-Goals

- 不改变 Riverpod 框架本身的行为
- 不强制重构所有现有代码（允许逐步迁移）

## Decisions

### Decision 1: build() 方法必须负责数据加载

**What**: Provider 的 `build()` 方法必须直接加载数据，而不是返回占位值。

**Why**: 
- 符合 Riverpod 的设计原则：`build()` 负责初始化
- 避免时序竞争：不需要手动调用 `load()`
- 简化状态管理：减少状态转换的复杂度

**Alternatives considered**:
- `build()` 返回占位值，手动调用 `load()`：引入了时序竞争问题
- 使用 `ref.listen()` 监听状态变化：增加了复杂度，不符合 Riverpod 的设计理念

### Decision 2: 在顶层无条件 watch Provider

**What**: 所有需要的 Provider 必须在 Widget 的 `build()` 方法顶层无条件 watch，避免在条件渲染中 watch。

**Why**:
- 确保 Provider 能够及时初始化
- 避免条件渲染导致的依赖链断裂
- 实现并行加载，提升性能

**Alternatives considered**:
- 在条件渲染中 watch：可能导致初始化死锁
- 使用 `ref.read()` 替代 `ref.watch()`：无法响应状态变化

### Decision 3: 统一的错误处理策略

**What**: Provider 的 `build()` 方法在加载失败时应该抛出异常，而不是返回占位值。

**Why**:
- 让 UI 能够正确显示错误状态
- 避免 UI 一直显示加载中（当返回 null 时）
- 提供清晰的错误信息

**Alternatives considered**:
- 返回 null 或空列表：UI 无法区分"加载中"和"加载失败"
- 使用 `AsyncValue.error()`：需要在 `build()` 中手动管理状态，不符合 Riverpod 的设计

### Decision 4: 保持状态管理一致性

**What**: 所有 Provider 必须遵循相同的设计模式。

**Why**:
- 提高代码可维护性
- 减少认知负担
- 避免不同 Provider 行为不一致导致的问题

## Risks / Trade-offs

### Risk 1: 现有代码不符合规范

**Mitigation**: 
- 规范是指导性的，不强制立即重构
- 新代码必须遵循规范
- 逐步重构现有代码

### Risk 2: build() 中加载数据可能导致初始化阻塞

**Mitigation**:
- 这是 Riverpod 的设计理念，`build()` 本身就是异步的
- 如果数据加载很慢，可以考虑添加缓存或优化加载逻辑
- 可以使用 `ref.future` 在 UI 中显示加载状态

### Risk 3: 无条件 watch 可能导致不必要的初始化

**Mitigation**:
- Riverpod 的懒加载机制确保只有被 watch 的 Provider 才会初始化
- 如果某些 Provider 确实不需要立即初始化，可以考虑使用 `ref.read()` 或延迟初始化
- 但这种情况应该很少，大多数情况下并行初始化是更好的选择

## Migration Plan

1. **新代码**：必须遵循规范
2. **现有代码**：逐步重构，优先重构有问题的代码
3. **代码审查**：在 PR 审查中检查是否符合规范

## Open Questions

- 是否需要创建代码检查工具（linter）来强制执行规范？
- 是否需要为不同类型的 Provider（AsyncNotifier、Notifier、FutureProvider）制定不同的规范？

