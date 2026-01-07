# PrismBox 媒体处理重构总规划

## 一、现状分析

### 当前架构
- 图片加载：Flutter 层通过 `photo_manager` 处理，缺少原生 RAW 解码
- 视频播放：使用 `video_player`，不支持 HDR
- Live Photo：数据模型已有 `livePhotoVideoId`，但缺少完整实现
- 跨平台通信：已有 Pigeon 基础设施（connectivity_api、background_worker_api）

### 目标架构
- RAW 照片预览：原生层解码，Flutter 层渲染
- HDR 视频播放：使用原生播放器（native_video_player）
- 普通媒体处理：混合架构（缩略图走原生，原图走 Flutter）
- Live Photo：完整的上传、下载、播放支持

---

## 二、重构阶段规划

### 阶段 1：基础设施搭建（Foundation）

#### 1.1 创建 ThumbnailApi Pigeon 接口
- 目标：建立 Flutter 与原生层的图片解码桥接
- 工作内容：
  - 创建 `pigeon/thumbnail_api.dart`
  - 定义接口：`requestImage`、`cancelImageRequest`、`getThumbhash`
  - 生成 Dart/Kotlin/Swift 代码
- 参考：`immich/mobile/pigeon/thumbnail_api.dart`
- 依赖：无
- 影响范围：新增 Pigeon 接口，不影响现有功能

#### 1.2 Android 原生实现
- 目标：实现 Android 端 RAW 解码
- 工作内容：
  - 创建 `ThumbnailsImpl.kt`
  - 实现 `ImageDecoder`（API 29+）和 Glide 降级
  - 实现原生内存分配与 RGBA 数据传递
  - 支持视频缩略图生成
- 参考：`immich/mobile/android/app/src/main/kotlin/app/alextran/immich/images/ThumbnailsImpl.kt`
- 依赖：阶段 1.1
- 影响范围：新增原生代码

#### 1.3 iOS 原生实现
- 目标：实现 iOS 端 RAW 解码
- 工作内容：
  - 创建 `ThumbnailsImpl.swift`
  - 使用 `PHImageManager` 请求图片
  - 实现 RGBA 数据传递
  - 支持视频缩略图生成
- 参考：`immich/mobile/ios/Runner/Images/ThumbnailsImpl.swift`
- 依赖：阶段 1.1
- 影响范围：新增原生代码

#### 1.4 Flutter 层桥接实现
- 目标：封装 ThumbnailApi 调用
- 工作内容：
  - 创建 `lib/platform/thumbnail_api_service.dart`
  - 封装请求/取消逻辑
  - 处理指针到 `ImmutableBuffer` 的转换
  - 错误处理与重试
- 参考：`immich/mobile/lib/infrastructure/loaders/image_request.dart`
- 依赖：阶段 1.1-1.3
- 影响范围：新增服务层

---

### 阶段 2：图片处理重构（Image Processing）

#### 2.1 重构本地图片加载策略
- 目标：实现混合架构（缩略图原生，原图 Flutter）
- 工作内容：
  - 修改 `LocalThumbProvider`：小尺寸走 ThumbnailApi
  - 修改 `LocalFullImageProvider`：原图仍走 Flutter 层
  - 更新 `LocalImageRequest`：根据尺寸选择路径
  - 保持渐进式加载（缩略图 → 适配尺寸 → 原图）
- 参考：Immich 技术方案第 3.1 节
- 依赖：阶段 1
- 影响范围：`lib/features/media_loading/providers/`、`lib/features/media_loading/requests/`

#### 2.2 RAW 格式支持增强
- 目标：确保 RAW 格式正确解码
- 工作内容：
  - Android：验证 ImageDecoder 对 DNG/CR2/NEF/ARW 的支持
  - iOS：验证 PHImageManager 对 RAW 的支持
  - 添加 RAW 格式检测与降级策略
  - 测试常见 RAW 格式
- 依赖：阶段 2.1
- 影响范围：原生层、错误处理

#### 2.3 远程图片处理优化
- 目标：保持 Flutter 层处理，优化性能
- 工作内容：
  - 保持 `RemoteFullImageProvider` 的渐进式加载
  - 优化缓存策略
  - 确保与本地图片加载的一致性
- 参考：Immich 技术方案第 3.1 节
- 依赖：无（独立优化）
- 影响范围：`lib/features/media_loading/providers/remote_*.dart`

