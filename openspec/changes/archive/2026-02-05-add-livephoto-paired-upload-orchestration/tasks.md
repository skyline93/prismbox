## 1. Live Photo 上传任务建模

- [x] 1.1 设计并文档化 Live Photo 上传任务元数据结构（参考 Immich `UploadTaskMetadata`）：
  - 需要至少包含：本地资产 ID、是否为 Live Photo、已上传的视频资产远程 ID（可为空）、子任务类型（视频 / 图片）。
  - 明确该元数据与现有 `upload_task_entity` 的关系（附加 JSON 字段或扩展列）。
- [x] 1.2 在任务层面定义 Live Photo 的任务分组与优先级策略：
  - 视频任务所属的备份组（普通组）；
  - 图片任务所属的 Live Photo 高优先级组；
  - 取消与重试对两个子任务的影响范围（例如只取消视频组，不影响已上传的视频对应的图片组）。

## 2. 前台上传（手动 / 前台备份）成对逻辑

- [x] 2.1 分析并记录当前前台上传路径（如 `UploadOrchestrator._executeUpload` 及其调用链）如何处理单一资产。
- [x] 2.2 设计前台上传中 Live Photo 成对处理的调用时序：
  - 从「当前正在处理的本地资产」中识别 Live Photo；
  - 为该资产构造「视频上传步骤」和「图片上传步骤」的顺序调用；
  - 将第一个步骤的响应视频资产 ID 传递给第二个步骤的上传表单字段（`live_photo_video_id`）。
- [x] 2.3 在设计文档中明确失败与重试策略：
  - 视频上传失败：不继续执行图片上传；允许后续重试视频；
  - 视频成功、图片失败：记录「已上传视频、待补图片」状态，允许只重试图片并携带历史视频 ID；
  - 需要与 `asset-upload` 中的 `isUploaded` / `mediaUuids` 语义保持一致。

## 3. 后台上传（自动备份）成对编排

- [x] 3.1 复盘 Immich `BackgroundUploadService` 中关于 Live Photo 的实现方式，总结：
  - 如何为 Live Photo 生成首个「视频上传任务」；
  - 如何在视频任务完成回调中，通过响应 ID 构造第二个「图片上传任务」；
  - 如何通过任务组和优先级控制「先视频后图片，且图片尽快上传」。
- [x] 3.2 在 PrismBox 的备份上传设计中，引入类似的两阶段任务编排：
  - 在备份候选筛选阶段，对 Live Photo 资产生成「视频任务」；
  - 在「视频任务完成」的统一回调处理处，读取响应中的远程 ID，为对应图片资产创建新的上传任务，并附上 `live_photo_video_id` 字段与高优先级组；
  - 确保任务状态机与错误处理器支持这类「派生任务」。
- [x] 3.3 设计并记录后台成对上传的失败与重试策略：
  - 视频任务失败：不生成图片任务；允许后续重试视频任务；
  - 图片任务失败：允许独立重试图片任务（携带同一 `live_photo_video_id`），不再重新上传视频；
  - 确保不会因为重试逻辑产生重复的图片 / 视频资产。
- [x] 3.4 明确并文档化后台上传中 Live Photo 图片任务所属的「最高优先级组」策略，确保：
   - Live Photo 图片任务在所有上传任务中拥有最高调度优先级；
   - 取消操作只影响视频任务组，不影响已生成的 Live Photo 图片最高优先级任务组。

## 4. 与现有上传能力与 Spec 的衔接

- [x] 4.1 对照 `specs/asset-upload/spec.md`，列出所有与 Live Photo 成对上传相关的约束点（去重、`isUploaded`、`UploadResult.mediaUuids` 等），检查成对编排设计是否满足这些约束。
- [x] 4.2 在设计文档中明确：
  - 成对上传对 `UploadResult.mediaUuids` 的影响（是否需要返回两条 UUID，以及如何映射到任务 ID）；
  - 成对上传对 `isUploaded` 字段的更新时机（图片与视频资产在本地的 isUploaded 更新顺序和互相影响）。
