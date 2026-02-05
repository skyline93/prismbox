## 1. 数据层

- [x] 1.1 在 `local_asset_entity` 表定义中增加可空列 `live_photo_video_id`（TextColumn，nullable）
- [x] 1.2 在 `app_database.dart` 的 Drift 迁移中新增对应 migration step（ALTER TABLE local_asset_entity ADD COLUMN live_photo_video_id TEXT NULL），并运行生成代码（build_runner）

## 2. 本地同步

- [x] 2.1 在 `LocalSyncService._convertToEntity` 中，当资产类型为图片且 `asset.isLivePhoto == true` 时，将 `livePhotoVideoId` 设为 `asset.id`，否则设为 null
- [x] 2.2 确保 `LocalAssetEntityData` 构造（及 insert/update）包含 `livePhotoVideoId` 字段，与表结构一致

## 3. 时间线组装

- [x] 3.1 在 `TimelineProviderService._getFromDatabase` 中，从 `localAssetsData` 构建 `LocalAsset.fromData` 时传入 `livePhotoVideoId: localData.livePhotoVideoId`
- [x] 3.2 在 `TimelineProviderService._getLocalAssetsOnly` 中，从 `data` 构建 `LocalAsset.fromData` 时传入 `livePhotoVideoId: data.livePhotoVideoId`
- [x] 3.3 在 `TimelineProviderService._convertAssetEntityToLocalAsset` 中，当 `asset.type == AssetType.image` 且 `asset.isLivePhoto == true` 时传入 `livePhotoVideoId: asset.id`，否则传入 null

## 4. 视频源解析

- [x] 4.1 在 `VideoProvider.getVideoSource` 中，当 `videoIdOverride != null` 且 `asset is LocalAsset` 时，走「本地 Live Photo」分支：不调用 `_getRemoteVideoSource`
- [x] 4.2 获取 `AssetEntity`：优先使用 `(asset as LocalAsset).assetEntity`，若为空则使用 `assetEntityLoader.loadAsync(asset)`；若仍为空则返回 null
- [x] 4.3 通过 AssetEntity 获取 motion 文件：iOS 使用 `originFileWithSubtype`（或当前 photo_manager 等价 API），Android 使用 `loadFile(withSubtype: true)`（或插件文档等价方式），得到 File 后使用其 path 构造 `VideoSource.init(path: ..., type: VideoSourceType.file)`
- [x] 4.4 若获取 motion 文件失败或超时，返回 null，查看器侧已支持「播放失败切回主图」

## 5. 质量与规范

- [x] 5.1 符合项目 Drift 迁移与 local_sync、media_loading 模块规范；新增分支需考虑 Android 上 photo_manager 对 Motion Photo 的支持情况并做注释或降级
- [x] 5.2 运行 `dart analyze` 与现有测试，确保无回归
