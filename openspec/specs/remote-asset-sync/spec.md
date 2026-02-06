# remote-asset-sync Specification

## Purpose
TBD - created by archiving change decouple-local-remote-assets. Update Purpose after archive.
## Requirements
### Requirement: 远程资产同步

系统 SHALL 提供远程资产同步功能，从服务器同步远程媒体资源到本地数据库。远程资产同步 SHALL 完全独立于本地资产同步，不进行任何关联。

#### Scenario: 流式同步
- **WHEN** 执行远程资产同步
- **THEN** 系统 SHALL 使用流式 API 从服务器获取资产列表
- **AND** 系统 SHALL 支持全量同步（reset=true）和增量同步（updatedAfter）
- **AND** 系统 SHALL 批量写入数据库（每批 100 个）
- **AND** 系统 SHALL 处理删除事件（软删除）
- **AND** 系统 SHALL 在增量同步时接收并处理 `asset_delete_v1` 事件
- **AND** 系统 SHALL 在收到删除事件后更新本地数据库的 `deletedAt` 字段

#### Scenario: 删除事件同步
- **WHEN** 服务器上有资产被软删除（deleted=true）
- **AND** 执行增量同步（updatedAfter 时间点之后）
- **THEN** 服务器 SHALL 查询在时间范围内被软删除的资产
- **AND** 服务器 SHALL 发送 `asset_delete_v1` 事件，包含已删除资产的ID列表
- **AND** 客户端 SHALL 收到删除事件后调用 `softDeleteAsset` 更新本地数据库
- **AND** 客户端 SHALL 设置 `deletedAt` 字段为当前时间

#### Scenario: 永久删除事件同步
- **WHEN** 服务器上有资产被永久删除（PurgeMedia）
- **AND** 该资产之前未被软删除（deleted=false）
- **THEN** 服务器 SHALL 在永久删除前发送 `asset_delete_v1` 事件
- **AND** 客户端 SHALL 收到删除事件后更新本地数据库
- **AND** 如果资产之前已被软删除（deleted=true），服务器 SHALL 不发送删除事件（其他设备应该已经收到）

#### Scenario: 独立于本地资产
- **WHEN** 执行远程资产同步
- **THEN** 系统 SHALL 不查询本地资产表
- **AND** 系统 SHALL 不进行 checksum 匹配
- **AND** 系统 SHALL 不建立远程-本地资产关联
- **AND** 远程资产 SHALL 包含服务器计算的 checksum（用于后端去重）

#### Scenario: 数据源选择
- **WHEN** 选择时间线数据源
- **THEN** 系统 SHALL 检查是否有远程资产
- **AND** 如果存在远程资产，系统 SHALL 使用数据库数据源（需要合并显示）
- **AND** 如果不存在远程资产，系统 SHALL 根据本地资产数量选择数据源

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

