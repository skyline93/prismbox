import 'dart:async';
import 'dart:io' show Platform;
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

/// 媒体查看器页面
@RoutePage()
class MediaViewerPage extends ConsumerStatefulWidget {
  final String initialAssetId;
  final List<String> assetIds;

  const MediaViewerPage({
    super.key,
    required this.initialAssetId,
    required this.assetIds,
  });

  @override
  ConsumerState<MediaViewerPage> createState() => _MediaViewerPageState();
}

class _MediaViewerPageState extends ConsumerState<MediaViewerPage> {
  late PageController _pageController;
  late int _initialIndex;
  bool _showControls = true;
  bool _isZoomed = false;
  Timer? _controlsTimer;

  @override
  void initState() {
    super.initState();
    _initialIndex = widget.assetIds.indexOf(widget.initialAssetId);
    if (_initialIndex < 0) {
      _initialIndex = 0;
    }
    _pageController = PageController(initialPage: _initialIndex);

    // 自动隐藏控制栏
    _startControlsTimer();
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            // 图片查看器
            PhotoViewGallery.builder(
              pageController: _pageController,
              itemCount: widget.assetIds.length,
              scrollPhysics: _isZoomed
                  ? const NeverScrollableScrollPhysics()
                  : (Platform.isIOS
                      ? const BouncingScrollPhysics()
                      : const ClampingScrollPhysics()),
              // 在 gallery 级别监听缩放状态变化
              scaleStateChangedCallback: (PhotoViewScaleState state) {
                setState(() {
                  _isZoomed = state != PhotoViewScaleState.initial;
                  if (_isZoomed) {
                    _hideControls();
                  } else {
                    _startControlsTimer();
                  }
                });
              },
              builder: (context, index) {
                final assetId = widget.assetIds[index];
                return PhotoViewGalleryPageOptions(
                  imageProvider: _getImageProvider(assetId),
                  heroAttributes: PhotoViewHeroAttributes(
                    tag: 'asset_$assetId',
                    transitionOnUserGestures: true,
                  ),
                  initialScale: PhotoViewComputedScale.contained * 0.99,
                  minScale: PhotoViewComputedScale.contained * 0.99,
                  maxScale: PhotoViewComputedScale.covered * 4.0,
                  onTapDown: (_, __, ___) => _toggleControls(),
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '加载失败',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              onPageChanged: (index) {
                // 页面切换时的处理
                setState(() {
                  _isZoomed = false;
                });
                _resetControlsTimer();
              },
              loadingBuilder: (context, event) {
                if (event == null) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  );
                }
                final value = event.cumulativeBytesLoaded /
                    (event.expectedTotalBytes ?? 1);
                return Center(
                  child: CircularProgressIndicator(
                    value: value,
                    color: Colors.white,
                  ),
                );
              },
            ),

            // 控制栏
            if (_showControls) _buildControls(),
          ],
        ),
      ),
    );
  }

  ImageProvider _getImageProvider(String assetId) {
    // TODO: 实现实际的图片提供者
    // 这里暂时返回一个占位符
    return const NetworkImage('https://via.placeholder.com/800');
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startControlsTimer();
    } else {
      _hideControls();
    }
  }

  void _hideControls() {
    setState(() {
      _showControls = false;
    });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (!_isZoomed) {
        _hideControls();
      }
    });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void _resetControlsTimer() {
    if (_showControls) {
      _startControlsTimer();
    }
  }

  Widget _buildControls() {
    // final currentIndex = _pageController.page?.round() ?? _initialIndex;

    return Stack(
      children: [
        // 顶部 AppBar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AppBar(
            backgroundColor: Colors.black.withOpacity(0.5),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  // TODO: 分享媒体
                },
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  // TODO: 显示更多选项
                },
              ),
            ],
          ),
        ),
        // 底部控制栏
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.black.withOpacity(0.5),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite_border, color: Colors.white),
                  onPressed: () {
                    // TODO: 切换收藏状态
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.white),
                  onPressed: () {
                    // TODO: 显示信息
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () {
                    // TODO: 编辑媒体
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

