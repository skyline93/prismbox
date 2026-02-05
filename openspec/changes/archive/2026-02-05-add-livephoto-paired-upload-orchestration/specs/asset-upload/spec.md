## ADDED Requirements

### Requirement: Live Photo 成对上传队列编排

系统 SHALL 在资产上传能力中，为 Live Photo / Motion Photo 提供与 Immich 一致的「先上传视频，再自动排队上传图片并携带返回 ID」的成对上传队列编排。

#### Scenario: Live Photo 上传任务拆分

- **WHEN** 上传队列发现待上传资产为 Live Photo / Motion Photo
- **THEN** 系统 SHALL 将该资产拆分为两个上传任务：一个用于上传视频文件，一个用于上传图片文件
- **AND** 系统 SHALL 在任务元数据中记录本地资产 ID、是否为 Live Photo 以及子任务类型（视频 / 图片）

#### Scenario: 前台上传先视频再图片

- **WHEN** 前台上传路径处理 Live Photo 资产
- **THEN** 系统 SHALL 首先上传 Live Photo 的视频文件
- **AND** 系统 SHALL 在视频上传成功后，从服务端响应中获取视频资产的远程 ID
- **AND** 系统 SHALL 随后上传 Live Photo 的图片文件
- **AND** 系统 SHALL 在上传图片文件时，将该视频资产远程 ID 通过约定字段（例如 `live_photo_video_id`）携带给服务端

#### Scenario: 后台上传两阶段任务生成

- **WHEN** 后台自动备份为 Live Photo 资产创建上传任务
- **THEN** 系统 SHALL 仅为该资产创建首个视频上传任务
- **AND** 当视频上传任务状态变为完成时，系统 SHALL 从上传响应中读取视频资产远程 ID
- **AND** 系统 SHALL 基于该信息自动生成第二个图片上传任务
- **AND** 系统 SHALL 在图片上传任务的表单字段中携带该视频资产远程 ID（例如字段 `live_photo_video_id`）

#### Scenario: Live Photo 上传任务分组与优先级

- **WHEN** 系统为 Live Photo 生成上传任务
- **THEN** 系统 SHALL 将视频上传任务放入普通备份任务组
- **AND** 系统 SHALL 将图片上传任务放入 Live Photo 专属的最高优先级任务组或等效的最高优先级队列
- **AND** 系统 SHALL 保证在视频任务完成后，图片任务可以尽快被调度执行

#### Scenario: Live Photo 上传失败与重试

- **WHEN** Live Photo 的视频上传任务失败或被取消
- **THEN** 系统 SHALL 不自动创建对应的图片上传任务
- **AND** 系统 SHALL 允许后续仅重试视频上传任务
- **WHEN** Live Photo 的图片上传任务失败或被取消
- **THEN** 系统 SHALL 保留已成功上传的视频资产信息（远程 ID）
- **AND** 系统 SHALL 允许后续仅重试图片上传任务，并在重试时继续携带原有视频资产远程 ID

#### Scenario: Live Photo 上传状态对外暴露

- **WHEN** 上层模块查询某个 Live Photo（图片资产）的上传状态
- **THEN** 系统 SHALL 能够同时提供与该 Live Photo 关联的视频上传状态和图片上传状态
- **AND** 系统 SHALL 能区分「仅视频成功」「仅图片成功」「视频与图片均成功」等典型组合状态
- **AND** 系统 SHALL 在相关后端 API 响应中暴露与 Live Photo 上传状态枚举一致的字段（例如 `livePhotoUploadState` 或等效字段），以便客户端能够基于同一语义解析该状态

#### Scenario: Live Photo 上传状态枚举与组合语义

- **WHEN** 系统计算并对外暴露 Live Photo 上传状态
- **THEN** 系统 SHALL 使用一套有限的、文档化的状态枚举来描述「图片任务 + 视频任务」的组合结果（例如：`none`、`uploadingVideo`、`uploadingPhoto`、`videoOnlyUploaded`、`photoOnlyUploaded`、`bothUploaded`、`failedVideo`、`failedPhoto`、`failedBoth`）
- **AND** 该状态枚举 SHALL 作为队列内部的聚合视图存在（底层仍使用通用任务状态驱动），不得以「自由文本」或未约束的字符串替代
- **AND** 服务端 SHALL 在上传结果、任务状态查询或资产状态 API 中使用与该枚举完全一致的取值集合（或可一一映射的值域），以保证多端对 Live Photo 上传状态的解析语义一致