# Design: 异步宽高比获取服务设计

## Context

之前的修复在 `BaseAsset` 中添加了 `aspectRatio` getter，但当 `asset.aspectRatio` 为 null 时，直接使用临时宽高比（16/9），导致视频仍然被拉伸。

根本原因是：
1. `asset.aspectRatio` 可能为 null（width/height 未加载、orientation 为 null 等）
2. 缺少异步获取宽高比的机制
3. 直接使用临时宽高比导致拉伸

参考 Immich 的实现（`immich/mobile/lib/domain/services/asset.service.dart`），需要创建一个服务来异步获取宽高比。

## Goals / Non-Goals

### Goals
- 创建异步宽高比获取服务，彻底解决视频拉伸问题
- 当 `asset.aspectRatio` 为 null 时，从数据库获取 width/height/orientation
- 对于 RemoteAsset，从 EXIF 获取 orientation（如果可用，当前阶段可简化）
- 确保视频预览时使用正确的宽高比

### Non-Goals
- 不改变现有的 `BaseAsset.aspectRatio` getter 实现
- 不在此阶段实现完整的 EXIF 解析（仅获取 orientation，如果不可用则使用 width/height 直接计算）

## Decisions

### Decision 1: 创建 AssetService
**What**: 在 `mobile/lib/services/asset/` 目录下创建 `AssetService`，提供 `getAspectRatio` 异步方法。

**Why**:
- 参考 Immich 的实现，确保一致性
- 封装数据库访问逻辑，便于维护
- 支持异步操作，不阻塞 UI
- 符合 PrismBox 的架构模式：通用服务放在 `lib/services/` 目录下，按功能分类
- 与 `lib/services/auth/`、`lib/services/trash/` 等保持一致的组织结构

**Alternatives considered**:
- 在 ViewerVideoPage 中直接访问数据库：会增加代码复杂度，不利于复用
- 在 BaseAsset 中添加异步方法：不符合实体类的设计原则
- 扩展现有服务：没有合适的现有服务可以扩展

### Decision 2: 从数据库获取 width/height/orientation
**What**: 如果 asset 的 width/height 为 null，从数据库获取。

**Why**:
- 确保能够获取到完整的尺寸信息
- 参考 Immich 的实现（`_getLocalAssetDimensions` 和 `_getRemoteAssetDimensions`）
- PrismBox 已有 `LocalAssetDao.getAssetById` 和 `RemoteAssetDao.getAssetById` 方法

**Alternatives considered**:
- 始终使用临时宽高比：会导致拉伸问题
- 等待 videoInfo：会导致死锁（NativeVideoPlayerView 无法创建）

### Decision 3: RemoteAsset 的 orientation 处理
**What**: 对于 RemoteAsset，当前阶段简化处理：如果 width/height 可用，直接使用 width/height 计算宽高比（不考虑 orientation）。

**Why**:
- RemoteAsset 没有 orientation 字段，需要从 EXIF 获取
- 当前阶段不实现完整的 EXIF 解析，避免过度复杂
- 在 `_onPlaybackReady` 中会更新为 `videoInfo` 的真实宽高比，确保最终准确性

**Alternatives considered**:
- 从 EXIF 获取 orientation：需要实现 EXIF 解析，增加复杂度
- 返回 null：会导致宽高比计算不准确
- 使用默认值：不符合实际情况

### Decision 4: 服务依赖注入
**What**: `AssetService` 通过构造函数接收 `LocalAssetDao` 和 `RemoteAssetDao` 依赖。

**Why**:
- 符合依赖注入原则，便于测试
- 与 PrismBox 的其他服务保持一致的设计模式
- 可以通过 Riverpod Provider 提供

**Alternatives considered**:
- 直接创建 DAO 实例：不符合依赖注入原则
- 使用单例：不利于测试和扩展

## Risks / Trade-offs

### Risk 1: 数据库访问性能
**Risk**: 异步访问数据库可能影响性能。

**Mitigation**: 
- 使用异步操作，不阻塞 UI
- 仅在 `aspectRatio` 为 null 时才查询
- 查询是轻量级操作，性能影响可忽略

### Risk 2: EXIF 信息获取
**Risk**: RemoteAsset 的 EXIF 信息可能不可用。

**Mitigation**:
- 当前阶段简化处理，使用 width/height 直接计算
- 在 `_onPlaybackReady` 中会更新为 `videoInfo` 的真实宽高比
- 后续可以扩展 EXIF 解析，但不在本次变更范围内

### Risk 3: 服务创建和依赖管理
**Risk**: 需要创建新服务并管理依赖。

**Mitigation**:
- 参考 PrismBox 现有的服务模式
- 使用 Riverpod Provider 管理依赖
- 保持简单的接口，易于使用

### Trade-off: 简单性 vs 完整性
**Decision**: 优先保证简单性，当前阶段不实现完整的 EXIF 解析。

**Rationale**: 
- 视频预览的核心问题是宽高比计算
- 使用 `videoInfo` 的真实宽高比作为最终值，确保准确性
- 完整的 EXIF 解析可以在后续阶段实现

## Migration Plan

### Phase 1: 创建 AssetService
1. 创建 `mobile/lib/services/asset/asset_service.dart` 目录和文件
2. 添加 `getAspectRatio` 异步方法
3. 实现 `_getLocalAssetDimensions` 方法（从数据库获取 width/height/orientation）
4. 实现 `_getRemoteAssetDimensions` 方法（从数据库获取 width/height，当前阶段不考虑 orientation）
5. 根据 isFlipped 计算宽高比

### Phase 2: 创建 Riverpod Provider
1. 创建 `AssetService` 的 Provider
2. 注入 `LocalAssetDao` 和 `RemoteAssetDao` 依赖

### Phase 3: 修改 ViewerVideoPage
1. 在 `ViewerVideoPage` 中添加对 `AssetService` 的依赖（通过构造函数或 Provider）
2. 在 `initState` 中，如果 `asset.aspectRatio` 为 null，异步调用 `getAspectRatio`
3. 在获取到宽高比后，更新 `_aspectRatio` 并调用 `setState`
4. 确保在宽高比获取完成前，使用临时宽高比（16/9）显示 `NativeVideoPlayerView`

### Phase 4: 测试与验证
1. 测试 width/height 为 null 的情况
2. 测试 orientation 为 null 的情况（RemoteAsset）
3. 测试异步获取宽高比的逻辑
4. 验证视频预览时不再被拉伸

### Rollback Plan
如果出现问题，可以：
1. 回退到使用临时宽高比的版本
2. 通过 Git 回退相关提交
3. 分析问题并修复后重新部署

## Open Questions

1. **RemoteAsset 的 EXIF 获取**: 当前阶段简化处理，是否需要从 EXIF 获取 orientation？
   - **Resolution**: 当前阶段简化处理，使用 width/height 直接计算。在 `_onPlaybackReady` 中会更新为 `videoInfo` 的真实宽高比。后续可以扩展 EXIF 解析，但不在本次变更范围内。

2. **服务位置**: 应该放在 `domain/services` 还是 `services` 目录？
   - **Resolution**: 放在 `lib/services/asset/` 目录，遵循 PrismBox 的架构模式：
     - 通用服务放在 `lib/services/` 目录下，按功能分类（如 `auth/`、`backup/`、`trash/`）
     - `AssetService` 是通用的资产服务，不是特定于某个功能模块的
     - 创建 `lib/services/asset/asset_service.dart` 文件
     - 与 `lib/services/auth/auth_service.dart`、`lib/services/trash/` 等保持一致的模式

