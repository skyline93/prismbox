## Context

- 本地 Live Photo = 系统相册中「一张主图 + 一段 motion 视频」；photo_manager 的 `AssetEntity` 对同一张图提供 `isLivePhoto` 及获取 motion 文件的 API（如 `originFileWithSubtype` / `loadFile(withSubtype: true)`）。本地没有独立的「视频资产」行，motion 与主图同属一个 AssetEntity。
- 方案 B：在 `local_asset_entity` 持久化 `live_photo_video_id`，使无论时间线数据源为「数据库」还是「photo_manager」，本地 Live Photo 都能带上 `livePhotoVideoId`，从而复用 add-live-photo-preview 的角标与播放入口；播放时由 VideoProvider 从 AssetEntity 取 motion 文件。

## Goals / Non-Goals

- **Goals**: 本地表可存 Live Photo 标记；同步时写入；时间线从 DB 与 photo_manager 组装 LocalAsset 时传入 livePhotoVideoId；查看器内「播放 Live」时使用本地 motion 文件作为视频源。
- **Non-Goals**: 上传/下载 Live Photo、后端 API、远程 sync 的 livePhotoVideoId 解析（另案处理）。

## Decisions

- **本地 `live_photo_video_id` 语义**：存主图资产 id（与 remote 的「视频资产 UUID」区分）。表示「该行为 Live Photo，motion 由同一 AssetEntity 提供」；播放时用该 id 通过 AssetEntity 取 motion 文件。
- **同步写入时机**：在 `LocalSyncService._convertToEntity` 中，当 `asset.type == AssetType.image` 且 `asset.isLivePhoto == true` 时设置 `livePhotoVideoId: asset.id`，否则为 null。与收藏状态写入方式一致。
- **VideoProvider 分支**：当 `videoIdOverride != null` 且 `asset is LocalAsset` 时，不调用 `_getRemoteVideoSource`；优先使用 `asset.assetEntity`，若为空则通过 `assetEntityLoader.loadAsync(asset)` 获取；再通过平台 API（iOS: `originFileWithSubtype`，Android: `loadFile(withSubtype: true)`）取 motion 文件路径，构造 `VideoSource.init(path: ..., type: VideoSourceType.file)`。
- **平台差异**：iOS 以 `AssetEntity.isLivePhoto` + `originFileWithSubtype` 为准；Android 以 photo_manager 提供的 isLivePhoto / Motion Photo 及 `loadFile(withSubtype: true)` 为准，若插件无则仅支持 iOS。
- **迁移**：新增可空列，无数据迁移；已有行 `live_photo_video_id` 为 null。

## Risks / Trade-offs

- **性能**：同步时多一次 `isLivePhoto` 读取（若为同步调用），需确认 photo_manager 该属性是否轻量；若重可考虑异步或批量。
- **Android 差异**：Motion Photo 形态因厂商而异，若 photo_manager 未统一暴露 isLivePhoto/motion 文件，Android 可能仅部分设备生效，需在任务中注明。

## Migration Plan

- Drift 迁移：`ALTER TABLE local_asset_entity ADD COLUMN live_photo_video_id TEXT NULL;`（或 Drift 等效）。无回填；新同步与后续增量同步会写入新字段。

## Open Questions

- 无；与《Live Photo 支持模块详细设计文档》及方案 B 一致。
