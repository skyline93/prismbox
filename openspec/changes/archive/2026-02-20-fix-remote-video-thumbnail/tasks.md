## 1. 媒体处理器层支持视频缩略图

- [x] 1.1 在 MediaProcessor 接口中增加 `GenerateThumbnailFromVideo(ctx, videoPath, timeOffset, spec) (string, error)`（或等效方法），由 videoProcessor 实现从视频抽帧生成图片
- [x] 1.2 在 processor 实现中实现该方法，委托给 videoProcessor.GenerateThumbnail
- [x] 1.3 确认 videoProcessor（FFmpeg）的 GenerateThumbnail 接受 ImageSpec 或可转换为现有参数（时间偏移、尺寸、输出路径）

## 2. 媒体服务按需生成使用视频处理器

- [x] 2.1 在 GetOrGenerateThumbnailWithInfo 的动态生成分支中，当 `media.ItemType == "video"` 时，获取视频文件路径或 signed URL 作为 videoPath
- [x] 2.2 视频分支调用 MediaProcessor 的 GenerateThumbnailFromVideo（或等效），传入 videoPath、默认/配置的 timeOffset、以及当前请求的 ImageSpec
- [x] 2.3 将生成得到的本地图片文件读取后写入 dynamicKey 存储，并返回 Reader（与现有 image 分支逻辑一致）
- [x] 2.4 移除或避免对视频调用 imageProcessor.GenerateThumbnail(sourcePath, spec)

## 3. 可选：视频 Worker 预生成缩略图

- [x] 3.1 在 processVideoHandler 成功完成 ProcessVideo 后，调用 videoProcessor.GenerateThumbnail 生成默认尺寸（如与 thumbnail 规格一致）的 jpg
- [x] 3.2 将生成的 jpg 通过 storageManager.Put 写入 BuildThumbnailKey(media)
- [x] 3.3 处理生成或上传失败时不阻塞 ProcessingStatus 更新为 COMPLETED（可选：记录日志或标记）

## 3.5 运行时修复（视频缩略图仍无法加载）

- [x] 3.5.1 有降级方案时异步生成使用 `context.WithoutCancel(ctx)`，避免请求结束后 context 被 cancel 导致 FFmpeg 被终止
- [x] 3.5.2 无降级方案（视频无 ThumbHash 且无预生成）时改为同步生成并等待完成后从存储返回，不再直接返回 400

## 4. 测试与质量

- [ ] 4.1 为 media service 中视频缩略图按需生成分支增加单元测试（mock processor 与 storage）
- [x] 4.2 运行现有后端测试并修复因接口或行为变更导致的失败
- [x] 4.3 运行 `go build ./...` 与 linter，确保无新增告警
