# media-download Delta

## ADDED Requirements

### Requirement: 统一下载请求与队列

系统 SHALL 提供统一下载请求抽象（MediaDownloadRequest）与下载服务（DownloadService），使照片页时间线资产与帖子媒体均可通过同一管道加入下载队列；下载 SHALL 在后台执行（使用 background_downloader，独立 group prismbox_download），任务 SHALL 持久化并可观测状态与进度。

#### Scenario: 从时间线资产加入下载

- **WHEN** 用户从媒体查看器（MediaViewerPage）对当前远程资产（asset.remoteId 非空）触发下载
- **THEN** 系统 SHALL 从当前 BaseAsset 构造 MediaDownloadRequest（sourceType=timeline_asset, sourceId=assetId, mediaUuid=remoteId, livePhotoVideoUuid=livePhotoVideoId, itemType, filename）
- **AND** 系统 SHALL 调用 DownloadService.addDownload(request)
- **AND** 系统 SHALL 插入或更新 DownloadTaskEntity（status 初始为 pending），并触发后台下载编排

#### Scenario: 从帖子媒体加入下载

- **WHEN** 用户从帖子预览页（PhotoViewerPage）对当前帖子媒体触发下载
- **THEN** 系统 SHALL 从当前 PostMedia 构造 MediaDownloadRequest（sourceType=post_media, sourceId=media.uuid, mediaUuid=uuid, livePhotoVideoUuid=livePhotoVideoId, itemType, filename）
- **AND** 系统 SHALL 调用 DownloadService.addDownload(request)
- **AND** 系统 SHALL 插入或更新 DownloadTaskEntity（status 初始为 pending），并触发后台下载编排

#### Scenario: 冲突与去重

- **WHEN** DownloadService.addDownload 被调用且已存在同 userId、sourceType、sourceId 且状态为 pending/queued/downloading 的任务
- **THEN** 系统 SHALL 按约定策略处理（跳过或替换），避免重复下载

### Requirement: 下载任务存储与状态机

系统 SHALL 使用 DownloadTaskEntity 表存储每条用户可见的下载任务（普通媒体 1 条对应 1 个文件，Live Photo 1 条对应 2 个文件）；任务状态 SHALL 经 DownloadTaskStateMachine 流转（pending → queued → downloading → processing → completed，或 failed/permanentlyFailed/cancelled）。

#### Scenario: 状态流转

- **WHEN** 任务被创建并入队
- **THEN** 状态 SHALL 可从 pending 转为 queued，再转为 downloading
- **AND** 当 background_downloader 报告完成且无需后处理时，状态 SHALL 转为 completed
- **AND** 当需要写相册时，状态 SHALL 先转为 processing，写相册成功后转为 completed，失败则转为 failed 并记录 errorMessage

#### Scenario: 进度与错误持久化

- **WHEN** background_downloader 触发 progress 或 status 回调
- **THEN** 系统 SHALL 根据 taskId 反查 DownloadTaskEntity 并更新 progress、status、errorMessage、imageTempPath、videoTempPath（若适用）

### Requirement: 后台下载执行与 URL

系统 SHALL 使用 background_downloader 的 DownloadTask、独立 group（prismbox_download）执行下载；下载目标 URL SHALL 为原始资源（/api/v1/media/:uuid/download/original），请求头 SHALL 使用 ApiService.getRequestHeaders() 以携带鉴权。

#### Scenario: 单文件下载

- **WHEN** DownloadTaskEntity 无 livePhotoVideoUuid
- **THEN** 系统 SHALL 创建 1 个 DownloadTask，taskId 与 entity 约定一致（如 entity.id 或 entity.id_image），保存路径为临时目录下约定文件名
- **AND** 系统 SHALL 使用 mediaUuid 拼出 original URL 并 enqueue

#### Scenario: Live Photo 双文件下载

- **WHEN** DownloadTaskEntity 含 livePhotoVideoUuid
- **THEN** 系统 SHALL 创建 2 个 DownloadTask（主图 mediaUuid、视频 livePhotoVideoUuid），taskId 分别带 _image、_video 后缀
- **AND** 两个 DownloadTask 均 SHALL 使用 original URL 并 enqueue 到同一 group
- **AND** 当两个任务均报告完成时，系统 SHALL 将 entity 状态设为 processing 并触发后处理

### Requirement: 下载完成后写相册

下载完成后系统 SHALL 根据任务类型执行后处理：将临时文件写入系统相册（PhotoManager.editor.saveImage/saveVideo），Live Photo SHALL 使用 saveLivePhoto 写回为一条 Live Photo；后处理完成后 SHALL 删除临时文件并更新任务状态。

#### Scenario: 普通图片写相册

- **WHEN** 单文件下载完成且 itemType 为 IMAGE、无 livePhotoVideoUuid
- **THEN** 系统 SHALL 使用 PhotoManager.editor.saveImage 将 imageTempPath 写入相册
- **AND** 系统 SHALL 删除临时文件并将状态更新为 completed

#### Scenario: 普通视频写相册

- **WHEN** 单文件下载完成且 itemType 为 VIDEO
- **THEN** 系统 SHALL 使用 PhotoManager.editor.saveVideo 将视频临时文件写入相册
- **AND** 系统 SHALL 删除临时文件并将状态更新为 completed

#### Scenario: Live Photo 写相册

- **WHEN** Live Photo 两个文件均下载完成（imageTempPath 与 videoTempPath 均已写入）
- **THEN** 系统 SHALL 调用 PhotoManager.editor.darwin.saveLivePhoto(imageFile, videoFile, title)（iOS）；Android 可降级为仅保存图片
- **AND** 系统 SHALL 删除两个临时文件并将状态更新为 completed
- **AND** 下载结果 SHALL 为一条 Live Photo，而非独立照片与视频

#### Scenario: 写相册失败

- **WHEN** 后处理（saveImage/saveVideo/saveLivePhoto）失败或权限不足
- **THEN** 系统 SHALL 将任务状态更新为 failed，errorMessage SHALL 记录原因
- **AND** 系统 SHALL 清理已存在的临时文件（若适用）
