# Change: 本地 Live Photo 支持（方案 B）

## Why

当前仅远程资产在同步后可能带有 `livePhotoVideoId`（且目前被写死为 null 待后端与 remote_sync 修复）；本地资产在 `local_asset_entity` 表无 `live_photo_video_id` 列，且本地同步与时间线组装均未写入或传递该字段，导致时间线使用「数据库」或「photo_manager」数据源时，本地 Live Photo 的 `isMotionPhoto` 恒为 false，角标与「播放 Live」按钮不显示。本变更按方案 B 在本地表持久化 Live Photo 标记，并在同步、时间线与视频源解析全链路支持本地 Live Photo 预览。

## What Changes

- **数据层**：在 `local_asset_entity` 表增加可空列 `live_photo_video_id`（TEXT），通过 Drift 迁移生效；本地同步（`_convertToEntity`）在资产为图片且 `AssetEntity.isLivePhoto == true` 时写入该列（语义：存本图 id，表示 motion 由同一 AssetEntity 提供）。
- **时间线组装**：从数据库构建 `LocalAsset` 时传入 `livePhotoVideoId: localData.livePhotoVideoId`；从 photo_manager 构建 `LocalAsset`（`_convertAssetEntityToLocalAsset`）时，当 `asset.isLivePhoto == true` 传入 `livePhotoVideoId: asset.id`，使两种数据源下本地 Live Photo 均带 `isMotionPhoto`。
- **视频源解析**：在 `VideoProvider.getVideoSource` 中，当 `videoIdOverride != null` 且 `asset is LocalAsset` 时，视为本地 Live Photo，通过 `AssetEntity.originFileWithSubtype`（iOS）或 `loadFile(withSubtype: true)`（Android）获取 motion 视频文件路径并返回本地 `VideoSource`，不再走远程 URL。
- **依赖**：与 add-live-photo-preview 的 UI（角标、播放按钮、查看器切换）无冲突，仅补齐本地数据与播放源。

## Impact

- **Affected specs**: `local-asset-sync`（表结构、同步写入、时间线从 DB/photo_manager 传入 livePhotoVideoId）, `media-viewer`（本地 Live Photo 视频源从 AssetEntity 获取）
- **Affected code**: `lib/data/database/tables/local_asset_entity.dart`、`lib/data/database/app_database.dart`（迁移）、`lib/features/local_sync/services/local_sync_service.dart`（_convertToEntity）、`lib/features/local_sync/services/timeline_provider_service.dart`（_getFromDatabase、_getLocalAssetsOnly、_convertAssetEntityToLocalAsset）、`lib/features/media_loading/video_provider.dart`（本地 motion 文件分支）
