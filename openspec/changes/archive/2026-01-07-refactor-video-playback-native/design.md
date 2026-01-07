# Design: 视频播放重构技术方案

## Context

当前 PrismBox 使用 `video_player` 插件进行视频播放，该插件不支持 HDR 视频格式。为了支持 HDR 视频播放，需要替换为 `native_video_player` 插件，该插件基于平台原生播放器（Android ExoPlayer、iOS AVPlayer），原生支持 HDR 格式。

参考 Immich 移动端的实现方案（`immich/mobile/lib/pages/common/native_video_viewer.page.dart`），采用相同的技术栈和实现模式。

## Goals / Non-Goals

### Goals
- 替换 `video_player` 为 `native_video_player`，支持 HDR 视频播放
- 保持现有视频播放功能的完整性（播放/暂停、进度控制、静音等）
- 保持现有 API 接口的兼容性（渐进式替换）
- 支持本地和远程视频播放
- 自动识别并启用 HDR 渲染（无需额外配置）

### Non-Goals
- 不改变视频查看器的 UI 结构
- 不改变视频播放的用户交互方式
- 不在此阶段实现 Live Photo 视频播放（将在阶段 4 实现）

## Decisions

### Decision 1: 使用 native_video_player 插件
**What**: 使用 Immich 自维护的 `native_video_player` 插件替代 `video_player`。

**Why**:
- 原生支持 HDR 格式（HEVC/H.265、VP9、AV1 等）
- Android 基于 ExoPlayer，iOS 基于 AVPlayer，性能优异
- Immich 已在实际项目中验证稳定性
- 自动识别并启用 HDR 渲染，无需额外配置

**Alternatives considered**:
- `media_kit`: 功能强大但体积较大，且 Immich 未采用
- 继续使用 `video_player`: 不支持 HDR，无法满足需求

### Decision 2: 保持 VideoProvider 接口语义
**What**: `VideoProvider.getVideoSource` 方法名和参数保持不变，但返回类型改为 `native_video_player.VideoSource`。

**Why**:
- 最小化调用方代码变更
- 保持接口语义清晰
- 便于后续扩展（如 Live Photo 视频支持）

**Alternatives considered**:
- 创建新的方法：会增加代码复杂度，不利于渐进式迁移

### Decision 3: ViewerVideoManager 移除 controller 缓存（对齐 Immich）
**What**: `ViewerVideoManager` 不再缓存 controller，只保留视频源缓存和可见页面范围管理功能。每个 `ViewerVideoPage` Widget 独立管理自己的 controller。

**Why**:
- 对齐 Immich 的架构，每个 Widget 独立管理 controller
- 避免 controller 生命周期与 `NativeVideoPlayerView` 不同步的问题
- 简化状态管理，减少全局状态带来的复杂性
- 确保 controller 的生命周期与 Widget 绑定，自动同步

**Alternatives considered**:
- 保持全局缓存但改进同步机制：复杂度高，难以保证完全同步
- 完全移除 ViewerVideoManager：仍需要视频源缓存和可见页面范围管理功能

**移除的方法**：
- `registerController` / `registerControllerOnly`
- `getController`
- `playController` / `pauseController`
- `setMuted` / `isMuted`
- `disposeController`（controller 相关部分）

**保留的功能**：
- `getVideoSource`：视频源缓存（性能优化）
- `calculateVisibleIndices` / `updateVisibleIndices`：可见页面范围管理
- `setCurrentVideoAssetId` / `getCurrentVideoAssetId`：当前视频状态管理（用于兜底，主要使用 Provider）

### Decision 4: 视频源创建逻辑
**What**: 本地视频使用文件路径创建 `VideoSource.init(path: filePath, type: VideoSourceType.file)`，远程视频使用网络 URL 创建 `VideoSource.init(path: url, type: VideoSourceType.network, headers: ...)`。

**Why**:
- 与 Immich 实现保持一致
- 支持自定义请求头（用于认证）
- 支持原始视频和转码版本选择（通过 URL 路径区分）

**Reference**: `immich/mobile/lib/pages/common/native_video_viewer.page.dart` 的 `createSource` 方法

### Decision 5: Controller 生命周期管理对齐 Immich
**What**: 修复 `initController` 和 `ref.listen` 逻辑，完全对齐 Immich 的实现模式。

**Why**:
- 当前实现导致 controller 生命周期与 `NativeVideoPlayerView` 不同步
- 当 `NativeVideoPlayerView` 被销毁时（key 改变），原生实现被销毁，但 `ViewerVideoManager` 缓存的 controller 仍在使用
- 导致 `MissingPluginException`：调用 `setVolume` 或 `play` 时找不到原生实现
- 导致黑屏：切换回上一个视频时，controller 的底层原生实现已被销毁

**Immich 的关键实现**:
- **Controller 生命周期管理**：
  - `initController` 检查 `controller.value != null`（本地状态），如果已存在直接返回
  - 直接调用 `nc.loadVideoSource(source)`，然后设置 `controller.value = nc`（本地状态管理）
  - 使用 `NativeVideoPlayerView(key: ValueKey(asset), ...)` 确保 asset 改变时 Widget 被销毁并重新创建
- **状态同步机制**：
  - `useEffect` cleanup：当 Widget 被销毁时，调用 `removeListeners(playerController)` 和 `playerController.stop()`
  - `ref.listen`：当视频不再是当前视频时，调用 `removeListeners(playerController)`（但不设置 `controller.value = null`）
  - 每个 Widget 独立管理自己的 `controller.value`，不使用全局缓存
