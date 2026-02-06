# Change: 发布帖子媒体上传与手动上传逻辑对齐（含完整 Live Photo）

## Why

发布圈子帖子时，若用户选择的是 Live Photo，当前实现只上传了主图文件，未上传 Live 视频部分，也未在服务端建立图片与视频的关联，导致帖子里无法展示完整 Live Photo。根因是帖子发布路径未复用「手动备份」的同一套任务创建与编排逻辑（TaskFactory、先视频后图片、live_photo_video_id），而是按路径逐条手造上传任务且无 Live Photo 元数据。将「上传帖子媒体」与「手动上传媒体」逻辑对齐并复用，即可在发帖时上传完整 Live Photo。

## What Changes

- **移动端**：帖子发布任务管理器（PostTaskManager）改为基于选中资产的 LocalAssetEntity 使用 TaskFactory 创建上传任务（与 BackupService 手动备份一致），使用相同 remotePath 与 UploadOrchestrator；编排层在上传结果中增加按「展示用资产 ID」的 UUID 映射（displayAssetIdToUuid），供帖子按选中顺序取每格的展示用 UUID（Live Photo 取图片 UUID）。
- **规范**：资产上传规范增加「上传结果可选的按展示用资产 ID 的 UUID 映射」；帖子规范明确「发帖媒体上传与手动备份共用同一任务创建与编排，且使用 displayAssetIdToUuid 得到有序媒体 UUID」。
- **服务端**：维持现有规范——`is_live_photo_video` 仅在上传 Live **视频**时写入（创建该视频媒体记录时即写入），不在上传图片时写入或修改。

## Impact

- Affected specs: `asset-upload`, `post`
- Affected code: `mobile/lib/services/backup/upload_orchestrator.dart`（UploadResult、orchestrateUpload）, `mobile/lib/services/post/post_task_manager.dart`（_uploadMedia 任务创建与 UUID 收集）, `mobile/lib/providers`（PostTaskManager 注入 TaskFactory 与 endpoint）
