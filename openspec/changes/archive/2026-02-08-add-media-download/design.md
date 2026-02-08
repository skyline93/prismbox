# Design: 媒体资源统一后台下载

## Context

- 上传侧已有完整管道：UploadTaskEntity、UploadTaskManager（background_downloader 上传）、UploadService、UploadOrchestrator、状态机；下载需与其对齐，使用同一底层库、独立 task group，并增加「下载完成后写相册」的后处理。
- 两处入口：照片页（MediaViewerPage，数据为 BaseAsset）与帖子预览（PhotoViewerPage，数据为 PostMedia），需统一为同一请求抽象（MediaDownloadRequest）和同一 DownloadService.addDownload 管道。
- Live Photo：服务端以「图片媒体 + live_photo_video_id 指向视频媒体」表示；下载时需请求两个 original URL，两个文件都完成后调用 PhotoManager.editor.darwin.saveLivePhoto 写回相册。

## Goals / Non-Goals

- **Goals**：后台执行、任务持久化与状态可观测、统一时间线与帖子两处入口、仅下载 origin、Live Photo 整份保存。
- **Non-Goals**：本提案不包含「下载队列」设置页入口（可后续迭代）；Android 上 Live Photo 写回可为降级（仅保存图片）。

## Decisions

- **独立 group**：下载使用 `prismbox_download`，与 `prismbox_upload_manual` / `prismbox_upload_auto` 分开，避免回调与上传混在一起。
- **1 条 DB 记录 = 1 个用户可见下载**：普通媒体 1 个 DownloadTask，Live Photo 1 条 DownloadTaskEntity 对应 2 个 DownloadTask（image + video），回调中两文件都完成后触发后处理（saveLivePhoto）。
- **后处理在 status 回调中执行**：下载完成后在 main isolate 中调用 PhotoManager.editor.saveImage/saveVideo/saveLivePhoto，再删临时文件、更新状态为 completed/failed。
- **帖子媒体 API 返回 live_photo_video_id**：与 sync 一致，便于帖子预览页构造 MediaDownloadRequest 并走同一套 Live Photo 双文件下载与写回。

## Risks / Trade-offs

- **写相册权限**：后处理前需确保已请求相册/存储权限，失败时写入 errorMessage 并可选提示。
- **大文件**：与上传一致，可配置 background_downloader 大文件前台运行（如已有 runInForegroundIfFileLargerThan）。

## Migration Plan

- 无数据迁移；新表 DownloadTaskEntity 随部署创建。现有 API 仅扩展媒体项字段（live_photo_video_id），向后兼容。

## Open Questions

- 无。
