# Immich 移动端媒体处理技术方案文档

## 目录
1. [RAW 照片预览方案](#1-raw-照片预览方案)
2. [HDR 视频播放方案](#2-hdr-视频播放方案)
3. [普通照片和视频处理方案](#3-普通照片和视频处理方案)
4. [Live Photo 支持方案](#4-live-photo-支持方案)
5. [架构总结](#5-架构总结)

---

## 1. RAW 照片预览方案

### 1.1 设计理念
利用平台原生解码能力处理 RAW，Flutter 层负责桥接和渲染，避免在 Flutter 层重复实现解码逻辑。

### 1.2 Android 端实现

#### 解码路径选择
- Android Q (API 29+)：使用 `ImageDecoder` API
  - 通过 `ContentResolver` 获取媒体 URI
  - 系统解码器支持常见 RAW（DNG、CR2、NEF、ARW 等）
- 旧版本：使用 Glide 库作为降级方案
  - 通过 `BitmapFactory` 解码

#### 关键实现位置
- `mobile/android/app/src/main/kotlin/app/alextran/immich/images/ThumbnailsImpl.kt`
- `decodeSource` 方法处理图片解码

#### 颜色空间处理
- 强制使用 SRGB（`ColorSpace.get(ColorSpace.Named.SRGB)`）
- 使用软件解码器（`ALLOCATOR_SOFTWARE`）提升兼容性
- 支持采样缩放以优化内存

### 1.3 iOS 端实现

#### Photos Framework 集成
- 通过 `PHImageManager` 请求图片
- 系统自动处理 RAW（DNG、CR2、NEF 等）
- 使用 `PHImageRequestOptions` 配置高质量格式

#### 关键实现位置
- `mobile/ios/Runner/Images/ThumbnailsImpl.swift`
- `requestImage` 方法处理图片请求

### 1.4 Flutter 层处理

#### 本地图片加载
- `ImmichLocalImageProvider` 使用 `ui.ImmutableBuffer.fromFilePath` 读取文件
- 通过 Flutter 的 `ImageDecoderCallback` 解码
- 支持错误处理和重试

#### 远程图片加载
- `RemoteFullImageProvider` 实现渐进式加载
- 加载顺序：缩略图 → 预览图 → 原图（按需）
- 支持缓存机制，减少网络请求

---

## 2. HDR 视频播放方案

### 2.1 架构设计
使用自定义 `native_video_player` 插件，基于平台原生播放器，原生支持 HDR 格式。

### 2.2 视频播放器实现

#### 插件选择
- 使用 Immich 自维护的 `native_video_player` 插件
- Android：基于 ExoPlayer
- iOS：基于 AVPlayer

#### 视频源处理
- 本地文件：直接使用文件路径创建 `VideoSource`
- 远程视频：使用网络 URL，支持原始视频或转码版本
- 根据用户设置选择加载原始视频或转码版本

#### 关键实现位置
- `mobile/lib/pages/common/native_video_viewer.page.dart`
- `createSource` 方法创建视频源

### 2.3 HDR 支持机制

#### 原生支持
- Android ExoPlayer 和 iOS AVPlayer 原生支持 HDR
- 支持的 HDR 格式：HEVC/H.265、VP9、AV1 等
- 系统自动识别并启用 HDR 渲染，无需额外配置

#### 视频格式支持
- 编解码器：h264、hevc、vp9、av1
- 容器格式：mov、mp4、ogg、webm
- 自动检测视频元数据（分辨率、帧率、色彩空间等）

#### 显示适配
- 使用 `AspectRatio` 保持正确宽高比
- 通过 `NativeVideoPlayerView` 渲染视频帧
- 支持全屏和窗口模式切换

### 2.4 性能优化

#### 渐进式加载
- 视频加载前显示缩略图
- 支持延迟加载，避免不必要的资源消耗
- 智能预加载策略

#### 生命周期管理
- 应用进入后台时自动暂停播放
- 支持唤醒锁防止屏幕关闭
- 内存管理和资源释放

#### 缓冲管理
- 监听缓冲状态，提供用户反馈
- 支持网络视频的流式播放
- 自适应码率选择

---

## 3. 普通照片和视频处理方案

### 3.1 照片处理方案

#### 本地照片：混合方案

**缩略图和小尺寸预览 → 原生层处理**
- 通过 `ThumbnailApi`（Pigeon 桥接）调用原生代码
- Android：使用 `ImageDecoder` 或 Glide 解码
- iOS：使用 `PHImageManager` 请求图片
- 原生层返回 RGBA 像素数据指针，Flutter 层转换为 `ImmutableBuffer` 并渲染

**全尺寸原图 → Flutter 层处理**
- 直接使用 `ui.ImmutableBuffer.fromFilePath` 读取文件
- 通过 Flutter 的 `ImageDecoderCallback` 解码
- 不经过原生层，减少跨层数据传递开销

**设计原因**
- 缩略图需要快速生成，原生层更高效
- 原图文件较大，在 Flutter 层解码可减少内存拷贝
- 原生层解码后需要转换为 RGBA 传递，大图成本高

#### 远程照片：Flutter 层处理

**下载与解码流程**
- 使用 `HttpClient` 下载图片数据到内存
- 通过 `ImmutableBuffer.fromUint8List` 创建缓冲区
- 使用 Flutter 的 `ImageDecoderCallback` 解码
- 支持渐进式加载（缩略图 → 预览图 → 原图）

**缓存机制**
- 使用 `RemoteImageCacheManager` 缓存到本地文件
- 缓存命中时从文件读取，仍使用 Flutter 解码器
- 支持缓存过期和清理策略

**设计原因**
- 网络数据已在 Flutter 层，无需跨层传递
- Flutter 解码器支持常见格式（JPEG、PNG、WebP 等）
- 统一在 Flutter 层处理，代码更简洁

### 3.2 视频处理方案

#### 所有视频：原生层处理

**统一使用原生播放器**
- 本地视频：直接传递文件路径给原生层
- 远程视频：传递网络 URL 给原生层
- 通过 `native_video_player` 插件桥接

**原生播放器选择**
- Android：ExoPlayer
- iOS：AVPlayer
- 自动支持硬件解码、HDR、各种编解码器

**设计原因**
- 视频解码与渲染复杂，原生播放器更成熟
- 硬件解码需要原生层支持
- Flutter 层主要负责控制逻辑（播放/暂停/进度等）

### 3.3 处理路径决策树

```
照片处理：
├─ 本地照片
│  ├─ 缩略图/小尺寸 → 原生层（ThumbnailApi）→ 返回像素数据 → Flutter 渲染
│  └─ 全尺寸原图 → Flutter 层直接读取文件 → Flutter 解码器 → Flutter 渲染
│
└─ 远程照片
   └─ 完全 Flutter 层：下载 → 缓存 → Flutter 解码器 → Flutter 渲染

视频处理：
├─ 本地视频 → 原生播放器（文件路径）
└─ 远程视频 → 原生播放器（网络 URL）
```

### 3.4 设计原则

1. 性能优先：缩略图等高频操作走原生层
2. 内存效率：大文件避免不必要的跨层数据传递
3. 统一性：远程资源统一在 Flutter 层处理
4. 专业性：视频解码与渲染交给原生播放器

### 3.5 关键优化点

1. 本地照片原图：跳过原生层，减少内存拷贝
2. 远程照片：渐进式加载，先显示低分辨率
3. 视频：原生播放器自动处理硬件加速和格式兼容
4. 缓存：本地和远程都支持缓存，提升二次加载速度

---

## 4. Live Photo 支持方案

### 4.1 核心设计理念

Live Photo 在 Immich 中被视为**图片 + 视频的组合**，通过 `livePhotoVideoId` 字段关联视频部分。图片和视频在服务器端作为两个独立资产存储，通过 ID 关联。

### 4.2 数据模型设计

#### 资产关联机制
- 图片资产存储 `livePhotoVideoId` 字段，指向关联的视频资产 ID
- 通过 `isMotionPhoto` 判断是否为 Live Photo（`livePhotoVideoId != null`）
- 图片和视频在服务器端作为两个独立资产存储，通过 ID 关联

#### 平台差异处理
- iOS Live Photo：图片（HEIC/JPG）+ 视频（MOV）
- Android Motion Photo：图片文件名包含 `.MP` 扩展名，视频嵌入在图片文件中

### 4.3 上传流程

#### 检测与分离
- 使用 `photo_manager` 检测 `isLivePhoto`
- iOS：通过 `originFileWithSubtype` 获取视频部分
- Android：识别文件名中的 `.MP` 标记

#### 分步上传
1. 先上传图片部分，服务器返回图片资产 ID
2. 再上传视频部分，在请求中携带 `livePhotoVideoId` 参数
3. 服务器将两者关联，视频资产也保存关联信息

#### 上传任务管理
- 使用 `UploadTaskMetadata` 标记 Live Photo 任务
- 图片上传完成后自动触发视频上传任务
- 支持任务取消和错误处理

### 4.4 下载流程

#### 识别 Live Photo
- 检查 `livePhotoVideoId` 字段
- Android Motion Photo 通过文件名 `.MP` 识别（iOS 无法链接，需特殊处理）

#### 并行下载
- 创建两个下载任务：图片和视频
- 使用 `LivePhotosMetadata` 标记任务类型（image/video）和关联 ID
- 两个任务完成后统一处理

#### 保存到本地
- iOS：使用 `PhotoManager.editor.darwin.saveLivePhoto` 保存为系统 Live Photo
- Android：保存为普通图片（Motion Photo 格式限制）
- 失败时降级为仅保存图片

### 4.5 预览与播放

#### 显示模式
- 默认显示静态图片
- 顶部工具栏显示播放按钮（`MotionPhotoActionButton`）
- 通过 `isPlayingMotionVideoProvider` 控制播放状态

#### 播放触发
- 长按图片或点击播放按钮触发
- 切换为视频播放模式，使用 `NativeVideoPlayerView` 播放
- 视频 URL 通过 `livePhotoVideoId` 构建

#### 播放行为
- Live Photo 视频不循环播放（与普通视频区分）
- 播放完成后自动切换回静态图片
- 支持播放控制（暂停、进度条等）

### 4.6 技术实现细节

#### 平台原生支持
- iOS：使用 `PHAssetResource` 获取 Live Photo 资源
- Android：通过 `photo_manager` 检测 Motion Photo
- 利用平台 API 处理文件访问

#### 视频播放
- 复用 `native_video_player` 插件
- 本地：直接使用文件路径
- 远程：通过服务器 API 获取视频流

#### 状态管理
- 使用 Riverpod 管理播放状态
- `isPlayingMotionVideoProvider` 控制显示模式
- 与普通视频播放共享控制逻辑

### 4.7 兼容性处理

#### 跨平台差异
- iOS 完整支持 Live Photo 的保存和播放
- Android 支持 Motion Photo 的识别和上传，但下载时可能降级为普通图片
- 服务器端统一存储，保持跨平台兼容

#### 降级策略
- 视频部分缺失时仅显示图片
- 保存失败时降级为普通图片
- 播放失败时显示错误提示

### 4.8 用户体验优化

#### 视觉标识
- Live Photo 在缩略图上显示特殊标记
- 播放按钮提供明确的操作提示
- 平滑的图片/视频切换动画

#### 性能优化
- 视频按需加载，不自动播放
- 支持本地缓存，减少网络请求
- 异步处理，不阻塞 UI

---

## 5. 架构总结

### 5.1 整体架构设计

Immich 移动端采用**混合架构**，充分利用平台原生能力和 Flutter 跨平台优势：

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter 应用层                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │  图片预览     │  │  视频播放     │  │  Live Photo   │ │
│  │  组件         │  │  组件         │  │  组件         │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────┘
           │                    │                    │
           ▼                    ▼                    ▼
┌─────────────────────────────────────────────────────────┐
│               Flutter 桥接层 (Pigeon)                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │ ThumbnailApi │  │ VideoPlayer  │  │ PhotoManager │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────┘
           │                    │                    │
           ▼                    ▼                    ▼
┌─────────────────────────────────────────────────────────┐
│                   原生平台层                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │ ImageDecoder  │  │ ExoPlayer/   │  │ PHImageManager│ │
│  │ /PHImageMgr  │  │ AVPlayer     │  │ /PhotoManager│ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### 5.2 核心设计原则

1. 性能优先：高频操作（缩略图、视频播放）走原生层
2. 内存效率：大文件避免不必要的跨层数据传递
3. 统一性：远程资源统一在 Flutter 层处理
4. 专业性：复杂解码和渲染交给原生播放器
5. 兼容性：充分利用平台原生能力，保证跨平台兼容

### 5.3 关键技术选型

#### 图片处理
- 缩略图：原生层（Android ImageDecoder/Glide，iOS PHImageManager）
- 原图：Flutter 层（减少内存拷贝）
- 远程图片：Flutter 层（统一处理）

#### 视频处理
- 所有视频：原生播放器（Android ExoPlayer，iOS AVPlayer）
- 自动支持硬件解码、HDR、各种编解码器

#### Live Photo
- 分离存储：图片和视频作为独立资产
- 关联管理：通过 `livePhotoVideoId` 字段关联
- 统一播放：复用视频播放器组件

### 5.4 性能优化策略

1. 渐进式加载：缩略图 → 预览图 → 原图
2. 智能缓存：本地和远程都支持缓存
3. 按需加载：视频和 Live Photo 视频不自动播放
4. 异步处理：不阻塞 UI 线程
5. 内存管理：及时释放资源，避免内存泄漏

### 5.5 兼容性保障

1. 平台差异处理：iOS 和 Android 使用不同的原生 API
2. 降级策略：功能失败时提供降级方案
3. 格式支持：充分利用系统原生格式支持
4. 错误处理：完善的错误处理和用户提示

### 5.6 未来扩展方向

1. 更多 RAW 格式支持：随着系统更新自动支持新格式
2. 更多 HDR 格式：支持 Dolby Vision 等新格式
3. 性能优化：进一步优化内存使用和加载速度
4. 用户体验：改进交互和视觉反馈

---

## 附录：关键代码位置

### Android 原生代码
- 图片解码：`mobile/android/app/src/main/kotlin/app/alextran/immich/images/ThumbnailsImpl.kt`
- 视频播放：通过 `native_video_player` 插件

### iOS 原生代码
- 图片解码：`mobile/ios/Runner/Images/ThumbnailsImpl.swift`
- Live Photo 处理：`mobile/ios/Runner/Sync/PHAssetExtensions.swift`
- 视频播放：通过 `native_video_player` 插件

### Flutter 层代码
- 图片提供者：`mobile/lib/providers/image/`
- 视频播放器：`mobile/lib/pages/common/native_video_viewer.page.dart`
- Live Photo 处理：`mobile/lib/services/upload.service.dart`、`mobile/lib/services/download.service.dart`
- 资产查看器：`mobile/lib/presentation/widgets/asset_viewer/`

---

**文档版本**: 1.0  
**最后更新**: 2024年  
**维护者**: Immich 开发团队

---

该文档整合了 Immich 移动端在 RAW 照片预览、HDR 视频播放、普通媒体处理和 Live Photo 支持方面的技术方案，可作为技术参考和架构设计指南。

