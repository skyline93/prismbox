# Change: Live Photo 资产预览展示

## Why

当前 PrismBox 已具备 Live Photo 数据模型（`BaseAsset.livePhotoVideoId`、`isMotionPhoto`）与同步写入，但应用内时间线网格与媒体查看器尚未对 Live Photo 做统一预览与播放支持。用户无法在网格中区分动态照片、也无法在查看器内播放关联短视频。本变更在不动上传/下载流程的前提下，补齐「预览展示」能力，与《Live Photo 支持模块详细设计文档》及 Immich 的预览实现对齐。

## What Changes

- **时间线/网格**：在缩略图右下角为 Live Photo（`asset.isMotionPhoto == true`）显示 Live 角标，与视频时长角标互斥（Live Photo 主资产为图片，不显示时长）。
- **媒体查看器**：当当前资产为 Live Photo 时，在控制栏提供「播放 Live 视频」入口；通过单一状态（如 `isPlayingMotionVideoProvider`）在「静态主图」与「Live 短视频」视图间切换；复用现有 `ViewerVideoPage`/`ViewerVideoManager`，视频源由 `livePhotoVideoId` 解析（本地路径或远程 URL）；Live 视频不循环，播完自动切回主图；页面切换或滑离时停止播放并重置为静态图。
- **参考实现**：采用与 Immich 一致的模式——`is_motion_video_playing.provider`、`MotionPhotoActionButton`、`createSource` 中按 `livePhotoVideoId` 选本地文件或拼装远程 URL，不循环播放。

## Impact

- **Affected specs**: `media-viewer`（播放入口、状态、图/视频切换、页面切换释放）, `timeline-page`（网格 Live 角标）
- **Affected code**: `lib/presentation/pages/viewer/media_viewer_page.dart`、`lib/presentation/widgets/viewer/viewer_controls_bar.dart`（或新 Live 播放按钮组件）、`lib/presentation/widgets/media/selectable_media_item.dart`（或时间线网格项）、新建 Provider（如 `is_playing_motion_video_provider.dart`）、视频源解析（复用或扩展现有 playback URL 逻辑）
