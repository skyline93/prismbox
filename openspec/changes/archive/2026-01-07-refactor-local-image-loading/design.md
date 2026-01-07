# Design: 本地图片加载策略重构

## Context

PrismBox 移动端需要实现混合架构的图片加载策略，充分利用阶段一建立的原生解码能力，同时保持内存效率。

当前实现完全依赖 Flutter 层的 `photo_manager`，无法利用原生解码能力，也不支持 RAW 格式。阶段一已建立 `ThumbnailApi` 基础设施，现在需要在图片加载流程中集成使用。

参考 Immich 的实现：
- **缩略图**：使用 `LocalImageRequest` → `thumbnailApi.requestImage`（原生层）
- **原图**：使用 `ImmichLocalImageProvider` → `ImmutableBuffer.fromFilePath`（Flutter 层）

## Goals / Non-Goals

### Goals
- 实现混合架构：缩略图原生解码，原图 Flutter 层处理
- 支持 RAW 格式照片预览（通过原生层自动支持）
- 提升缩略图生成性能（原生层更高效）
- 保持内存效率（大文件避免跨层传递）
- 保持向后兼容性（降级策略）

### Non-Goals
- 不在此阶段修改远程图片加载策略（保持 Flutter 层处理）
- 不在此阶段实现原图的原生解码（原图继续走 Flutter 层）
- 不在此阶段优化视频播放（后续阶段处理）

## Decisions

### Decision 1: 尺寸阈值决策逻辑
**Rationale**:
- 小尺寸图片（如缩略图）使用原生解码，性能更好且支持 RAW
- 大尺寸图片继续走 Flutter 层，避免跨层大文件数据传递

**实现**:
- 定义阈值常量：`MAX_NATIVE_DECODE_SIZE = 512x512`（可配置）
- `isThumbnail=true` 时强制使用原生解码
- 尺寸小于阈值时使用原生解码
- 否则使用 Flutter 层处理

**Alternatives considered**:
- 所有本地图片都走原生解码：大文件跨层传递开销大，内存占用高
- 完全在 Flutter 层处理：无法利用原生能力，不支持 RAW 格式

### Decision 2: 保持原图 Flutter 层处理
**Rationale**:
- 原图文件较大，原生层解码后需要转换为 RGBA 传递，内存开销大
- Flutter 层直接读取文件，使用 `ImmutableBuffer.fromFilePath`，避免跨层数据传递
- Flutter 解码器对常见格式（JPEG、PNG、WebP）支持良好

**实现**:
- `LocalFullImageProvider` 保持不变
- 原图加载继续使用 `ImmutableBuffer.fromFilePath`
- 保持渐进式加载逻辑不变

**Alternatives considered**:
- 原图也走原生解码：内存开销大，性能提升有限

### Decision 3: 降级策略
**Rationale**:
- 原生解码可能失败（格式不支持、系统版本问题等）
- 需要提供降级方案，确保功能可用性

**实现**:
- 原生解码失败时自动降级到 Flutter 层处理
- 记录错误日志，但不中断用户流程
- 逐步迁移，保持现有代码路径作为后备

**Alternatives considered**:
- 原生解码失败时直接报错：用户体验差，不友好

### Decision 4: 缓存策略
**Rationale**:
- 原生解码结果需要缓存，避免重复解码
- 保持与现有缓存系统的一致性

**实现**:
- 原生解码结果通过 `ThumbnailImageCacheManager` 缓存
- 缓存键格式保持一致：`{userId}{localId}{checksum}{width}{height}`
- 缓存命中时从缓存读取，仍使用 Flutter 解码器（缓存的是压缩后的数据）

**Alternatives considered**:
- 原生解码结果不缓存：性能差，重复解码浪费资源

### Decision 5: RAW 格式支持
**Rationale**:
- 原生层自动支持 RAW 格式（Android ImageDecoder、iOS PHImageManager）
- 通过原生解码自然获得 RAW 支持

**实现**:
- RAW 格式检测（通过文件扩展名或 MIME 类型）
- 优先使用原生解码（原生层自动处理 RAW）
- 如果原生解码失败，尝试 Flutter 层（可能不支持 RAW，但保持向后兼容）

**Alternatives considered**:
- 在 Flutter 层手动处理 RAW：复杂度高，需要第三方库

