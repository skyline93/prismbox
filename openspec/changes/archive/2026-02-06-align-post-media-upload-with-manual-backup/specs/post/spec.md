## MODIFIED Requirements

### Requirement: 媒体上传集成

系统 SHALL 将帖子发布时的媒体上传与手动备份上传逻辑对齐：使用同一套任务创建（TaskFactory）、同一 remotePath、同一编排（addTasks + orchestrateUpload），以便发布帖子时能上传完整 Live Photo（先视频、再图片并携带 live_photo_video_id）；帖子按选中资产顺序使用「展示用 UUID」列表（displayAssetIdToUuid）组帖。

#### Scenario: 媒体上传流程

- **WHEN** 后台任务进入媒体上传阶段
- **THEN** 系统 SHALL 根据选中的媒体资产 ID（mediaAssetIds）从 LocalAssetDao 获取 LocalAssetEntityData 列表
- **AND** 系统 SHALL 使用与手动备份相同的 remotePath（endpoint + `/api/v1/media/upload-stream`）与 TaskFactory.createTasks 创建上传任务
- **AND** 系统 SHALL 调用 UploadService.addTasks 与 UploadOrchestrator.orchestrateUpload 执行上传
- **AND** 系统 SHALL 跟踪上传进度；上传完成后从编排结果中按「展示用资产 ID」映射（displayAssetIdToUuid）依 mediaAssetIds 顺序得到媒体 UUID 列表
- **AND** 系统 SHALL 将得到的媒体 UUID 列表保存并用于创建帖子
- **AND** 若 displayAssetIdToUuid 不可用，系统 SHALL 可回退到按任务 ID 与初始任务顺序得到 UUID 列表（兼容旧行为）

#### Scenario: 发帖时 Live Photo 完整上传

- **WHEN** 用户选择的媒体中包含 Live Photo（主图资产带 livePhotoVideoId）
- **THEN** 系统 SHALL 通过 TaskFactory 为该资产生成先视频、后图片的成对上传任务（与手动备份一致）
- **AND** 编排器 SHALL 在视频上传完成后派生图片任务并携带 live_photo_video_id
- **AND** 帖子媒体列表中该格 SHALL 使用图片资产的 UUID（展示用），不使用视频资产的 UUID
- **AND** 服务端 SHALL 在接收 Live 视频上传时即写入 is_live_photo_video，不在图片上传时写入或修改该字段

#### Scenario: 媒体上传失败处理

- **WHEN** 媒体上传失败
- **THEN** 系统 SHALL 根据上传服务的重试策略自动重试
- **AND** 系统 SHALL 如果达到最大重试次数仍失败，标记任务为失败
- **AND** 系统 SHALL 保存已成功上传的媒体 UUID（部分成功的情况）
- **AND** 系统 SHALL 允许用户选择重试失败的媒体或取消任务
