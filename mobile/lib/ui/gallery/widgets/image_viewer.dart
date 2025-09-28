// lib/ui/gallery/widgets/image_viewer.dart

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class MediaImageViewer extends StatelessWidget {
  final ImageProvider imageProvider;
  final String heroTag;
  final VoidCallback onTap; // 新增：接收 onTap 回调
  final Color backgroundColor;

  const MediaImageViewer({
    super.key,
    required this.imageProvider,
    required this.heroTag,
    required this.onTap, // 新增：在构造函数中接收
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // 使用 GestureDetector 包装 PhotoView 来捕获单击手势
    // PhotoView 内部会处理缩放和拖动手势
    return GestureDetector(
      onTap: onTap,
      child: PhotoView(
        imageProvider: imageProvider,
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2.5,
        heroAttributes: PhotoViewHeroAttributes(tag: heroTag),
        backgroundDecoration: BoxDecoration(color: backgroundColor),
        loadingBuilder: (context, event) => Container(color: backgroundColor),
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, color: Colors.red, size: 60),
        SizedBox(height: 16),
        Text('无法加载图片', style: TextStyle(color: Colors.white70)),
      ],
    );
  }
}
