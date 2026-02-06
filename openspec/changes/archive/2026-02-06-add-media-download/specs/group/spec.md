# group Delta

## ADDED Requirements

### Requirement: 帖子媒体 API 返回 Live Photo 视频 ID

Feed 与帖子详情等接口返回的帖子媒体列表中，每条媒体项 SHALL 在媒体为 Live Photo 时包含 `live_photo_video_id` 字段（值为关联视频媒体的 UUID），以便客户端在下载该媒体时可将图片与视频一并下载并写回为一条 Live Photo。

#### Scenario: Feed 媒体项含 live_photo_video_id

- **WHEN** 后端组装 Feed 或帖子详情的媒体列表（MediaInfo 或等价 DTO）
- **THEN** 若媒体记录的 LivePhotoVideoUUID 非空（即该媒体为 Live Photo 主图），系统 SHALL 在响应中将该字段以 `live_photo_video_id` 暴露给客户端
- **AND** 客户端 SHALL 可据此构造下载请求并执行 Live Photo 双文件下载与写回

#### Scenario: 非 Live Photo 媒体无该字段

- **WHEN** 媒体记录非 Live Photo（LivePhotoVideoUUID 为空）
- **THEN** 响应中该媒体项 MAY 不包含 `live_photo_video_id` 或 SHALL 为 null/省略
- **AND** 客户端 SHALL 按单文件下载处理
