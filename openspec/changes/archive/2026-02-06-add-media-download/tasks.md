## 1. 数据层（移动端）

- [x] 1.1 新增 DownloadTaskEntity 表（id, userId, sourceType, sourceId, mediaUuid, livePhotoVideoUuid, filename, itemType, status, progress, errorMessage, imageTempPath, videoTempPath, createdAt, updatedAt）及索引
- [x] 1.2 新增 DownloadTaskStatus 枚举（pending, queued, downloading, processing, completed, failed, permanentlyFailed, cancelled）
- [x] 1.3 新增 DownloadTaskDao 及在 AppDatabase 中注册

## 2. 下载任务管理层（移动端）

- [x] 2.1 实现 DownloadTaskStateMachine（状态转换规则与 DB 更新）
- [x] 2.2 实现 DownloadTaskManager：配置 FileDownloader 的 prismbox_download group、创建 DownloadTask、enqueue、注册 status/progress 回调；在回调中更新 DB 并在 Live Photo 双文件都完成时触发后处理

## 3. 请求与任务创建（移动端）

- [x] 3.1 定义 MediaDownloadRequest、MediaDownloadSourceType（timeline_asset | post_media）
- [x] 3.2 实现从 MediaDownloadRequest 生成 DownloadTaskEntity 及 1 或 2 个 DownloadTask 的逻辑（URL、headers、保存路径、taskId 约定）

## 4. 编排与后处理（移动端）

- [x] 4.1 实现 DownloadOrchestrator：获取 pending/queued 任务、_executeDownload（创建并 enqueue DownloadTask），不阻塞返回
- [x] 4.2 在 DownloadTaskManager 完成回调中实现后处理：根据 itemType 与 livePhotoVideoUuid 调用 saveImage/saveVideo/saveLivePhoto，删除临时文件，更新状态

## 5. 服务层（移动端）

- [x] 5.1 实现 DownloadService：addDownload(MediaDownloadRequest)（冲突检测、插入 entity、乐观更新、触发 startDownload）、getQueueStatus(userId）
- [x] 5.2 在现有 DI 中注册 DownloadService、DownloadOrchestrator、DownloadTaskManager、DownloadTaskStateMachine

## 6. 后端

- [x] 6.1 在 Feed/帖子媒体 API 的 MediaInfo（或等价 DTO）中增加 LivePhotoVideoID 字段，构建时从 media.LivePhotoVideoUUID 赋值

## 7. 前端模型与 UI

- [x] 7.1 PostMedia 模型增加 livePhotoVideoId 字段，fromJson 解析 live_photo_video_id
- [x] 7.2 MediaViewerPage：ViewerControlsBar 的 AppBar actions 增加下载按钮，仅当当前 asset.remoteId != null 时可用，点击构造 MediaDownloadRequest 并调用 DownloadService.addDownload
- [x] 7.3 PhotoViewerPage：AppBar actions 增加下载按钮，点击从当前 PostMedia 构造 MediaDownloadRequest 并调用 DownloadService.addDownload
- [x] 7.4 写相册前请求相册权限；失败时在 status 中写入 errorMessage，SnackBar 或等价方式提示

## 8. 测试与质量

- [x] 8.1 为 DownloadTaskStateMachine 编写单元测试（状态转换）
- [x] 8.2 为 MediaDownloadRequest 构造与 DownloadTask 生成逻辑编写单元测试（可选）
- [x] 8.3 运行 dart analyze / flutter analyze 确保无新增告警
