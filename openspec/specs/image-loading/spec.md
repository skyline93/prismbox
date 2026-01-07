# image-loading Specification

## Purpose
TBD - created by archiving change refactor-local-image-loading. Update Purpose after archive.
## Requirements
### Requirement: 混合架构本地图片加载
系统 SHALL 实现混合架构的本地图片加载策略，所有本地图片请求（包括原图）统一使用原生层解码。

#### Scenario: 缩略图使用原生解码
- **WHEN** 请求加载本地图片缩略图（`isThumbnail=true`）
- **THEN** 系统 SHALL 使用 `ThumbnailApiService.requestImage` 调用原生解码
- **AND** 原生层 SHALL 解码图片并返回 RGBA 像素数据
- **AND** Flutter 层 SHALL 将像素数据转换为 `ImmutableBuffer` 并解码渲染
- **AND** 解码结果 SHALL 写入缓存（通过 `ThumbnailImageCacheManager`）
- **AND** 如果原生解码失败，系统 SHALL 自动降级到 Flutter 层处理

#### Scenario: 适配尺寸使用原生解码
- **WHEN** 请求加载本地图片适配尺寸（用于渐进式加载的阶段2）
- **THEN** 系统 SHALL 使用 `ThumbnailApiService.requestImage` 调用原生解码
- **AND** 原生层 SHALL 根据请求尺寸解码图片并返回 RGBA 像素数据
- **AND** 原生层 SHALL 自动进行采样缩放，优化内存使用
- **AND** Flutter 层 SHALL 将像素数据转换为 `ImmutableBuffer` 并解码渲染
- **AND** 如果原生解码失败，系统 SHALL 自动降级到 Flutter 层处理

#### Scenario: 原图使用原生解码
- **WHEN** 请求加载本地图片原图（明确请求原图或 `targetSize=null`）
- **THEN** 系统 SHALL 使用 `ThumbnailApiService.requestImage` 调用原生解码，传递 `width=0, height=0` 表示最大尺寸
- **AND** iOS 原生层 SHALL 使用 `PHImageManagerMaximumSize` 返回原图
- **AND** Android 原生层 SHALL 检测到 `width=0, height=0` 时返回原图尺寸
- **AND** 原生层 SHALL 解码原图并返回 RGBA 像素数据
- **AND** Flutter 层 SHALL 将像素数据转换为 `ImmutableBuffer` 并解码渲染
- **AND** 如果原生解码失败，系统 SHALL 自动降级到 Flutter 层处理（`ImmutableBuffer.fromFilePath`）

#### Scenario: 统一使用原生解码决策
- **WHEN** 请求加载本地图片（包括原图）
- **THEN** 系统 SHALL 统一使用原生解码，不区分格式和尺寸
- **AND** 如果 `isThumbnail=true`，系统 SHALL 强制使用原生解码
- **AND** 如果 `targetSize=null` 或明确请求原图，系统 SHALL 传递 `width=0, height=0` 给原生 API 表示最大尺寸
- **AND** 原生 API SHALL 自动处理各种格式（包括 RAW 格式）和任意尺寸
- **AND** 原生层 SHALL 自动进行采样缩放，优化内存使用
- **AND** 如果原生解码失败，系统 SHALL 自动降级到 Flutter 层处理

#### Scenario: 渐进式加载保持不变
- **WHEN** 使用 `LocalFullImageProvider` 加载图片
- **THEN** 系统 SHALL 保持渐进式加载流程（缩略图 → 适配尺寸 → 原图）
- **AND** 缩略图阶段 SHALL 使用原生解码（通过 `LocalThumbProvider`）
- **AND** 适配尺寸阶段 SHALL 使用原生解码（通过 `ThumbnailApiService.requestImage`，传递适配屏幕尺寸）
- **AND** 原图阶段 SHALL 使用原生解码（通过 `ThumbnailApiService.requestImage`，传递 `width=0, height=0` 表示最大尺寸）

#### Scenario: RAW 格式自动支持
- **WHEN** 请求加载 RAW 格式照片（DNG、CR2、NEF、ARW 等）
- **THEN** 系统 SHALL 通过原生层自动识别并解码 RAW 格式
- **AND** Android 系统 SHALL 使用 `ImageDecoder` 自动处理 RAW 格式
- **AND** iOS 系统 SHALL 使用 `PHImageManager` 自动处理 RAW 格式
- **AND** 系统 SHALL 返回可渲染的 RGBA 数据
- **AND** RAW 格式 SHALL 执行完整的渐进式加载流程（缩略图 → 适配尺寸 → 原图）
- **AND** 所有阶段 SHALL 使用原生解码，确保预览清晰
- **AND** 如果原生解码失败，系统 SHALL 尝试 Flutter 层处理或显示错误

#### Scenario: 视频缩略图原生解码
- **WHEN** 请求生成视频缩略图
- **THEN** 系统 SHALL 使用原生解码（通过 `ThumbnailApiService.requestImage` 并设置 `isVideo=true`）
- **AND** Android 系统 SHALL 使用 `ContentResolver.loadThumbnail` 或 `Video.Thumbnails.getThumbnail`
- **AND** iOS 系统 SHALL 使用 `PHImageManager.requestImage` 生成视频缩略图
- **AND** 系统 SHALL 返回指定尺寸的缩略图数据

#### Scenario: 降级策略
- **WHEN** 原生解码失败（格式不支持、系统版本问题、解码错误等）
- **THEN** 系统 SHALL 自动降级到 Flutter 层处理
- **AND** 系统 SHALL 记录错误日志（不中断用户流程）
- **AND** Flutter 层处理 SHALL 继续使用现有代码路径（`photo_manager`）
- **AND** 用户 SHALL 感知不到降级过程（功能正常可用）

