# Change: 移除原生解码尺寸限制，统一使用原生 API

## Why

当前 PrismBox 移动端的本地图片加载策略存在以下问题：

- **RAW 格式预览模糊**：虽然 RAW 格式照片可以显示缩略图（200x200），但在预览放大时非常模糊，因为适配屏幕尺寸的图片（如 3240x5760）超过了 `MAX_NATIVE_DECODE_SIZE = 512.0` 的限制，降级到 Flutter 层处理，而 Flutter 层无法处理 RAW 格式
- **架构不一致**：当前实现根据尺寸大小决定使用原生解码还是 Flutter 层，这种混合策略增加了复杂度，且无法充分利用原生 API 的能力
- **与 Immich 设计不一致**：参考 Immich 的实现，`LocalImageRequest` 统一使用原生 API，不区分格式和尺寸，原生层已经能够高效处理各种格式和尺寸

根据《PrismBox 媒体处理重构总规划》和《Immich 移动端媒体处理技术方案文档》，原生 API（Android `ImageDecoder`、iOS `PHImageManager`）已经能够：
- 自动处理 RAW 格式（DNG、CR2、NEF、ARW 等）
- 支持任意尺寸的图片解码
- 在原生层进行采样缩放，优化内存使用

移除尺寸限制，统一使用原生 API，可以：
- 解决 RAW 格式预览放大模糊的问题
- 简化架构设计，减少特殊判断逻辑
- 与 Immich 的设计保持一致，降低维护成本
- 充分利用原生 API 的能力，提升性能和兼容性

## What Changes

- **移除 `MAX_NATIVE_DECODE_SIZE` 限制**：
  - 删除或大幅提高 `MAX_NATIVE_DECODE_SIZE` 常量（从 512.0 提高到 4096.0 或移除）
  - 修改 `LocalImageRequest._shouldUseNativeDecode()` 方法，统一使用原生解码
  - 保留 `isThumbnail` 的判断逻辑（明确标记为缩略图时使用原生解码）

- **简化 `LocalImageRequest` 逻辑**：
  - 移除基于尺寸的决策逻辑
  - 统一使用原生 API 处理所有本地图片请求
  - 保持降级策略：原生解码失败时回退到 Flutter 层

- **修改 `LocalFullImageProvider` 的 RAW 格式处理**：
  - 移除对 RAW 格式的特殊处理（不再跳过阶段2和阶段3）
  - RAW 格式也执行完整的渐进式加载流程（缩略图 → 适配尺寸 → 原图）
  - 所有阶段都使用原生解码，确保 RAW 格式预览清晰

- **修改原图加载策略（按照 Immich 新架构）**：
  - 原图加载也使用原生解码（通过 `Size.zero` 或 `width=0, height=0` 表示最大尺寸）
  - iOS 原生层：`Size.zero` 对应 `PHImageManagerMaximumSize`，返回原图
  - Android 原生层：`width=0, height=0` 时返回原图尺寸
  - 移除 `_loadOriginalImage()` 中使用 Flutter 层读取文件的逻辑

- **性能优化（如需要）**：
  - 依赖原生层的采样缩放能力（Android `ImageDecoder`、iOS `PHImageManager` 已支持）
  - 通过缓存机制减少重复解码
  - 监控内存使用，必要时添加保护

所有实现参考 Immich 的成熟方案，确保稳定性和性能。

## Impact

- **修改文件**：
  - `mobile/lib/features/media_loading/requests/local_image_request.dart` - 移除尺寸限制，简化决策逻辑，支持原图加载（`width=0, height=0`）
  - `mobile/lib/features/media_loading/providers/local_full_provider.dart` - 移除 RAW 格式的特殊处理，修改原图加载使用原生解码

- **受影响能力**：
  - 修改 `image-loading` capability（修改现有需求）

- **向后兼容性**：
  - 保持现有 API 接口不变，仅修改内部实现
  - 原生解码失败时自动降级到 Flutter 层，不影响现有功能
  - 对于非 RAW 格式，行为基本不变（只是统一使用原生解码）
  - 原图加载从 Flutter 层改为原生解码，但功能保持一致（都能正确显示原图）

- **性能影响**：
  - 预期性能提升：原生解码更高效，支持采样缩放
  - 内存使用：原生层已优化，预期不会显著增加
  - 需要实际测试验证，必要时添加监控

- **依赖变更**：
  - 无需新增外部依赖
  - 依赖阶段一建立的 `ThumbnailApiService`（已存在）

