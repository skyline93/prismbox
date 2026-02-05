## ADDED Requirements

### Requirement: 本地 Live Photo 视频源解析

当媒体查看器播放「本地 Live Photo」关联的 motion 视频时，系统 SHALL 从本地 AssetEntity 获取 motion 视频文件并作为视频源，而非使用远程 URL。仅当 asset 为 LocalAsset 且存在 videoIdOverride（livePhotoVideoId）时走此分支。

#### Scenario: 本地 Live Photo 使用本地 motion 文件

- **WHEN** VideoProvider.getVideoSource 被调用且 `videoIdOverride != null` 且 `asset is LocalAsset`
- **THEN** 系统 SHALL 不调用远程视频源逻辑（_getRemoteVideoSource）
- **AND** 系统 SHALL 通过 AssetEntity 获取 motion 视频文件（优先使用 asset.assetEntity，若为空则通过 assetEntityLoader.loadAsync(asset) 获取）
- **AND** 系统 SHALL 使用平台约定 API（iOS：如 originFileWithSubtype；Android：如 loadFile(withSubtype: true)）取得 motion 文件路径
- **AND** 系统 SHALL 使用该路径构造并返回 VideoSource.init(path: path, type: VideoSourceType.file)

#### Scenario: 无 AssetEntity 或 motion 文件不可用时降级

- **WHEN** asset 为 LocalAsset 且 videoIdOverride != null，但无法获取 AssetEntity 或 motion 文件获取失败/超时
- **THEN** 系统 SHALL 返回 null（表示视频源不可用）
- **AND** 查看器侧已有逻辑将播放失败时切回静态主图并重置 isPlayingMotionVideoProvider，不阻塞用户浏览
