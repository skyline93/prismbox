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
import 'package:prismbox/providers/infrastructure/asset_providers.dart';
import 'package:flutter/material.dart' show ScaffoldMessenger;
import 'package:prismbox/presentation/widgets/viewer/viewer_video_manager.dart';
import 'package:prismbox/presentation/widgets/viewer/viewer_video_state_provider.dart';
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

  // 需要保留资源的页面索引集合
  Set<int> _visiblePageIndices = {};

  // 当前页面的资产 ID
  String? _currentAssetId;

  @override
  void initState() {
    super.initState();
    _initialIndex = widget.assetIds.indexOf(widget.initialAssetId);
    if (_initialIndex < 0) {
      _initialIndex = 0;
    }
    _pageController = PageController(initialPage: _initialIndex);

    // 初始化当前资产 ID（不依赖 _assetMap，避免时序问题）
    if (_initialIndex < widget.assetIds.length) {
      _currentAssetId = widget.assetIds[_initialIndex];
    }

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

    // 注意：不再需要释放 controller，每个 ViewerVideoPage Widget 独立管理自己的 controller

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
        // 构建 assetId 到 BaseAsset 的映射（每次更新时都重新构建，确保缓存最新）
        _assetMap = {for (final asset in allAssets) asset.id: asset};

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
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              // 点击屏幕任意位置切换控制栏显示/隐藏
              if (!_isZoomed) {
                _toggleControls();
              }
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

                // 控制栏（使用 Consumer 包装，直接响应 timelineAssetsProvider 更新）
                Consumer(
                  builder: (context, ref, child) {
                    final assetsAsync = ref.watch(timelineAssetsProvider());
                    final currentFavoriteStatus = assetsAsync.maybeWhen(
                      data: (allAssets) {
                        if (_currentAssetId == null) return null;
                        try {
                          final asset = allAssets.firstWhere(
                            (a) => a.id == _currentAssetId,
                          );
                          return asset.isFavorite;
                        } catch (e) {
                          // 如果找不到，回退到缓存
                          final asset = _assetMap?[_currentAssetId];
                          return asset?.isFavorite;
                        }
                      },
                      orElse: () => _getCurrentAssetFavoriteStatus(), // 回退到缓存
                    );

                    return ViewerControlsBar(
                      showControls: _showControls,
                      onToggleControls: _toggleControls,
                      onBack: () {
                        context.router.pop();
                      },
                      isFavorite: currentFavoriteStatus,
                      onFavorite: _handleFavoriteToggle,
                    );
                  },
                ),
              ],
            ),
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

  /// 处理页面切换
  ///
  /// 更新当前资产 ID，确保收藏按钮显示正确的状态
  void _handlePageChanged(int index) {
    // 计算新的可见页面范围
    final newVisibleIndices = _videoManager.calculateVisibleIndices(
      index,
      widget.assetIds.length,
    );

    // 更新可见页面索引集合
    _videoManager.updateVisibleIndices(newVisibleIndices);
    _visiblePageIndices = newVisibleIndices;

    // 处理当前页面
    if (index < widget.assetIds.length) {
      final assetId = widget.assetIds[index];
      final asset = _assetMap?[assetId];

      // 更新当前资产 ID
      setState(() {
        _currentAssetId = assetId;
      });

      if (asset != null && asset.isVideo) {
        _videoManager.setCurrentVideoAssetId(assetId);
        // 更新 Provider，触发响应式更新（ViewerVideoPage 会通过 ref.listen 响应并自动播放）
        ref.read(currentVideoAssetIdProvider.notifier).state = assetId;
        // 注意：不再调用 playController，播放控制由 ViewerVideoPage 的 onPlaybackReady 完成
      } else {
        _videoManager.setCurrentVideoAssetId(null);
        // 切换到非视频页面时，将 Provider 状态设置为 null
        ref.read(currentVideoAssetIdProvider.notifier).state = null;
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

  /// 获取当前资产的收藏状态
  ///
  /// 从缓存的 `_assetMap` 中获取当前资产的收藏状态
  /// 注意：此方法主要用于回退场景，正常情况下应通过 Consumer 从 Provider 获取
  bool? _getCurrentAssetFavoriteStatus() {
    if (_currentAssetId == null) {
      return null;
    }
    final asset = _assetMap?[_currentAssetId];
    return asset?.isFavorite;
  }

  /// 处理收藏切换
  ///
  /// 调用 AssetFavoriteService 切换收藏状态（仅更新 Prismbox 数据库，不修改系统相册）
  /// 操作成功后刷新 timelineAssetsProvider 以更新 UI 状态
  Future<void> _handleFavoriteToggle() async {
    if (_currentAssetId == null) {
      return;
    }

    try {
      // 获取 AssetFavoriteService
      final favoriteService = await ref.read(
        assetFavoriteServiceProvider.future,
      );

      // 获取当前状态用于提示
      final currentStatus = _getCurrentAssetFavoriteStatus() ?? false;

      // 调用服务切换收藏状态（仅更新数据库）
      final assetId = _currentAssetId!;
      await favoriteService.toggleFavorite(assetId);

      // 刷新 timelineAssetsProvider 以获取最新状态
      ref.invalidate(timelineAssetsProvider());

      // 显示成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(currentStatus ? '已取消收藏' : '已添加收藏'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      // 显示错误提示
      if (mounted) {
        String errorMessage = '收藏操作失败';
        if (e.toString().contains('not found')) {
          errorMessage = '资源不存在';
        } else {
          errorMessage = '收藏操作失败: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // 刷新 Provider 以确保状态一致
      ref.invalidate(timelineAssetsProvider());
    }
  }
}
