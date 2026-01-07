# Design: 移除原生解码尺寸限制，统一使用原生 API

## Context

当前 PrismBox 移动端的本地图片加载策略使用混合架构：
- 缩略图和小尺寸（≤512x512）：使用原生解码
- 大尺寸（>512x512）：使用 Flutter 层处理

这种设计导致 RAW 格式照片在预览放大时模糊，因为适配屏幕尺寸的图片超过了 512x512 的限制，降级到 Flutter 层，而 Flutter 层无法处理 RAW 格式。

参考 Immich 的实现，`LocalImageRequest` 统一使用原生 API，不区分格式和尺寸，原生层已经能够高效处理各种格式和尺寸。

## Goals / Non-Goals

### Goals
- 移除尺寸限制，统一使用原生 API 处理所有本地图片请求
- 解决 RAW 格式预览放大模糊的问题
- 简化架构设计，减少特殊判断逻辑
- 与 Immich 的设计保持一致，降低维护成本

### Non-Goals
- 不修改远程图片处理逻辑（远程图片继续使用 Flutter 层）
- 不修改原生 API 实现（使用阶段一已建立的基础设施）
- 不在此阶段实现性能监控（后续优化）

## Decisions

### Decision 1: 移除 `MAX_NATIVE_DECODE_SIZE` 限制
**Rationale**:
- 原生 API（Android `ImageDecoder`、iOS `PHImageManager`）已经能够处理任意尺寸的图片
- 原生层已经实现了采样缩放，优化内存使用
- 512x512 的限制是人为约束，非技术必需
- 与 Immich 的设计保持一致

**Alternatives considered**:
- 提高阈值（如 4096x4096）：仍然存在限制，无法彻底解决问题
- 仅对 RAW 格式移除限制：增加复杂度，违反单一职责原则

### Decision 2: 简化 `_shouldUseNativeDecode()` 逻辑
**Rationale**:
- 统一使用原生解码，减少决策复杂度
- 保留 `isThumbnail` 判断，确保缩略图明确使用原生解码
- 原生解码失败时自动降级到 Flutter 层，保证兼容性

**实现方式**:
```dart
bool _shouldUseNativeDecode() {
  // 统一使用原生解码，不区分格式和尺寸
  // 原生 API 已经能够高效处理各种格式和尺寸
  return true; // 或者保留 isThumbnail 的判断
}
```

**Alternatives considered**:
- 保留尺寸判断，仅对 RAW 格式移除限制：增加复杂度，需要异步检测 RAW 格式
- 完全移除方法：可能影响某些特殊场景的判断

### Decision 3: 移除 `LocalFullImageProvider` 的 RAW 格式特殊处理
**Rationale**:
- RAW 格式现在可以通过原生 API 处理任意尺寸
- 不需要跳过阶段2和阶段3
- 保持与非 RAW 格式一致的渐进式加载流程

**Alternatives considered**:
- 保留 RAW 格式特殊处理：违反一致性原则，增加维护成本

### Decision 4: 依赖原生层的采样缩放能力
**Rationale**:
- Android `ImageDecoder` 和 iOS `PHImageManager` 都支持采样缩放
- 原生层已经优化了内存使用
- 不需要在 Flutter 层实现额外的采样逻辑

**Alternatives considered**:
- 在 Flutter 层实现采样：增加复杂度，性能不如原生层

## Risks / Trade-offs

### Risk 1: 内存使用增加
**Mitigation**: 
- 原生层已经实现了采样缩放，优化内存使用
- 监控内存使用，必要时添加保护
- 实际测试验证，确保不会显著增加内存占用

### Risk 2: 性能回归
**Mitigation**:
- 原生解码通常比 Flutter 层更高效
- 原生层已经优化了并发处理
- 实际测试验证，确保性能不会下降

### Risk 3: 某些特殊格式可能不支持
**Mitigation**:
- 保持降级策略：原生解码失败时自动回退到 Flutter 层
- 充分测试常见格式的兼容性
- 记录错误日志，便于排查问题