---

### 阶段 3：视频播放重构（Video Playback）

#### 3.1 集成 native_video_player
- 目标：替换 video_player，支持 HDR
- 工作内容：
  - 添加 `native_video_player` 依赖（GitHub 源）
  - 创建 `lib/features/media_loading/native_video_service.dart`
  - 封装 `NativeVideoPlayerController` 创建与管理
  - 实现视频源创建逻辑（本地文件/网络 URL）
- 参考：`immich/mobile/lib/pages/common/native_video_viewer.page.dart`
- 依赖：无
- 影响范围：新增服务，准备替换现有播放器

#### 3.2 重构视频查看器组件
- 目标：使用 native_video_player 替换 video_player
- 工作内容：
  - 重构 `ViewerVideoPage`：使用 `NativeVideoPlayerView`
  - 重构 `ViewerVideoManager`：管理 `NativeVideoPlayerController`
  - 保持现有 API 兼容性（渐进式替换）
  - 实现播放控制（播放/暂停/进度/音量）
- 参考：`immich/mobile/lib/presentation/widgets/asset_viewer/video_viewer.widget.dart`
- 依赖：阶段 3.1
- 影响范围：`lib/presentation/widgets/viewer/viewer_video_*.dart`

#### 3.3 HDR 支持验证
- 目标：确保 HDR 视频正确播放
- 工作内容：
  - 测试 HEVC/H.265、VP9、AV1 等 HDR 格式
  - 验证自动 HDR 渲染
  - 测试不同设备兼容性
  - 文档化支持的格式
- 依赖：阶段 3.2
- 影响范围：测试与文档

#### 3.4 视频源提供者重构
- 目标：适配 native_video_player 的 VideoSource
- 工作内容：
  - 修改 `VideoProvider.getVideoSource`：返回 native_video_player 的 `VideoSource`
  - 支持本地文件路径和网络 URL
  - 处理 Live Photo 视频的特殊情况
- 参考：`immich/mobile/lib/presentation/widgets/asset_viewer/video_viewer.widget.dart` 的 `createSource`
- 依赖：阶段 3.1
- 影响范围：`lib/features/media_loading/video_provider.dart`

---

### 阶段 4：Live Photo 完整支持（Live Photo）

#### 4.1 上传流程实现
- 目标：支持 Live Photo 分步上传
- 工作内容：
  - 检测 Live Photo（iOS：`isLivePhoto`，Android：`.MP` 扩展名）
  - 修改上传服务：先上传图片，再上传视频
  - 实现 `UploadTaskMetadata` 标记 Live Photo 任务
  - 图片上传完成后自动触发视频上传
  - 服务器端关联处理（如需要）
- 参考：`immich/mobile/lib/services/upload.service.dart`、`immich/mobile/lib/services/backup.service.dart`
- 依赖：无（可并行开发）
- 影响范围：`lib/services/upload/`、`lib/services/backup/`

#### 4.2 下载流程实现
- 目标：支持 Live Photo 并行下载与保存
- 工作内容：
  - 识别 Live Photo（检查 `livePhotoVideoId`）
  - 创建并行下载任务（图片 + 视频）
  - 使用 `LivePhotosMetadata` 标记任务类型
  - 实现保存逻辑：
    - iOS：使用 `PhotoManager.editor.darwin.saveLivePhoto`
    - Android：降级为普通图片（Motion Photo 限制）
  - 错误处理与降级策略
- 参考：`immich/mobile/lib/services/download.service.dart`、`immich/mobile/lib/repositories/download.repository.dart`
- 依赖：无（可并行开发）
- 影响范围：`lib/services/download/`、`lib/repositories/download/`

#### 4.3 预览与播放实现
- 目标：实现 Live Photo 的预览与播放
- 工作内容：
  - 在资产查看器中检测 Live Photo
  - 显示播放按钮（`MotionPhotoActionButton`）
  - 实现播放状态管理（使用 Riverpod Provider）
  - 长按或点击播放按钮触发视频播放
  - 使用 `NativeVideoPlayerView` 播放视频部分
  - 播放完成后自动切换回静态图片
  - 不循环播放（与普通视频区分）
