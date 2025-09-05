// lib/ui/group/widgets/photo_viewer_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/providers/group_providers.dart';
import 'package:tuple/tuple.dart';

class PhotoViewerPage extends StatefulWidget {
  final List<UnifiedMediaEntity> attachments;
  final int initialIndex;
  final String groupUuid;

  const PhotoViewerPage({
    super.key,
    required this.attachments,
    required this.initialIndex,
    required this.groupUuid,
  });

  @override
  State<PhotoViewerPage> createState() => _PhotoViewerPageState();
}

// [MODIFIED] 使用 with SingleTickerProviderStateMixin 来支持动画控制器
class _PhotoViewerPageState extends State<PhotoViewerPage>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late int _currentIndex;

  // [NEW] 用于处理手势和动画的状态变量
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;
  Offset _dragPosition = Offset.zero;
  bool _isDragging = false;

  // [NEW] 用于控制 PageView 是否可以水平滑动
  // 当用户开始垂直滑动时，我们应禁止水平滑动，以避免手势冲突
  bool _isPageViewScrollable = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _currentIndex = widget.initialIndex;

    // [NEW] 初始化动画控制器
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    // [NEW] 监听动画控制器，并在动画值改变时更新UI
    _animationController.addListener(() {
      setState(() {
        _dragPosition = _offsetAnimation.value;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // [NEW] 垂直拖动开始时的处理
  void _onVerticalDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      // 开始垂直拖动时，禁止 PageView 的水平滚动
      _isPageViewScrollable = false;
    });
  }

  // [NEW] 垂直拖动过程中的处理
  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragPosition += details.delta;
    });
  }

  // [NEW] 垂直拖动结束时的处理
  void _onVerticalDragEnd(DragEndDetails details) {
    final screenSize = MediaQuery.of(context).size;
    // 定义关闭页面的阈值：拖动超过屏幕高度的 25% 或 速度足够快
    final dismissThreshold = screenSize.height * 0.25;
    final velocityThreshold = 800;

    // 如果满足关闭条件
    if (_dragPosition.dy.abs() > dismissThreshold ||
        details.primaryVelocity!.abs() > velocityThreshold) {
      // 执行一个快速的透明度动画然后关闭页面
      Navigator.of(context).pop();
    } else {
      // 否则，执行动画弹回原位
      _offsetAnimation = Tween<Offset>(begin: _dragPosition, end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOut,
            ),
          );
      _animationController.forward(from: 0.0);
    }

    setState(() {
      _isDragging = false;
      // 拖动结束后，恢复 PageView 的水平滚动能力
      _isPageViewScrollable = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    // [NEW] 根据拖动距离计算背景的透明度，提供视觉反馈
    // 当拖动到屏幕高度的 40% 时，背景将接近透明
    final double backgroundOpacity =
        (1 - _dragPosition.dy.abs() / (screenSize.height * 0.4)).clamp(
          0.0,
          1.0,
        );

    // [MODIFIED] 将整个 Scaffold 包裹在 GestureDetector 中来监听垂直拖动手势
    return GestureDetector(
      onVerticalDragStart: _onVerticalDragStart,
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      child: Scaffold(
        // [MODIFIED] 背景颜色会随着拖动而变化
        backgroundColor: Colors.black.withOpacity(backgroundOpacity),
        // [MODIFIED] AppBar 也随着拖动而渐隐
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(
            color: Colors.white.withOpacity(backgroundOpacity),
          ),
          // 使用 AnimatedOpacity 使标题在拖动时平滑地消失
          title: AnimatedOpacity(
            duration: const Duration(milliseconds: 100),
            opacity: _isDragging ? 0.0 : 1.0,
            child: Text(
              '${_currentIndex + 1} / ${widget.attachments.length}',
              style: TextStyle(
                color: Colors.white.withOpacity(backgroundOpacity),
              ),
            ),
          ),
          centerTitle: true,
        ),
        // [MODIFIED] 将 PageView 包裹在 Transform.translate 中，使其跟随手势移动
        body: Transform.translate(
          offset: _dragPosition,
          child: PageView.builder(
            // [MODIFIED] 根据状态决定 PageView 是否可以滚动
            physics: _isPageViewScrollable
                ? const PageScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            controller: _pageController,
            itemCount: widget.attachments.length,
            itemBuilder: (context, index) {
              final attachment = widget.attachments[index];
              return Consumer(
                builder: (context, ref, child) {
                  final fullImageAsyncValue = ref.watch(
                    groupPostFullImageProvider(
                      Tuple2(attachment, widget.groupUuid),
                    ),
                  );

                  return fullImageAsyncValue.when(
                    data: (imageData) {
                      if (imageData != null && imageData.isNotEmpty) {
                        return InteractiveViewer(
                          minScale: 1.0,
                          maxScale: 4.0,
                          child: Center(
                            child: Image.memory(imageData, fit: BoxFit.contain),
                          ),
                        );
                      }
                      return const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.white,
                          size: 48,
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    error: (error, stack) => const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  );
                },
              );
            },
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }
}
