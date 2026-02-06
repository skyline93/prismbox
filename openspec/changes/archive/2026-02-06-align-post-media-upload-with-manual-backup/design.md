# Design: 发布帖子媒体上传与手动上传对齐

## Context

- 手动备份：BackupService 用 TaskFactory.createTasks(assets, …) 建任务，Live Photo 会生成「先视频」任务，编排器在视频完成后派生图片任务并带 live_photo_video_id；remotePath 为 endpoint + `/api/v1/media/upload-stream`。
- 帖子发布：PostTaskManager 当前按 mediaPaths 手造 UploadTaskEntityData，无 livePhotoMetadata，故只上传主图；且用 result.mediaUuids 按 taskId 顺序取 UUID，无法区分 Live Photo 的「展示用」为图片 UUID。
- 服务端：`is_live_photo_video` 已在规范中约定为「视频上传时写入、图片上传时不修改」；本方案不改变该约定。

## Goals / Non-Goals

- **Goals**：发帖时选中 Live Photo 能上传完整成对（视频+图片并关联）；帖子与手动备份共用同一套任务创建、remotePath、addTasks、orchestrateUpload；帖子侧能按选中顺序拿到「每格展示用 UUID」（Live Photo 为图片 UUID）。
- **Non-Goals**：不改变备份或帖子 API 的对外接口；不改变服务端 is_live_photo_video 的写入时机（仍为视频上传时）。

## Decisions

- **复用 TaskFactory + 同一 remotePath**：PostTaskManager 依赖 TaskFactory 与 ApiConfig（或 ApiService）以构造与 BackupService 相同的 remotePath；_uploadMedia 内用 mediaAssetIds 查 LocalAssetEntity 列表，调用 TaskFactory.createTasks(assets, userId, remotePath, manual, priority 1)，再 addTasks + orchestrateUpload。这样 Live Photo 自动走「先视频、后派生图片」逻辑。
- **displayAssetIdToUuid**：在 UploadResult 中新增可选字段 `Map<String, String>? displayAssetIdToUuid`。编排器在任一任务完成时，若该任务为「展示用」（非 Live Photo 即 task.assetId；Live Photo 仅 part==image 时，展示用为 task.assetId），则写入 displayAssetIdToUuid[displayAssetId] = mediaUuid。帖子侧按 mediaAssetIds 顺序从该 map 取 UUID 组成列表；手动备份不依赖此字段。
- **服务端 is_live_photo_video**：保持「仅在上传 Live 视频时写入」；不在图片上传时写入或修改该字段。若当前实现存在在图片上传时写入的情况，需改为仅在视频上传并创建视频媒体记录时写入。

## Risks / Trade-offs

- 帖子与手动备份共用同一上传队列与编排，若队列中有大量备份任务，发帖任务可能排队；当前手动备份已是高优先级，帖子任务同样使用 manual + 高优先级，可接受。
- displayAssetIdToUuid 为可选，旧版或未实现时帖子可回退到按 taskId 顺序取 UUID（此时 Live Photo 仍不完整），保证兼容。

## Migration Plan

- 无数据迁移。部署后发帖选 Live Photo 即走新逻辑；已有帖子不受影响。

## Open Questions

- 无。
