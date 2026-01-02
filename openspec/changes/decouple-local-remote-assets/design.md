# Design: 本地资源与远程资源完全解耦

## Context

当前系统通过 checksum（文件哈希）关联本地资产和远程资产。这种设计在跨平台环境下存在不可靠性，且增加了系统复杂度。本设计旨在完全解耦本地资源和远程资源，通过简单的 `isUploaded` 标识管理上传状态。

## Goals / Non-Goals

### Goals
- 完全解耦本地资产和远程资产，消除数据关联依赖
- 简化上传状态管理，使用单一布尔字段
- 提升性能，前端不再计算文件 hash
- 支持多设备独立上传，后端统一去重
- 时间线支持独立展示本地和远程资产

### Non-Goals
- 不实现跨设备上传状态同步（未来通过 WebSocket 实现）
- 不实现删除远程资产后的自动状态重置（未来通过 WebSocket 实现）
- 不实现数据修复机制（未来通过 WebSocket 或工具实现）
- 不考虑历史数据迁移（项目处于开发阶段）

## Decisions

### Decision 1: 使用 `isUploaded` 字段管理上传状态

**What**: 在本地资产表中添加 `isUploaded` 布尔字段，标识资产是否已上传。

**Why**: 
- 简单直接，无需复杂的关联逻辑
- 状态持久化在本地资产表，不依赖可能被清理的上传任务表
- 查询性能好，单表查询即可

**Alternatives considered**:
- 通过上传任务表关联：上传任务可能被清理，状态丢失
- 通过 checksum 关联远程资产表：跨平台不可靠，增加复杂度

### Decision 2: 后端统一计算 hash

**What**: 前端不再计算文件 hash，由后端接收文件后统一计算。

**Why**:
- 避免跨平台 hash 不一致问题
- 统一 hash 计算标准
- 减少前端计算开销
- 后端可以使用更可靠的 hash 算法

**Alternatives considered**:
- 前端计算 hash：存在跨平台不一致问题
- 前后端都计算：冗余计算，增加复杂度

### Decision 3: 多设备允许独立上传

**What**: 不同设备可以独立上传相同资产，后端通过 hash 去重。

**Why**:
- 设备间无需同步上传状态
- 后端统一去重，避免重复存储
- 每个设备独立管理自己的上传状态

**Alternatives considered**:
- 设备间同步上传状态：需要复杂的同步机制，增加复杂度

### Decision 4: 时间线独立展示本地和远程资产

**What**: 时间线同时展示本地资产和远程资产，不进行自动关联去重。

**Why**:
- 完全解耦，无需关联逻辑
- 用户可以选择查看方式（全部/仅本地/仅远程）
- 简化代码逻辑

**Alternatives considered**:
- 基于文件名/时间智能去重：增加复杂度，可能误判
- 基于 checksum 关联：存在跨平台不可靠问题

### Decision 5: 仅在上传成功时设置 `isUploaded = true`

**What**: 只有在上传任务状态为 `completed` 时，才更新 `isUploaded = true`。

**Why**:
- 确保状态准确性
- 失败时保持 `false`，允许重试
- 避免误标记

**Alternatives considered**:
- 创建任务时即标记：可能导致误标记，无法重试

## Risks / Trade-offs

### Risk 1: 时间线可能显示重复资产

**Risk**: 同一张照片可能同时显示本地版本和远程版本。

**Mitigation**: 
- 提供过滤选项（全部/仅本地/仅远程）
- 用户可以选择查看方式
- 未来可考虑基于文件名/时间智能去重（可选）

### Risk 2: 多设备可能重复上传

**Risk**: 设备A上传后，设备B不知道，可能重复上传。

**Mitigation**:
- 后端通过 hash 去重，不存储重复文件
- 设备B上传成功后也会标记 `isUploaded = true`
- 未来通过 WebSocket 实现实时同步

### Risk 3: 删除远程资产后状态不一致

**Risk**: 用户删除服务器上的资产，本地 `isUploaded` 仍为 `true`。

**Mitigation**:
- 暂时不处理，未来通过 WebSocket 实时通知
- 或提供手动"重置上传状态"功能

### Risk 4: 数据修复机制缺失

**Risk**: `isUploaded = true` 但远程资产不存在时，无法自动修复。

**Mitigation**:
- 暂时不处理，未来通过 WebSocket 或数据修复工具实现
- 确保上传成功回调的可靠性，减少不一致情况

## Migration Plan

### Phase 1: 数据库迁移
1. 添加 `isUploaded` 字段到 `local_asset_entity` 表
2. 默认值设为 `false`
3. 所有现有数据初始化为 `false`

### Phase 2: 代码重构
1. 移除 ChecksumMatchingService
2. 重构上传去重逻辑
3. 重构上传成功回调
4. 重构时间线合并逻辑
5. 重构上传状态标识逻辑

### Phase 3: 清理废弃代码
1. 移除前端 hash 计算代码
2. 从本地资产表中移除 `checksum` 字段
3. 清理 checksum 相关注释和文档
4. 删除 `ChecksumService` 及相关代码

### Rollback Plan
- 如果出现问题，可以回滚数据库迁移
- 代码通过 Git 版本控制回滚

## Open Questions

1. **是否需要保留 `checksum` 字段？**
   - 决策：完全移除，不再需要

2. **时间线去重策略？**
   - 决策：暂时不实现，提供过滤选项

3. **多设备状态同步机制？**
   - 决策：暂时不实现，未来通过 WebSocket

4. **数据修复机制？**
   - 决策：暂时不实现，未来通过 WebSocket 或工具

