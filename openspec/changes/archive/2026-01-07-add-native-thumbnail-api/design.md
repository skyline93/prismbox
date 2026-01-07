# Design: 原生缩略图解码 API

## Context

PrismBox 移动端需要支持 RAW 格式照片预览和提升图片加载性能。当前完全依赖 Flutter 层的 `photo_manager`，无法利用平台原生解码能力。

参考 Immich 的成熟实现，建立原生层图片解码基础设施，为后续混合架构（缩略图原生、原图 Flutter）奠定基础。

## Goals / Non-Goals

### Goals
- 建立原生层图片解码能力，支持 RAW 格式
- 提供类型安全的跨平台通信接口（Pigeon）
- 实现高效的缩略图生成（原生层处理）
- 保持与现有 Flutter 层代码的兼容性

### Non-Goals
- 不在此阶段重构现有图片加载逻辑（后续阶段）
- 不实现原图解码（仅缩略图和小尺寸预览）
- 不处理远程图片（仅本地资源）

## Decisions

### Decision 1: 使用 Pigeon 进行跨平台通信
**Rationale**:
- 项目已有 Pigeon 基础设施（connectivity_api、background_worker_api）
- Pigeon 提供类型安全的接口定义，编译时检查
- 自动生成 Dart/Kotlin/Swift 代码，减少手动维护成本

**Alternatives considered**:
- MethodChannel：需要手动维护类型定义，容易出错
- Platform Channel：功能类似但缺少类型安全

### Decision 2: Android 使用 ImageDecoder（API 29+）和 Glide 降级
**Rationale**:
- ImageDecoder 是 Android Q+ 官方 API，原生支持 RAW 格式（DNG、CR2、NEF、ARW 等）
- 使用软件解码器（ALLOCATOR_SOFTWARE）提升兼容性
- Glide 作为旧版本降级方案，保证向后兼容

**Alternatives considered**:
- 仅使用 Glide：不支持 RAW 格式
- 仅使用 ImageDecoder：不支持旧版本 Android

### Decision 3: iOS 使用 PHImageManager
**Rationale**:
- PHImageManager 是 iOS Photos Framework 官方 API
- 自动处理 RAW 格式（DNG、CR2、NEF 等）
- 支持高质量格式请求，满足预览需求

**Alternatives considered**:
- Core Image：需要手动处理 RAW 格式，复杂度高
- ImageIO：功能类似但 PHImageManager 更符合项目架构

### Decision 4: 使用原生内存分配传递 RGBA 数据
**Rationale**:
- 避免跨层数据拷贝，提升性能
- 使用指针传递，减少内存占用
- Flutter 层通过 `ImmutableBuffer.fromUint8List` 转换

**Alternatives considered**:
- Base64 编码传递：数据量大，性能差
- 文件路径传递：需要额外文件 I/O，延迟高

### Decision 5: 支持请求取消机制
**Rationale**:
- 图片解码可能耗时，需要支持取消避免资源浪费
- 使用 requestId 管理请求生命周期
- 原生层使用 CancellationSignal（Android）和 DispatchWorkItem（iOS）

## Risks / Trade-offs

### Risk 1: 原生代码复杂度
**Mitigation**: 参考 Immich 的成熟实现，逐步迁移和测试

### Risk 2: 内存管理问题
**Mitigation**: 
- 严格遵循内存分配/释放配对
- 使用 try-finally 确保资源释放
- 在 Flutter 层及时释放 ImmutableBuffer

### Risk 3: 平台差异处理
**Mitigation**:
- Android 和 iOS 使用不同的原生 API，但接口统一
- 通过 Pigeon 抽象平台差异
- 充分测试不同平台版本

### Risk 4: 性能回归
**Mitigation**:
- 仅用于缩略图和小尺寸预览，不处理原图
- 使用线程池并发处理，避免阻塞主线程
- 实现请求缓存机制（后续优化）

## Migration Plan

### Phase 1: 基础设施搭建（本提案）
1. 创建 Pigeon 接口定义
2. 实现 Android/iOS 原生代码
3. 实现 Flutter 层桥接服务
4. 单元测试和集成测试

### Phase 2: 集成到图片加载流程（后续提案）
1. 修改 LocalThumbProvider 使用 ThumbnailApi
2. 保持向后兼容，逐步迁移
3. 性能测试和优化

### Rollback Plan
- 如果原生实现有问题，可以回退到纯 Flutter 层处理
- 通过配置开关控制是否使用原生解码
- 保持现有代码路径不变

## Open Questions

### Q1: Android 原生内存分配库（native_buffer）是否需要单独实现？
**答案（基于 Immich 实现）**：**是，需要实现**

Immich 使用 JNI 实现了 `native_buffer` 原生库，包含以下函数：
- `allocateNative(size: Int): Long` - 分配原生内存
- `freeNative(pointer: Long)` - 释放原生内存
- `wrapAsBuffer(address: Long, capacity: Int): ByteBuffer` - 将指针包装为 ByteBuffer

**实现要求**：
- 创建 `mobile/android/app/src/main/cpp/native_buffer.c` 文件
- 使用 CMakeLists.txt 配置构建（参考 Immich 的 `android/app/CMakeLists.txt`）
- 在 `ThumbnailsImpl.kt` 中使用 `System.loadLibrary("native_buffer")` 加载库
- 使用 `@JvmStatic external` 声明 JNI 函数

**原因**：Android 需要通过 JNI 分配原生内存，以便在 Flutter 层通过指针访问 RGBA 数据，避免跨层数据拷贝。

### Q2: 是否需要实现请求缓存机制？
**答案（基于 Immich 实现）**：**iOS 需要，Android 可选**

Immich 的实现：
- **iOS**：使用 `NSCache<NSString, PHAsset>` 缓存 PHAsset 对象（最多 10000 个），减少重复查询
- **Android**：没有明显的请求缓存机制，每次都通过 ContentResolver 查询

**实现建议**：
- **iOS**：实现 PHAsset 缓存（参考 Immich 的 `assetCache`）
- **Android**：暂不实现请求缓存（ContentResolver 查询性能足够）
- **后续优化**：可以考虑在 Flutter 层实现解码结果缓存

### Q3: 错误处理策略是否需要统一？
**答案（基于 Immich 实现）**：**已统一，使用 Result 类型**

Immich 的错误处理策略：
- **Android**：使用 `Result<Map<String, Long>>` 类型，通过 callback 返回
  - 成功：`Result.success(mapOf("pointer" to pointer, "width" to width, "height" to height))`
  - 失败：`Result.failure(e)`
  - 取消：`Result.success(mapOf())`（空 Map 表示取消）
- **iOS**：使用 `Result<[String: Int64], any Error>` 类型，通过 completion 回调
  - 成功：`.success(["pointer": Int64(...), "width": Int64(...), "height": Int64(...)])`
  - 失败：`.failure(PigeonError(...))`
  - 取消：`.success([:])`（空字典表示取消）

**Flutter 层处理**：
- 检查返回的 Map 是否为空来判断是否取消
- 使用 try-catch 捕获异常
- 在 `_fromPlatformImage` 方法中处理指针转换和内存释放

**结论**：当前设计使用 Result 类型是正确的，与 Immich 保持一致。

