## ADDED Requirements

### Requirement: Live Photo 关联字段远程同步

系统 SHALL 在远程资产同步能力中完整同步 Live Photo / Motion Photo 的关联字段，使客户端能够仅通过远程资产数据重建 Live Photo 语义。

#### Scenario: 服务端返回关联字段

- **WHEN** 服务器返回远程资产列表或资产详情
- **THEN** 服务器 SHALL 在图片资产的响应中包含指向 Live Photo 视频资产 ID 的字段（例如 `livePhotoVideoId`）
- **AND** 非 Live Photo 资产的该字段 SHALL 为 `null`
- **AND** 作为 Live Photo 一部分的视频资产响应中不要求反向关联字段（可选实现）

#### Scenario: 客户端写入本地模型

- **WHEN** 客户端执行远程资产同步并解析服务器响应
- **THEN** 客户端 SHALL 读取响应中的 `livePhotoVideoId` 字段
- **AND** 客户端 SHALL 将该字段写入本地远程资产表（例如 `remote_asset_entity.live_photo_video_id`）
- **AND** 客户端 SHALL 不得在同步过程中将该字段强制置为 `null` 或丢弃

#### Scenario: Live Photo 判定与展示前提

- **WHEN** 客户端基于远程资产同步后的本地数据构建时间线或媒体查看器
- **THEN** 客户端 SHALL 以「图片资产 + 非空的 `livePhotoVideoId`」作为 Live Photo / Motion Photo 的判定前提之一
- **AND** 客户端 SHALL 允许后续下载与播放模块基于该字段构造 Live Photo 视频下载与播放请求

