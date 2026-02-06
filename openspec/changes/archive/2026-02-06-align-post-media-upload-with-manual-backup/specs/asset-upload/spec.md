## ADDED Requirements

### Requirement: 上传结果按展示用资产 ID 的 UUID 映射

系统 SHALL 在编排层上传完成后，可选地提供按「展示用资产 ID」到媒体 UUID 的映射（displayAssetIdToUuid），以便需要按选中资产顺序得到「每格一个展示用 UUID」的调用方（如发布帖子）使用；Live Photo 的展示用为图片资产 ID 对应图片上传后的 UUID，非 Live Photo 为对应任务资产 ID 的 UUID。

#### Scenario: 编排完成时填充 displayAssetIdToUuid

- **WHEN** 上传编排中某个任务完成且该任务为「展示用」任务
- **THEN** 系统 SHALL 将 displayAssetId -> mediaUuid 写入 UploadResult 的 displayAssetIdToUuid 映射
- **AND** 非 Live Photo 任务的展示用资产 ID SHALL 为 task.assetId
- **AND** Live Photo 图片任务（part 为 image）的展示用资产 ID SHALL 为 task.assetId（即主图本地资产 ID）
- **AND** Live Photo 视频任务（part 为 video）SHALL 不写入 displayAssetIdToUuid（视频不单独占展示格）

#### Scenario: 调用方不依赖 displayAssetIdToUuid

- **WHEN** 调用方仅需按任务 ID 获取 UUID（如仅做备份上传）
- **THEN** 系统 SHALL 仍通过 UploadResult.mediaUuids（taskId -> uuid）提供结果
- **AND** displayAssetIdToUuid 为可选字段，可为空或 null
