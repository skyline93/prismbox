## 1. 编排层：上传结果增加 displayAssetIdToUuid

- [x] 1.1 在 `UploadResult` 中增加可选字段 `displayAssetIdToUuid`（`Map<String, String>?`）
- [x] 1.2 在 `orchestrateUpload` 中，每当任务完成且该任务为「展示用」时（非 Live Photo 或 Live Photo 的 image 部分），将 `displayAssetId` -> `mediaUuid` 写入该 map
- [x] 1.3 单元测试：验证 Live Photo 视频任务完成不写入 displayAssetIdToUuid，图片任务完成写入 localAssetId -> uuid；普通任务完成写入 assetId -> uuid

## 2. PostTaskManager：复用 TaskFactory 与同一编排

- [x] 2.1 为 PostTaskManager 注入 TaskFactory 与 endpoint 来源（ApiConfig 或 ApiService）
- [x] 2.2 `_uploadMedia` 中改为用 mediaAssetIds 从 LocalAssetDao 获取 LocalAssetEntityData 列表，使用与 BackupService 相同的 remotePath 构造方式
- [x] 2.3 使用 TaskFactory.createTasks(assets, userId, remotePath, UploadTaskType.manual, priority: 1) 创建任务，替代按 path 手造 UploadTaskEntityData
- [x] 2.4 上传完成后从 result.displayAssetIdToUuid 按 mediaAssetIds 顺序组装 orderedMediaUuids；若 displayAssetIdToUuid 为空则回退到按 result.mediaUuids 与初始任务 assetId 的现有逻辑
- [x] 2.5 校验 orderedMediaUuids.length == mediaAssetIds.length，否则抛错
- [x] 2.6 更新 PostTaskManager 的 Provider/构造处，传入 TaskFactory 与 endpoint 依赖

## 3. 服务端：is_live_photo_video 写入时机（如未满足则改）

- [x] 3.1 确认媒体上传接口在**创建视频媒体记录时**根据请求字段 `is_live_photo_video` 写入 `is_live_photo_video`，且不在接收图片上传时修改视频记录该字段
- [x] 3.2 若当前在图片上传时写入或修改该字段，改为仅在上传 Live 视频并创建该视频记录时写入

## 4. 验证与文档

- [x] 4.1 为 PostTaskManager 或编排层新增/更新单元测试，覆盖 Live Photo 发帖场景下 orderedMediaUuids 为图片 UUID
- [x] 4.2 代码内注释或文档说明发帖媒体上传与手动备份共用 TaskFactory 与编排逻辑
