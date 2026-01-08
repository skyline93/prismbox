// lib/presentation/widgets/posts/post_media_grid.dart

import 'package:flutter/material.dart';
import 'package:prismbox/data/models/post/post_media.dart';
import 'package:prismbox/presentation/widgets/posts/post_media_image_provider.dart';

/// 帖子媒体网格组件（Threads 风格）
/// 使用横向滚动的 ListView.separated 显示多张图片
class PostMediaGrid extends StatelessWidget {
  final List<PostMedia> media;

  const PostMediaGrid({
    super.key,
    required this.media,
  });

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 150, // 固定高度（缩小一半：从 300 改为 150）
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: media.length,
        separatorBuilder: (context, index) => const SizedBox(width: 4),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: _buildMediaItem(context, media[index]),
          );
        },
      ),
    );
  }

  Widget _buildMediaItem(BuildContext context, PostMedia mediaItem) {
    final imageUrl = mediaItem.thumbnailUrl ?? mediaItem.previewUrl ?? '';

    if (mediaItem.isVideo) {
      return Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl.isNotEmpty)
            _buildImage(imageUrl, width: 110) // 缩小一半：从 220 改为 110
          else
            _buildPlaceholder(),
          Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      );
    } else {
      if (imageUrl.isEmpty) {
        return _buildPlaceholder();
      }
        return _buildImage(imageUrl, width: 110); // 缩小一半：从 220 改为 110
      }
  }

  Widget _buildImage(String imageUrl, {required double width}) {
    // 使用自定义的 ImageProvider，支持认证头
    return SizedBox(
      width: width,
      child: Image(
        image: PostMediaImageProvider(url: imageUrl),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholder();
        },
      ),
      );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 110, // 缩小一半：从 220 改为 110
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: Colors.grey,
          size: 32,
        ),
      ),
    );
  }
}
