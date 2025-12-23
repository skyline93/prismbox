import 'dart:async';
import 'dart:io' show Platform;
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';
import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/features/local_sync/providers/local_sync_providers.dart';
import 'package:prismbox/features/local_sync/services/asset_entity_loader.dart';
import 'package:prismbox/features/local_sync/providers/timeline_provider.dart';
import 'package:prismbox/features/media_loading/image_provider_factory.dart';
import 'package:prismbox/features/media_loading/video_provider.dart';
import 'package:prismbox/providers/infrastructure/api_service_provider.dart';

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

  // 缓存 assetId 到 BaseAsset 的映射
  Map<String, BaseAsset>? _assetMap;
  // 缓存的服务器 URL
  String? _serverUrl;
  // 缓存的 AssetEntityLoader
  AssetEntityLoader? _assetEntityLoader;

  // 视频播放器控制器缓存（按 assetId）
  final Map<String, VideoPlayerController> _videoControllers = {};
  // 当前播放的视频 assetId
  String? _currentVideoAssetId;
  
  // 当前可见的页面索引
  int _currentPageIndex = 0;
  // 可见页面范围（当前页 ± 1，即最多保留 3 页）
  static const int _visiblePageRange = 1;
  // 需要保留资源的页面索引集合
  Set<int> _visiblePageIndices = {};
  // 视频静音状态（默认静音）
  final Map<String, bool> _videoMutedStates = {};

  @override
  void initState() {
    super.initState();
    _initialIndex = widget.assetIds.indexOf(widget.initialAssetId);
    if (_initialIndex < 0) {
      _initialIndex = 0;
    }
    _currentPageIndex = _initialIndex;
    _pageController = PageController(initialPage: _initialIndex);

    // 初始化可见页面范围
    _visiblePageIndices = _calculateVisibleIndices(_initialIndex);

    // 自动隐藏控制栏
    _startControlsTimer();

    // 如果初始项是视频，标记为当前视频（会在 build 后自动播放）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_assetMap != null && _initialIndex < widget.assetIds.length) {
        final assetId = widget.assetIds[_initialIndex];
        final asset = _assetMap?[assetId];
        if (asset != null && asset.isVideo) {
          _currentVideoAssetId = assetId;
        }
      }
    });
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _pageController.dispose();

    // 释放所有视频播放器资源
    _disposeAllVideoControllers();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  /// 计算可见页面索引范围
  Set<int> _calculateVisibleIndices(int currentIndex) {
    final indices = <int>{};
    for (int i = -_visiblePageRange; i <= _visiblePageRange; i++) {
      final index = currentIndex + i;
      if (index >= 0 && index < widget.assetIds.length) {
        indices.add(index);
      }
    }
    return indices;
  }

  /// 释放所有视频播放器资源
  void _disposeAllVideoControllers() {
    // 暂停所有正在播放的视频
    for (final controller in _videoControllers.values) {
      if (controller.value.isPlaying) {
        controller.pause();
      }
    }

    // 释放所有控制器
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    _videoMutedStates.clear();
    _visiblePageIndices.clear();
  }

  /// 释放不可见页面的资源
  void _releaseInvisibleResources(Set<int> visibleIndices) {
    // 更新可见页面集合
    final toRelease = _visiblePageIndices.difference(visibleIndices);
    _visiblePageIndices = visibleIndices;

    // 释放不可见页面的视频控制器
    for (final index in toRelease) {
      if (index < widget.assetIds.length) {
        final assetId = widget.assetIds[index];
        final asset = _assetMap?[assetId];

        if (asset != null && asset.isVideo) {
          _disposeVideoController(assetId);
        }
      }
    }
  }

  /// 释放单个视频控制器
  void _disposeVideoController(String assetId) {
    final controller = _videoControllers.remove(assetId);
    if (controller != null) {
      // 确保先暂停
      if (controller.value.isPlaying) {
        controller.pause();
      }
      // 释放资源
      controller.dispose();
    }

    // 清理相关状态
    _videoMutedStates.remove(assetId);

    // 如果这是当前视频，清除标记
    if (_currentVideoAssetId == assetId) {
      _currentVideoAssetId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 获取所有 assets 并构建映射
    final assetsAsync = ref.watch(timelineAssetsProvider());
    // 获取 AssetEntityLoader（用于延迟加载 AssetEntity）
    final assetEntityLoaderAsync = ref.watch(assetEntityLoaderProvider);

    return assetsAsync.when(
      data: (allAssets) {
        // 构建 assetId 到 BaseAsset 的映射
        _assetMap ??= {for (final asset in allAssets) asset.id: asset};

        // 获取服务器 URL（仅在第一次获取时）
        _serverUrl ??= _getServerUrl();

        // 获取 AssetEntityLoader
        return assetEntityLoaderAsync.when(
          data: (loader) {
            _assetEntityLoader ??= loader;
            return _buildGallery();
          },
          loading: () => const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          ),
          error: (error, stack) => Scaffold(
            backgroundColor: Colors.black,
            body: Center(
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
                    '加载失败: $error',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 48),
              const SizedBox(height: 16),
              Text(
                '加载失败: $error',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGallery() {
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
            // 混合媒体查看器（支持图片和视频）
            PageView.builder(
              controller: _pageController,
              itemCount: widget.assetIds.length,
              physics: _isZoomed
                  ? const NeverScrollableScrollPhysics()
                  : (Platform.isIOS
                        ? const BouncingScrollPhysics()
                        : const ClampingScrollPhysics()),
              onPageChanged: (index) {
                // 页面切换时的处理
                _handlePageChanged(index);
              },
              itemBuilder: (context, index) {
                final assetId = widget.assetIds[index];
                final asset = _assetMap?[assetId];

                if (asset == null) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                // 根据资产类型显示不同的内容
                if (asset.isVideo) {
                  return _buildVideoPlayer(asset, assetId);
                } else {
                  return _buildImageViewer(asset, assetId);
                }
              },
            ),

            // 控制栏
            if (_showControls) _buildControls(),
          ],
        ),
      ),
    );
  }

  /// 获取服务器 URL
  String? _getServerUrl() {
    try {
      final apiService = ref.read(apiServiceProvider);
      return apiService.endpoint;
    } catch (e) {
      // 忽略错误，返回 null（RemoteFullImageProvider 会自己处理）
      return null;
    }
  }

  /// 处理页面切换（增强版：即时释放资源）
  void _handlePageChanged(int index) {
    final previousIndex = _currentPageIndex;
    _currentPageIndex = index;

    // 计算新的可见页面范围
    final newVisibleIndices = _calculateVisibleIndices(index);

    // 释放不可见页面的资源
    _releaseInvisibleResources(newVisibleIndices);

    // 停止上一个页面的视频（如果存在）
    if (previousIndex < widget.assetIds.length) {
      final previousAssetId = widget.assetIds[previousIndex];
      _pauseAndReleaseVideo(previousAssetId, keepIfVisible: newVisibleIndices.contains(previousIndex));
    }

    // 处理当前页面
    if (index < widget.assetIds.length) {
      final assetId = widget.assetIds[index];
      final asset = _assetMap?[assetId];

      if (asset != null && asset.isVideo) {
        _currentVideoAssetId = assetId;
        // 确保视频控制器已创建并播放
        _playVideo(assetId);
      } else {
        _currentVideoAssetId = null;
      }
    }

    setState(() {
      _isZoomed = false;
    });
    _resetControlsTimer();
  }

  /// 暂停并释放视频（根据是否可见决定是否完全释放）
  void _pauseAndReleaseVideo(String assetId, {required bool keepIfVisible}) {
    final controller = _videoControllers[assetId];
    if (controller == null) {
      return;
    }

    // 暂停播放
    if (controller.value.isPlaying) {
      controller.pause();
    }

    // 如果不在可见范围内，完全释放
    if (!keepIfVisible) {
      _disposeVideoController(assetId);
    }
  }

  /// 构建图片查看器
  Widget _buildImageViewer(BaseAsset asset, String assetId) {
    return PhotoView(
      imageProvider: _getImageProvider(assetId),
      heroAttributes: PhotoViewHeroAttributes(
        tag: 'asset_$assetId',
        transitionOnUserGestures: true,
      ),
      initialScale: PhotoViewComputedScale.contained * 0.99,
      minScale: PhotoViewComputedScale.contained * 0.99,
      maxScale: PhotoViewComputedScale.covered * 4.0,
      onTapDown: (_, __, ___) => _toggleControls(),
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
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 48),
              const SizedBox(height: 16),
              Text('加载失败', style: TextStyle(color: Colors.white70)),
            ],
          ),
        );
      },
      loadingBuilder: (context, event) {
        if (event == null) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        final value =
            event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1);
        return Center(
          child: CircularProgressIndicator(value: value, color: Colors.white),
        );
      },
    );
  }

  /// 构建视频播放器
  Widget _buildVideoPlayer(BaseAsset asset, String assetId) {
    final currentIndex = widget.assetIds.indexOf(assetId);

    // 检查是否在可见范围内
    if (!_visiblePageIndices.contains(currentIndex)) {
      // 不在可见范围，返回占位符
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    // 如果已有控制器且已初始化，直接使用
    final existingController = _videoControllers[assetId];
    if (existingController != null && existingController.value.isInitialized) {
      return _buildVideoPlayerWidget(assetId);
    }

    // 异步加载视频源并创建播放器
    return FutureBuilder<VideoSource?>(
      future: VideoProvider.getVideoSource(
        asset,
        serverUrl: _serverUrl,
        assetEntityLoader: _assetEntityLoader,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
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

        final videoSource = snapshot.data!;
        return _createVideoPlayer(videoSource, assetId);
      },
    );
  }

  /// 构建视频播放器 Widget
  Widget _buildVideoPlayerWidget(String assetId) {
    final videoController = _videoControllers[assetId];
    if (videoController == null || !videoController.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final aspectRatio = videoController.value.aspectRatio > 0
        ? videoController.value.aspectRatio
        : 16 / 9;

    return GestureDetector(
      onTap: _toggleControls,
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
            child: _VideoPlayerControls(
              controller: videoController,
              showControls: _showControls,
              isMuted: _videoMutedStates[assetId] ?? true,
              onMuteChanged: (muted) {
                setState(() {
                  _videoMutedStates[assetId] = muted;
                });
              },
              onTap: _toggleControls,
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

  /// 创建视频播放器
  Widget _createVideoPlayer(VideoSource videoSource, String assetId) {
    // 如果已有控制器，直接使用
    if (_videoControllers.containsKey(assetId)) {
      return _buildVideoPlayerWidget(assetId);
    }

    // 创建新的 VideoPlayerController
    final videoController = videoSource.type == VideoSourceType.file
        ? VideoPlayerController.file(File(videoSource.source))
        : VideoPlayerController.networkUrl(Uri.parse(videoSource.source));

    _videoControllers[assetId] = videoController;
    _videoMutedStates[assetId] = true; // 默认静音

    // 初始化
    videoController.initialize().then((_) {
      if (mounted && videoController.value.isInitialized) {
        // 设置默认静音
        videoController.setVolume(0.0);

        // 如果是当前视频，自动播放
        if (assetId == _currentVideoAssetId) {
          videoController.play();
        }

        // 设置循环播放
        videoController.setLooping(true);

        // 触发重建（只重建视频播放器部分）
        setState(() {});
      }
    }).catchError((error) {
      // 错误处理
      if (mounted) {
        setState(() {});
      }
    });

    // 返回加载中的 Widget
    return _buildVideoPlayerWidget(assetId);
  }

  /// 播放视频
  void _playVideo(String assetId) {
    final controller = _videoControllers[assetId];
    if (controller != null && controller.value.isInitialized) {
      if (!controller.value.isPlaying) {
        controller.play();
      }
    }
  }


  ImageProvider _getImageProvider(String assetId) {
    try {
      // 从映射中查找对应的 BaseAsset
      final asset = _assetMap?[assetId];
      if (asset == null) {
        throw Exception('Asset not found: $assetId');
      }

      // 获取屏幕尺寸用于优化加载
      final screenSize = MediaQuery.of(context).size;

      // 在查看器场景中，始终加载原图以确保清晰度
      // LocalFullImageProvider 的渐进式加载机制会：
      // 1. 先快速显示适配屏幕尺寸的图片（阶段2）
      // 2. 然后在后台加载原图（阶段3）
      // 这样可以避免闪烁，同时保证放大时的清晰度
      return getFullImageProvider(
        asset,
        size: screenSize,
        loadOriginal: true, // 查看器场景始终加载原图
        serverUrl: _serverUrl,
        assetEntityLoader: _assetEntityLoader,
      );
    } catch (e) {
      // 如果找不到资源或获取失败，返回占位符
      return const NetworkImage('https://via.placeholder.com/800');
    }
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

/// 自定义视频控制器 Widget
/// 性能优化：独立 StatefulWidget，状态下沉，避免影响父页面
class _VideoPlayerControls extends StatefulWidget {
  final VideoPlayerController controller;
  final bool showControls;
  final bool isMuted;
  final ValueChanged<bool> onMuteChanged;
  final VoidCallback? onTap;

  const _VideoPlayerControls({
    required this.controller,
    required this.showControls,
    required this.isMuted,
    required this.onMuteChanged,
    this.onTap,
  });

  @override
  State<_VideoPlayerControls> createState() => _VideoPlayerControlsState();
}

class _VideoPlayerControlsState extends State<_VideoPlayerControls> {
  bool _isDragging = false;
  Duration? _dragPosition;
  Timer? _progressUpdateTimer;

  // 性能优化：提取样式对象为静态常量
  static const double _progressHeight = 4.0;
  static const double _horizontalPadding = 16.0;

  @override
  void initState() {
    super.initState();
    // 初始化时设置静音
    if (widget.isMuted) {
      widget.controller.setVolume(0.0);
    }
    _startProgressTimer();
  }

  @override
  void didUpdateWidget(_VideoPlayerControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果静音状态改变，更新音量
    if (oldWidget.isMuted != widget.isMuted) {
      widget.controller.setVolume(widget.isMuted ? 0.0 : 1.0);
    }
  }

  @override
  void dispose() {
    _progressUpdateTimer?.cancel();
    super.dispose();
  }

  /// 性能优化：使用 Timer 节流，避免每帧更新
  /// 视频进度不需要 60fps 更新，每 100ms 更新一次足够流畅
  void _startProgressTimer() {
    _progressUpdateTimer?.cancel();
    _progressUpdateTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) {
        if (mounted && widget.controller.value.isInitialized) {
          // ValueListenableBuilder 会自动监听，这里只是确保更新
          // 实际上不需要 setState，因为 ValueListenableBuilder 会处理
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showControls) {
      return const SizedBox.shrink();
    }

    // 性能优化：使用 ValueListenableBuilder 只监听 VideoPlayerController
    // 避免整个页面 rebuild
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: widget.controller,
      builder: (context, value, child) {
        return RepaintBoundary(
          // 性能优化：隔离绘制边界，避免影响视频播放区域
          child: GestureDetector(
            onTap: widget.onTap, // 点击空白区域切换显示/隐藏
            child: Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
              decoration: BoxDecoration(
                // 性能优化：使用渐变而非复杂效果
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              child: Row(
                children: [
                  // 播放/暂停按钮
                  _buildPlayPauseButton(value.isPlaying && value.isInitialized),
                  
                  const SizedBox(width: 12),
                  
                  // 进度条（可扩展）
                  Expanded(
                    child: _buildProgressBar(value),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // 静音按钮
                  _buildMuteButton(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 播放/暂停按钮
  Widget _buildPlayPauseButton(bool isPlaying) {
    return IconButton(
      icon: Icon(
        isPlaying ? Icons.pause : Icons.play_arrow,
        color: Colors.white,
        size: 28,
      ),
      onPressed: () {
        if (isPlaying) {
          widget.controller.pause();
        } else {
          widget.controller.play();
        }
      },
    );
  }

  /// 进度条实现（支持拖拽）
  Widget _buildProgressBar(VideoPlayerValue value) {
    final position = _isDragging && _dragPosition != null ? _dragPosition! : value.position;
    final duration = value.duration;

    if (duration == Duration.zero || !value.isInitialized) {
      return const SizedBox.shrink();
    }

    final progress = position.inMilliseconds / duration.inMilliseconds;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 时间显示
        Text(
          '${_formatDuration(position)} / ${_formatDuration(duration)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        // 进度条
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: _progressHeight,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white.withOpacity(0.3),
            thumbColor: Colors.white,
            overlayColor: Colors.white.withOpacity(0.2),
          ),
          child: Slider(
            value: progress.clamp(0.0, 1.0),
            onChanged: (newProgress) {
              // 拖拽时实时更新
              setState(() {
                _isDragging = true;
                _dragPosition = Duration(
                  milliseconds: (newProgress * duration.inMilliseconds).round(),
                );
              });
            },
            onChangeEnd: (newProgress) {
              final newPosition = Duration(
                milliseconds: (newProgress * duration.inMilliseconds).round(),
              );
              widget.controller.seekTo(newPosition);
              setState(() {
                _isDragging = false;
                _dragPosition = null;
              });
            },
          ),
        ),
      ],
    );
  }

  /// 静音按钮
  Widget _buildMuteButton() {
    return IconButton(
      icon: Icon(
        widget.isMuted ? Icons.volume_off : Icons.volume_up,
        color: Colors.white,
        size: 24,
      ),
      onPressed: () {
        final newMuted = !widget.isMuted;
        widget.controller.setVolume(newMuted ? 0.0 : 1.0);
        widget.onMuteChanged(newMuted);
      },
    );
  }

  /// 格式化时长
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}