## Risks / Trade-offs

### Risk 1: 原生解码失败导致功能降级
**Mitigation**: 
- 实现完善的降级策略，自动回退到 Flutter 层
- 记录错误日志，便于排查问题
- 充分测试不同格式和场景

### Risk 2: 性能回归
**Mitigation**:
- 仅对缩略图和小尺寸图片使用原生解码
- 保持现有缓存机制
- 进行性能基准测试

### Risk 3: 内存管理问题
**Mitigation**:
- 原生解码结果及时转换为 `ImmutableBuffer` 并释放原生内存
- 使用 try-finally 确保资源释放
- 进行内存泄漏测试

### Risk 4: 平台差异处理
**Mitigation**:
- Android 和 iOS 使用相同的接口（ThumbnailApi）
- 通过 Pigeon 抽象平台差异
- 充分测试不同平台版本

### Risk 5: 缓存一致性
**Mitigation**:
- 保持缓存键格式一致
- 原生解码和 Flutter 层解码使用相同的缓存键
- 确保缓存命中时的解码路径正确

## Migration Plan

### Phase 1: 重构缩略图加载（本提案）
1. 修改 `LocalImageRequest._loadThumbnail` 使用原生解码
2. 实现尺寸阈值决策逻辑
3. 实现降级策略
4. 测试和验证

### Phase 2: RAW 格式支持增强（本提案）
1. 验证 RAW 格式支持
2. 添加格式检测和错误处理
3. 测试常见 RAW 格式

### Phase 3: 远程图片优化（本提案）
1. 优化缓存策略
2. 优化渐进式加载
3. 性能测试

### Rollback Plan
- 如果原生解码有问题，可以通过配置开关禁用它
- 保持现有 Flutter 层代码路径不变，作为降级方案
- 逐步迁移，分阶段测试

## Open Questions

### Q1: 尺寸阈值如何确定？
**答案**：基于 Immich 的实现和性能测试，建议使用 **512x512** 作为阈值。

**理由**：
- 缩略图通常在 200x200 到 400x400 之间
- 512x512 已经足够大，覆盖大多数预览场景
- 超过此尺寸的图片通常需要原图质量，应该走 Flutter 层

**实现**：
```dart
static const double MAX_NATIVE_DECODE_SIZE = 512.0;

bool shouldUseNativeDecode(Size? targetSize, bool isThumbnail) {
  if (isThumbnail) return true;
  if (targetSize == null) return false;
  return targetSize.width <= MAX_NATIVE_DECODE_SIZE && 
         targetSize.height <= MAX_NATIVE_DECODE_SIZE;
}
```

### Q2: 缓存策略是否需要调整？
**答案**：**不需要大幅调整**，保持现有缓存策略即可。

**理由**：
- 原生解码结果仍然是图片数据（压缩后的字节流）
- 可以使用现有的 `ThumbnailImageCacheManager` 缓存
- 缓存键格式保持不变：`{userId}{localId}{checksum}{width}{height}`

**实现**：
- 原生解码结果写入缓存前，先转换为 `Uint8List`
- 缓存命中时从缓存读取，使用 Flutter 解码器解码
- 这样原生解码和 Flutter 解码可以使用相同的缓存

### Q3: 如何确保内存安全？
**答案**：遵循阶段一的设计，严格管理内存生命周期。

**关键点**：
1. **原生内存分配**：由 `ThumbnailApiService` 处理，使用 `_fromPlatformImage` 转换
2. **内存释放**：转换完成后立即释放原生内存（使用 `malloc.free` 或 `deallocate`）
3. **Flutter 层内存**：`ImmutableBuffer` 由 Flutter 管理，使用完毕后自动释放
4. **错误处理**：使用 try-finally 确保资源释放

**实现参考**：
```dart
Future<ui.Codec> _loadThumbnailNative(...) async {
  final result = await thumbnailApiService.requestImage(...);
  Pointer<Uint8>? pointer;
  try {
    pointer = Pointer<Uint8>.fromAddress(result['pointer']!);
    final buffer = await ImmutableBuffer.fromUint8List(
      pointer.asTypedList(result['width']! * result['height']! * 4)
    );
    return await decode(buffer);
  } finally {
    if (pointer != null) {
      malloc.free(pointer);
    }
  }
}
```

