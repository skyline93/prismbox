# Change: 添加原生缩略图解码 API（阶段1：基础设施搭建）

## Why

当前 PrismBox 移动端的图片加载完全依赖 Flutter 层的 `photo_manager` 处理，存在以下限制：

- **RAW 格式支持不足**：Flutter 层无法直接解码 RAW 格式（DNG、CR2、NEF、ARW 等），导致 RAW 照片无法正常预览
- **性能瓶颈**：缩略图生成完全在 Flutter 层处理，无法充分利用平台原生解码能力
- **内存效率低**：大尺寸图片在 Flutter 层解码需要完整加载到内存，内存占用高

根据《PrismBox 媒体处理重构总规划》，需要建立原生层图片解码能力，为后续的 RAW 照片预览、混合架构图片加载等功能奠定基础。

通过参考 Immich 的实现，建立 ThumbnailApi Pigeon 接口，实现 Android 和 iOS 原生解码支持，可以：
- 支持 RAW 格式照片预览（利用系统原生解码器）
- 提升缩略图生成性能（原生层更高效）
- 为后续混合架构（缩略图原生、原图 Flutter）提供基础设施
- 保持与现有 Flutter 层图片加载的兼容性

## What Changes

- **创建 ThumbnailApi Pigeon 接口**：
  - 创建 `mobile/pigeon/thumbnail_api.dart` 定义接口
  - 定义 `requestImage`、`cancelImageRequest`、`getThumbhash` 三个方法
  - 生成 Dart/Kotlin/Swift 代码
- **Android 原生实现**：
  - 创建 `ThumbnailsImpl.kt` 实现 ThumbnailApi
  - 使用 `ImageDecoder`（API 29+）或 Glide（降级）解码图片
  - 实现原生内存分配与 RGBA 数据传递
  - 支持视频缩略图生成
- **iOS 原生实现**：
  - 创建 `ThumbnailsImpl.swift` 实现 ThumbnailApi
  - 使用 `PHImageManager` 请求图片（自动支持 RAW）
  - 实现 RGBA 数据传递
  - 支持视频缩略图生成
- **Flutter 层桥接服务**：
  - 创建 `lib/platform/thumbnail_api_service.dart` 封装 API 调用
  - 处理请求/取消逻辑
  - 实现指针到 `ImmutableBuffer` 的转换
  - 错误处理与重试机制

所有实现参考 Immich 的成熟方案，确保稳定性和性能。

## Impact

- **新增文件**：
  - `mobile/pigeon/thumbnail_api.dart` - Pigeon 接口定义
  - `mobile/lib/platform/thumbnail_api.g.dart` - 生成的 Dart 代码
  - `mobile/android/app/src/main/kotlin/app/prismbox/images/ThumbnailsImpl.kt` - Android 实现
  - `mobile/android/app/src/main/kotlin/app/prismbox/images/Thumbnails.g.kt` - 生成的 Kotlin 代码
  - `mobile/ios/Runner/Images/ThumbnailsImpl.swift` - iOS 实现
  - `mobile/ios/Runner/Images/Thumbnails.g.swift` - 生成的 Swift 代码
  - `mobile/lib/platform/thumbnail_api_service.dart` - Flutter 层桥接服务
- **受影响能力**：
  - 新增 `native-image-decoding` capability
- **向后兼容性**：纯新增功能，不影响现有图片加载逻辑，完全向后兼容
- **依赖变更**：无需新增外部依赖，使用现有 Pigeon 基础设施

