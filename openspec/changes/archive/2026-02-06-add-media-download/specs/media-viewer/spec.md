# media-viewer Delta

## ADDED Requirements

### Requirement: 媒体查看器下载按钮

媒体查看器（MediaViewerPage）SHALL 在控制栏（ViewerControlsBar）的 AppBar actions 中提供下载按钮；仅当当前资产为远程资源（asset.remoteId 非空）时该按钮 SHALL 可用或显示。用户点击后系统 SHALL 从当前 BaseAsset 构造 MediaDownloadRequest 并调用 DownloadService.addDownload，并 SHALL 提示已加入下载队列。

#### Scenario: 远程资产显示下载并加入队列

- **WHEN** 当前页对应资产满足 asset.remoteId != null
- **THEN** 系统 SHALL 显示下载按钮（如 Icons.download）
- **AND** 用户点击后系统 SHALL 使用 mediaUuid=asset.remoteId、livePhotoVideoUuid=asset.livePhotoVideoId、itemType、filename 构造 MediaDownloadRequest（sourceType=timeline_asset, sourceId=assetId）
- **AND** 系统 SHALL 调用 DownloadService.addDownload(request)
- **AND** 系统 SHALL 向用户提示「已加入下载队列」或等价文案

#### Scenario: 仅本地资产不提供下载

- **WHEN** 当前页对应资产无远程 ID（asset.remoteId 为空，仅本地存在）
- **THEN** 系统 SHALL 不显示下载按钮或 SHALL 将下载按钮置为不可用
- **AND** 不调用 DownloadService.addDownload（原图已在本地，无需从服务器下载）
