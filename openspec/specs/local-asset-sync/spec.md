# local-asset-sync Specification

## Purpose
TBD - created by archiving change decouple-local-remote-assets. Update Purpose after archive.
## Requirements
### Requirement: 本地资产同步

系统 SHALL 提供本地资产同步功能，扫描设备媒体库并同步到本地数据库。本地资产同步 SHALL 完全独立于远程资产同步，不进行任何关联。

#### Scenario: 全量同步
- **WHEN** 执行全量同步（首次同步或数据库为空）
- **THEN** 系统 SHALL 扫描所有系统相册资产
- **AND** 系统 SHALL 批量写入数据库（每批 100 个）
- **AND** 系统 SHALL 检测已删除的资产并更新数据库
- **AND** 系统 SHALL 不计算文件 hash（checksum）

#### Scenario: 增量同步
- **WHEN** 执行增量同步（数据库已有数据）
- **THEN** 系统 SHALL 只处理新增/修改/删除的资产
- **AND** 系统 SHALL 通过修改时间快速判断，避免全量对比
- **AND** 系统 SHALL 不计算文件 hash（checksum）

#### Scenario: 上传状态标识
- **WHEN** 同步本地资产到数据库
- **THEN** 系统 SHALL 为每个本地资产维护 `isUploaded` 字段
- **AND** `isUploaded` 字段 SHALL 默认为 `false`
- **AND** `isUploaded` 字段 SHALL 仅在上传成功时更新为 `true`

#### Scenario: 独立于远程资产
- **WHEN** 执行本地资产同步
- **THEN** 系统 SHALL 不查询远程资产表
- **AND** 系统 SHALL 不进行 checksum 匹配
- **AND** 系统 SHALL 不建立本地-远程资产关联

### Requirement: 收藏属性同步

系统 SHALL 在本地资产同步流程中从系统相册读取收藏（favorite）属性，并存储到本地数据库。收藏属性的获取 SHALL 通过原生平台 API 实现，支持 iOS 和 Android 平台。

#### Scenario: iOS 平台获取收藏状态

- **WHEN** 在 iOS 平台执行本地资产同步
- **THEN** 系统 SHALL 通过 PHAsset.isFavorite 属性获取每个资产的收藏状态
- **AND** 系统 SHALL 将收藏状态存储到 LocalAssetEntityData 的 isFavorite 字段
- **AND** 获取失败时系统 SHALL 记录警告日志并默认为 false

#### Scenario: Android 平台获取收藏状态

- **WHEN** 在 Android 平台执行本地资产同步
- **THEN** 系统 SHALL 检测 Android 版本是否为 11 (API 30) 及以上
- **AND** 如果版本支持，系统 SHALL 通过 MediaStore.MediaColumns.IS_FAVORITE 字段查询收藏状态
- **AND** 如果版本不支持（Android 10-），系统 SHALL 默认返回 false
- **AND** 系统 SHALL 将收藏状态存储到 LocalAssetEntityData 的 isFavorite 字段
- **AND** 获取失败时系统 SHALL 记录警告日志并默认为 false

#### Scenario: 原生平台桥接

- **WHEN** 需要获取资产的收藏状态
- **THEN** 系统 SHALL 通过 Pigeon 定义的 AssetNativeApi 接口与原生平台通信
- **AND** 接口 SHALL 提供 getIsFavorite(String assetId) 方法获取单个资产收藏状态
- **AND** 接口 SHALL 提供 getAssetMetadata(List<String> assetIds) 方法批量获取资产元数据（包含收藏状态）
- **AND** 原生实现 SHALL 返回布尔值表示收藏状态
- **AND** 原生实现 SHALL 处理资产不存在等异常情况

#### Scenario: 同步流程集成

- **WHEN** LocalSyncService 执行 _convertToEntity 方法转换资产
- **THEN** 系统 SHALL 调用 AssetNativeApi.getIsFavorite 获取收藏状态
- **AND** 系统 SHALL 将获取的收藏状态赋值给 LocalAssetEntityData.isFavorite 字段
- **AND** 系统 SHALL 在获取失败时默认设为 false 并继续处理
- **AND** 系统 SHALL 记录日志便于调试和监控

#### Scenario: 增量同步中的收藏状态变化检测

- **WHEN** 执行增量同步
- **THEN** 系统 SHALL 为新增或修改的资产获取最新的收藏状态
- **AND** 如果资产的收藏状态与数据库中的不一致，系统 SHALL 更新数据库
- **AND** 系统 SHALL 在日志中记录收藏状态的变化

#### Scenario: 性能优化（批量查询）

- **WHEN** 需要获取多个资产的收藏状态
- **THEN** 系统可选地 SHALL 使用 getAssetMetadata 批量查询接口
- **AND** 批量查询 SHALL 减少跨平台调用次数（每批最多 100 个资产）
- **AND** 系统 SHALL 将批量查询结果映射到对应的资产
- **AND** 性能优化 SHALL 不改变功能语义

#### Scenario: 错误处理

- **WHEN** 获取收藏状态时发生错误（如资产不存在、权限不足）
- **THEN** 系统 SHALL 记录警告日志包含错误信息和资产 ID
- **AND** 系统 SHALL 默认该资产的收藏状态为 false
- **AND** 系统 SHALL 继续处理其他资产，不中断同步流程

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

