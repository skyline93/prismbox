## 1. Pigeon 接口定义

- [x] 1.1 创建 `mobile/pigeon/thumbnail_api.dart` 文件
- [x] 1.2 定义 `@ConfigurePigeon` 配置（Dart/Kotlin/Swift 输出路径）
- [x] 1.3 定义 `@HostApi()` 抽象类 `ThumbnailApi`
- [x] 1.4 定义 `requestImage` 方法（assetId, requestId, width, height, isVideo）
- [x] 1.5 定义 `cancelImageRequest` 方法（requestId）
- [x] 1.6 定义 `getThumbhash` 方法（thumbhash）
- [x] 1.7 运行 `flutter pub run pigeon` 生成代码
- [x] 1.8 验证生成的代码文件存在且格式正确

## 2. Android 原生实现

- [x] 2.1 创建原生内存分配库：
  - [x] 2.1.1 创建 `mobile/android/app/src/main/cpp/native_buffer.c` 文件
  - [x] 2.1.2 实现 `allocateNative` JNI 函数（malloc 分配内存）
  - [x] 2.1.3 实现 `freeNative` JNI 函数（free 释放内存）
  - [x] 2.1.4 实现 `wrapAsBuffer` JNI 函数（NewDirectByteBuffer 包装）
  - [x] 2.1.5 创建或更新 `mobile/android/app/CMakeLists.txt` 配置构建
- [x] 2.2 创建 `mobile/android/app/src/main/kotlin/app/prismbox/images/ThumbnailsImpl.kt`
- [x] 2.3 实现 `ThumbnailApi` 接口
- [x] 2.4 在 companion object 中加载 native_buffer 库（System.loadLibrary）
- [x] 2.5 声明 JNI 函数（@JvmStatic external fun allocateNative/freeNative/wrapAsBuffer）
- [x] 2.6 实现 `requestImage` 方法：
  - [x] 2.6.1 创建 CancellationSignal 和线程池
  - [x] 2.6.2 实现图片解码逻辑（ImageDecoder API 29+ 或 Glide 降级）
  - [x] 2.6.3 实现视频缩略图生成逻辑
  - [x] 2.6.4 实现原生内存分配和 RGBA 数据传递（使用 allocateNative）
- [x] 2.7 实现 `cancelImageRequest` 方法（取消请求逻辑）
- [x] 2.8 实现 `getThumbhash` 方法（ThumbHash 解码）
- [x] 2.9 添加错误处理和日志记录（使用 Result 类型）
- [x] 2.10 在 MainActivity 中注册 ThumbnailsImpl

## 3. iOS 原生实现

- [x] 3.1 创建 `mobile/ios/Runner/Images/ThumbnailsImpl.swift`
- [x] 3.2 实现 `ThumbnailApi` 协议
- [x] 3.3 实现 PHAsset 缓存机制（NSCache，最多 10000 个对象）
- [x] 3.4 实现 `requestImage` 方法：
  - [x] 3.4.1 创建 DispatchQueue 和线程池
  - [x] 3.4.2 使用 PHImageManager 请求图片（从缓存或查询）
  - [x] 3.4.3 实现视频缩略图生成逻辑
  - [x] 3.4.4 实现 RGBA 数据传递（UnsafeMutableRawPointer.allocate）
- [x] 3.5 实现 `cancelImageRequest` 方法（取消请求逻辑）
- [x] 3.6 实现 `getThumbhash` 方法（ThumbHash 解码）
- [x] 3.7 添加错误处理和日志记录（使用 Result 类型）
- [x] 3.8 在 AppDelegate 中注册 ThumbnailApiImpl

## 4. Flutter 层桥接服务

- [x] 4.1 创建 `mobile/lib/platform/thumbnail_api_service.dart`
- [x] 4.2 实现 `ThumbnailApiService` 类
- [x] 4.3 封装 `requestImage` 方法：
  - [x] 4.3.1 调用原生 API
  - [x] 4.3.2 处理指针到 ImmutableBuffer 的转换
  - [x] 4.3.3 实现错误处理和重试机制
- [x] 4.4 封装 `cancelImageRequest` 方法
- [x] 4.5 封装 `getThumbhash` 方法
- [x] 4.6 添加请求生命周期管理（requestId 生成和管理）
- [x] 4.7 添加日志记录和错误处理

## 5. 代码质量与测试

- [x] 5.1 运行 `dart format` 格式化 Dart 代码
- [ ] 5.2 运行 `flutter analyze` 检查代码质量
- [ ] 5.3 运行 `openspec validate add-native-thumbnail-api --strict` 验证提案
- [ ] 5.4 编写单元测试（如需要）
- [ ] 5.5 验证 Android 编译通过
- [ ] 5.6 验证 iOS 编译通过
- [ ] 5.7 验证 Flutter 层代码无编译错误
