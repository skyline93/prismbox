import 'dart:async';
import 'dart:io' show Platform;
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/features/local_sync/providers/local_sync_providers.dart';
import 'package:prismbox/features/local_sync/services/asset_entity_loader.dart';
import 'package:prismbox/features/local_sync/providers/timeline_provider.dart';
import 'package:prismbox/features/media_loading/image_provider_factory.dart';
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
    // 获取所有 assets 并构建映射
    final assetsAsync = ref.watch(timelineAssetsProvider());
    // 获取 AssetEntityLoader（用于延迟加载 AssetEntity）
    final assetEntityLoaderAsync = ref.watch(assetEntityLoaderProvider);
    
    return assetsAsync.when(
      data: (allAssets) {
        // 构建 assetId 到 BaseAsset 的映射
        _assetMap ??= {
          for (final asset in allAssets) asset.id: asset,
        };
        
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
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
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
      },
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
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

