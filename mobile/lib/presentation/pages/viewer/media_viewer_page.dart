import 'dart:async';
import 'dart:io' show Platform;
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/widgets/photo_view.dart';
import 'package:prismbox/widgets/photo_view_gallery.dart';

import 'package:prismbox/data/database/enums/asset_type.dart';
import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/domain/entities/local_asset.dart';
import 'package:prismbox/features/backup/models/asset_upload_status.dart';
import 'package:prismbox/features/local_sync/providers/local_sync_providers.dart';
import 'package:prismbox/features/media_loading/image_provider_factory.dart';
import 'package:prismbox/presentation/pages/photos/controllers/timeline_upload_handler.dart';
import 'package:prismbox/services/backup/providers/asset_upload_status_provider.dart';
import 'package:prismbox/data/database/enums/media_download_source_type.dart';
import 'package:prismbox/providers/auth/auth_state_provider.dart';
import 'package:prismbox/services/download/media_download_request.dart';
import 'package:prismbox/services/download/providers/download_providers.dart';
import 'package:prismbox/features/local_sync/services/asset_entity_loader.dart';
import 'package:prismbox/features/local_sync/providers/timeline_provider.dart';
import 'package:prismbox/providers/infrastructure/api_service_provider.dart';
import 'package:prismbox/providers/infrastructure/asset_providers.dart';
import 'package:flutter/material.dart' show ScaffoldMessenger;
import 'package:prismbox/presentation/widgets/viewer/viewer_video_manager.dart';
import 'package:prismbox/presentation/widgets/viewer/viewer_video_state_provider.dart';
import 'package:prismbox/presentation/widgets/viewer/viewer_controls_bar.dart';
import 'package:prismbox/presentation/widgets/viewer/viewer_video_page.dart';
import 'package:prismbox/presentation/widgets/viewer/media_detail_sheet.dart';

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

  /// 背景不透明度 0–255，下滑时渐变（与 Immich 一致）
  int _backgroundOpacity = 255;
  /// 独立背景层用 Notifier 驱动，避免受 build 中 when 分支影响导致不重绘
  final ValueNotifier<int> _backgroundOpacityNotifier = ValueNotifier<int>(255);

  // --- Immich 风格下滑关闭：由 PhotoView 内部 VerticalDrag 驱动 ---
  PhotoViewControllerBase? _viewController;
  PhotoViewControllerValue _initialPhotoViewState = const PhotoViewControllerValue(
    position: Offset.zero,
    scale: null,
    rotation: 0,
    rotationFocusPoint: null,
  );
  Offset _dragDownPosition = Offset.zero;
  bool? _hasDraggedDown;
  bool _blockGestures = false;
  bool _shouldPopOnDrag = false;
  bool _hasOpenedSheetThisGesture = false;

  // 用于抑制长按播放 Live 后松手产生的「伪点击」导致的下一次控制栏切换
  bool _suppressNextToggleControls = false;

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

  /// 本次查看会话内收藏状态覆盖（assetId -> isFavorite），用于收藏/取消收藏后立即更新 UI，
  /// 避免在查看器内 invalidate timeline provider 导致异步 refetch 时通知到已 dispose 的 element 报错。
  final Map<String, bool> _favoriteOverrides = {};

  /// 是否已设置过「初始页为视频」时的 currentVideo 状态（方案一：避免首帧 _assetMap 为 null 导致不播放）
  bool _initialVideoStateSet = false;

  /// 缓存的静音状态 notifier，用于 dispose 时重置静音而不使用 ref（dispose 中禁止使用 ref）。
  StateController<bool>? _cachedMutedNotifier;

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

    // 初始视频状态改在 build 的 data 分支里设置（有 _assetMap 时），见下方 _initialVideoStateSet 逻辑
  }

  @override
  void dispose() {
    _pageController.dispose();
    _backgroundOpacityNotifier.dispose();

    // 退出预览时重置静音状态，下次进入时默认静音（使用缓存的 notifier，dispose 中禁止使用 ref）
    _cachedMutedNotifier?.state = true;

    // 注意：不再需要释放 controller，每个 ViewerVideoPage Widget 独立管理自己的 controller

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 缓存静音 notifier，供 dispose 时重置静音（dispose 中不能使用 ref）
    _cachedMutedNotifier ??= ref.read(viewerMutedProvider.notifier);

    // 获取所有 assets 并构建映射
    final assetsAsync = ref.watch(timelineAssetsProvider());
    // 获取 AssetEntityLoader（用于延迟加载 AssetEntity）
    final assetEntityLoaderAsync = ref.watch(assetEntityLoaderProvider);

    return assetsAsync.when(
      data: (allAssets) {
        // 构建 assetId 到 BaseAsset 的映射（每次更新时都重新构建，确保缓存最新）
        _assetMap = {for (final asset in allAssets) asset.id: asset};

        // 方案一：有 _assetMap 且初始项是视频时，在下一帧设置 Provider + Manager，只执行一次
        if (!_initialVideoStateSet &&
            _initialIndex < widget.assetIds.length) {
          final initialAsset =
              _assetMap?[widget.assetIds[_initialIndex]];
          if (initialAsset != null && initialAsset.isVideo) {
            _initialVideoStateSet = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              final assetId = widget.assetIds[_initialIndex];
              ref.read(currentVideoAssetIdProvider.notifier).state = assetId;
              _videoManager.setCurrentVideoAssetId(assetId);
            });
          }
        }

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
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            ValueListenableBuilder<int>(
              valueListenable: _backgroundOpacityNotifier,
              builder: (context, opacity, _) {
                debugPrint('[MediaViewer] ValueListenableBuilder rebuild opacity=$opacity');
                return Positioned.fill(
                  child: Container(color: Colors.black.withAlpha(opacity)),
                );
              },
            ),
            PhotoViewGallery.builder(
              gaplessPlayback: true,
              pageController: _pageController,
              itemCount: widget.assetIds.length,
              scrollPhysics: _isZoomed
                  ? const NeverScrollableScrollPhysics()
                  : (Platform.isIOS
                        ? const BouncingScrollPhysics()
                        : const ClampingScrollPhysics()),
              scrollDirection: Axis.horizontal,
              onPageChanged: (index, _) => _handlePageChanged(index),
              onPageBuild: _onPageBuild,
              scaleStateChangedCallback: _onScaleStateChanged,
              builder: _buildPageOptions,
              backgroundDecoration: const BoxDecoration(color: Colors.transparent),
              loadingBuilder: (context, event, index) => Center(
                child: event == null
                    ? const CircularProgressIndicator(color: Colors.white)
                    : CircularProgressIndicator(
                        value: event.cumulativeBytesLoaded /
                            (event.expectedTotalBytes ?? 1),
                        color: Colors.white,
                      ),
              ),
              enablePanAlways: true,
            ),
            Consumer(
                  builder: (context, ref, child) {
                    // 优先使用本次会话内的收藏覆盖，避免依赖 invalidate 触发的 refetch（会引发 defunct element 断言）
                    final overridden = _currentAssetId != null
                        ? _favoriteOverrides[_currentAssetId]
                        : null;
                    final assetsAsync = ref.watch(timelineAssetsProvider());
                    final currentFavoriteStatus = overridden ?? assetsAsync.maybeWhen(
                      data: (allAssets) {
                        if (_currentAssetId == null) return null;
                        try {
                          final asset = allAssets.firstWhere(
                            (a) => a.id == _currentAssetId,
                          );
                          return asset.isFavorite;
                        } catch (e) {
                          final asset = _assetMap?[_currentAssetId];
                          return asset?.isFavorite;
                        }
                      },
                      orElse: () => _getCurrentAssetFavoriteStatus(),
                    );
                    final currentAsset = _currentAssetId == null
                        ? null
                        : _assetMap?[_currentAssetId];
                    final isMotionPhoto = currentAsset?.isMotionPhoto ?? false;
                    final isPlayingMotionVideo =
                        ref.watch(isPlayingMotionVideoProvider);
                    final canDownload = currentAsset?.remoteId != null;
                    final authState = ref.watch(authNotifierProvider).value;
                    final userId = authState is AuthStateAuthenticated
                        ? authState.user.id.toString()
                        : null;

                    // 仅本地资源监听上传状态，用于顶栏云图标（与缩略图一致）及可点击状态
                    final AssetUploadStatus? uploadStatus = currentAsset != null &&
                            currentAsset is LocalAsset
                        ? ref
                            .watch(
                              assetUploadStatusProvider(
                                currentAsset.localId ?? currentAsset.id,
                                currentAsset.hasRemote,
                                currentAsset.checksum,
                              ),
                            )
                            .valueOrNull
                            ?.status
                        : null;

                    return ViewerControlsBar(
                      showControls: _showControls,
                      onToggleControls: _toggleControls,
                      onBack: () {
                        // 退出前清空当前视频，触发当前 ViewerVideoPage 立即 pause，避免退出后仍后台播放
                        ref.read(currentVideoAssetIdProvider.notifier).state = null;
                        context.router.pop();
                      },
                      isFavorite: currentFavoriteStatus,
                      onFavorite: _handleFavoriteToggle,
                      isMotionPhoto: isMotionPhoto,
                      isPlayingMotionVideo: isPlayingMotionVideo,
                      onPlayMotionVideo: isMotionPhoto
                          ? () {
                              final next = !ref.read(isPlayingMotionVideoProvider);
                              ref.read(isPlayingMotionVideoProvider.notifier).state =
                                  next;
                              if (next && _currentAssetId != null) {
                                ref
                                    .read(currentVideoAssetIdProvider.notifier)
                                    .state = _currentAssetId;
                              }
                            }
                          : null,
                      showDownloadButton: canDownload && userId != null,
                      onDownload: (canDownload && userId != null && currentAsset != null)
                          ? () async {
                              final downloadService = await ref.read(downloadServiceProvider.future);
                              final request = MediaDownloadRequest(
                                userId: userId,
                                sourceType: MediaDownloadSourceType.timeline_asset,
                                sourceId: currentAsset.id,
                                mediaUuid: currentAsset.remoteId!,
                                livePhotoVideoUuid: currentAsset.livePhotoVideoId,
                                itemType: currentAsset.type == AssetType.image ? 'IMAGE' : 'VIDEO',
                                filename: currentAsset.name,
                              );
                              final added = await downloadService.addDownload(request);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      added ? '已加入下载队列' : '已在下载队列中',
                                    ),
                                  ),
                                );
                              }
                            }
                          : null,
                      onUpload: (currentAsset is LocalAsset && _currentAssetId != null)
                          ? () async {
                              final handler = TimelineUploadHandler(
                                context: context,
                                ref: ref,
                                mounted: () => mounted,
                              );
                              await handler.handleUploadWithAssetIds([_currentAssetId!]);
                            }
                          : null,
                      uploadStatus: uploadStatus,
                      onInfo: () => _showMediaDetailSheet(context, currentAsset),
                    );
                  },
                ),
              ],
            ),
      ),
    );
  }

  // --- Immich 风格下滑/上滑：与 asset_viewer.page 一致 ---
  void _onPageBuild(PhotoViewControllerBase controller) {
    _viewController = controller;
  }

  void _onDragStart(
    _,
    DragStartDetails details,
    PhotoViewControllerBase controller,
    PhotoViewScaleStateController scaleStateController,
  ) {
    debugPrint('[MediaViewer] _onDragStart: localPosition=${details.localPosition}');
    _viewController = controller;
    _dragDownPosition = details.localPosition;
    _initialPhotoViewState = controller.value;
    _hasOpenedSheetThisGesture = false;
    final isZoomed = scaleStateController.scaleState == PhotoViewScaleState.zoomedIn ||
        scaleStateController.scaleState == PhotoViewScaleState.covering;
    if (isZoomed) {
      _blockGestures = true;
      debugPrint('[MediaViewer] _onDragStart: isZoomed=true, blocking gestures');
    }
  }

  void _onDragEnd(BuildContext ctx, _, __) {
    debugPrint('[MediaViewer] _onDragEnd: shouldPop=$_shouldPopOnDrag blockGestures=$_blockGestures hasDraggedDown=$_hasDraggedDown');
    if (_shouldPopOnDrag) {
      // 退出前清空当前视频，触发当前 ViewerVideoPage 立即 pause，避免退出后仍后台播放
      ref.read(currentVideoAssetIdProvider.notifier).state = null;
      ctx.router.pop();
      return;
    }
    if (_blockGestures) {
      _blockGestures = false;
      return;
    }
    _shouldPopOnDrag = false;
    _hasDraggedDown = null;
    _viewController?.animateMultiple(
      position: _initialPhotoViewState.position,
      scale: _viewController?.initialScale ?? _initialPhotoViewState.scale,
      rotation: _initialPhotoViewState.rotation,
    );
    _backgroundOpacity = 255;
    _backgroundOpacityNotifier.value = 255;
    debugPrint('[MediaViewer] _onDragEnd: reset opacity to 255');
  }

  void _onDragUpdate(BuildContext ctx, DragUpdateDetails details, _) {
    if (_blockGestures) return;
    final delta = details.localPosition - _dragDownPosition;
    final wasDown = _hasDraggedDown;
    _hasDraggedDown ??= delta.dy > 0;
    if (_hasDraggedDown! == false) {
      if (wasDown == null) debugPrint('[MediaViewer] _onDragUpdate: delta=$delta -> drag UP path');
      _handleDragUp(ctx, delta);
      return;
    }
    if (wasDown == null) debugPrint('[MediaViewer] _onDragUpdate: delta=$delta -> drag DOWN path');
    _handleDragDown(ctx, delta);
  }

  static const double _kDragRatio = 0.2;
  static const double _kPopThreshold = 75.0;
  static const double _kOpenThreshold = 50.0;

  void _handleDragUp(BuildContext ctx, Offset delta) {
    final position = _initialPhotoViewState.position + Offset(0, delta.dy);
    final distanceToOrigin = position.distance;
    _viewController?.updateMultiple(position: position);
    if (!_hasOpenedSheetThisGesture && distanceToOrigin > _kOpenThreshold) {
      _hasOpenedSheetThisGesture = true;
      final currentAsset =
          _currentAssetId == null ? null : _assetMap?[_currentAssetId];
      _showMediaDetailSheet(ctx, currentAsset);
    }
  }

  void _handleDragDown(BuildContext ctx, Offset delta) {
    final distance = delta.distance;
    _shouldPopOnDrag = delta.dy > 0 && distance > _kPopThreshold;
    final maxScaleDistance = MediaQuery.sizeOf(ctx).height * 0.5;
    final scaleReduction = (distance / maxScaleDistance).clamp(0.0, _kDragRatio);
    final initialScale = _viewController?.initialScale ?? _initialPhotoViewState.scale;
    final updatedScale =
        initialScale != null ? initialScale * (1.0 - scaleReduction) : null;
    final backgroundOpacity =
        (255 * (1.0 - (scaleReduction / _kDragRatio))).round();
    debugPrint('[MediaViewer] _handleDragDown: distance=${distance.toStringAsFixed(1)} scaleReduction=${scaleReduction.toStringAsFixed(3)} opacity=$backgroundOpacity');
    _viewController?.updateMultiple(
      position: _initialPhotoViewState.position + delta,
      scale: updatedScale,
    );
    _backgroundOpacityNotifier.value = backgroundOpacity;
  }

  void _onTapDown(_, __, ___) {
    if (!_isZoomed) _toggleControls();
  }

  void _onScaleStateChanged(PhotoViewScaleState scaleState) {
    setState(() {
      _isZoomed = scaleState != PhotoViewScaleState.initial;
    });
  }

  /// 构建当前页的 PhotoView 选项（图 / 视频）
  PhotoViewGalleryPageOptions _buildPageOptions(BuildContext ctx, int index) {
    final assetId = widget.assetIds[index];
    final asset = _assetMap?[assetId];
    final isPlayingMotionVideo = ref.watch(isPlayingMotionVideoProvider);
    final mediaSize = MediaQuery.sizeOf(ctx);

    if (asset == null) {
      return PhotoViewGalleryPageOptions.customChild(
        heroAttributes: PhotoViewHeroAttributes(tag: 'loading_$index'),
        child: Container(
          width: mediaSize.width,
          height: mediaSize.height,
          color: Colors.black.withAlpha(_backgroundOpacity),
          child: const Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
    }

    // 视频或 Live 正在播
    if (asset.isVideo ||
        (asset.isMotionPhoto &&
            isPlayingMotionVideo &&
            asset.livePhotoVideoId != null)) {
      return PhotoViewGalleryPageOptions.customChild(
        onDragStart: _onDragStart,
        onDragUpdate: _onDragUpdate,
        onDragEnd: _onDragEnd,
        onTapDown: _onTapDown,
        heroAttributes: PhotoViewHeroAttributes(
          tag: 'asset_${asset.id}',
          transitionOnUserGestures: true,
        ),
        initialScale: PhotoViewComputedScale.contained * 0.99,
        minScale: PhotoViewComputedScale.contained * 0.99,
        maxScale: 1.0,
        basePosition: Alignment.center,
        disableScaleGestures: true,
        child: SizedBox(
          width: mediaSize.width,
          height: mediaSize.height,
          child: ViewerVideoPage(
            asset: asset,
            assetId: assetId,
            videoManager: _videoManager,
            serverUrl: _serverUrl,
            assetEntityLoader: _assetEntityLoader,
            showControls: _showControls,
            onToggleControls: _toggleControls,
            onMuteChanged: (_) {},
            currentIndex: index,
            visiblePageIndices: _visiblePageIndices,
            livePhotoVideoId: asset.livePhotoVideoId,
            isLivePhotoVideo: asset.isMotionPhoto && isPlayingMotionVideo,
          ),
        ),
      );
    }

    // 图片或 Live 静态图
    final imageProvider = getFullImageProvider(
      asset,
      size: mediaSize,
      loadOriginal: true,
      serverUrl: _serverUrl,
      assetEntityLoader: _assetEntityLoader,
    );
    return PhotoViewGalleryPageOptions(
      key: ValueKey(asset.id),
      imageProvider: imageProvider,
      heroAttributes: PhotoViewHeroAttributes(
        tag: 'asset_${asset.id}',
        transitionOnUserGestures: true,
      ),
      filterQuality: FilterQuality.high,
      tightMode: true,
      initialScale: PhotoViewComputedScale.contained * 0.99,
      minScale: PhotoViewComputedScale.contained * 0.99,
      maxScale: PhotoViewComputedScale.covered * 4.0,
      onDragStart: _onDragStart,
      onDragUpdate: _onDragUpdate,
      onDragEnd: _onDragEnd,
      onTapDown: _onTapDown,
      onLongPressStart: asset.isMotionPhoto ? _onLongPressMotion : null,
      errorBuilder: (_, __, ___) => Container(
        width: mediaSize.width,
        height: mediaSize.height,
        color: Colors.black,
        child: const Center(
          child: Icon(Icons.error_outline, color: Colors.white, size: 48),
        ),
      ),
    );
  }

  void _onLongPressMotion(_, __, ___) {
    final next = !ref.read(isPlayingMotionVideoProvider);
    ref.read(isPlayingMotionVideoProvider.notifier).state = next;
    if (next && _currentAssetId != null) {
      _suppressNextToggleControls = true;
      ref.read(currentVideoAssetIdProvider.notifier).state = _currentAssetId;
    }
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

  /// 显示媒体详细信息底部 sheet（拍摄设备、原文件名、文件大小、尺寸、拍摄位置、拍摄参数）
  void _showMediaDetailSheet(BuildContext context, BaseAsset? asset) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.25,
        maxChildSize: 0.7,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '媒体信息',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Flexible(
                child: MediaDetailSheet(
                  asset: asset,
                  scrollController: scrollController,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 处理页面切换
  ///
  /// 更新当前资产 ID，确保收藏按钮显示正确的状态；离开当前页时重置 Live 播放状态。
  void _handlePageChanged(int index) {
    ref.read(isPlayingMotionVideoProvider.notifier).state = false;

    final newVisibleIndices = _videoManager.calculateVisibleIndices(
      index,
      widget.assetIds.length,
    );
    _videoManager.updateVisibleIndices(newVisibleIndices);
    _visiblePageIndices = newVisibleIndices;

    if (index < widget.assetIds.length) {
      final assetId = widget.assetIds[index];
      final asset = _assetMap?[assetId];

      setState(() {
        _currentAssetId = assetId;
      });

      if (asset != null && asset.isVideo) {
        _videoManager.setCurrentVideoAssetId(assetId);
        ref.read(currentVideoAssetIdProvider.notifier).state = assetId;
      } else {
        _videoManager.setCurrentVideoAssetId(null);
        ref.read(currentVideoAssetIdProvider.notifier).state = null;
      }
    }

    setState(() {
      _isZoomed = false;
    });
  }

  void _toggleControls() {
    // 若刚刚通过长按触发了 Live 播放，忽略紧接着的一次切换请求，保持当前控制栏状态不变
    if (_suppressNextToggleControls) {
      _suppressNextToggleControls = false;
      return;
    }

    setState(() {
      _showControls = !_showControls;
    });
    SystemChrome.setEnabledSystemUIMode(
      _showControls ? SystemUiMode.edgeToEdge : SystemUiMode.immersive,
    );
  }

  /// 获取当前资产的收藏状态
  ///
  /// 优先使用 _favoriteOverrides，否则从 _assetMap 取；用于 Consumer 的 orElse 回退。
  bool? _getCurrentAssetFavoriteStatus() {
    if (_currentAssetId == null) return null;
    final overridden = _favoriteOverrides[_currentAssetId];
    if (overridden != null) return overridden;
    final asset = _assetMap?[_currentAssetId];
    return asset?.isFavorite;
  }

  /// 处理收藏切换
  ///
  /// 调用 AssetFavoriteService：先更新数据库，再写回系统相册（需相册写入权限）。
  /// iOS 需「完全访问」相册才能写回；无权限时仅保留 App 内收藏状态。
  /// 成功后通过 _favoriteOverrides + setState 更新 UI，不在查看器内 invalidate timeline 以免触发 defunct element 断言。
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

      // 调用服务：更新数据库并写回系统相册
      final assetId = _currentAssetId!;
      await favoriteService.toggleFavorite(assetId);

      // 用本地覆盖更新 UI，不在查看器内 invalidate timeline（避免 refetch 通知到已 dispose 的 element）
      final newFavoriteStatus = !currentStatus;
      _favoriteOverrides[assetId] = newFavoriteStatus;
      if (mounted) {
        setState(() {});
        // 缩略图收藏图标单独监听媒体表，invalidate 后时间线页会即时更新
        ref.invalidate(assetFavoriteStatusProvider(assetId));
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
      // 失败时不刷新 provider，避免 defunct element 断言；返回时间线后数据会由其它逻辑刷新
    }
  }
}
