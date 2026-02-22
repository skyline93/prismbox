## 1. 配置

- [x] 1.1 在后端统一配置中增加媒体缩略图/预览图配置（如 `media.thumbnail.size`、`media.preview.size`、format、quality），单处定义、与 Viper/mapstructure 键一致。
- [x] 1.2 媒体处理器（media-processor）从该统一配置读取 thumbnail/preview 的 size、format、quality，移除或替换对 DefaultImageSpecs 中 Crop 及双 MaxWidth/MaxHeight 的依赖（仅 thumbnail/preview 两档）。

## 2. 图片流水线（media-processor）

- [x] 2.1 在 imagick 中实现「长边 ≤ size」的等比缩放（如 resizeToLongEdge），不裁剪；thumbnail 与 preview 均走此路径。
- [x] 2.2 移除 GenerateThumbnail 中对 Crop 的强制为 true；thumbnail 与 preview 共用「长边约束、不裁剪」逻辑。
- [x] 2.3 更新 DefaultImageSpecs（或等价配置）：thumbnail 与 preview 仅保留单边 size 语义，Crop 不再用于该两档。
- [x] 2.4 运行 media-processor 相关单元测试并修复失败。

## 3. 视频流水线

- [x] 3.1 确认视频缩略图/预览使用单边 size 语义（框内等比或短边=size），不裁剪；必要时调整 FFmpeg scale 参数以与 Immich 一致。
- [x] 3.2 视频预生成 thumbnail（及 preview）时使用新配置的 size，写入存储。

## 4. 服务层与 API

- [x] 4.1 缩略图/预览图接口的 size 参数仅接受 `thumbnail`、`preview`、`fullsize`（若实现）；返回对应档位的预生成文件或按档位规则按需生成。
- [x] 4.2 移除 ParseThumbnailSize 对 `WxH`、单边数字的解析；仅保留对 `thumbnail`、`preview`、`fullsize` 的映射。
- [x] 4.3 移除 BuildDynamicThumbnailKey、动态 variant、以及按请求 WxH 生成并缓存的逻辑；thumbnail/preview 仅使用固定档位 key。

## 5. Worker

- [x] 5.1 图片入库 worker 使用新规格（单边 size、不裁剪）生成 thumbnail 与 preview，并上传到固定档位 key。
- [x] 5.2 视频入库 worker 使用新规格预生成 thumbnail（及 preview），写入固定档位 key。

## 6. 遗留清理

- [x] 6.1 删除 ThumbnailSize 的 Width/Height 双参数在 thumbnail/preview 档位的使用，或删除 ThumbnailSize 仅保留档位枚举/字符串。
- [x] 6.2 删除仅用于动态 WxH 的队列 key、缓存 key、fallback 逻辑及相关日志与监控。
- [x] 6.3 清理 ImageSpec 中与 thumbnail/preview 预设相关的 Crop 用法及注释；保留 Crop 仅用于其他用途（若有）。

## 7. 测试与质量

- [x] 7.1 为「长边 ≤ size、不裁剪」的图片生成添加单元测试（给定原图宽高与 size，断言输出比例与长边）。
- [x] 7.2 运行后端相关 linter/静态检查并修复问题。
- [x] 7.3 更新或补充 media-thumbnail、backend-configuration 相关集成或单元测试以覆盖新行为。

## 8. 前端（移动端）

- [x] 8.1 修改 `RemoteThumbProvider._buildUrl`：构建 `/api/v1/assets/:id/thumbnail` 时仅使用档位参数（如 `?size=thumbnail`），不再使用 `key.size` 拼成 `WxH`；保留 `key.size` 仅用于布局或本地解码相关逻辑（若有）。
- [x] 8.2 确认 `RemoteFullImageProvider` 使用的 `/download/preview` 与 `/download/original` 无需改 URL；若后端路由与档位命名一致则无需改动。
- [x] 8.3 运行移动端相关 linter/分析并修复问题；可选：为远程缩略图 URL 构建添加单元测试。