### Risk 4: 与现有代码的兼容性
**Mitigation**:
- 保持现有 API 接口不变
- 渐进式替换，不影响现有代码路径
- 充分测试现有功能，确保向后兼容

## Migration Plan

### Phase 1: 移除尺寸限制（本提案）
1. 修改 `LocalImageRequest._shouldUseNativeDecode()` 方法
2. 移除或提高 `MAX_NATIVE_DECODE_SIZE` 常量
3. 修改 `LocalFullImageProvider` 移除 RAW 格式特殊处理
4. 单元测试和集成测试

### Phase 2: 性能验证和优化（后续）
1. 实际测试不同尺寸和格式的图片加载性能
2. 监控内存使用情况
3. 根据测试结果进行优化（如需要）

### Rollback Plan
- 如果性能或兼容性有问题，可以恢复尺寸限制
- 通过配置开关控制是否使用原生解码（如需要）
- 保持现有代码路径不变，便于回退

## Open Questions

### Q1: 是否需要完全移除 `MAX_NATIVE_DECODE_SIZE` 常量？
**答案（基于 Immich 实现）**：**完全移除**

Immich 的 `LocalImageRequest` 完全没有 `MAX_NATIVE_DECODE_SIZE` 这样的常量，它直接接受 `size` 参数，无论大小都使用原生 API。

**实现要求**：
- 完全移除 `MAX_NATIVE_DECODE_SIZE` 常量定义
- 移除 `_shouldUseNativeDecode()` 方法中的尺寸判断逻辑
- 统一使用原生 API，不区分尺寸大小
- 保留 `isThumbnail` 的判断（如果仍然需要）

**原因**：原生 API（Android `ImageDecoder`、iOS `PHImageManager`）已经能够处理任意尺寸的图片，并且原生层已经实现了采样缩放，优化内存使用。512x512 的限制是人为约束，非技术必需。

### Q2: 是否需要添加性能监控？
**答案（基于 Immich 实现）**：**后续优化阶段添加**

Immich 的实现中没有特殊的性能监控代码，依赖原生层的优化和实际测试验证。

**实现建议**：
- 当前阶段专注于解决 RAW 格式预览模糊问题
- 性能监控可以在后续优化阶段添加
- 通过实际测试验证性能，必要时添加监控
- 如果发现性能问题，可以通过日志记录和错误处理来排查

### Q3: 原图加载是否也应该使用原生解码？
**答案（基于 Immich 实现）**：**按照 Immich 新架构，原图也使用原生解码**

Immich 的 `LocalFullImageProvider`（新架构）实现：
- **阶段2（适配尺寸）**：使用 `Size(size.width * devicePixelRatio, size.height * devicePixelRatio)` 通过原生 API
- **阶段3（原图）**：使用 `Size.zero` 通过原生 API（表示最大尺寸/原图）

**原生层的处理**：
- **iOS**：`Size.zero` 对应 `PHImageManagerMaximumSize`，`PHImageManager` 返回原图
- **Android**：`width=0, height=0` 时，原生层返回原图尺寸

**PrismBox 的设计决策**：
- **按照 Immich 新架构实现**：原图也使用原生解码（通过 `Size.zero` 或 `targetSize=null` 时传递 `width=0, height=0`）
- **原因**：
  - 与 Immich 新架构保持一致，降低维护成本
  - 原生层已经优化了内存管理，支持采样和缩放
  - 统一使用原生 API，简化架构设计
  - 确保 RAW 格式原图也能正确显示

**实现要求**：
- 修改 `LocalFullImageProvider._loadOriginalImage()` 方法，使用原生 API 加载原图
- 当 `targetSize=null` 时，传递 `width=0, height=0` 给原生 API，表示请求原图
- **iOS 原生层**：`width=0, height=0` 时使用 `PHImageManagerMaximumSize`（已实现，见 `ThumbnailsImpl.swift:112`）
- **Android 原生层**：`width=0, height=0` 时会调用 `decodeSource`，`ImageDecoder` 不设置采样时返回原图（已实现，见 `ThumbnailsImpl.kt:166-167, 197-200`）
- 保持降级策略：原生解码失败时回退到 Flutter 层

