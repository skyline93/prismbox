// lib/presentation/widgets/viewer/media_gallery_viewer.dart

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prismbox/presentation/widgets/common/photo_view.dart';
import 'package:prismbox/presentation/widgets/common/photo_view_gallery.dart';

/// 手势回调集合，由 [MediaGalleryViewer] 提供，供 [pageOptionsBuilder] 挂到每页的 [PhotoViewGalleryPageOptions] 上。
/// 实现下滑渐变退出、单击沉浸式等统一行为。
class MediaGalleryGestureCallbacks {
  const MediaGalleryGestureCallbacks({
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onTapDown,
  });

  final PhotoViewImageDragStartCallback onDragStart;
  final PhotoViewImageDragUpdateCallback onDragUpdate;
  final PhotoViewImageDragEndCallback onDragEnd;
  final PhotoViewImageTapDownCallback onTapDown;
}

/// 媒体画廊查看器（方案 B1 共享组件）
///
/// 统一实现：手势下滑渐变退出、双击放大、单击进入/退出沉浸式（背景黑白切换）、
/// 放大时禁止横向滑动。由 [PhotoViewGallery] + 内部手势/背景/沉浸逻辑完成。
///
/// 调用方通过 [pageOptionsBuilder] 提供每页的 [PhotoViewGalleryPageOptions]（图/视频），
/// 通过 [controlsBuilder] 提供顶栏/底栏等 UI。
/// [showControls] / [onToggleControls] 由查看器传入，用于视频页等需要与控制栏联动的子组件。
typedef MediaGalleryPageOptionsBuilder = PhotoViewGalleryPageOptions Function(
  BuildContext context,
  int index,
  MediaGalleryGestureCallbacks gestureCallbacks, {
  bool showControls,
  VoidCallback? onToggleControls,
});

typedef MediaGalleryControlsBuilder = Widget? Function(
  BuildContext context,
  int currentIndex,
  bool showControls,
  VoidCallback onToggleControls,
);

/// 共享的媒体画廊查看器
///
/// - [initialIndex] / [itemCount]：初始页与总页数
/// - [pageOptionsBuilder]：按索引返回每页的 [PhotoViewGalleryPageOptions]，需挂上 [gestureCallbacks] 的回调
/// - [onPageChanged]：页码变化时回调
/// - [onDismiss]：用户下滑关闭时调用（由调用方执行 pop）
/// - [controlsBuilder]：构建顶栏/底栏等，传 [currentIndex] / [showControls] / [onToggleControls]
/// - [onSwipeUp]：可选，用户上滑超过阈值时调用（如时间线查看器打开媒体信息 sheet）
class MediaGalleryViewer extends StatefulWidget {
  const MediaGalleryViewer({
    super.key,
    required this.initialIndex,
    required this.itemCount,
    required this.pageOptionsBuilder,
    required this.onDismiss,
    this.onPageChanged,
    this.controlsBuilder,
    this.onSwipeUp,
    this.gaplessPlayback = true,
  });

  final int initialIndex;
  final int itemCount;
  final MediaGalleryPageOptionsBuilder pageOptionsBuilder;
  final VoidCallback onDismiss;
  final ValueChanged<int>? onPageChanged;
  final MediaGalleryControlsBuilder? controlsBuilder;
  final void Function(BuildContext context)? onSwipeUp;
  final bool gaplessPlayback;

  @override
  State<MediaGalleryViewer> createState() => _MediaGalleryViewerState();
}

class _MediaGalleryViewerState extends State<MediaGalleryViewer> {
  late final PageController _pageController;
  int _currentIndex = 0;

  bool _showControls = true;
  bool _isZoomed = false;

  Color get _baseBackgroundColor =>
      _showControls ? Colors.white : Colors.black;

  final ValueNotifier<int> _backgroundOpacityNotifier = ValueNotifier<int>(255);

