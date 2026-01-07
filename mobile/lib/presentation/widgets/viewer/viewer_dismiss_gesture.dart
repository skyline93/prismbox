import 'package:flutter/material.dart';

/// 下滑退出手势处理组件
///
/// 封装垂直拖动手势识别，处理退出动画（执行和重置），
/// 隔离手势逻辑，避免影响主页面状态。
class ViewerDismissGesture extends StatefulWidget {
  /// 子组件
  final Widget child;

  /// 是否已放大（放大时禁用手势）
  final bool isZoomed;

  /// 退出回调
  final VoidCallback onDismiss;

  const ViewerDismissGesture({
    super.key,
    required this.child,
    required this.isZoomed,
    required this.onDismiss,
  });

  @override
  State<ViewerDismissGesture> createState() => _ViewerDismissGestureState();
}

class _ViewerDismissGestureState extends State<ViewerDismissGesture>
    with SingleTickerProviderStateMixin {
  /// 垂直拖动偏移量
  double _verticalDragOffset = 0.0;

  /// 垂直拖动起始位置
  double _verticalDragStartY = 0.0;

  /// 退出动画控制器
  late AnimationController _dismissAnimationController;

  /// 退出动画
  Animation<double>? _dismissAnimation;

  @override
  void initState() {
    super.initState();
    // 初始化退出动画控制器
    _dismissAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _dismissAnimationController.dispose();
    super.dispose();
  }

  /// 执行退出动画
  void _dismissWithAnimation() {
    final screenHeight = MediaQuery.of(context).size.height;
    final startOffset = _verticalDragOffset;
    final endOffset = screenHeight;

    // 移除之前的监听器（如果有）
    _dismissAnimationController.removeListener(_animationListener);

    // 创建动画
    _dismissAnimation = Tween<double>(begin: startOffset, end: endOffset)
        .animate(
          CurvedAnimation(
            parent: _dismissAnimationController,
            curve: Curves.easeOut,
          ),
        );

    // 添加监听器
    _dismissAnimationController.addListener(_animationListener);

    _dismissAnimationController.forward().then((_) {
      // 动画完成后退出
      if (mounted) {
        _dismissAnimationController.removeListener(_animationListener);
        widget.onDismiss();
      }
    });
  }

  /// 重置退出动画
  void _resetDismissAnimation() {
    // 移除之前的监听器（如果有）
    _dismissAnimationController.removeListener(_animationListener);

    _dismissAnimationController.reset();
    _dismissAnimation = Tween<double>(begin: _verticalDragOffset, end: 0.0)
        .animate(
          CurvedAnimation(
            parent: _dismissAnimationController,
            curve: Curves.easeOut,
          ),
        );

    // 添加监听器
    _dismissAnimationController.addListener(_animationListener);

    _dismissAnimationController.forward().then((_) {
      if (mounted) {
        _dismissAnimationController.removeListener(_animationListener);
        setState(() {
          _verticalDragOffset = 0.0;
        });
        _dismissAnimationController.reset();
      }
    });
  }

  /// 动画监听器回调
  void _animationListener() {
    if (mounted && _dismissAnimation != null) {
      setState(() {
        _verticalDragOffset = _dismissAnimation!.value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 计算动画进度（0.0 到 1.0）
    final screenHeight = MediaQuery.of(context).size.height;
    final dragProgress = (_verticalDragOffset / screenHeight).clamp(0.0, 1.0);

    // 计算缩放比例（从 1.0 缩小到 0.3）
    final scale = 1.0 - (dragProgress * 0.7);

    // 计算内容透明度（从 1.0 到 0.5）
    final contentOpacity = 1.0 - (dragProgress * 0.5);

    return GestureDetector(
      // 只在未放大时响应垂直滑动
      onVerticalDragStart: widget.isZoomed
          ? null
          : (details) {
              setState(() {
                _verticalDragStartY = details.globalPosition.dy;
                _verticalDragOffset = 0.0;
              });
            },
      onVerticalDragUpdate: widget.isZoomed
          ? null
          : (details) {
              // 只响应向下滑动
              final delta = details.globalPosition.dy - _verticalDragStartY;
              if (delta > 0) {
                setState(() {
                  _verticalDragOffset = delta;
                });
              }
            },
      onVerticalDragEnd: widget.isZoomed
          ? null
          : (details) {
              final screenHeight = MediaQuery.of(context).size.height;
              final threshold = screenHeight * 0.03; // 3% 的屏幕高度作为阈值

              // 如果向下滑动距离超过阈值，则执行退出动画
              if (_verticalDragOffset > threshold) {
                _dismissWithAnimation();
              } else {
                // 否则重置偏移量，添加回弹动画
                _resetDismissAnimation();
              }
            },
      // 使用 translucent 行为，确保不会拦截子组件的手势
      behavior: HitTestBehavior.translucent,
      child: Transform.translate(
        offset: Offset(0, _verticalDragOffset),
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.topCenter,
          child: Opacity(opacity: contentOpacity, child: widget.child),
        ),
      ),
    );
  }
}
