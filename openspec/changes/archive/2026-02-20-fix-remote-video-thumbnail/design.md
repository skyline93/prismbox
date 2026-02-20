# Design: 远程视频缩略图修复

## Context

- 缩略图接口：`GET /api/v1/assets/:uuid/thumbnail?size=...`，由 `DownloadThumbnail` 处理，要求 `ProcessingStatus == "COMPLETED"`，再调用 `GetOrGenerateThumbnailWithInfo`。
- 预生成：若存储中已存在对应 key（如默认尺寸的 thumbnail），直接读存储返回；否则进入按需生成。
- 按需生成：当前对 image 与 video 均调用 `s.processor.GenerateThumbnail(ctx, sourcePath, spec)`，而 `processor.GenerateThumbnail` 仅转发到 `imageProcessor.GenerateThumbnail`，导致视频用 Imagick 打开视频文件失败。
- 视频 worker：`ProcessVideo` 仅执行 `ProcessVideo(ctx, originalPath, specs)`，specs 为 VideoSpec（转码），产出为预览视频等，无 jpg 缩略图；且 worker 未将任何文件写入 thumbnail 的 storage key。

## Goals / Non-Goals

- **Goals**：远程视频资产请求 thumbnail 时能稳定返回一张图片（预生成或按需生成）；按需生成时使用视频抽帧而非图片解码器。
- **Non-Goals**：不改变 API 路径与参数；不要求为视频支持 ThumbHash 占位符；不改变客户端 RemoteThumbProvider 行为。

## Decisions

- **按需生成路由**：在 media service 的“动态生成”分支中，当 `media.ItemType == "video"` 时，不再调用统一的 `processor.GenerateThumbnail(ctx, sourcePath, spec)`（image 处理器）。改为调用视频处理器：获取视频文件路径或 signed URL 作为 `videoPath`，使用 `videoProcessor.GenerateThumbnail(ctx, videoPath, timeOffset, imageSpec)` 生成一帧图片，再将生成的本地文件读取并写入存储（与现有 image 分支写入 dynamicKey 的方式一致）。timeOffset 使用配置或默认值（如 1 秒）。
- **MediaProcessor 接口**：在 `pkg/media-processor` 的 MediaProcessor 接口上增加或复用“按类型生成缩略图”的能力：要么在现有 `GenerateThumbnail` 内根据 first argument 是 image 还是 video 做路由（需传入 media 或 itemType），要么新增 `GenerateThumbnailFromVideo(ctx, videoPath string, timeOffset float64, spec ImageSpec) (string, error)` 由 service 在 video 分支调用。推荐后者，避免破坏现有 GenerateThumbnail(imagePath, spec) 的语义；service 层对 video 调用 `GenerateThumbnailFromVideo`，对 image 仍调用 `GenerateThumbnail`。
- **预生成（可选）**：在 `processVideoHandler` 成功完成后，使用 videoProcessor.GenerateThumbnail 生成一张默认尺寸（与 BuildThumbnailKey 对应，如 400x400 或配置的 thumbnail 尺寸）的 jpg，将生成的文件通过 storageManager.Put 写入 `BuildThumbnailKey(media)`。这样首次 thumbnail 请求即可命中存储，无需按需生成。若不做预生成，仅靠按需生成也可修复“无法显示”的问题。
- **Alternatives considered**： (1) 在 processor 层用启发式（如扩展名）判断 image/video 并路由：不可靠，且混合职责。(2) 仅做按需生成、不做 worker 预生成：实现更简单，首请求略慢，可接受。

## Risks / Trade-offs

- **风险**：视频抽帧依赖 FFmpeg；若 signed URL 或本地路径不可用，按需生成会失败。**缓解**：与现有“获取 originalPath”逻辑一致，失败时返回错误，客户端已能处理 errorBuilder。
- **权衡**：预生成增加 worker 耗时与存储写入，换首次请求更快；可先只做按需生成，后续再加预生成。

## Migration Plan

- 无数据迁移。部署后现有远程视频的 thumbnail 请求将开始成功（按需生成或预生成）。
- 回滚：还原 service 与 processor 改动即可；若已加 worker 预生成，回滚后新上传视频不再写 thumbnail，旧已写入的 key 仍可被读。

## Open Questions

- 无。
