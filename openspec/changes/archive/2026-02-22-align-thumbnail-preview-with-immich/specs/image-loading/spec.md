## ADDED Requirements

### Requirement: 远程缩略图请求仅使用档位参数

请求服务端 assets 缩略图接口（如 `/api/v1/assets/:uuid/thumbnail`）时，系统 SHALL 仅使用档位参数（如 `size=thumbnail`），SHALL NOT 传递动态宽高（如 `size=200x200`）或单边数字（如 `size=1280`），以与后端「仅支持 thumbnail/preview/fullsize 档位」的 API 一致。组件层传入的尺寸（如 `Size`）仅用于布局或本地解码配置，不参与拼写请求 URL 的 query。

#### Scenario: 网格/时间线请求远程缩略图

- **WHEN** 使用 `RemoteThumbProvider` 加载远程资产缩略图（如时间线、网格）
- **THEN** 请求 URL SHALL 包含档位参数（如 `?size=thumbnail`）或省略 size 由服务端默认
- **AND** URL SHALL NOT 包含 `size=WxH`（如 `200x200`）或单边数字
- **AND** 服务端返回的 thumbnail 档位图（长边 ≤ 配置 size、等比不裁剪）SHALL 用于显示，由布局组件（如 BoxFit）适配格子尺寸

#### Scenario: 远程预览图与原图 URL 不变

- **WHEN** 使用 `RemoteFullImageProvider` 进行渐进式加载（预览图 → 原图）
- **THEN** 预览图阶段 SHALL 继续使用固定 endpoint（如 `/api/v1/media/:uuid/download/preview`），无需在 URL 上添加 size 参数
- **AND** 原图阶段 SHALL 继续使用固定 endpoint（如 `/download/original`）
- **AND** 后端 SHALL 对上述 endpoint 返回对应档位（preview / original）内容
