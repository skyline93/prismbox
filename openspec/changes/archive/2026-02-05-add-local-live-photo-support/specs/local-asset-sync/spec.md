## ADDED Requirements

### Requirement: Live Photo 属性同步

系统 SHALL 在本地资产表与同步流程中支持 Live Photo 标记（`live_photo_video_id`），并在时间线从数据库或 photo_manager 组装 LocalAsset 时传入该字段，使本地 Live Photo 在网格与查看器中能显示 Live 角标与「播放 Live」入口。

#### Scenario: 表结构包含 live_photo_video_id

- **WHEN** 查看 `local_asset_entity` 表定义
- **THEN** 表 SHALL 包含可空列 `live_photo_video_id`（TEXT）
- **AND** 该列 SHALL 用于存储「本图为 Live Photo」的标记（本地语义为存主图 id，表示 motion 由同一 AssetEntity 提供）

#### Scenario: 同步时写入 Live Photo 标记

- **WHEN** LocalSyncService 执行 _convertToEntity 将 photo_manager 的 AssetEntity 转为 LocalAssetEntityData
- **THEN** 若资产类型为图片且 `asset.isLivePhoto == true`，系统 SHALL 将 `livePhotoVideoId` 设为该资产的 id
- **AND** 否则系统 SHALL 将 `livePhotoVideoId` 设为 null
- **AND** 写入或更新数据库时 SHALL 持久化该字段

#### Scenario: 时间线从数据库组装时传入 livePhotoVideoId

- **WHEN** TimelineProviderService 从数据库读取 localAssetsData 并构建 LocalAsset（_getFromDatabase 或 _getLocalAssetsOnly）
- **THEN** 系统 SHALL 在调用 LocalAsset.fromData 时传入 `livePhotoVideoId: localData.livePhotoVideoId`（或 data.livePhotoVideoId）
- **AND** 以便从数据库数据源展示的本地资产具备正确的 isMotionPhoto 状态

#### Scenario: 时间线从 photo_manager 组装时传入 livePhotoVideoId

- **WHEN** TimelineProviderService 从 photo_manager 的 AssetEntity 转为 LocalAsset（_convertAssetEntityToLocalAsset）
- **THEN** 若资产类型为图片且 `asset.isLivePhoto == true`，系统 SHALL 传入 `livePhotoVideoId: asset.id`
- **AND** 否则系统 SHALL 传入 null（或不传，使用默认 null）
- **AND** 以便使用 photo_manager 数据源时本地 Live Photo 也能显示角标与播放入口
