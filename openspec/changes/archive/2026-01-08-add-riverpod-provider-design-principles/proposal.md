# Change: Add Riverpod Provider Design Principles

## Why

在开发过程中，我们遇到了多次因 Riverpod Provider 设计不当导致的问题：

1. **初始化死锁**：Provider 的 `build()` 方法返回占位值（空列表/null），依赖手动调用 `load()` 加载数据，导致时序竞争问题
2. **条件渲染导致的依赖链断裂**：Provider 在条件渲染的 Widget 中被 watch，导致初始化被延迟或跳过
3. **状态管理不一致**：不同 Provider 采用不同的初始化策略，导致行为不一致

这些问题反映了对 Riverpod 懒加载机制和初始化流程理解不足，需要建立明确的设计原则规范，避免后续再踩到类似问题。

## What Changes

- **ADDED**：Riverpod Provider 设计原则规范（`specs/riverpod-provider-design/spec.md`）
  - Provider 初始化原则：`build()` 方法必须负责数据加载
  - Provider Watch 原则：避免在条件渲染中 watch Provider
  - 并行加载原则：在顶层无条件 watch 所有需要的 Provider
  - 错误处理原则：统一的错误处理策略
  - 状态管理一致性原则：所有 Provider 遵循相同的设计模式

## Impact

- **Affected specs**: 新增 `riverpod-provider-design` capability
- **Affected code**: 
  - 所有使用 Riverpod Provider 的代码（`mobile/lib/providers/`）
  - 所有使用 Provider 的 UI 代码（`mobile/lib/presentation/`）
- **Breaking changes**: 无（这是新增规范，不改变现有行为）
- **Migration**: 现有代码可以逐步重构以符合新规范

