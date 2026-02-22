# Change: 缩略图与预览图方案对齐 Immich

## Why

当前 Prismbox 的缩略图使用「固定框 + 中心裁剪」（如 400×400），输出横纵比与原图不一致；预览图虽保持比例但规格语义为 MaxWidth/MaxHeight 双参数，与 Immich 的「单边上限、不裁剪」方案不一致。对齐 Immich 可保证缩略图/预览图与原图尺寸与横纵比严格一致，配置与实现更简洁，便于维护与客户端对接。

## What Changes

- 缩略图与预览图统一为「长边 ≤ size」的等比缩放，不裁剪；横纵比与原图一致。
- 规格语义改为单边 `size`（像素）：thumbnail 与 preview 各一个 size，配置统一存放。
- 图片流水线：thumbnail 不再使用 Crop；仅保留「长边约束」的 resize。
- 视频缩略图/预览：保持现有「框内等比、不裁剪」，传入单边 size 语义。
- API 尺寸档位：仅支持 `thumbnail`、`preview`、`fullsize`（可选）；**BREAKING**：移除动态 `WxH` 或单边数字的 size 参数，客户端只传档位。
- 配置：媒体处理器中 thumbnail/preview 的 size、format、quality 在一处配置（如 `media.thumbnail`、`media.preview`），与后端配置加载体系一致。
- 移除历史遗留：删除与「动态 WxH 缩略图」相关的代码路径、ParseThumbnailSize 的 WxH/单边解析、以及不再使用的 Crop 分支与配置项。
- **前端（移动端）配合**：请求远程缩略图时仅使用档位参数（`size=thumbnail`），不再传递动态 WxH；预览图与原图继续使用现有固定 URL（`/download/preview`、`/download/original`），无需改 URL 形态。

## Impact

- Affected specs: media-thumbnail, backend-configuration, image-loading
- Affected code:
  - **后端**：`backend/pkg/media-processor/`（core/types.go, core/config.go, image/imagick.go）、`backend/pkg/media-processor/video/ffmpeg.go`、`backend/internal/service/media/`（service.go, storage_adapter.go）、`backend/internal/worker/media/handler.go`、配置加载与媒体处理器配置注入处、API 层 thumbnail/preview 的 size 参数处理。
  - **前端（移动端）**：`mobile/lib/features/media_loading/providers/remote_thumb_provider.dart`（构建 assets 缩略图 URL 时使用档位 `thumbnail`，不再使用 `key.size` 拼 WxH）；调用方仍可传 `Size` 用于布局/解码，仅不传给后端。
