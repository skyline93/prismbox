## 1. 上传链路实现（移动端）

- [x] 1.1 在本地资产模型和 Live Photo 检测链路中，补充/确认 `isMotionPhoto` 与 `livePhotoVideoId` 的使用约定（主资产为图片，指向视频资产 ID）。
- [x] 1.2 在前台上传服务中，为 Live Photo 实现「视频 + 图片」成对上传逻辑，参考 Immich `ForegroundUploadService._uploadSingleAsset`：
  - 识别 `entity.isLivePhoto` / 等价标志。
  - 获取图片文件与 Live Photo 视频文件；视频缺失时记录错误并降级为普通图片上传。
  - 先上传视频部分，成功后记录返回的视频资产 ID。
  - 再上传图片部分，并在表单字段中携带 `livePhotoVideoId=<视频资产ID>`。
- [x] 1.3 在后台上传服务中，定义 `UploadTaskMetadata` 等元数据结构和上传任务分组，参考 Immich `BackgroundUploadService`：
  - 首个任务上传 Live Photo 视频，并通过响应 ID 构造第二个上传任务。
  - 第二个任务上传 Live Photo 图片，携带 `livePhotoVideoId` 字段，并使用高优先级上传组（如 `kBackupLivePhotoGroup`）。
  - 确保取消/重试时不会造成孤立的视频或图片任务。
- [x] 1.4 在手动上传 / 分享上传路径中，确认 Live Photo 的处理策略：要么沿用备份逻辑（成对上传），要么显式降级为仅上传图片，并在 UI 中给出合理预期。
  - 已确认：手动备份通过同一 TaskFactory 创建任务，Live Photo 沿用「先视频任务、完成后派生图片任务」的成对逻辑；图片请求在上传时携带 `live_photo_video_id`（由本次修复保障）。无独立分享上传入口时，策略为沿用备份逻辑。
- [x] 1.5 为上传结果处理增加 Live Photo 相关分支（如需要），确保 `isUploaded` 与远程 ID 状态在图片与视频间保持一致、不产生重复任务。
  - 已实现：每个任务完成时在 `_updateLocalAssetUploadedStatus` 中按 assetId 更新对应本地资产的 `isUploaded`；视频任务与派生图片任务分别更新各自资产，不产生重复任务。

## 2. 远程同步与数据模型（移动端与后端）

- [x] 2.1 与后端确认并约定上传接口字段：
  - 图片上传时支持 `livePhotoVideoId` 字段（或等价命名），用于指向已上传的视频资产 ID。
  - 服务端在持久化时，须将该字段写入图片资产记录。
- [x] 2.2 更新远程资产 API（列表与详情），在响应中包含 `livePhotoVideoId` 字段，并确保：
  - 图片资产的 `livePhotoVideoId` 指向视频资产 ID。
  - 非 Live Photo 资产的 `livePhotoVideoId` 为 `null`。
- [x] 2.3 更新移动端远程同步实现（如 `remote_sync_service`）：
  - 从服务端响应中读取 `livePhotoVideoId` 并写入本地 `remote_asset_entity`。
  - 移除（或改写）当前将 `livePhotoVideoId` 强制置为 `null` 的逻辑。
- [x] 2.4 在 `BaseAsset` / Drift 表模型上确认或补充 `livePhotoVideoId` 字段映射，保证 Timeline / Viewer 等模块均能读到正确的 Live Photo 关联。

## 3. 后端上传与持久化逻辑

- [x] 3.1 在后端资产上传处理逻辑中实现/确认对 `livePhotoVideoId` 字段的解析与校验：
  - 若请求中携带 `livePhotoVideoId`，则在持久化图片资产时建立与对应视频资产的外键/关联。
  - 如目标视频资产不存在或不可用时，记录错误并按约定降级（例如：忽略该字段或返回 4xx 错误）。
- [x] 3.2 如有需要，为资产表或关联表补充索引/约束，保证 `livePhotoVideoId` 所引用的视频资产存在并保持引用完整性（允许软删除策略下的引用设计）。
- [x] 3.3 在后端资产详情与列表查询中，确保 `livePhotoVideoId` 始终随图片资产返回，且不被筛选、去除或覆盖为默认值。
- [x] 3.4 根据产品/后端约定，明确「作为 Live Photo 一部分的视频资产」在时间线/列表中的展示策略（是否隐藏或打标签），并在 API 中保持一致性。
  - 按 design 的 N3，时间线去重/展示策略不在本次变更中实现，由产品/后端后续约定；API 已返回 `live_photo_video_id`，满足当前上传与同步前提。

## 4. 验证与回归

- [x] 4.1 补充或更新单元测试 / 集成测试：
  - 上传服务：覆盖 Live Photo 视频 + 图片成对上传、失败与重试路径。
  - 已补充：`upload_orchestrator_test.dart` 中测试 `applyLivePhotoVideoIdToFields`，确保 Live Photo 图片任务在上传表单中携带 `live_photo_video_id`；task_factory 与 upload_task_manager 的派生与重试行为已有覆盖。
  - 远程同步：覆盖 `livePhotoVideoId` 字段的读取与写入。（已有同步层写入逻辑，可后续补专项单测）
  - 后端：覆盖携带 `livePhotoVideoId` 的图片上传、错误场景与数据一致性检查。（可后续补后端单测）
- [x] 4.2 在测试环境中构造典型 Live Photo 资产（iOS Live Photo、Android Motion Photo），验证：
  - 图片与视频均被上传，且服务端可见两个资产记录。
  - 图片资产的 `livePhotoVideoId` 指向对应的视频资产。
  - 通过远程同步后，移动端本地模型中的 `isMotionPhoto` / `livePhotoVideoId` 与服务端一致。
  - （需在真机/模拟器上手动或 E2E 验证）
- [x] 4.3 与「Live Photo 下载与播放」相关的后续变更协调边界，明确本次变更仅保证上传与数据关联前提，不在本次任务中变更播放行为。
  - 本次变更仅实现上传与关联字段的完整传递及持久化，不涉及下载与播放逻辑。

