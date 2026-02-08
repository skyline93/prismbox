# post Delta

## ADDED Requirements

### Requirement: 帖子媒体模型包含 Live Photo 视频 ID

客户端帖子媒体模型（PostMedia）SHALL 包含 `livePhotoVideoId` 字段，并从 API 响应的 `live_photo_video_id` 解析；用于帖子预览页下载时构造 MediaDownloadRequest，以支持 Live Photo 整份下载。

#### Scenario: 解析 live_photo_video_id

- **WHEN** 客户端解析 Feed 或帖子详情中的媒体项（PostMedia.fromJson）
- **THEN** 系统 SHALL 读取 `live_photo_video_id` 并写入 PostMedia.livePhotoVideoId
- **AND** 若 API 未返回该字段，livePhotoVideoId SHALL 为 null

### Requirement: 帖子预览页下载入口

帖子媒体预览页（PhotoViewerPage）SHALL 在 AppBar 或等效位置提供下载按钮；用户点击后系统 SHALL 从当前显示的 PostMedia 构造 MediaDownloadRequest 并调用 DownloadService.addDownload，并 SHALL 提示已加入下载队列（如 SnackBar）。

#### Scenario: 点击下载加入队列

- **WHEN** 用户在 PhotoViewerPage 点击下载按钮
- **THEN** 系统 SHALL 使用当前页对应的 PostMedia（media.uuid, media.livePhotoVideoId, itemType, originalFilename/filename）构造 MediaDownloadRequest
- **AND** 系统 SHALL 调用 DownloadService.addDownload(request)
- **AND** 系统 SHALL 向用户提示「已加入下载队列」或等价文案