- 参考：`immich/mobile/lib/providers/asset_viewer/is_motion_video_playing.provider.dart`
- 依赖：阶段 3（视频播放器）、阶段 4.1-4.2
- 影响范围：`lib/presentation/widgets/viewer/`、`lib/providers/asset_viewer/`

#### 4.4 视觉标识与用户体验
- 目标：优化 Live Photo 的用户体验
- 工作内容：
  - 在缩略图上显示 Live Photo 标识
  - 优化播放按钮样式与位置
  - 实现平滑的图片/视频切换动画
  - 添加加载状态提示
- 依赖：阶段 4.3
- 影响范围：UI 组件

---

### 阶段 5：性能优化与测试（Optimization & Testing）

#### 5.1 性能优化
- 目标：优化内存使用与加载速度
- 工作内容：
  - 优化原生层内存分配与释放
  - 优化 Flutter 层图片缓存策略
  - 优化视频预加载策略
  - 优化 Live Photo 下载与保存流程
- 依赖：阶段 1-4
- 影响范围：全栈

#### 5.2 兼容性测试
- 目标：确保跨平台兼容性
- 工作内容：
  - 测试不同 Android 版本（特别是 API 29+）
  - 测试不同 iOS 版本
  - 测试不同 RAW 格式
  - 测试不同 HDR 格式
  - 测试 Live Photo 的跨平台兼容性
- 依赖：阶段 1-4
- 影响范围：测试

#### 5.3 错误处理与降级策略
- 目标：完善错误处理
- 工作内容：
  - 添加 RAW 解码失败的降级策略
  - 添加 HDR 播放失败的降级策略
  - 添加 Live Photo 保存失败的降级策略
  - 完善错误日志与用户提示
- 依赖：阶段 1-4
- 影响范围：全栈

---

## 三、技术选型与依赖

### 新增依赖
1. `native_video_player`（GitHub 源）
   - 用途：HDR 视频播放
   - 来源：`https://github.com/immich-app/native_video_player`
   - 版本：与 Immich 保持一致

### 原生依赖
- Android：
  - `ImageDecoder`（API 29+）
  - `Glide`（降级方案）
  - `ExoPlayer`（通过 native_video_player）
- iOS：
  - `PHImageManager`（Photos Framework）
  - `AVPlayer`（通过 native_video_player）

### 现有依赖（保持不变）
- `photo_manager`：本地媒体访问
- `pigeon`：跨平台通信
- Flutter 图片解码器：原图处理

---

## 四、架构设计原则

1. 渐进式重构：保持向后兼容，逐步替换
2. 性能优先：高频操作（缩略图）走原生层
3. 内存效率：大文件避免不必要的跨层传递
4. 统一性：远程资源统一在 Flutter 层处理
5. 专业性：复杂解码与渲染交给原生层
6. 兼容性：充分利用平台能力，保证跨平台兼容

---

## 五、风险评估与缓解

### 风险 1：原生代码复杂度
- 缓解：参考 Immich 实现，逐步迁移

### 风险 2：性能回归
- 缓解：分阶段测试，保持性能基准

### 风险 3：兼容性问题
- 缓解：充分测试，提供降级策略

### 风险 4：依赖管理
- 缓解：使用与 Immich 一致的依赖版本

---

## 六、里程碑与交付物

### 里程碑 1：基础设施完成（阶段 1）
- ThumbnailApi 接口与实现
- Android/iOS 原生解码支持
- Flutter 层桥接服务

### 里程碑 2：图片处理重构完成（阶段 2）
- RAW 照片预览支持
- 混合架构图片加载
- 性能优化

### 里程碑 3：视频播放重构完成（阶段 3）
- HDR 视频播放支持
- native_video_player 集成
- 视频查看器重构

### 里程碑 4：Live Photo 支持完成（阶段 4）
- 上传流程
- 下载流程
- 预览与播放

### 里程碑 5：优化与测试完成（阶段 5）
- 性能优化
- 兼容性测试
- 错误处理完善

---

## 七、后续细化建议

1. 每个阶段拆分为具体任务
2. 每个任务明确输入/输出与验收标准
3. 建立代码审查清单
4. 建立性能基准测试
5. 建立兼容性测试矩阵

---

该规划遵循渐进式重构，每个阶段可独立交付与测试，降低风险并保持系统稳定。建议按阶段推进，每个阶段完成后进行充分测试再进入下一阶段。
