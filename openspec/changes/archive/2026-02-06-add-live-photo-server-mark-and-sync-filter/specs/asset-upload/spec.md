## ADDED Requirements

### Requirement: Live Photo 视频资产服务端标记

系统 SHALL 在上传 Live Photo 视频文件时由客户端显式标记，服务端在**创建该视频媒体记录时**即将该记录标记为 Live Photo 附属视频（例如写入 `is_live_photo_video`），以便同步与展示层排除该条记录。标记时机为**视频上传时**，不迟于图片上传。

#### Scenario: 上传 Live 视频时客户端携带标记

- **WHEN** 客户端上传 Live Photo 的**视频文件**（即成对上传中的第一个任务）
- **THEN** 客户端 SHALL 在请求中携带约定字段（例如 `is_live_photo_video=1` 或等效命名）
- **AND** 服务端 SHALL 在创建该条视频媒体记录时，根据该字段将 `is_live_photo_video` 设为 true
- **AND** 服务端 SHALL 不在图片上传时再写入或修改视频资产的该字段（该字段仅在视频上传时写入）

#### Scenario: 上传图片时关联维护不变

- **WHEN** 服务端接收到带 `live_photo_video_id` 的图片上传请求
- **THEN** 服务端 SHALL 继续在图片资产上持久化该引用（例如 `live_photo_video_uuid`）
- **AND** 服务端 SHALL 不在此步骤修改视频资产的 `is_live_photo_video` 字段
