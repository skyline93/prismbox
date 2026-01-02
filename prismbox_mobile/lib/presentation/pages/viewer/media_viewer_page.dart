import 'dart:async';
import 'dart:io' show Platform;
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';

import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/features/local_sync/providers/local_sync_providers.dart';
import 'package:prismbox/features/local_sync/services/asset_entity_loader.dart';
import 'package:prismbox/features/local_sync/providers/timeline_provider.dart';
import 'package:prismbox/providers/infrastructure/api_service_provider.dart';
import 'package:prismbox/presentation/widgets/viewer/viewer_video_manager.dart';
import 'package:prismbox/presentation/widgets/viewer/viewer_dismiss_gesture.dart';
import 'package:prismbox/presentation/widgets/viewer/viewer_controls_bar.dart';
import 'package:prismbox/presentation/widgets/viewer/viewer_image_page.dart';
import 'package:prismbox/presentation/widgets/viewer/viewer_video_page.dart';

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

  // 视频管理器
  late ViewerVideoManager _videoManager;

  // 缓存 assetId 到 BaseAsset 的映射
  Map<String, BaseAsset>? _assetMap;
  // 缓存的服务器 URL
  String? _serverUrl;
  // 缓存的 AssetEntityLoader
  AssetEntityLoader? _assetEntityLoader;

  // 当前可见的页面索引
  int _currentPageIndex = 0;
  // 需要保留资源的页面索引集合
  Set<int> _visiblePageIndices = {};

  @override
  void initState() {
    super.initState();
    _initialIndex = widget.assetIds.indexOf(widget.initialAssetId);
    if (_initialIndex < 0) {
      _initialIndex = 0;
    }
    _currentPageIndex = _initialIndex;
    _pageController = PageController(initialPage: _initialIndex);

    // 初始化视频管理器
    _videoManager = ViewerVideoManager();

    // 初始化可见页面范围
    _visiblePageIndices = _videoManager.calculateVisibleIndices(
      _initialIndex,
      widget.assetIds.length,
    );

    // 自动隐藏控制栏
    _startControlsTimer();

    // 如果初始项是视频，标记为当前视频（会在 build 后自动播放）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_assetMap != null && _initialIndex < widget.assetIds.length) {
        final assetId = widget.assetIds[_initialIndex];
        final asset = _assetMap?[assetId];
        if (asset != null && asset.isVideo) {
          _videoManager.setCurrentVideoAssetId(assetId);
        }
      }
    });
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _pageController.dispose();

    // 释放所有视频播放器资源
    _videoManager.disposeAllControllers();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
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
        body: ViewerDismissGesture(
          isZoomed: _isZoomed,
          onDismiss: () {
            context.router.pop();
          },
          child: Stack(
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
                    return ViewerVideoPage(
                      asset: asset,
                      assetId: assetId,
                      videoManager: _videoManager,
                      serverUrl: _serverUrl,
                      assetEntityLoader: _assetEntityLoader,
                      showControls: _showControls,
                      onToggleControls: _toggleControls,
                      onMuteChanged: (muted) {
                        // 静音状态由视频管理器管理，这里不需要额外处理
                      },
                      currentIndex: index,
                      visiblePageIndices: _visiblePageIndices,
                    );
                  } else {
                    return ViewerImagePage(
                      asset: asset,
                      assetId: assetId,
                      serverUrl: _serverUrl,
                      assetEntityLoader: _assetEntityLoader,
                      onTap: _toggleControls,
                      onScaleStateChanged: (PhotoViewScaleState state) {
                        setState(() {
                          _isZoomed = state != PhotoViewScaleState.initial;
                          if (_isZoomed) {
                            _hideControls();
                          } else {
                            _startControlsTimer();
                          }
                        });
                      },
                    );
                  }
                },
              ),

              // 控制栏
              ViewerControlsBar(
                showControls: _showControls,
                onToggleControls: _toggleControls,
                onBack: () {
                  context.router.pop();
                },
              ),
            ],
          ),
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
    final newVisibleIndices = _videoManager.calculateVisibleIndices(
      index,
      widget.assetIds.length,
    );

    // 释放不可见页面的资源
    _videoManager.updateVisibleIndices(
      newVisibleIndices,
      widget.assetIds,
      _assetMap,
    );

    // 更新可见页面索引集合
    _visiblePageIndices = newVisibleIndices;

    // 停止上一个页面的视频（如果存在）
    if (previousIndex < widget.assetIds.length) {
      final previousAssetId = widget.assetIds[previousIndex];
      _videoManager.pauseAndReleaseVideo(
        previousAssetId,
        keepIfVisible: newVisibleIndices.contains(previousIndex),
      );
    }

    // 处理当前页面
    if (index < widget.assetIds.length) {
      final assetId = widget.assetIds[index];
      final asset = _assetMap?[assetId];

      if (asset != null && asset.isVideo) {
        _videoManager.setCurrentVideoAssetId(assetId);
        // 确保视频控制器已创建并播放
        _videoManager.playController(assetId);
      } else {
        _videoManager.setCurrentVideoAssetId(null);
      }
    }

    setState(() {
      _isZoomed = false;
    });
    _resetControlsTimer();
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

}
