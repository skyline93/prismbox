## Context

- Live Photo = 主图资产 + `livePhotoVideoId` 指向的关联视频资产；主资产为图片，列表与查看器均以「一张 Live Photo」为单位展示。
- PrismBox 已有 `BaseAsset.livePhotoVideoId`、`isMotionPhoto`；Immich 移动端在查看器内用 `isPlayingMotionVideoProvider` + `MotionPhotoActionButton` + 同一页面内根据状态切换 Image/Video 子视图实现预览播放。本变更仅覆盖「预览展示」，不涉及上传、下载、同步接口变更。

## Goals / Non-Goals

- **Goals**: 时间线网格 Live 角标；查看器内 Live 播放入口、图/视频切换、播完回图、页面切换释放；与 Immich 行为对齐，复用现有 ViewerVideoPage/ViewerVideoManager。
- **Non-Goals**: Live Photo 上传/下载流程、后端 API 变更、iOS/Android 系统相册写回、独立「全部 Live Photo」页面。

## Decisions

- **播放状态**：使用单一全局 Provider（如 `isPlayingMotionVideoProvider`）表示「当前是否正在播放 Live 视频」，与 Immich 一致；按页切换时重置，避免跨页状态错乱。
- **视频源**：本地优先：若已有 Live 视频本地文件则用 path；否则用 `$serverUrl/assets/{livePhotoVideoId}/video/playback`（或与现有视频一致的 original/playback 策略）。与 Immich `native_video_viewer.page.dart` 中 `createSource()` 逻辑对齐。
- **复用 ViewerVideoPage**：不单独为 Live 做一套播放页；仅传入 Live 视频源 + 不循环 + 播完回调中置 `isPlayingMotionVideoProvider = false`。
- **角标位置**：网格右下角；视频显示时长、Live Photo（非视频）显示 Live 角标，二者互斥，避免重叠。
- **参考实现**：Immich `lib/providers/asset_viewer/is_motion_video_playing.provider.dart`、`lib/presentation/widgets/action_buttons/motion_photo_action_button.widget.dart`、`lib/pages/common/native_video_viewer.page.dart`（createSource 中 livePhotoVideoId 分支）、`lib/pages/common/gallery_viewer.page.dart`（buildImage 长按、buildVideo 与 isMotionPhoto）。

## Risks / Trade-offs

- **全局 Provider 与多页**：同一时刻仅一个「当前页」在查看器内，按页切换时重置即可；若未来支持多窗口/画中画需再考虑作用域。
- **视频不可用**：先以 `livePhotoVideoId != null` 显示按钮，加载失败再灰显或隐藏并提示，避免过度预检查增加复杂度。

## Migration Plan

- 无数据迁移；仅前端 UI 与状态逻辑新增。若后端尚未返回 `livePhotoVideoId`，现有 `remote_sync_service` 置空逻辑下 `isMotionPhoto` 为 false，角标与播放入口不显示，无行为变化。

## Open Questions

- 无；与《Live Photo 支持模块详细设计文档》及 Immich 实现对齐即可。
