## 1. 状态与基础设施

- [x] 1.1 新增「当前是否正在播放 Live 视频」的 Riverpod Provider（如 `StateNotifierProvider` 或 `StateProvider`），供媒体查看器与播放按钮使用；参考 Immich `is_motion_video_playing.provider.dart`
- [x] 1.2 实现由 `livePhotoVideoId` 解析 Live 视频源的逻辑：本地已下载用本地文件路径，否则用与现有视频一致的远程 URL（如 `$serverUrl/assets/{livePhotoVideoId}/video/playback` 或 original）；与 ViewerVideoPage 所需视频源格式兼容

## 2. 媒体查看器

- [x] 2.1 在 ViewerControlsBar 或顶部栏中，当 `asset.isMotionPhoto == true` 时显示「播放 Live 视频」按钮（可参考 Immich MotionPhotoActionButton）；按钮根据 `isPlayingMotionVideoProvider` 切换图标/文案（播放 vs 暂停/停止）
- [x] 2.2 MediaViewerPage 的 PageView itemBuilder：当当前资产为 Live Photo 且 `isPlayingMotionVideoProvider == true` 时展示 ViewerVideoPage（视频源为上述 Live 视频源），否则展示 ViewerImagePage；Live 视频不循环，播完将 Provider 置为 false 并切回主图
- [x] 2.3 页面切换（onPageChanged）时，若当前页为 Live Photo 且正在播 Live，则停止播放并将 `isPlayingMotionVideoProvider` 置为 false；滑回该页时默认显示静态主图，不自动续播
- [x] 2.4 ViewerVideoPage 或视频管理器在用于 Live 视频时传入不循环参数；播完回调中重置 `isPlayingMotionVideoProvider`
- [x] 2.5 可选：主图区域支持长按触发「播放 Live」，与按钮行为一致

## 3. 时间线网格

- [x] 3.1 在 SelectableMediaItem（或统一网格项）中，当 `asset.isMotionPhoto == true` 且非视频时，在右下角显示 Live 角标（与现有 _VideoIndicatorWithAsset 位置互斥：仅视频显示时长，仅 Live Photo 显示 Live 角标）；样式与视频角标接近，带语义标签（如「动态照片」）便于无障碍
- [x] 3.2 确保 Live Photo 缩略图仍使用主图（现有 `getThumbnailImageProvider`/MediaImageWidget），不显示时长、不自动播放

## 4. 降级与边界

- [x] 4.1 当 `livePhotoVideoId != null` 但视频不可用（404、未下载且离线、加载失败）时，不显示或灰显播放按钮，仅显示主图；播放失败时提示并切回静态图
- [x] 4.2 以当前页 `asset` 的 `isMotionPhoto` 为准，不依赖陈旧缓存导致误显示角标或按钮

## 5. 质量与规范

- [x] 5.1 新增/修改的 Widget 与 Provider 符合项目 UI 拆分与 Riverpod 规范（见 openspec/project.md、media-viewer/timeline-page spec）
- [x] 5.2 为新增 Provider 与关键分支补充单元测试或 Widget 测试（如可行）
