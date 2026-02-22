# Design: 缩略图与预览图对齐 Immich

## Context

Immich 对缩略图与预览图采用：单边 `size`（像素，表示长边或短边上限）、等比缩放、不裁剪。输出横纵比与原图/原视频一致。Prismbox 当前使用 ImageSpec 的 MaxWidth/MaxHeight 与 Crop，thumbnail 为「Cover + 中心裁剪」，导致横竖图均变成固定比例（如 1:1）。需要在不做向后兼容的前提下，改为与 Immich 一致的语义与实现，并统一配置、删除遗留逻辑。

## Goals / Non-Goals

- **Goals**：thumbnail/preview 生成与 Immich 对齐（单边 size、不裁剪、横纵比一致）；配置项简洁、统一存放；代码简洁可维护；移除动态 WxH 及旧 Crop 相关代码。
- **Non-Goals**：不保留对旧 API（如 `?size=200x200`）的兼容；不实现 Immich 的 fullsize 转换策略以外的扩展功能。

## Decisions

### 1. 规格语义：单边 size，不裁剪

- **Thumbnail**：配置一项 `size`（如 250），表示输出图像「长边 ≤ size」等比缩放，不裁剪。图片与视频均按此语义。
- **Preview**：配置一项 `size`（如 1440），同上。
- **实现**：图片处理器（Imagick）中，thumbnail 与 preview 共用「长边约束」的 resize（等价于 resizeToFit 仅按长边）；删除 thumbnail 的 Crop 强制与 resizeToCover + CropImage 路径在该两档的使用。视频沿用现有 FFmpeg 框内等比（或改为短边=size 以与 Immich 完全一致），不裁剪。

### 2. 配置统一存放

- 媒体处理器所需的 thumbnail/preview 配置 SHALL 从后端统一配置中读取，键名清晰（如 `media.thumbnail.size`、`media.thumbnail.format`、`media.preview.size`、`media.preview.format`、`media.preview.quality`），与 Viper/配置加载体系一致，不散落在多处以减少重复与歧义。

### 3. API 仅支持档位

- 缩略图/预览图接口的 size 参数 SHALL 仅接受 `thumbnail`、`preview`、`fullsize`（若实现）。移除对 `200x200`、`1280` 等动态尺寸的解析与按需生成；客户端只请求档位，服务端返回对应预生成文件或按档位规则生成。

### 4. 预生成与按需生成

- 入库（worker）时 SHALL 按新规则预生成 thumbnail 与 preview（图片与视频），写入存储。请求时优先返回已存在文件；缺失时可按档位规则按需生成并写入，不保留「按请求的 WxH 生成并缓存」的路径。

### 5. 遗留清理

- 删除：ParseThumbnailSize 中对 `WxH`、单边数字的解析；BuildDynamicThumbnailKey / 动态 variant 的生成与查找；ThumbnailSize 的 Width/Height 双参数在 thumbnail/preview 档位的使用；ImageSpec 中 Crop 在 thumbnail/preview 预设中的使用；以及仅用于动态尺寸的队列与缓存 key 逻辑（与 thumbnail/preview 档位相关的保留并简化为档位 key）。

### 6. 前端（移动端）配合

- **远程缩略图 URL**：请求 `/api/v1/assets/:uuid/thumbnail` 时，query 参数 SHALL 仅使用档位（如 `?size=thumbnail` 或省略由服务端默认）。SHALL NOT 使用 `size=WxH`（如 200x200）或单边数字。`RemoteThumbProvider` 的 `Size size` 仅用于本地布局与解码配置，不参与拼 URL。
- **远程预览图与原图**：已使用固定 endpoint（`/api/v1/media/:uuid/download/preview`、`/download/original`），无需增加 size 参数；后端返回对应档位即可。
- **帖子/圈子**：使用服务端返回的 `thumbnail_url`、`preview_url`，无需前端改 URL 构建逻辑。
- **缓存**：缩略图 URL 从 `?size=200x200` 改为 `?size=thumbnail` 后缓存 key 变化，旧缓存自然失效，可接受。

## Risks / Trade-offs

- **BREAKING**：依赖 `?size=200x200` 或 `?size=1280` 的客户端将失效，需改为 `thumbnail`/`preview`。文档与发布说明需明确。
- **一致性**：统一为单边后，列表/网格中每张图比例各异（与原图一致），若 UI 依赖固定比例格子需在客户端用 aspect ratio 或占位处理。

## Migration Plan

- 无数据迁移；已存在的旧缩略图/预览图文件可继续被使用直到被新规则覆盖（如重新生成或新上传）。建议在发布说明中注明：新规则下将按需重新生成或在上传时生成新格式，旧缓存可逐步淘汰。

## Open Questions

- 无。
