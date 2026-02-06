## ADDED Requirements

### Requirement: 远程 Live Photo 视频预览与下载

当媒体查看器播放或下载「仅云端 Live Photo」关联的 Live 视频时，系统 SHALL 使用 `live_photo_video_id` 构造请求：预览播放时优先使用预览视频 URL，不可用时回退到原片 URL；下载时使用原片 URL。

#### Scenario: 远程 Live 预览优先预览回退原片

- **WHEN** 需要播放远程 Live Photo 的 Live 视频（即 asset 为远程且 `livePhotoVideoId` 非空）
- **THEN** 系统 SHALL 优先使用该 ID 请求预览 URL（例如 `.../media/{id}/download/preview`）
- **AND** 若预览返回 4xx 或加载/解码失败，系统 SHALL 回退到原片 URL（例如 `.../media/{id}/download/original`）
- **AND** 系统 SHALL 不在预览不可用时阻塞播放，仅切换为原片继续播放

#### Scenario: 下载 Live Photo 时使用原片

- **WHEN** 用户对远程 Live Photo 执行下载或导出原片
- **THEN** 系统 SHALL 使用 `live_photo_video_id` 请求原片 URL（例如 `.../media/{id}/download/original`）获取 Live 视频文件
- **AND** 系统 SHALL 不在此场景使用预览 URL
