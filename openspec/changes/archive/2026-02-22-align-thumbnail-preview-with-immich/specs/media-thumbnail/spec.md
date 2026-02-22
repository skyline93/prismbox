## MODIFIED Requirements

### Requirement: 资产缩略图接口对视频可返回图片

系统 SHALL 使 `GET /api/v1/assets/:uuid/thumbnail` 对视频资产（ItemType 为 video）能够返回一张图片（JPEG）响应，与图片资产行为一致，以便客户端在时间线等场景显示远程视频缩略图。缩略图与预览图 SHALL 使用配置中的单边 size（长边上限），等比缩放、不裁剪，输出横纵比与原图/原视频一致。

#### Scenario: 视频按需生成缩略图使用视频处理器

- **WHEN** 请求某视频资产的缩略图且存储中不存在该视频的预生成缩略图
- **THEN** 系统 SHALL 使用视频处理器（如 FFmpeg）从视频文件中抽帧生成缩略图
- **AND** 系统 SHALL 不使用图片处理器（如 Imagick）解码视频文件
- **AND** 系统 SHALL 将生成的图片写入存储并返回给客户端
- **AND** 抽帧时间偏移 SHALL 使用配置或默认值（如 1 秒）
- **AND** 输出 SHALL 为「长边 ≤ 配置 size」的等比缩放图，不裁剪

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

系统 SHALL 在媒体服务层根据媒体类型选择正确的缩略图生成路径：图片使用图片处理器，视频使用视频处理器（抽帧），避免用图片解码器处理视频文件。图片与视频的缩略图/预览图 SHALL 均采用单边 size、等比不裁剪的语义。

#### Scenario: 图片资产仍使用图片处理器

- **WHEN** 按需生成图片资产的缩略图或预览图
- **THEN** 系统 SHALL 使用图片处理器（如 Imagick）生成缩略图/预览图
- **AND** 系统 SHALL 使用「长边 ≤ 配置 size」的等比缩放，不裁剪，输出横纵比与原图一致

#### Scenario: 视频资产使用视频处理器抽帧

- **WHEN** 按需生成视频资产的缩略图或预览图
- **THEN** 系统 SHALL 调用视频处理器的 GenerateThumbnail（或等价接口），传入视频路径与图片规格
- **AND** 视频处理器 SHALL 从视频中抽一帧并输出为图片文件
- **AND** 输出 SHALL 在配置的 size 约束内等比缩放，不裁剪，横纵比与原视频一致
- **AND** 媒体服务 SHALL 将该图片文件写入存储并返回给请求方

## ADDED Requirements

### Requirement: 缩略图与预览图保持原图横纵比

系统 SHALL 生成缩略图与预览图时仅使用「长边 ≤ size」的等比缩放，不进行裁剪。输出图像的宽高比 SHALL 与原始媒体（图片或视频）的宽高比一致。size 为配置中的单一边长（像素），表示输出长边的上限。

#### Scenario: 图片缩略图等比不裁剪

- **WHEN** 为图片资产生成 thumbnail 或 preview
- **THEN** 系统 SHALL 将原图按比例缩放使长边 ≤ 配置的 size
- **AND** 系统 SHALL NOT 裁剪图像以匹配固定宽高
- **AND** 输出宽高比 SHALL 等于原图宽高比

#### Scenario: 视频缩略图等比不裁剪

- **WHEN** 为视频资产生成 thumbnail 或 preview
- **THEN** 系统 SHALL 将抽帧得到的图像在 size 约束内等比缩放
- **AND** 系统 SHALL NOT 裁剪以匹配固定宽高
- **AND** 输出宽高比 SHALL 等于原视频宽高比

### Requirement: 缩略图与预览图 API 仅支持档位

缩略图/预览图接口的 size 参数 SHALL 仅接受档位值：`thumbnail`、`preview`、`fullsize`（若实现）。系统 SHALL 根据档位返回对应预生成文件或按该档位规则按需生成。系统 SHALL NOT 接受动态宽高（如 `200x200`）或单边数字（如 `1280`）作为 size 参数。

#### Scenario: 请求 thumbnail 档位

- **WHEN** 客户端请求 `?size=thumbnail`（或等价）
- **THEN** 系统 SHALL 返回使用配置中 thumbnail.size 生成的、长边 ≤ 该值的等比图
- **AND** 若存储中已存在该档位文件则直接返回

#### Scenario: 请求 preview 档位

- **WHEN** 客户端请求 `?size=preview`（或等价）
- **THEN** 系统 SHALL 返回使用配置中 preview.size 生成的、长边 ≤ 该值的等比图
- **AND** 若存储中已存在该档位文件则直接返回

#### Scenario: 动态 WxH 或单边数字不再支持

- **WHEN** 客户端请求 `?size=200x200` 或 `?size=1280`
- **THEN** 系统 SHALL 返回 400 Bad Request 或等价错误
- **AND** 系统 SHALL NOT 按该参数生成或返回图片
