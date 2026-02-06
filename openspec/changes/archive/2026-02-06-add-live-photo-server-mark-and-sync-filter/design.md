# Design: Live Photo 服务端标记与同步过滤

## Context

- Live Photo 成对上传：先传视频，再传图片并带 `live_photo_video_id`。服务端目前仅在图片上持久化 `live_photo_video_uuid`，视频媒体无「是否为 Live 附属」标记。
- 同步流当前返回所有媒体（含 Live 视频），客户端时间线在「仅云端」会显示图片 + 视频两条。
- 决策：服务端用字段标记 Live 视频；同步不返回该记录；预览优先用处理好的预览视频，没有则用原 Live 视频；下载用原 Live 视频。

## Goals / Non-Goals

- **Goals**: 时间线仅显示一张 Live Photo；同步 payload 不包含 Live 视频记录；预览先 preview 后 original 回退；下载使用 original；`is_live_photo_video` 在**上传 Live 视频时**即写入。
- **Non-Goals**: 不在此变更内实现 Live 视频转码流水线（预览可暂无，由客户端回退到 original）；不改变上传成对顺序与现有 API 路径。

## Decisions

### 1. is_live_photo_video 写入时机

- **Decision**: 在**上传 Live Photo 的视频文件**时由客户端在请求中携带标记（如表单字段 `is_live_photo_video=1`），服务端在创建该条视频媒体记录时即将 `is_live_photo_video` 设为 true。
- **Rationale**: 视频先于图片上传，此时即可确定该条媒体为 Live 附属，无需等图片上传再反写视频记录；同步与过滤逻辑可仅依赖该字段，不依赖「被某图片引用」的二次查询。

### 2. 同步过滤规则

- **Decision**: 流式同步在组 asset_v1 批次时，排除满足 `item_type == "video"` 且 `is_live_photo_video == true` 的媒体记录。
- **Rationale**: 客户端不再收到 Live 视频的独立事件，时间线自然只有 Live 照片一条；图片上的 `live_photo_video_id` 仍可用来请求预览/原片。

### 3. 远程 Live 预览与下载

- **Decision**: 预览播放时，用 `live_photo_video_id` 先请求 `.../download/preview`，若返回 4xx 或加载失败则回退到 `.../download/original`；下载（导出原片）时仅请求 `.../download/original`。
- **Rationale**: 与「没有处理好的预览就用原 Live 视频」一致；后端无需在 DownloadPreview 内对视频做 fallback，由客户端统一处理。

### 4. 客户端兼容

- **Decision**: 若本地已有旧版同步下来的「Live 视频」远程记录，可在后续同步中因服务端不再返回该 UUID（或删除事件）而清理；新客户端仅写入收到的 Live 照片记录。
- **Rationale**: 不破坏现有同步协议格式，仅服务端少返回一类记录；客户端解析逻辑可不变，仅数据量变化。

## Risks / Trade-offs

- **风险**: 旧客户端已缓存的 Live 视频远程记录可能残留一条「仅本地有、远程已不返回」的条目。**缓解**: 同步层对「服务端未返回且被某 Live 照片的 live_photo_video_id 引用」的 UUID 做软删或不再展示为独立时间线条目，或依赖删除事件清理。
- **权衡**: 预览未就绪时回退到原片会占用更多带宽，可接受为短期行为，后续可增加 Live 视频转码再启用预览。

## Open Questions

- 无。
