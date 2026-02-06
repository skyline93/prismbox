# Change: Live Photo 服务端标记与同步过滤

## Why

当前 Live Photo 在服务端存为两条独立媒体（图片 + 视频），远程同步会下发给客户端两条记录。在「仅云端」时间线中会同时出现一张图片和一条视频，且 Live 视频可能无法正常播放，体验与「一个 Live Photo = 一个条目」的心智不一致。需要在服务端标记 Live 附属视频、同步时排除该视频记录，客户端仅通过 Live 照片记录的 `live_photo_video_id` 请求预览或原片；预览时若无处理好的预览视频则回退到原 Live 视频。

## What Changes

- **服务端**：在媒体模型上新增 `is_live_photo_video` 字段。**在上传 Live Photo 的视频文件时**（即客户端上传成对中的「视频」任务时），由客户端在请求中携带约定标记（如 `is_live_photo_video=1`），服务端在**创建该视频媒体记录时**即将 `is_live_photo_video` 设为 true，不等到上传图片时再写。
- **同步**：流式同步接口在组包时排除 `item_type=video` 且 `is_live_photo_video=true` 的媒体记录，仅同步 Live 照片（图片）记录，图片上继续带 `live_photo_video_id`。
- **移动端**：时间线仅包含 Live 照片一条远程资产，无需在客户端做「按 livePhotoVideoId 隐藏视频条」的去重。远程 Live 预览播放时，优先使用 `live_photo_video_id` 请求 `/download/preview`，若不可用则回退到 `/download/original`；下载时使用 `/download/original` 获取原 Live 视频。

## Impact

- **Affected specs**: asset-upload, remote-asset-sync, media-viewer
- **Affected code**: 后端媒体模型与上传 handler、同步 stream 组装逻辑；移动端远程同步解析（无逻辑变更，仅数据源少一条）、VideoProvider / 查看器内 Live 视频 URL 选择与下载路径