- **播放控制**：
  - `ref.listen` 使用本地状态 `currentAsset.value` 延迟更新（200ms 后检查）
  - `onPlaybackReady` 开头检查 `isCurrent`，如果不是当前视频直接返回

**我们的修复**（完全对齐 Immich）:
- **架构变更：移除全局 controller 缓存**：
  - `ViewerVideoManager` 不再缓存 controller，只保留视频源缓存和可见页面范围管理
  - 每个 `ViewerVideoPage` Widget 独立管理自己的 `_controller`（对齐 Immich 的 `controller.value`）
  - `ViewerVideoPage` 直接操作本地 controller，不通过 `ViewerVideoManager`
- **Controller 生命周期管理**：
  - `initController` 只检查本地 `_controller`，如果已存在直接返回（对齐 Immich：`if (controller.value != null || !context.mounted) return;`）
  - 不在 `_initializeVideo` 中重用已存在的 controller（会导致生命周期不同步）
  - 使用 `NativeVideoPlayerView(key: ValueKey(widget.assetId), ...)` 确保 assetId 改变时 Widget 被销毁并重新创建
- **状态同步机制**：
  - `dispose`：调用 `removeListeners` 和 `controller.stop()`（对齐 Immich 的 useEffect cleanup）
  - `ref.listen`：当视频不再是当前视频时，调用 `removeListeners`（对齐 Immich 的 ref.listen 逻辑）
- **播放控制**：
  - `ref.listen` 使用本地状态跟踪当前视频，延迟更新，对齐 Immich
  - `onPlaybackReady` 开头检查 `isCurrent`，确保只有当前视频才执行播放逻辑
  - 直接操作本地 controller，不需要通过 `ViewerVideoManager`

**Reference**: 
- `immich/mobile/lib/pages/common/native_video_viewer.page.dart` 的 `initController` 和 `ref.listen` 方法
- `immich/mobile/lib/presentation/widgets/asset_viewer/video_viewer.widget.dart` 的类似实现

## Risks / Trade-offs

### Risk 1: API 差异导致功能缺失
**Risk**: `native_video_player` 的 API 与 `video_player` 存在差异，可能导致某些功能实现困难。

**Mitigation**: 
- 参考 Immich 实现，确保功能完整性
- 充分测试播放控制、进度、音量等功能
- 提供降级策略（如果播放失败，显示错误提示）

### Risk 2: 性能回归
**Risk**: 新播放器可能导致性能问题（启动时间、内存使用等）。

**Mitigation**:
- 使用与 Immich 相同的实现模式
- 保持现有的资源管理策略（可见页面范围管理）
- 进行性能测试，确保不劣于现有实现

### Risk 3: 依赖管理
**Risk**: `native_video_player` 来自 GitHub 源，可能存在版本管理问题。

**Mitigation**:
- 使用与 Immich 相同的版本或提交
- 定期检查更新
- 如有问题，考虑 fork 并维护

### Trade-off: 代码复杂度 vs 功能完整性
**Decision**: 优先保证功能完整性，接受一定的代码复杂度。

**Rationale**: 视频播放是核心功能，必须保证完整性和稳定性。

## Migration Plan

### Phase 1: 依赖添加
1. 在 `pubspec.yaml` 中添加 `native_video_player` 依赖（GitHub 源）
2. 运行 `flutter pub get`
3. 暂时保留 `video_player` 依赖（用于对比测试）

### Phase 2: VideoProvider 重构
1. 修改 `VideoProvider.getVideoSource` 返回 `native_video_player.VideoSource`
2. 更新视频源创建逻辑（本地文件路径、远程 URL）
3. 支持请求头传递（用于远程视频认证）

### Phase 3: ViewerVideoManager 重构
1. 将内部 `VideoPlayerController` 替换为 `NativeVideoPlayerController`
2. 更新控制器创建逻辑（使用 `VideoSource.init`）
3. 更新播放控制方法（play、pause、seek、setVolume 等）
4. 更新状态监听逻辑（使用 `onPlaybackReady`、`onPlaybackStatusChanged` 等）

### Phase 4: ViewerVideoPage 重构
1. 将 `VideoPlayer` widget 替换为 `NativeVideoPlayerView`
2. 更新状态监听（使用 `NativeVideoPlayerController` 的回调）
3. 更新视频加载逻辑（使用 `loadVideoSource`）
4. 保持 UI 和交互逻辑不变

### Phase 5: 测试与清理
1. 测试本地视频播放
2. 测试远程视频播放
3. 测试 HDR 视频播放（如果可用）
4. 测试播放控制功能
5. 移除 `video_player` 依赖

### Rollback Plan
如果出现问题，可以：
1. 回退到使用 `video_player` 的版本
2. 通过 Git 回退相关提交
3. 分析问题并修复后重新部署

## Open Questions

1. **HDR 视频测试**: 需要确认测试设备是否支持 HDR，以及如何获取 HDR 测试视频。
   - **Resolution**: 使用 Immich 的测试方法，或使用公开的 HDR 测试视频

2. **Live Photo 视频支持**: 当前阶段不实现，但需要考虑后续扩展。
   - **Resolution**: 在阶段 4 实现 Live Photo 支持时，复用相同的视频播放逻辑

3. **视频转码版本选择**: 是否需要支持用户选择原始视频或转码版本？
   - **Resolution**: 参考 Immich 实现，通过用户设置控制（当前阶段暂不实现，但保留扩展性）

