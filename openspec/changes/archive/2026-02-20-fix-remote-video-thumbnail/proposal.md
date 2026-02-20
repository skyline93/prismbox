# Change: 修复远程视频无法显示缩略图

## Why

远程视频资产在时间线等场景无法显示缩略图：客户端请求 `GET /api/v1/assets/:uuid/thumbnail` 时，后端对视频资产未正确生成或返回缩略图。根因有两处：(1) 视频处理流水线（ProcessVideo）只产出转码视频（如 preview.mp4），从未生成并写入预生成缩略图；(2) 按需生成缩略图时统一使用图片处理器（Imagick）的 `GenerateThumbnail`，对视频文件传入的是视频路径，Imagick 无法解码视频导致生成失败。

## What Changes

- 后端媒体服务在按需生成缩略图时，对 `ItemType == "video"` 使用视频处理器（FFmpeg）的 `GenerateThumbnail`（从视频抽帧成图），而非图片处理器。
- MediaProcessor 层对外暴露或路由：在生成缩略图时根据媒体类型选择 image 或 video 处理器。
- 可选：视频 worker（ProcessVideo）完成后生成一张默认缩略图并上传到 `BuildThumbnailKey(media)`，使首次请求即可命中预生成文件，与图片行为一致。
- 不改变现有 API 契约：仍为 `GET /api/v1/assets/:uuid/thumbnail?size=...`，客户端无需改动。

## Impact

- Affected specs: 新增 capability `media-thumbnail`（后端缩略图服务与生成逻辑）；可选补充 `image-loading` 中远程视频缩略图展示预期。
- Affected code:
  - `backend/pkg/media-processor/processor.go`（GenerateThumbnail 按类型路由）
  - `backend/internal/service/media/service.go`（GetOrGenerateThumbnailWithInfo 中视频分支调用 video 处理器）
  - 可选：`backend/internal/worker/media/handler.go`（processVideoHandler 中生成并上传 thumbnail）
  - 可选：worker 与 storage 的集成（上传生成的 jpg 到 thumbnail key）