  PhotoViewControllerBase? _viewController;
  PhotoViewControllerValue _initialPhotoViewState =
      const PhotoViewControllerValue(
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

  static const double _kDragRatio = 0.2;
  static const double _kPopThreshold = 75.0;
  static const double _kOpenThreshold = 50.0;

  late MediaGalleryGestureCallbacks _gestureCallbacks;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _currentIndex = widget.initialIndex;
    _gestureCallbacks = MediaGalleryGestureCallbacks(
      onDragStart: _onDragStart,
      onDragUpdate: _onDragUpdate,
      onDragEnd: _onDragEnd,
      onTapDown: _onTapDown,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _backgroundOpacityNotifier.dispose();
    super.dispose();
  }

  void _onPageBuild(PhotoViewControllerBase controller) {
    _viewController = controller;
  }

  void _onDragStart(
    BuildContext ctx,
    DragStartDetails details,
    PhotoViewControllerBase controller,
    PhotoViewScaleStateController scaleStateController,
  ) {
    _viewController = controller;
    _dragDownPosition = details.localPosition;
    _initialPhotoViewState = controller.value;
    _hasOpenedSheetThisGesture = false;
    final isZoomed = scaleStateController.scaleState ==
            PhotoViewScaleState.zoomedIn ||
        scaleStateController.scaleState == PhotoViewScaleState.covering;
    if (isZoomed) {
      _blockGestures = true;
    }
  }

  void _onDragEnd(
    BuildContext ctx,
    DragEndDetails details,
    PhotoViewControllerValue controllerValue,
  ) {
    if (_shouldPopOnDrag) {
      widget.onDismiss();
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
    _backgroundOpacityNotifier.value = 255;
  }

  void _onDragUpdate(
    BuildContext ctx,
    DragUpdateDetails details,
    PhotoViewControllerValue controllerValue,
  ) {
    if (_blockGestures) return;
    final delta = details.localPosition - _dragDownPosition;
    _hasDraggedDown ??= delta.dy > 0;
    if (_hasDraggedDown! == false) {
      _handleDragUp(ctx, delta);
      return;
    }
    _handleDragDown(ctx, delta);
  }

  void _handleDragUp(BuildContext ctx, Offset delta) {
    final position = _initialPhotoViewState.position + Offset(0, delta.dy);
    final distanceToOrigin = position.distance;
    _viewController?.updateMultiple(position: position);
    if (!_hasOpenedSheetThisGesture && distanceToOrigin > _kOpenThreshold) {
      _hasOpenedSheetThisGesture = true;
      widget.onSwipeUp?.call(ctx);
    }
  }

  void _handleDragDown(BuildContext ctx, Offset delta) {
    final distance = delta.distance;
    _shouldPopOnDrag = delta.dy > 0 && distance > _kPopThreshold;
    final maxScaleDistance = MediaQuery.sizeOf(ctx).height * 0.5;
    final scaleReduction =
        (distance / maxScaleDistance).clamp(0.0, _kDragRatio);
    final initialScale =
        _viewController?.initialScale ?? _initialPhotoViewState.scale;
    final updatedScale =
        initialScale != null ? initialScale * (1.0 - scaleReduction) : null;
    final backgroundOpacity =
        (255 * (1.0 - (scaleReduction / _kDragRatio))).round();
    _viewController?.updateMultiple(
      position: _initialPhotoViewState.position + delta,
      scale: updatedScale,
    );
    _backgroundOpacityNotifier.value = backgroundOpacity;
  }

  void _onTapDown(
    BuildContext context,
    TapDownDetails details,
    PhotoViewControllerValue controllerValue,
  ) {
    if (!_isZoomed) _toggleControls();
  }

  void _onScaleStateChanged(PhotoViewScaleState scaleState) {
    setState(() {
      _isZoomed = scaleState != PhotoViewScaleState.initial;
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    _backgroundOpacityNotifier.value = 255;
    SystemChrome.setEnabledSystemUIMode(
      _showControls ? SystemUiMode.edgeToEdge : SystemUiMode.immersive,
    );
  }

  void _handlePageChanged(int index) {
    setState(() => _currentIndex = index);
    widget.onPageChanged?.call(index);
  }

  PhotoViewGalleryPageOptions _buildPageOptions(BuildContext context, int index) {
    return widget.pageOptionsBuilder(
      context,
      index,
      _gestureCallbacks,
      showControls: _showControls,
      onToggleControls: _toggleControls,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkBackground = !_showControls;
    final indicatorColor =
        isDarkBackground ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          ValueListenableBuilder<int>(
            valueListenable: _backgroundOpacityNotifier,
            builder: (context, opacity, _) {
              return Positioned.fill(
                child: Container(
                  color: _baseBackgroundColor.withAlpha(opacity),
                ),
              );
            },
          ),
          // 将 gallery 限制在安全区内绘制，避免放大时照片画进状态栏/底栏区域
          Positioned.fill(
            child: Padding(
              padding: MediaQuery.of(context).padding,
              child: PhotoViewGallery.builder(
                gaplessPlayback: widget.gaplessPlayback,
                pageController: _pageController,
                itemCount: widget.itemCount,
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
                backgroundDecoration:
                    const BoxDecoration(color: Colors.transparent),
                loadingBuilder: (context, event, index) {
                  final value = event == null
                      ? null
                      : event.cumulativeBytesLoaded /
                          (event.expectedTotalBytes ?? 1);
                  return Center(
                    child: CircularProgressIndicator(
                      value: value,
                      color: indicatorColor,
                    ),
                  );
                },
                enablePanAlways: true,
              ),
            ),
          ),
          // 控制栏：用 Align(topCenter) 包裹，使仅占一行的顶栏（如帖子预览）贴在顶部而非垂直居中
          if (widget.controlsBuilder != null)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: 0,
              child: SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: widget.controlsBuilder!(
                    context,
                    _currentIndex,
                    _showControls,
                    _toggleControls,
                  ) ?? const SizedBox.shrink(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
