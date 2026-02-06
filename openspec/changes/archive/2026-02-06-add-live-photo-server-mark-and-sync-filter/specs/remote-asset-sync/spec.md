## ADDED Requirements

### Requirement: Live Photo 视频资产不同步

系统 SHALL 在远程资产同步流中排除「Live Photo 附属视频」媒体记录，仅同步 Live 照片（图片）记录，使客户端时间线仅显示一张 Live Photo。

#### Scenario: 服务端同步流排除 Live 视频记录

- **WHEN** 服务端生成流式同步（如 asset_v1）的资产列表
- **THEN** 服务端 SHALL 排除满足「item_type 为 video 且 is_live_photo_video 为 true」的媒体记录
- **AND** 服务端 SHALL 仅返回 Live 照片（图片）记录，并在该记录中保留 `live_photo_video_id` 字段
- **AND** 客户端 SHALL 不会收到 Live 附属视频的独立资产事件，因此不会在时间线中创建对应的远程资产条目

#### Scenario: 客户端仅写入收到的 Live 照片记录

- **WHEN** 客户端处理同步流中的资产事件
- **THEN** 客户端 SHALL 仅对收到的资产记录写入本地远程资产表
- **AND** 由于服务端已排除 Live 视频记录，客户端 SHALL 不拥有「仅云端 Live 视频」的远程资产记录
- **AND** 客户端 SHALL 继续将图片资产上的 `livePhotoVideoId` 写入 `remote_asset_entity.live_photo_video_id`，用于预览与下载
