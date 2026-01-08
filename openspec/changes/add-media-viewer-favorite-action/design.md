# Design: 媒体预览页面收藏功能实现

## Context

媒体预览页面（MediaViewerPage）需要支持收藏功能的显示和操作。当前已有：
- ViewerControlsBar 组件包含收藏按钮占位
- 数据库中有 `isFavorite` 字段存储收藏状态
- 原生 API 已有 `getIsFavorite` 读取系统相册收藏状态（用于同步流程）
- 缺少收藏状态切换的服务层封装

**设计原则**：Prismbox 中的收藏操作仅更新 Prismbox 数据库，不修改系统相册。系统相册的收藏状态通过现有的 `getIsFavorite` API 读取，在同步流程中同步到 Prismbox 数据库。

## Goals / Non-Goals

### Goals
- 在预览页面显示当前资源的收藏状态（从 Prismbox 数据库读取）
- 支持点击收藏按钮切换收藏状态（仅更新 Prismbox 数据库）
- 确保 UI 响应式更新

### Non-Goals
- 不在本次变更中实现批量收藏操作
- 不在本次变更中实现收藏筛选功能
- 不在本次变更中实现收藏同步到服务器（后续可能通过备份流程同步）

## Decisions

### Decision 1: 不修改系统相册，仅更新数据库
**选择**: Prismbox 中的收藏操作仅更新 Prismbox 数据库，不调用原生 API 修改系统相册

**理由**:
- 简化实现，避免平台兼容性问题（如 Android 10 及以下不支持修改）
- 避免权限问题（不需要写入系统相册的权限）
- 系统相册的收藏状态通过同步流程读取，保持单向同步
- 降低实现复杂度，减少错误处理场景

**替代方案**: 同时更新系统相册和数据库
- 缺点：需要处理平台兼容性、权限问题、URI 选择等复杂场景

### Decision 2: 创建独立的 AssetFavoriteService
**选择**: 创建 `AssetFavoriteService` 封装收藏操作逻辑

**理由**:
- 遵循单一职责原则，收藏操作逻辑独立封装
- 便于测试和维护
- 未来可以扩展更多收藏相关功能（如批量操作）

**替代方案**: 直接在 MediaViewerPage 中调用 DAO
- 缺点：违反分层架构，业务逻辑混入 UI 层

### Decision 3: 使用乐观更新策略
**选择**: 先更新 UI 状态，再更新数据库

**理由**:
- 提供即时的用户反馈，提升用户体验
- 数据库更新失败概率低，回滚成本低
- 符合现代 UI 设计的最佳实践

**替代方案**: 等待数据库更新完成后再更新 UI
- 缺点：用户需要等待，体验较差

### Decision 4: 状态同步方案
**选择**: 使用局部状态 + Provider 刷新

**理由**:
- 局部状态用于即时 UI 更新（乐观更新）
- Provider 刷新确保数据一致性（从数据库重新加载）
- 平衡性能和一致性

**替代方案 A**: 仅使用 Provider 刷新
- 缺点：可能触发全量刷新，性能开销大

**替代方案 B**: 仅使用局部状态
- 缺点：数据可能不一致，需要手动同步

### Decision 5: 响应式状态更新方案
**选择**: 方案1 + 方案3 组合

**方案1**: 每次更新 `_assetMap`
- 去掉 `_assetMap ??=` 中的 `??`，每次 `allAssets` 更新时都重新构建映射
- 确保缓存始终是最新的

**方案3**: 使用 `Consumer` 包装 `ViewerControlsBar`
- 让 `ViewerControlsBar` 直接响应 `timelineAssetsProvider` 的更新
- 确保收藏按钮状态与照片页面缩略图状态一致

**理由**:
- 方案1 确保 `_assetMap` 缓存始终最新，提升性能
- 方案3 确保 UI 组件直接响应数据源变化，保证状态一致性
- 组合使用既保证性能又保证响应式更新

**替代方案**: 仅使用方案1
- 缺点：如果 `_assetMap` 更新时机不对，UI 可能不会自动刷新

**替代方案**: 仅使用方案3
- 缺点：每次都需要查询 Provider，可能有性能开销

## Risks / Trade-offs

### Risk 1: 并发操作导致状态不一致
**影响**: 用户快速连续点击可能导致状态混乱

**缓解措施**:
- 在操作进行中禁用按钮
- 使用防抖或节流机制
- 操作完成后从数据库重新加载状态

### Risk 2: 状态显示不一致
**影响**: 预览页面收藏按钮状态与照片页面缩略图状态不一致，或与数据库状态不一致

**缓解措施**:
- 使用 `Consumer` 包装 `ViewerControlsBar`，直接响应 `timelineAssetsProvider` 更新
- 每次 `allAssets` 更新时都更新 `_assetMap`，确保缓存最新
- 收藏操作成功后刷新 `timelineAssetsProvider`，确保全局状态一致

## Migration Plan

### 步骤 1: 创建服务层
1. 创建 `AssetFavoriteService` 类
2. 实现 `toggleFavorite` 和 `setFavorite` 方法（仅更新数据库）
3. 添加错误处理和日志记录

### 步骤 2: 更新 UI 组件
1. 更新 `ViewerControlsBar` 支持状态显示
2. 在 `MediaViewerPage` 中集成收藏功能
3. 实现状态同步逻辑
4. 修复状态响应式更新：使用 `Consumer` 包装 `ViewerControlsBar`，确保直接响应 `timelineAssetsProvider` 更新
5. 修复 `_assetMap` 更新逻辑：每次 `allAssets` 更新时都重新构建映射

### 步骤 3: 清理旧代码
1. 移除 Pigeon 接口中的 `setIsFavorite` 方法
2. 移除 iOS 和 Android 原生实现中的 `setIsFavorite` 方法
3. 移除测试文件
4. 更新 `AssetFavoriteService`，移除对 `AssetNativeApi` 的依赖

## Open Questions

1. **是否需要支持批量收藏操作？**
   - 当前方案：仅支持单个资源操作
   - 未来扩展：可以在后续变更中添加批量操作

2. **收藏状态是否需要同步到服务器？**
   - 当前方案：仅更新本地数据库
   - 未来扩展：可以通过备份流程同步到服务器
   - 系统相册的收藏状态通过同步流程读取，保持单向同步

3. **是否需要添加收藏操作的撤销功能？**
   - 当前方案：不支持撤销，用户需要再次点击取消收藏
   - 未来扩展：可以添加操作历史记录和撤销功能

