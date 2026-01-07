# Change: 重构本地图片加载策略（阶段2：图片处理重构）

## Why

当前 PrismBox 移动端的本地图片加载完全依赖 Flutter 层的 `photo_manager` 处理，存在以下问题：

- **RAW 格式支持不足**：虽然阶段一已建立原生解码基础设施，但本地图片加载流程尚未使用，RAW 格式照片仍无法正常预览
- **性能瓶颈**：缩略图生成完全在 Flutter 层处理，无法充分利用阶段一建立的原生解码能力
- **架构不一致**：未实现《PrismBox 媒体处理重构总规划》中定义的混合架构（缩略图原生、原图 Flutter）

根据《PrismBox 媒体处理重构总规划》阶段二的要求和《Immich 移动端媒体处理技术方案文档》的设计理念，需要重构本地图片加载策略，实现混合架构：

- **缩略图和小尺寸预览**：使用阶段一建立的原生 ThumbnailApi，充分利用平台原生解码能力，支持 RAW 格式，提升性能
- **全尺寸原图**：继续在 Flutter 层处理，直接读取文件并使用 Flutter 解码器，避免跨层大文件数据传递带来的内存开销

这样可以在保证性能的同时，优化内存使用效率。

## What Changes

- **重构 LocalThumbProvider**：
  - 修改 `LocalImageRequest`：当 `isThumbnail=true` 或尺寸小于阈值时，使用 `ThumbnailApiService` 调用原生解码
  - 保持缓存机制：原生解码结果仍通过现有缓存系统缓存
  - 降级策略：原生解码失败时回退到 Flutter 层处理

- **保持 LocalFullImageProvider 不变**：
  - 原图加载继续使用 `ImmutableBuffer.fromFilePath` 直接读取文件
  - 保持渐进式加载（缩略图 → 适配尺寸 → 原图）的现有逻辑

- **RAW 格式支持增强**：
  - 通过原生层解码自动支持 RAW 格式（DNG、CR2、NEF、ARW 等）
  - 添加 RAW 格式检测与错误处理
  - 测试常见 RAW 格式的兼容性

- **远程图片处理优化**：
  - 保持完全在 Flutter 层处理的策略
  - 优化缓存策略和渐进式加载性能
  - 确保与本地图片加载体验的一致性

所有实现参考 Immich 的成熟方案，确保稳定性和性能。

## Impact

- **修改文件**：
  - `mobile/lib/features/media_loading/requests/local_image_request.dart` - 重构缩略图加载逻辑
  - `mobile/lib/features/media_loading/providers/local_thumb_provider.dart` - 可能需要调整以适配新的加载策略
  - `mobile/lib/platform/thumbnail_api_service.dart` - 阶段一已创建，可能需要扩展功能

- **新增文件**：
  - 无（使用阶段一已建立的基础设施）

- **受影响能力**：
  - 修改 `image-loading` capability（新增）
  - 依赖 `native-image-decoding` capability（阶段一）

- **向后兼容性**：
  - 保持现有 API 接口不变，内部实现重构
  - 原生解码失败时自动降级到 Flutter 层，不影响现有功能
  - 渐进式替换，不影响现有代码路径

- **依赖变更**：
  - 依赖阶段一建立的 `ThumbnailApiService`
  - 无需新增外部依赖

