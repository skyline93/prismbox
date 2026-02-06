# Tasks: Live Photo 服务端标记与同步过滤

## 1. 服务端

- [x] 1.1 媒体模型新增 `is_live_photo_video` 布尔字段（默认 false），并做数据库迁移
- [x] 1.2 上传接口（视频）：解析请求中的 `is_live_photo_video`（或约定字段名），在创建该条视频媒体记录时写入 `is_live_photo_video`
- [x] 1.3 同步流组装：在生成 asset_v1 批次时排除 `item_type=video` 且 `is_live_photo_video=true` 的媒体记录
- [x] 1.4 单元/集成测试：上传 Live 视频时带标记后记录为 true；同步流中不包含该视频记录

## 2. 移动端上传

- [x] 2.1 在上传 Live Photo **视频**任务时，在请求表单中携带约定字段（如 `is_live_photo_video=1`）
- [x] 2.2 确认图片上传仍携带 `live_photo_video_id`，不在此变更中修改

## 3. 移动端同步与时间线

- [x] 3.1 确认远程同步解析逻辑：仅写入收到的资产（因服务端已排除 Live 视频，无需新增过滤）
- [x] 3.2 可选：对本地已存在但同步中不再返回的 Live 视频远程记录做清理或软删（兼容旧数据）

## 4. 移动端预览与下载

- [x] 4.1 VideoProvider（或等效）：远程 Live 视频源优先使用 `.../download/preview`，若 4xx 或加载失败则回退到 `.../download/original`
- [x] 4.2 下载/导出 Live Photo 时，使用 `live_photo_video_id` 请求 `.../download/original` 作为原 Live 视频
- [x] 4.3 测试：仅云端 Live 照片一条展示；长按播放先试 preview 再 fallback original；下载得到原视频

## 5. 验证与文档

- [x] 5.1 运行 openspec validate add-live-photo-server-mark-and-sync-filter --strict 通过
- [x] 5.2 更新 API/协议文档（上传字段、同步行为、下载 URL 语义）
