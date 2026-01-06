import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/features/local_sync/services/asset_entity_loader.dart';
import 'package:prismbox/presentation/widgets/viewer/viewer_video_manager.dart';
import 'package:prismbox/presentation/widgets/viewer/viewer_video_controller.dart';

/// 视频查看页面组件
///
/// 封装 VideoPlayer 相关逻辑，集成视频控制器 UI，处理视频加载和错误状态。
class ViewerVideoPage extends StatefulWidget {
  /// 资产对象
  final BaseAsset asset;

  /// 资产 ID
  final String assetId;

  /// 视频管理器
  final ViewerVideoManager videoManager;

  /// 服务器 URL（可选）
  final String? serverUrl;

  /// AssetEntity 加载器（可选）
  final AssetEntityLoader? assetEntityLoader;

  /// 是否显示控制栏
  final bool showControls;

  /// 切换控制栏显示/隐藏回调
  final VoidCallback? onToggleControls;

  /// 静音状态改变回调
  final ValueChanged<bool>? onMuteChanged;

  /// 当前页面索引（用于判断是否在可见范围内）
  final int currentIndex;

  /// 可见页面索引集合
  final Set<int> visiblePageIndices;

  const ViewerVideoPage({
    super.key,
    required this.asset,
    required this.assetId,
    required this.videoManager,
    this.serverUrl,
    this.assetEntityLoader,
    required this.showControls,
    this.onToggleControls,
    this.onMuteChanged,
    required this.currentIndex,
    required this.visiblePageIndices,
  });

  @override
  State<ViewerVideoPage> createState() => _ViewerVideoPageState();
}

class _ViewerVideoPageState extends State<ViewerVideoPage> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  @override
  void didUpdateWidget(ViewerVideoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果 assetId 改变，重新加载视频
    if (oldWidget.assetId != widget.assetId) {
      _loadVideo();
    }
  }

  @override
  void dispose() {
    // 不在这里释放控制器，由 ViewerVideoManager 管理
    super.dispose();
  }

  /// 加载视频
  Future<void> _loadVideo() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    // 检查是否在可见范围内
    if (!widget.visiblePageIndices.contains(widget.currentIndex)) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // 尝试获取已存在的控制器
    final existingController = widget.videoManager.getController(widget.assetId);
    if (existingController != null && existingController.value.isInitialized) {
      setState(() {
        _controller = existingController;
        _isLoading = false;
      });
      return;
    }

    // 创建新控制器
    final controller = await widget.videoManager.createController(
      widget.asset,
      widget.assetId,
      serverUrl: widget.serverUrl,
      assetEntityLoader: widget.assetEntityLoader,
    );

    if (controller != null && mounted) {
      setState(() {
        _controller = controller;
        _isLoading = false;
      });

      // 如果是当前视频，自动播放
      if (widget.assetId == widget.videoManager.getCurrentVideoAssetId()) {
        widget.videoManager.playController(widget.assetId);
      }
    } else if (mounted) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 检查是否在可见范围内
    if (!widget.visiblePageIndices.contains(widget.currentIndex)) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_hasError || _controller == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text('视频加载失败', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    if (!_controller!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return _buildVideoPlayerWidget();
  }

  /// 构建视频播放器 Widget
  Widget _buildVideoPlayerWidget() {
    final videoController = _controller!;
    final aspectRatio = videoController.value.aspectRatio > 0
        ? videoController.value.aspectRatio
        : 16 / 9;

    return GestureDetector(
      onTap: widget.onToggleControls,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 视频播放区域
          Center(
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: videoController,
                builder: (context, value, child) {
                  if (value.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.white, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            '播放失败: ${value.errorDescription ?? "未知错误"}',
                            style: const TextStyle(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  return VideoPlayer(videoController);
                },
              ),
            ),
          ),

          // 自定义控制器（在底部，底部栏上方）
          Positioned(
            bottom: _getBottomBarHeight() + 16,
            left: 0,
            right: 0,
            child: VideoPlayerControls(
              controller: videoController,
              showControls: widget.showControls,
              isMuted: widget.videoManager.isMuted(widget.assetId),
              onMuteChanged: (muted) {
                widget.videoManager.setMuted(widget.assetId, muted);
                widget.onMuteChanged?.call(muted);
              },
              onTap: widget.onToggleControls,
            ),
          ),
        ],
      ),
    );
  }

  /// 获取底部栏高度
  double _getBottomBarHeight() {
    return 56.0 + MediaQuery.of(context).padding.bottom;
  }
}