#### Scenario: 缓存一致性
- **WHEN** 原生解码生成缩略图、适配尺寸图片或原图
- **THEN** 系统 SHALL 将解码结果写入缓存（使用 `ThumbnailImageCacheManager`）
- **AND** 缓存键格式 SHALL 保持一致：`{userId}{localId}{checksum}{width}{height}`
- **AND** 原图的缓存键 SHALL 使用实际原图尺寸（从原生层返回的尺寸）或特殊标识
- **AND** 原生解码和 Flutter 层解码 SHALL 使用相同的缓存键
- **AND** 缓存命中时，系统 SHALL 从缓存读取并使用 Flutter 解码器解码

#### Scenario: 请求取消支持
- **WHEN** Flutter 层取消图片加载请求
- **THEN** 系统 SHALL 取消原生解码请求（通过 `ThumbnailApiService.cancelImageRequest`）
- **AND** 原生层 SHALL 释放已分配的内存资源
- **AND** Flutter 层 SHALL 停止后续处理

#### Scenario: 内存管理
- **WHEN** 原生解码返回 RGBA 像素数据
- **THEN** Flutter 层 SHALL 立即将指针转换为 `ImmutableBuffer`
- **AND** 系统 SHALL 在转换完成后释放原生内存（使用 `malloc.free` 或 `deallocate`）
- **AND** 系统 SHALL 使用 try-finally 确保资源释放
- **AND** `ImmutableBuffer` 的内存 SHALL 由 Flutter 管理，使用完毕后自动释放
- **AND** 原生层 SHALL 自动进行采样缩放，优化内存使用

### Requirement: RAW 格式支持增强
系统 SHALL 增强对 RAW 格式照片的支持，确保常见 RAW 格式能够正确预览，包括缩略图、适配尺寸和原图。

#### Scenario: RAW 格式检测
- **WHEN** 加载本地图片
- **THEN** 系统 SHALL 检测图片格式（通过文件扩展名或 MIME 类型）
- **AND** 系统 SHALL 识别常见 RAW 格式（DNG、CR2、NEF、ARW、ORF、SRW 等）
- **AND** RAW 格式图片 SHALL 统一使用原生解码，不区分尺寸

#### Scenario: RAW 格式解码
- **WHEN** 请求解码 RAW 格式照片
- **THEN** 系统 SHALL 通过原生层解码 RAW 格式
- **AND** Android 系统 SHALL 使用 `ImageDecoder` 自动处理 RAW 格式
- **AND** iOS 系统 SHALL 使用 `PHImageManager` 自动处理 RAW 格式
- **AND** 系统 SHALL 返回可渲染的 RGBA 数据
- **AND** RAW 格式 SHALL 支持任意尺寸的解码（包括适配屏幕尺寸的大尺寸图片）

#### Scenario: RAW 格式渐进式加载
- **WHEN** 使用 `LocalFullImageProvider` 加载 RAW 格式照片
- **THEN** 系统 SHALL 执行完整的渐进式加载流程（缩略图 → 适配尺寸 → 原图）
- **AND** 缩略图阶段 SHALL 使用原生解码，生成清晰的缩略图
- **AND** 适配尺寸阶段 SHALL 使用原生解码，生成清晰的适配屏幕尺寸图片
- **AND** 原图阶段 SHALL 使用原生解码（通过 `ThumbnailApiService.requestImage`，传递 `width=0, height=0` 表示最大尺寸）
- **AND** 所有阶段 SHALL 使用原生解码，确保 RAW 格式预览清晰，不模糊

#### Scenario: RAW 格式错误处理
- **WHEN** RAW 格式解码失败（格式不支持、系统版本问题等）
- **THEN** 系统 SHALL 尝试降级到 Flutter 层处理
- **AND** 如果 Flutter 层也不支持，系统 SHALL 显示友好的错误提示
- **AND** 系统 SHALL 记录错误日志，便于排查问题

### Requirement: 远程图片处理优化
系统 SHALL 优化远程图片加载性能，确保与本地图片加载体验的一致性。

#### Scenario: 远程图片保持 Flutter 层处理
- **WHEN** 加载远程图片
- **THEN** 系统 SHALL 完全在 Flutter 层处理（使用 `RemoteFullImageProvider`）
- **AND** 系统 SHALL 使用 `HttpClient` 下载图片数据
- **AND** 系统 SHALL 使用 `ImmutableBuffer.fromUint8List` 创建缓冲区
- **AND** 系统 SHALL 使用 Flutter 的 `ImageDecoderCallback` 解码

#### Scenario: 渐进式加载优化
- **WHEN** 加载远程图片
- **THEN** 系统 SHALL 实现渐进式加载（缩略图 → 预览图 → 原图）
- **AND** 系统 SHALL 优先加载低分辨率图片，提供即时视觉反馈
- **AND** 系统 SHALL 根据用户设置决定是否加载原图
- **AND** 系统 SHALL 支持加载进度显示

#### Scenario: 缓存策略优化
- **WHEN** 加载远程图片
- **THEN** 系统 SHALL 使用 `RemoteImageCacheManager` 缓存图片数据
- **AND** 缓存键 SHALL 唯一且稳定（基于 URL）
- **AND** 缓存过期策略 SHALL 合理（支持过期后仍可使用）
- **AND** 缓存命中时，系统 SHALL 从文件读取，避免重复下载

#### Scenario: 与本地图片体验一致
- **WHEN** 用户在相册中浏览图片（包括本地和远程）
- **THEN** 系统 SHALL 提供一致的加载体验（加载速度、错误处理、视觉反馈等）
- **AND** 系统 SHALL 支持相同的渐进式加载流程
- **AND** 系统 SHALL 支持相同的缓存策略（缓存键格式、过期策略等）