- [x] 4.3 如果需要，规划后续为上传能力引入新的 spec 能力（例如「上传任务分组 / 优先级」），并与现有 `asset-upload` spec 做好边界划分。
- [x] 4.4 设计并固化一套 Live Photo 专用上传状态枚举（如 none / uploadingVideo / uploadingPhoto / videoOnlyUploaded / bothUploaded 等），并定义：
  - 该枚举如何从底层视频任务与图片任务状态组合计算得到；
  - 该枚举如何通过 Provider / DTO 等形式向移动端上层暴露，用于驱动 UI 展示；
  - 该枚举如何通过后端 API（例如上传任务状态查询接口）以统一字段对外暴露，保证多端消费一致。

## 5. 验证与后续实现准备

- [x] 5.1 在 proposal 阶段准备至少一份时序图，描述：
  - 前台上传 Live Photo 的完整成功路径；
  - 后台上传 Live Photo 的完整成功路径；
  - 关键失败与重试路径（视频失败 / 图片失败）。
- [x] 5.2 为后续实现阶段列出最小验证用例：
  - 单个 Live Photo 成功上传（前台 / 后台）；
  - 批量 Live Photo 上传，确认队列顺序和优先级行为符合预期；
  - 只上传视频成功 / 只上传图片成功的异常场景，确保最终可以通过补传恢复到「图片 + 视频」完整状态。
- [x] 5.3 完成后运行 `openspec validate add-livephoto-paired-upload-orchestration --strict`，确保本变更在 OpenSpec 层面通过校验，为后续实现铺好路。

## 6. 实现：成对任务编排、严格视频先行与 Live Photo 状态机

- [x] 6.1 定义 Live Photo 任务元数据 DTO 并实现与 `upload_task_entity.livePhotoMetadataJson` 的序列化/反序列化：
  - 字段至少包含：`localAssetId`、`isLivePhoto`、`remoteVideoId`（可选）、`part`（`video` | `image`）；
  - 在创建上传任务时，对 Live Photo 资产生成并写入该元数据；非 Live Photo 任务该字段为空。
- [x] 6.2 在备份候选筛选/任务创建阶段，对 Live Photo 仅创建「视频任务」：
  - 识别本地资产为 Live Photo（如 `localAsset.livePhotoVideoId != null` 或等价标志）；
  - 为该 Live Photo 只创建一条上传任务（视频文件），元数据 `part=video`，不在此阶段创建图片任务。
- [x] 6.3 在「视频任务完成」的统一回调中派生图片任务：
  - 从上传完成响应中解析视频资产远程 ID（如 `uuid`）；
  - 根据任务元数据中的 `localAssetId` 找到对应图片资产；
  - 创建第二条上传任务（图片），表单字段携带 `live_photo_video_id`，元数据 `part=image`、`remoteVideoId` 已填；
  - 将图片任务设为 Live Photo 最高优先级（如 `priority` 数值最小或使用专属组），确保尽快调度。
- [x] 6.4 实现严格的视频先行排序：
  - 在 `UploadOrchestrator` 的排序逻辑中，保证同一 Live Photo 的视频任务优先于其图片任务（如按元数据 `part` 或任务创建时序）；
  - 保证 Live Photo 图片任务组整体优先于普通备份任务（通过 `priority` 或任务组常量）。
- [x] 6.5 实现 Live Photo 专用上传状态枚举与聚合计算：
  - 定义枚举（如 `none`、`uploadingVideo`、`uploadingPhoto`、`videoOnlyUploaded`、`bothUploaded`、`failedVideo`、`failedPhoto`、`failedBoth`）；
  - 在查询某图片资产的上传状态时，根据其关联的视频任务与图片任务状态组合计算该枚举；
  - 通过 Provider、DTO 或现有上传状态接口向 UI 层暴露，供展示与重试决策使用。
- [x] 6.6 实现取消与重试策略：
  - 取消备份组时仅影响视频任务，不取消已派生的 Live Photo 图片任务；
  - 重试仅针对失败任务；重试图片任务时继续携带已有 `remoteVideoId`，不重新上传视频。
- [x] 6.7 前台上传路径的成对处理：
  - 当手动/前台上传识别到 Live Photo 时，先执行视频上传，成功后再执行图片上传并携带返回的视频 ID；
  - 视频失败时不执行图片上传；视频成功、图片失败时允许仅重试图片并携带原 `remoteVideoId`。
- [x] 6.8 单元/集成测试与校验：
  - 覆盖：Live Photo 仅创建视频任务、视频完成后派生图片任务、排序与优先级、状态枚举计算、取消与重试行为；
  - 实现阶段结束后再次运行 `openspec validate add-livephoto-paired-upload-orchestration --strict`。

