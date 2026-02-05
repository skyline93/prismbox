# asset-upload Specification

## Purpose
TBD - created by archiving change decouple-local-remote-assets. Update Purpose after archive.
## Requirements
### Requirement: 资产上传

系统 SHALL 提供资产上传功能，将本地资产上传到服务器。上传功能 SHALL 基于 `isUploaded` 字段进行去重，不依赖 checksum 关联。上传完成后，系统 SHALL 通过 `orchestrateUpload` 的返回值提供媒体 UUID，确保调用方可以立即获取 UUID 而不需要轮询数据库。

#### Scenario: 上传前过滤
- **WHEN** 准备上传资产列表
- **THEN** 系统 SHALL 查询本地资产表的 `isUploaded` 字段
- **AND** 系统 SHALL 过滤掉 `isUploaded = true` 的资产
- **AND** 系统 SHALL 只对未上传的资产创建上传任务
- **AND** 系统 SHALL 不计算文件 hash（由后端计算）

#### Scenario: 上传执行
- **WHEN** 执行上传任务
- **THEN** 系统 SHALL 将文件上传到服务器
- **AND** 系统 SHALL 不在前端计算文件 hash
- **AND** 后端 SHALL 接收文件后计算 hash
- **AND** 后端 SHALL 检查 hash 是否已存在（秒传判断）

#### Scenario: 上传成功处理
- **WHEN** 上传任务状态变为 `completed`
- **THEN** 系统 SHALL 更新本地资产的 `isUploaded = true`
- **AND** 系统 SHALL 确保更新操作的原子性
- **AND** 系统 SHALL 处理更新失败的情况（记录日志但不阻塞流程）
- **AND** 秒传成功也 SHALL 视为上传成功
- **AND** 系统 SHALL 从上传响应中提取媒体 UUID 并存储到数据库
- **AND** 系统 SHALL 在 `orchestrateUpload` 返回前，确保 UUID 已存储完成（等待最多 1 秒）

#### Scenario: 上传结果返回
- **WHEN** `orchestrateUpload` 方法完成
- **THEN** 系统 SHALL 返回 `UploadResult` 对象
- **AND** `UploadResult` SHALL 包含 `mediaUuids` 字段（`Map<String, String>?`，可选）
- **AND** `mediaUuids` 的键 SHALL 为任务 ID（`taskId`），值 SHALL 为媒体 UUID（`mediaUuid`）
- **AND** 系统 SHALL 确保返回时所有成功任务的 UUID 已存储完成
- **AND** 如果 UUID 存储超时（1 秒后仍无 UUID），系统 SHALL 抛出异常
- **AND** 对于不需要 UUID 的场景（如备份上传），`mediaUuids` 可以为空

#### Scenario: 上传失败处理
- **WHEN** 上传任务失败、取消或暂停
- **THEN** 系统 SHALL 保持 `isUploaded = false`
- **AND** 系统 SHALL 允许重试上传
- **AND** 系统 SHALL 不更新 `isUploaded` 字段

#### Scenario: 多设备上传
- **WHEN** 设备A已上传资产，设备B也有相同资产
- **THEN** 设备B SHALL 可以创建上传任务（`isUploaded = false`）
- **AND** 后端 SHALL 通过 hash 检测到重复文件
- **AND** 后端 SHALL 返回秒传成功（不存储重复文件）
- **AND** 设备B SHALL 收到成功响应后设置 `isUploaded = true`

#### Scenario: 并发上传控制
- **WHEN** 创建上传任务
- **THEN** 系统 SHALL 检查资产的 `isUploaded` 状态
- **AND** 如果 `isUploaded = true`，系统 SHALL 跳过创建任务
- **AND** 如果已有进行中的上传任务，系统 SHALL 不创建新任务
- **AND** 系统 SHALL 使用数据库唯一约束防止重复任务

### Requirement: Live Photo 资产成对上传与关联维护

系统 SHALL 在资产上传能力中显式支持 Live Photo / Motion Photo，将其视为由「一张主图（图片资产）+ 一段短视频（视频资产）」组成的**成对资产**，并在服务端维护两者之间的关联关系。

#### Scenario: 识别 Live Photo 资产

- **WHEN** 上传模块遍历本地待上传资产
- **THEN** 系统 SHALL 能够基于本地模型和平台能力识别 Live Photo / Motion Photo（例如 `isLivePhoto` / `isMotionPhoto`）
- **AND** 系统 SHALL 将该资产拆解为两个上传单元：图片文件和视频文件
- **AND** 若无法获取视频文件，系统 SHALL 记录错误并按约定降级为普通图片上传

#### Scenario: 前台上传成对处理

- **WHEN** 前台上传服务（如手动备份、前台自动备份）处理 Live Photo 资产
- **THEN** 系统 SHALL 在一次上传流程中依次上传视频文件与图片文件
- **AND** 系统 SHALL 在上传 Live Photo 图片文件时，在请求字段中携带指向视频资产的标识字段（例如 `livePhotoVideoId`）
- **AND** 服务端 SHALL 基于该字段在图片资产上维护指向视频资产 ID 的关联

#### Scenario: 后台上传成对处理

- **WHEN** 后台上传服务为 Live Photo 创建上传任务
- **THEN** 系统 SHALL 为每个 Live Photo 创建两个独立的上传任务：第一个任务上传视频文件，第二个任务上传图片文件
- **AND** 系统 SHALL 在第一个任务成功完成并从响应中获得视频资产 ID 后，构造第二个任务
- **AND** 第二个任务 SHALL 在上传图片文件时携带该视频资产 ID（例如字段 `livePhotoVideoId`）
- **AND** 系统 SHALL 使用上传任务分组与优先级，保证第二个任务在视频上传完成后尽快执行

#### Scenario: 服务端关联维护

- **WHEN** 服务端接收到带有关联字段（例如 `livePhotoVideoId`）的图片上传请求
- **THEN** 服务端 SHALL 校验该字段引用的视频资产是否存在
- **AND** 如引用存在，服务端 SHALL 在图片资产记录上持久化该引用（例如写入 `livePhotoVideoId` 列）
- **AND** 如引用不存在或不可用，服务端 SHALL 记录错误并按约定降级（例如忽略该字段或返回客户端可识别的错误）

#### Scenario: 失败与重试

- **WHEN** Live Photo 的图片或视频上传任务失败、取消或暂停
- **THEN** 系统 SHALL 不将对应本地资产标记为完全上传完成
- **AND** 系统 SHALL 允许仅重试失败的一侧（仅视频或仅图片），并在重试成功后补齐关联字段
- **AND** 对于仅成功上传视频而图片未上传的场景，服务端 SHALL 保留视频资产，允许后续补充图片并完成关联

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

