import 'package:flutter/material.dart';

/// 下滑退出手势（完整复刻 Immich 动画）
///
/// 使用 Listener 做指针级跟踪，避免被 PageView/PhotoView 抢手势；
/// 检测到明确下滑后认领手势，驱动：跟手位移、缩放、背景透明度。
/// 公式与 Immich AssetViewer _handleDragDown 一致。
class ViewerDismissGesture extends StatefulWidget {
  final Widget child;
  final bool isZoomed;
  final VoidCallback onDismiss;
  final VoidCallback? onSwipeUp;
  final ValueChanged<int>? onBackgroundOpacityChanged;

  const ViewerDismissGesture({
    super.key,
    required this.child,
    required this.isZoomed,
    required this.onDismiss,
    this.onSwipeUp,
    this.onBackgroundOpacityChanged,
  });

  @override
  State<ViewerDismissGesture> createState() => _ViewerDismissGestureState();
}

class _ViewerDismissGestureState extends State<ViewerDismissGesture>
    with SingleTickerProviderStateMixin {
  static const double _dragRatio = 0.2;
  static const double _popThreshold = 75.0;
  static const double _verticalClaimThreshold = 12.0;
  static const double _verticalVsHorizontalRatio = 2.0;

  double _verticalDragOffset = 0.0;
  Offset _dragStartPosition = Offset.zero;
  Offset _dragDelta = Offset.zero;
  bool _shouldPopOnDrag = false;
  bool _dismissDragActive = false;

  late AnimationController _resetController;
  Animation<double>? _resetAnimation;
  double _resetStartOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _applyOpacityFromDistance(double distance) {
    final height = MediaQuery.sizeOf(context).height;
    final maxScaleDistance = height * 0.5;
    final scaleReduction =
        (distance / maxScaleDistance).clamp(0.0, _dragRatio);
    final backgroundOpacity =
        (255 * (1.0 - scaleReduction / _dragRatio)).round();
    widget.onBackgroundOpacityChanged?.call(backgroundOpacity);
  }

  void _resetToFullOpacity() {
    widget.onBackgroundOpacityChanged?.call(255);
  }

  void _runResetAnimation() {
    _resetStartOffset = _verticalDragOffset;
    _resetController.removeListener(_onResetTick);
    _resetAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOut),
    );
    _resetController.addListener(_onResetTick);
    _resetController.forward(from: 0.0).then((_) {
      if (!mounted) return;
      _resetController.removeListener(_onResetTick);
      setState(() {
        _verticalDragOffset = 0.0;
        _dragDelta = Offset.zero;
        _shouldPopOnDrag = false;
        _dismissDragActive = false;
      });
      _resetToFullOpacity();
    });
  }

  void _onResetTick() {
    if (!mounted || _resetAnimation == null) return;
    final t = _resetAnimation!.value;
    final currentOffset = _resetStartOffset * (1.0 - t);
    setState(() => _verticalDragOffset = currentOffset);
    _applyOpacityFromDistance(currentOffset.abs());
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final distance = _dragDelta.distance;
    final maxScaleDistance = height * 0.5;
    final scaleReduction =
        (distance / maxScaleDistance).clamp(0.0, _dragRatio);
    final scale = 1.0 - scaleReduction;

    return Listener(
      onPointerDown: widget.isZoomed
          ? null
          : (event) {
              setState(() {
                _dragStartPosition = event.position;
                _verticalDragOffset = 0.0;
                _dragDelta = Offset.zero;
                _shouldPopOnDrag = false;
                _dismissDragActive = false;
              });
              _resetToFullOpacity();
            },
      onPointerMove: widget.isZoomed
          ? null
          : (event) {
              final delta = event.position - _dragStartPosition;

              if (!_dismissDragActive) {
                if (delta.dy > _verticalClaimThreshold &&
                    delta.dy > _verticalVsHorizontalRatio * delta.dx.abs()) {
                  setState(() => _dismissDragActive = true);
                } else {
                  return;
                }
              }

              if (delta.dy <= 0) {
                setState(() {
                  _verticalDragOffset = 0.0;
                  _dragDelta = Offset.zero;
                });
                _resetToFullOpacity();
                return;
              }

              setState(() {
                _verticalDragOffset = delta.dy;
                _dragDelta = delta;
                _shouldPopOnDrag =
                    delta.dy > 0 && delta.distance > _popThreshold;
              });
              _applyOpacityFromDistance(delta.distance);
            },
      onPointerUp: widget.isZoomed
          ? null
          : (event) {
              if (!_dismissDragActive) return;

              const upThreshold = 40.0;
              if (_shouldPopOnDrag) {
                widget.onDismiss();
                return;
              }
              if (_dragDelta.dy < 0 ||
                  _dragDelta.distance < 1 ||
                  _verticalDragOffset < 1) {
                if (_dragDelta.dy < -upThreshold) {
                  widget.onSwipeUp?.call();
                }
                setState(() {
                  _verticalDragOffset = 0.0;
                  _dragDelta = Offset.zero;
                  _dismissDragActive = false;
                });
                _resetToFullOpacity();
                return;
              }
              _runResetAnimation();
            },
      onPointerCancel: widget.isZoomed
          ? null
          : (_) {
              if (_dismissDragActive) {
                setState(() {
                  _verticalDragOffset = 0.0;
                  _dragDelta = Offset.zero;
                  _dismissDragActive = false;
                });
                _resetToFullOpacity();
              }
            },
      child: AbsorbPointer(
        absorbing: _dismissDragActive,
        child: Transform.translate(
          offset: Offset(0, _verticalDragOffset),
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.center,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
