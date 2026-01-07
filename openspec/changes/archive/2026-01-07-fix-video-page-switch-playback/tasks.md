## 1. 创建响应式状态 Provider

- [x] 1.1 创建 `mobile/lib/presentation/widgets/viewer/viewer_video_state_provider.dart` 文件
- [x] 1.2 定义 `currentVideoAssetIdProvider` StateProvider<String?>，初始值为 null
- [x] 1.3 添加必要的注释说明 Provider 的用途

## 2. 更新 MediaViewerPage

- [x] 2.1 在 `media_viewer_page.dart` 顶部导入 `viewer_video_state_provider.dart`
- [x] 2.2 在 `_handlePageChanged` 方法中，当切换视频时（`asset.isVideo`），同时更新 Provider：
  - 调用 `ref.read(currentVideoAssetIdProvider.notifier).state = assetId`
  - 保持现有的 `_videoManager.setCurrentVideoAssetId(assetId)` 调用
- [x] 2.3 当切换到非视频页面时，将 Provider 状态设置为 null

## 3. 更新 ViewerVideoPage

- [x] 3.1 在 `viewer_video_page.dart` 顶部导入 `viewer_video_state_provider.dart`
- [x] 3.2 在 `build` 方法中添加 `ref.listen(currentVideoAssetIdProvider, ...)` 监听逻辑：
  - 检查该视频是否变成了当前视频（`next == widget.assetId && previous != widget.assetId`）
  - 如果控制器已就绪（`_controller != null && _isVideoReady`），延迟 300ms 后自动播放
  - 使用 `Timer` 延迟，确保切换动画完成
  - 检查 `mounted` 和控制器状态，确保安全性
- [x] 3.3 在 `_onPlaybackReady` 方法中增强自动播放逻辑：
  - 检查是否为当前视频（通过 `widget.videoManager.getCurrentVideoAssetId()` 或 Provider）
  - 如果是当前视频，调用 `widget.videoManager.playController`
  - 如果不是当前视频，记录日志但不播放
- [x] 3.4 在 `_initializeVideo` 方法中，当找到已存在的控制器时：
  - 检查是否为当前视频
  - 如果是当前视频，使用 `Future.microtask` 延迟播放，确保控制器完全准备好

## 4. 测试和验证

- [x] 4.1 编写单元测试验证 Provider 状态更新逻辑（如果适用）

## 5. 代码质量

- [x] 5.1 运行 linter 检查，修复所有警告和错误
- [x] 5.2 确保代码符合项目规范（参考 `openspec/project.md`）
- [x] 5.3 添加必要的日志记录，便于调试
- [x] 5.4 检查是否有内存泄漏（Provider 的自动清理）

