# native-image-decoding Specification

## Purpose
TBD - created by archiving change add-native-thumbnail-api. Update Purpose after archive.
## Requirements
### Requirement: 原生缩略图解码 API
系统 SHALL 提供原生层图片解码能力，通过 Pigeon 接口与 Flutter 层通信，支持 RAW 格式照片预览和高效缩略图生成。

#### Scenario: 通过 Pigeon 接口请求图片解码
- **WHEN** Flutter 层调用 `ThumbnailApi.requestImage` 方法
- **THEN** 系统 SHALL 通过 Pigeon 接口将请求传递到原生层
- **AND** 原生层 SHALL 根据 assetId 和尺寸参数解码图片
- **AND** 原生层 SHALL 返回 RGBA 像素数据指针、宽度和高度
- **AND** Flutter 层 SHALL 将指针转换为 `ImmutableBuffer` 并渲染

#### Scenario: Android 原生解码实现
- **WHEN** Android 平台收到图片解码请求
- **THEN** 系统 SHALL 使用 `ImageDecoder` API（Android Q/API 29+）解码图片
- **AND** 对于旧版本 Android，系统 SHALL 使用 Glide 库作为降级方案
- **AND** 系统 SHALL 使用软件解码器（`ALLOCATOR_SOFTWARE`）提升兼容性
- **AND** 系统 SHALL 强制使用 SRGB 颜色空间（`ColorSpace.get(ColorSpace.Named.SRGB)`）
- **AND** 系统 SHALL 支持采样缩放以优化内存使用

#### Scenario: iOS 原生解码实现
- **WHEN** iOS 平台收到图片解码请求
- **THEN** 系统 SHALL 使用 `PHImageManager` 请求图片
- **AND** 系统 SHALL 使用 `PHImageRequestOptions` 配置高质量格式
- **AND** 系统 SHALL 自动处理 RAW 格式（DNG、CR2、NEF 等）
- **AND** 系统 SHALL 返回 RGBA 像素数据

#### Scenario: RAW 格式支持
- **WHEN** 请求解码 RAW 格式照片（DNG、CR2、NEF、ARW 等）
- **THEN** Android 系统 SHALL 通过 `ImageDecoder` 自动识别并解码
- **AND** iOS 系统 SHALL 通过 `PHImageManager` 自动处理 RAW 格式
- **AND** 系统 SHALL 返回可渲染的 RGBA 数据

#### Scenario: 视频缩略图生成
- **WHEN** 请求解码视频缩略图（isVideo=true）
- **THEN** Android 系统 SHALL 使用 `ContentResolver.loadThumbnail` 或 `Video.Thumbnails.getThumbnail` 生成缩略图
- **AND** iOS 系统 SHALL 使用 `PHImageManager.requestImage` 生成视频缩略图
- **AND** 系统 SHALL 返回指定尺寸的缩略图数据

#### Scenario: 请求取消机制
- **WHEN** Flutter 层调用 `ThumbnailApi.cancelImageRequest` 方法
- **THEN** 系统 SHALL 取消对应的解码请求
- **AND** Android 系统 SHALL 使用 `CancellationSignal.cancel()` 取消请求
- **AND** iOS 系统 SHALL 取消对应的 `DispatchWorkItem`
- **AND** 系统 SHALL 释放已分配的内存资源

#### Scenario: ThumbHash 解码支持
- **WHEN** Flutter 层调用 `ThumbnailApi.getThumbhash` 方法
- **THEN** 系统 SHALL 在原生层解码 ThumbHash 数据
- **AND** 系统 SHALL 返回 RGBA 像素数据指针、宽度和高度
- **AND** Flutter 层 SHALL 将指针转换为 `ImmutableBuffer` 并渲染

#### Scenario: Flutter 层桥接服务
- **WHEN** 使用原生解码功能
- **THEN** 系统 SHALL 提供 `ThumbnailApiService` 类封装 API 调用
- **AND** 服务类 SHALL 处理请求/取消逻辑
- **AND** 服务类 SHALL 实现指针到 `ImmutableBuffer` 的转换
- **AND** 服务类 SHALL 提供错误处理和重试机制
- **AND** 服务类 SHALL 管理请求生命周期（requestId 生成和管理）

#### Scenario: 错误处理
- **WHEN** 图片解码失败
- **THEN** 系统 SHALL 返回错误信息
- **AND** Flutter 层 SHALL 捕获错误并记录日志
- **AND** 系统 SHALL 释放已分配的内存资源
- **AND** 系统 SHALL 提供降级策略（如回退到 Flutter 层处理）

#### Scenario: 内存管理
- **WHEN** 原生层分配内存用于传递 RGBA 数据
- **THEN** 系统 SHALL 在 Flutter 层使用后释放内存
- **AND** Android 系统 SHALL 使用 `freeNative` 释放内存
- **AND** iOS 系统 SHALL 使用 `deallocate` 释放内存
- **AND** 系统 SHALL 使用 try-finally 确保资源释放

#### Scenario: 并发处理
- **WHEN** 同时收到多个图片解码请求
- **THEN** 系统 SHALL 使用线程池并发处理请求
- **AND** Android 系统 SHALL 使用 `Executors.newFixedThreadPool` 管理线程
- **AND** iOS 系统 SHALL 使用 `DispatchQueue` 并发处理
- **AND** 系统 SHALL 避免阻塞主线程

#### Scenario: 向后兼容性
- **WHEN** 原生解码 API 可用时
- **THEN** 系统 SHALL 不影响现有 Flutter 层图片加载逻辑
- **AND** 现有代码路径 SHALL 继续正常工作
- **AND** 原生解码功能 SHALL 作为可选功能，可通过配置开关控制

