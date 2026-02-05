# Change: 为 Live Photo 提供成对上传队列编排（先视频后图片，自动携带关联 ID）

## Why

当前 PrismBox 仅在上传表单字段中，支持在图片上传时携带 `live_photo_video_id` 来建立图片与视频的关联，但：

- 上传队列仍然将 Live Photo 当作「单个文件」处理，没有「视频任务 → 图片任务」的队列级别编排；
- 失败与重试路径没有针对 Live Photo 做成对语义的保障，容易产生「孤立视频」或「孤立图片」；
- 与 Immich 已在生产环境验证的 Live Photo 成对上传流程（BackgroundUploadService + UploadTaskMetadata + 任务分组）存在明显差距。

为了获得与 Immich 一致、可靠的 Live Photo 体验，需要在 PrismBox 的上传队列和编排层引入「先上传视频、再自动排队上传图片并携带上一任务返回 ID」的成对上传逻辑。

## What Changes

- **上传任务建模（自动保证一图一视频成对存在）**
  - 为 Live Photo 引入明确的任务元数据（类似 Immich `UploadTaskMetadata`），区分「视频任务」与「图片任务」，并记录：
    - 本地资产 ID（`localAssetId`）；
    - 是否为 Live Photo（`isLivePhoto`）；
    - 已上传的视频资产远程 ID（`remoteVideoId`，初始为空，仅在视频任务完成后填充）；
    - 当前子任务类型（`part = video | image`）。
  - 在任务层面约定 Live Photo 的两个子任务如何分组（普通备份组 + Live Photo 最高优先级组），以及取消/重试时的行为，保证：
    - 无论前台还是后台路径，Live Photo 的视频与图片最终都会被成对上传；
    - 不会因为重试或取消导致长期「孤立视频」/「孤立图片」而无法补齐。

- **前后台上传编排**
  - 在**前台上传路径**（例如手动选择上传）中：
    - 当识别到 Live Photo 时，依次执行「上传视频 → 解析响应返回的视频资产 ID → 上传图片并携带该 ID」；
    - 失败时确保可以只重试失败部分，并在成功后补齐图片-视频关联。
  - 在**后台上传路径**（自动备份）中：
    - 为每个 Live Photo 生成两条上传任务：第一条上传视频，第二条上传图片；
    - 视频任务完成时，通过回调读取响应中的远程视频资产 ID，为对应图片任务填充 `live_photo_video_id` 字段，并将图片任务加入 Live Photo 专属的最高优先级上传组。

- **上传状态与结果暴露（专用 Live Photo 状态枚举 + API 对外暴露）**
  - 扩展上传结果与状态模型，使上层可以显式获知「某个图片资产对应的 Live Photo 视频上传状态」，例如：
    - 视频与图片是否都已成功上传；
    - 当前正在上传的是视频部分还是图片部分；
    - 哪一部分处于失败或等待重试状态。
  - 为 Live Photo 定义一套专用上传状态枚举（如 `none / uploadingVideo / uploadingPhoto / videoOnlyUploaded / bothUploaded / failedVideo / failedPhoto / failedBoth`），该枚举作为：
    - 队列内部基于「视频任务 + 图片任务」组合计算的聚合视图；
    - 后端上传结果 / 任务状态 / 资产状态 API 中对外暴露的统一字段（例如 `livePhotoUploadState`），供移动端直接消费并映射到本地状态。

- **与现有上传能力的衔接**
  - 保持非 Live Photo 资产现有上传行为不变；
  - 与 `asset-upload` spec 中关于 `isUploaded`、去重、`UploadResult.mediaUuids` 等要求兼容；
  - 确保成对上传逻辑不会破坏当前的队列调度和重试机制。

## Impact

- **Affected specs**
  - `specs/asset-upload/spec.md`
    - ADDED: 「Live Photo 成对上传编排」相关的规范要求（任务建模、顺序、最高优先级 Live Photo 图片任务组、失败与重试行为，以及 Live Photo 成对上传状态枚举及其在 API 层的对外暴露）。
- **Affected code (high level)**
  - 移动端（Flutter / PrismBox）：
    - 上传任务模型：`upload_task_entity` / 任务元数据结构。
    - 上传编排：`UploadOrchestrator`、`UploadTaskManager`、自动备份相关服务。
  - 参考实现（Immich）：
    - `mobile/lib/services/background_upload.service.dart`
    - `mobile/lib/services/foreground_upload.service.dart`
    - `mobile/lib/repositories/upload.repository.dart`

