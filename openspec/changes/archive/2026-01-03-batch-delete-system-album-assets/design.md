# Design: 批量删除系统相册资产优化

## Context

当前 `LocalAssetDeleteService.softDeleteAssets()` 方法循环调用 `softDeleteAsset()`，每个资产都单独调用系统删除 API (`PhotoManager.editor.deleteWithIds([assetId])`)，导致批量删除时弹出多次确认对话框。

## Goals / Non-Goals

### Goals
- 批量删除本地资产时，系统相册删除操作统一执行，只弹出一次确认对话框
- 保持单个删除场景不受影响
- 提升批量删除操作的效率和用户体验

### Non-Goals
- 不改变单个删除的行为
- 不修改系统 API 的调用方式（仍使用 `deleteWithIds`）
- 不改变文件复制和数据库更新的逻辑

## Decisions

### Decision: 两阶段批量删除流程

**方案**：
1. **阶段一**：批量处理文件复制和数据库更新（不涉及系统相册删除）
   - 遍历所有资产 ID
   - 对每个资产：验证、获取文件路径、复制到回收站、更新数据库
   - 收集成功处理的资产 ID
2. **阶段二**：统一批量删除系统相册资产
   - 将所有成功处理的资产 ID 一次性传递给 `PhotoManager.editor.deleteWithIds()`
   - 系统只会弹出一次确认对话框

**理由**：
- 将系统相册删除操作从循环中提取出来，统一执行
- 不影响现有的文件处理和数据库更新逻辑
- 保持代码清晰，易于维护

**替代方案考虑**：
- **方案 A**：保留循环，但收集所有 ID 后统一删除
  - 问题：如果某个资产在处理过程中失败，可能导致状态不一致
- **方案 B**：修改 `softDeleteAsset()` 不删除系统相册，统一在外层删除
  - 问题：改变单个删除的行为，可能影响其他调用场景

**选择方案**：采用两阶段流程，既保证了批量删除的统一确认，又不影响单个删除场景。

### Decision: 新增批量删除方法

**方案**：在 `TrashStorageService` 中新增 `deleteMultipleFromSystemAlbum()` 方法

**理由**：
- 保持职责分离：`TrashStorageService` 负责系统相册操作，`LocalAssetDeleteService` 负责业务逻辑编排
- 便于测试和维护
- 不影响现有的 `deleteFromSystemAlbum()` 方法

## Risks / Trade-offs

### Risk: 部分资产删除失败的处理

**风险**：阶段一成功但阶段二部分失败的场景

**缓解**：
- 记录阶段二的删除结果（成功/失败的资产 ID）
- 记录日志，允许用户查看详情
- 文件已复制到回收站，数据库已更新，即使系统相册删除失败，也可以从回收站恢复

### Risk: 错误处理复杂度增加

**风险**：两阶段流程可能增加错误处理的复杂度

**缓解**：
- 每个阶段独立处理错误
- 阶段一的失败不影响阶段二的执行
- 保持清晰的日志记录

## Migration Plan

无需迁移，这是内部实现优化，不影响外部接口和用户数据。

## Open Questions

无

