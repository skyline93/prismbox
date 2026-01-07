# Design: 视频宽高比计算修复方案

## Context

当前 PrismBox 在视频预览时存在宽高比计算错误的问题，导致手机拍摄的竖屏视频（9:16）被错误拉伸。问题根源在于：

1. `BaseAsset` 没有考虑 orientation（旋转角度）
2. 直接使用 `width / height` 计算宽高比，没有处理 90°/270° 旋转的情况
3. `ViewerVideoPage` 在初始化时使用不准确的宽高比，导致视频显示时拉伸

参考 Immich 的实现，需要在 `BaseAsset` 中添加考虑 orientation 的宽高比计算逻辑。

## Goals / Non-Goals

### Goals
- 修复视频预览时的宽高比计算问题，确保竖屏视频正确显示
- 在 `BaseAsset` 中添加 `aspectRatio` getter，考虑 orientation
- 保持与 Immich 实现的一致性，确保稳定性和兼容性
- 确保视频预览时使用最准确的宽高比（优先使用 `videoInfo`，回退到 `asset.aspectRatio`）

### Non-Goals
- 不改变视频播放器的实现（已使用 `native_video_player`）
- 不改变视频加载和播放逻辑
- 不在此阶段实现 EXIF 信息的完整解析（仅处理 orientation）

## Decisions

### Decision 1: 在 BaseAsset 中添加 aspectRatio getter
**What**: 在 `BaseAsset` 中添加 `aspectRatio` getter，使用 `orientatedWidth` 和 `orientatedHeight` 计算宽高比。

**Why**:
- 参考 Immich 的实现，确保一致性
- 考虑 orientation，正确处理竖屏视频
- 提供统一的宽高比计算接口

**Alternatives considered**:
- 在 `ViewerVideoPage` 中直接计算：会增加代码复杂度，不利于复用
- 创建独立的服务类：过度设计，不符合简单性原则

### Decision 2: 添加 orientatedWidth 和 orientatedHeight getter
**What**: 在 `BaseAsset` 中添加 `orientatedWidth` 和 `orientatedHeight` getter，根据 `isFlipped` 返回正确的宽高。

**Why**:
- 参考 Immich 的实现，确保一致性
- 封装 orientation 处理逻辑，便于维护
- 支持 `aspectRatio` getter 的实现

**Alternatives considered**:
- 直接在 `aspectRatio` 中处理：会增加代码复杂度，不利于复用

### Decision 3: 添加 isFlipped getter
**What**: 在 `BaseAsset` 中添加 `isFlipped` getter，判断是否需要交换宽高（Android 上 90°/270° 需要交换）。

**Why**:
- 参考 Immich 的实现，确保一致性
- Android 和 iOS 的 orientation 处理方式不同（iOS 的 Photos framework 已经预校正了尺寸）
- 仅在 Android 上需要处理 90°/270° 旋转

**Alternatives considered**:
- 统一处理所有平台：不符合平台特性，可能导致 iOS 上的问题

### Decision 4: LocalAsset 使用私有字段避免命名冲突
**What**: 将 `LocalAsset` 的 `orientation` 字段改为私有字段 `_orientation`，通过 getter 暴露。

**Why**:
- 避免 `BaseAsset.orientation` getter 和 `LocalAsset.orientation` 字段的命名冲突
- 保持代码清晰，符合 Dart 规范

**Alternatives considered**:
- 使用不同的字段名：会增加代码复杂度，不利于理解

### Decision 5: ViewerVideoPage 使用 asset.aspectRatio 作为初始值
**What**: `ViewerVideoPage` 在初始化时使用 `asset.aspectRatio` 作为初始宽高比，如果为 null 则使用临时宽高比（16/9）。

**Why**:
- 使用考虑 orientation 的宽高比，确保初始显示正确
- 如果为 null，使用临时宽高比确保 `NativeVideoPlayerView` 能被创建
- 在 `_onPlaybackReady` 中更新为 `videoInfo` 的真实宽高比（最准确）

**Alternatives considered**:
- 始终使用临时宽高比：会导致初始显示时拉伸
- 等待 videoInfo 准备好：会导致死锁（NativeVideoPlayerView 无法创建）

## Risks / Trade-offs

### Risk 1: 平台差异处理
**Risk**: Android 和 iOS 的 orientation 处理方式不同，可能导致平台特定的问题。

**Mitigation**: 
- 参考 Immich 的实现，仅在 Android 上处理 90°/270° 旋转
- iOS 的 Photos framework 已经预校正了尺寸，不需要额外处理
- 充分测试两个平台的视频预览功能

### Risk 2: RemoteAsset 的 orientation 获取
**Risk**: `RemoteAsset` 没有 orientation 字段，需要从 EXIF 获取，当前实现返回 null。

**Mitigation**:
- 当前阶段返回 null，使用临时宽高比
- 在 `_onPlaybackReady` 中会更新为 `videoInfo` 的真实宽高比
- 后续可以扩展 EXIF 信息解析，但不在本次变更范围内

### Risk 3: 性能影响
**Risk**: 添加多个 getter 可能影响性能。

**Mitigation**:
- getter 是轻量级操作，性能影响可忽略
- 使用 `@pragma('vm:prefer-inline')` 提示编译器内联（如 Immich 实现）

### Trade-off: 简单性 vs 完整性
**Decision**: 优先保证简单性，当前阶段不实现完整的 EXIF 解析。

**Rationale**: 
- 视频预览的核心问题是宽高比计算，orientation 处理已经足够
- 完整的 EXIF 解析可以在后续阶段实现
- 使用 `videoInfo` 的真实宽高比作为最终值，确保准确性

## Migration Plan

### Phase 1: 修改 BaseAsset
1. 添加 `orientation` getter（由子类实现）
2. 添加 `isFlipped` getter（基于 orientation）
3. 添加 `orientatedWidth` 和 `orientatedHeight` getter
4. 添加 `aspectRatio` getter

### Phase 2: 修改 LocalAsset
1. 将 `orientation` 字段改为私有字段 `_orientation`
2. 实现 `orientation` getter

### Phase 3: 修改 RemoteAsset
1. 实现 `orientation` getter（返回 null）

### Phase 4: 修改 ViewerVideoPage
1. 在 `initState` 中使用 `asset.aspectRatio` 作为初始宽高比
2. 如果为 null，使用临时宽高比（16/9）
3. 在 `_onPlaybackReady` 中更新为 `videoInfo` 的真实宽高比
4. 移除之前的 10% 差异限制，确保使用正确的宽高比

### Phase 5: 测试与验证
1. 测试竖屏视频（9:16）的预览
2. 测试横屏视频（16:9）的预览
3. 测试不同 orientation 的视频
4. 测试 Android 和 iOS 平台

### Rollback Plan
如果出现问题，可以：
1. 回退到使用 `asset.width / asset.height` 的版本
2. 通过 Git 回退相关提交
3. 分析问题并修复后重新部署

## Open Questions

1. **RemoteAsset 的 orientation 获取**: 当前返回 null，是否需要从 EXIF 获取？
   - **Resolution**: 当前阶段返回 null，使用临时宽高比，在 `_onPlaybackReady` 中会更新为 `videoInfo` 的真实宽高比。后续可以扩展 EXIF 信息解析，但不在本次变更范围内。

2. **性能优化**: 是否需要使用 `@pragma('vm:prefer-inline')` 提示编译器内联？
   - **Resolution**: 参考 Immich 的实现，可以添加，但当前阶段不是必需的。

