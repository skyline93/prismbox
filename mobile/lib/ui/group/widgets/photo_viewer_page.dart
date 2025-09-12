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

class _PhotoViewerPageState extends State<PhotoViewerPage>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late int _currentIndex;

  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;
  Offset _dragPosition = Offset.zero;
  bool _isDragging = false;

  bool _isPageViewScrollable = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _currentIndex = widget.initialIndex;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

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

  void _onVerticalDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _isPageViewScrollable = false;
    });
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragPosition += details.delta;
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final screenSize = MediaQuery.of(context).size;
    final dismissThreshold = screenSize.height * 0.25;
    final velocityThreshold = 800;

    if (_dragPosition.dy.abs() > dismissThreshold ||
        details.primaryVelocity!.abs() > velocityThreshold) {
      Navigator.of(context).pop();
    } else {
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
      _isPageViewScrollable = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double backgroundOpacity =
        (1 - _dragPosition.dy.abs() / (screenSize.height * 0.4)).clamp(
          0.0,
          1.0,
        );

    return GestureDetector(
      onVerticalDragStart: _onVerticalDragStart,
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(backgroundOpacity),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(
            color: Colors.white.withOpacity(backgroundOpacity),
          ),
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
        body: Transform.translate(
          offset: _dragPosition,
          child: PageView.builder(
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
