## ADDED Requirements

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

