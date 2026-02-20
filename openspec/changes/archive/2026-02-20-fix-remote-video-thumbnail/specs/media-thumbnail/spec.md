# media-thumbnail (delta)

## ADDED Requirements

### Requirement: 资产缩略图接口对视频可返回图片

系统 SHALL 使 `GET /api/v1/assets/:uuid/thumbnail` 对视频资产（ItemType 为 video）能够返回一张图片（JPEG）响应，与图片资产行为一致，以便客户端在时间线等场景显示远程视频缩略图。

#### Scenario: 视频按需生成缩略图使用视频处理器

- **WHEN** 请求某视频资产的缩略图且存储中不存在该视频的预生成缩略图
- **THEN** 系统 SHALL 使用视频处理器（如 FFmpeg）从视频文件中抽帧生成缩略图
- **AND** 系统 SHALL 不使用图片处理器（如 Imagick）解码视频文件
- **AND** 系统 SHALL 将生成的图片写入存储并返回给客户端
- **AND** 抽帧时间偏移 SHALL 使用配置或默认值（如 1 秒）

#### Scenario: 视频缩略图请求成功返回 200

- **WHEN** 视频资产已处理完成（ProcessingStatus 为 COMPLETED）且客户端请求其缩略图
- **THEN** 系统 SHALL 在权限校验通过后返回 HTTP 200 及图片内容（Content-Type 为 image/jpeg）
- **AND** 客户端 SHALL 能够将响应作为图片显示在网格或列表中

#### Scenario: 预生成缺失时回退到按需生成

- **WHEN** 视频资产无预生成缩略图且客户端请求默认或指定尺寸的缩略图
- **THEN** 系统 SHALL 按需从视频原文件生成对应尺寸的缩略图
- **AND** 生成成功后 SHALL 将结果写入存储并返回
- **AND** 后续同尺寸请求 SHALL 可命中已写入的存储

### Requirement: 视频缩略图生成按媒体类型路由

系统 SHALL 在媒体服务层根据媒体类型选择正确的缩略图生成路径：图片使用图片处理器，视频使用视频处理器（抽帧），避免用图片解码器处理视频文件。

#### Scenario: 图片资产仍使用图片处理器

- **WHEN** 按需生成图片资产的缩略图
- **THEN** 系统 SHALL 继续使用图片处理器（如 Imagick）生成缩略图
- **AND** 现有图片缩略图行为 SHALL 不变

#### Scenario: 视频资产使用视频处理器抽帧

- **WHEN** 按需生成视频资产的缩略图
- **THEN** 系统 SHALL 调用视频处理器的 GenerateThumbnail（或等价接口），传入视频路径与图片规格
- **AND** 视频处理器 SHALL 从视频中抽一帧并输出为图片文件
- **AND** 媒体服务 SHALL 将该图片文件写入存储并返回给请求方
