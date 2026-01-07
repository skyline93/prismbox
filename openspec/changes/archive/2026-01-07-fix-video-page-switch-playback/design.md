# Design: 视频页面切换播放修复方案

## Context

当前 PrismBox 的视频查看器存在一个问题：当用户在预览页面播放视频时，滑动切换到下一个视频播放后，再滑动切换回上一个视频时，上一个视频无法播放。这是因为：

1. `ViewerVideoManager` 使用内部状态 `_currentVideoAssetId` 管理当前视频，但不是响应式的
2. `ViewerVideoPage` 仅在 `didUpdateWidget` 中检查状态变化，但 PageView 可能复用 Widget 实例，导致状态不同步
3. 缺少响应式机制来通知所有视频页面当前视频状态变化

参考 Immich 的实现（`immich/mobile/lib/pages/common/native_video_viewer.page.dart`），他们使用 Riverpod Provider 管理当前资产状态，并通过 `ref.listen` 响应式地通知所有视频页面。

## Goals / Non-Goals

### Goals
- 修复视频切换后无法播放的问题
- 使用响应式状态管理，确保状态同步
- 保持现有功能不变（播放/暂停、进度控制、静音等）
- 参考 Immich 的成熟实现，确保稳定性和可靠性

### Non-Goals
- 不改变视频播放器的底层实现（NativeVideoPlayer）
- 不改变视频管理器的资源管理逻辑
- 不改变 UI 结构或用户交互方式

## Decisions

### Decision 1: 使用 Riverpod Provider 管理当前视频状态
**What**: 创建 `currentVideoAssetIdProvider` StateProvider 来管理当前视频资产 ID。

**Why**:
- 响应式状态管理，状态变化自动通知所有订阅者
- 不依赖 `didUpdateWidget`，PageView 复用 Widget 也能正常工作
- 与现有的 Riverpod 技术栈一致
- 参考 Immich 的成熟实现，已验证稳定性

**Alternatives considered**:
- 使用 ValueNotifier：需要手动管理订阅和取消订阅，增加复杂度
- 在 ViewerVideoManager 中添加回调：不如 Provider 响应式，需要手动管理
- 修改 didUpdateWidget 逻辑：无法解决 PageView 复用 Widget 的问题

**Reference**: `immich/mobile/lib/pages/common/native_video_viewer.page.dart` 使用 `ref.listen(currentAssetProvider, ...)`

### Decision 2: 在 MediaViewerPage 中同步更新 Provider
**What**: 在 `_handlePageChanged` 中，当切换视频时，同时更新 `ViewerVideoManager.setCurrentVideoAssetId` 和 `currentVideoAssetIdProvider`。

**Why**:
- 保持 `ViewerVideoManager` 的向后兼容性（其他代码可能依赖它）
- 通过 Provider 触发响应式更新
- 单一数据源原则：MediaViewerPage 是页面切换的唯一入口

**Alternatives considered**:
- 只使用 Provider，移除 ViewerVideoManager 的状态：破坏向后兼容性，需要修改更多代码
- 在 ViewerVideoManager 中更新 Provider：违反单一职责原则，ViewerVideoManager 不应该依赖 UI 层的 Provider

### Decision 3: 在 ViewerVideoPage 中使用 ref.listen 响应状态变化
**What**: 在 `ViewerVideoPage.build` 中使用 `ref.listen(currentVideoAssetIdProvider, ...)` 监听状态变化，当该视频变成当前视频时自动播放。

**Why**:
- 响应式地处理状态变化，不依赖 Widget 生命周期方法
- 与 Immich 的实现模式一致
- 延迟播放确保切换动画完成（参考 Immich 的实现）

**Reference**: `immich/mobile/lib/pages/common/native_video_viewer.page.dart` 第 282-324 行

### Decision 4: 延迟播放机制
**What**: 在 `ref.listen` 的回调中，使用 `Timer` 延迟 300ms 后再播放，确保页面切换动画完成。

**Why**:
- 避免播放与动画冲突，确保流畅的用户体验
- 与 Immich 的实现保持一致
- 参考 Immich 的注释："This delay seems like a hacky way to resolve underlying bugs in video playback, but other resolutions failed thus far"

**Alternatives considered**:
- 不延迟：可能导致动画和播放冲突，用户体验不佳
- 使用 addPostFrameCallback：不如 Timer 精确控制延迟时间

### Decision 5: 在多个位置检查并自动播放
**What**: 在 `_onPlaybackReady` 和 `_initializeVideo` 中也要检查是否为当前视频，如果是则自动播放。

**Why**:
- 多层次的检查确保不会遗漏任何场景
- `_onPlaybackReady`：处理视频首次加载完成时
- `_initializeVideo`：处理找到已存在的控制器时

**Alternatives considered**:
- 只在 ref.listen 中处理：可能在某些边缘情况下遗漏

## Risks / Trade-offs

### Risk 1: 状态同步问题
**Risk**: `ViewerVideoManager` 和 Provider 的状态可能不同步。

**Mitigation**: 
- 在单一入口（MediaViewerPage）同步更新两者
- 在 ViewerVideoPage 中，优先使用 Provider 的状态，但也检查 ViewerVideoManager 作为兜底

### Risk 2: 性能影响
**Risk**: 每次 build 都调用 `ref.listen` 可能导致性能问题。

**Mitigation**:
- Riverpod 会自动处理重复注册的问题（参考 AGENTS.md）
- `ref.listen` 只在状态变化时执行回调，不会重复执行
- 延迟播放逻辑只在状态真正变化时执行

### Risk 3: 延迟播放的时机问题
**Risk**: 300ms 延迟可能在某些情况下不够或不必要。

**Mitigation**:
- 参考 Immich 的实现，300ms 是他们验证过的值
- 如果后续发现问题，可以调整为可配置的值（如 Immich 的 `playbackDelayFactor`）

### Trade-off: 代码复杂度 vs 可靠性
**Decision**: 优先保证可靠性，接受一定的代码复杂度。

**Rationale**: 视频播放是核心功能，必须确保在所有场景下都能正常工作。参考 Immich 的实现模式，虽然增加了一些复杂度，但已经被验证是可靠的。

## Migration Plan

### Step 1: 创建 Provider
创建 `viewer_video_state_provider.dart` 文件，定义 `currentVideoAssetIdProvider`。

### Step 2: 更新 MediaViewerPage
在 `_handlePageChanged` 中，当切换视频时，同时更新 Provider。

### Step 3: 更新 ViewerVideoPage
- 添加 `ref.listen` 监听状态变化
- 增强 `_onPlaybackReady` 和 `_initializeVideo` 的自动播放逻辑

### Step 4: 测试验证
- 测试正常切换播放
- 测试切换回上一个视频
- 测试快速连续切换
- 测试在非当前视频时不会自动播放

## Open Questions

- 是否需要支持 Immich 的 `playbackDelayFactor` 机制（用于不同场景的延迟调整）？
  - **Decision**: 暂时不需要，使用固定的 300ms 延迟。如果后续有需求，可以添加。

