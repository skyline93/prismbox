# Change: 媒体资源统一后台下载

## Why

用户需要从「照片页时间线」和「圈子帖子」预览中下载远程媒体原图/原片到本地相册；下载应在后台执行（与上传一致），且对 Live Photo 下载后仍以一条 Live Photo 写回相册，而非拆成独立照片与视频。当前无统一下载管道与任务持久化，需新增与上传架构对齐的后台下载能力。

## What Changes

- 新增**媒体下载**能力（media-download）：统一下载请求抽象、下载任务表与状态机、DownloadService/DownloadOrchestrator/DownloadTaskManager，使用 `background_downloader` 独立 group 执行下载，完成后写相册（saveImage/saveVideo/saveLivePhoto）。
- **后端**：Feed/帖子媒体 API 返回的每条媒体 SHALL 包含 `live_photo_video_id`（当媒体为 Live Photo 时），以便客户端下载时保存为 Live Photo。
- **帖子**：帖子媒体模型（PostMedia）解析 `live_photo_video_id`；帖子预览页（PhotoViewerPage）提供下载按钮，点击后将当前媒体加入统一下载队列。
- **媒体查看器**：MediaViewerPage 控制栏提供下载按钮，仅当当前资产为远程（remoteId 非空）时可用，点击后将当前资产加入统一下载队列。

## Impact

- Affected specs: **media-download**（新增）、**group**、**post**、**media-viewer**
- Affected code:
  - Mobile: 新增 `lib/services/download/`（或 `lib/services/backup/` 下下载相关）、`lib/data/database/tables/download_task_entity.dart`、DAO/枚举；`ViewerControlsBar`、`PhotoViewerPage`、PostMedia 模型
  - Backend: `internal/service/group/service.go` 中 MediaInfo 构建处增加 `LivePhotoVideoID` 赋值
