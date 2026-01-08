// lib/presentation/widgets/posts/post_media_grid.dart

import 'package:flutter/material.dart';
import 'package:prismbox/data/models/post/post_media.dart';

/// 帖子媒体网格组件
/// 根据媒体数量使用不同布局：
/// - 单图：大图显示
/// - 2-4 图：2x2 网格
/// - 5-9 图：3x3 网格
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

    if (media.length == 1) {
      return _buildSingleMedia(context, media[0]);
    } else if (media.length <= 4) {
      return _build2x2Grid(context);
    } else {
      return _build3x3Grid(context);
    }
  }

  Widget _buildSingleMedia(BuildContext context, PostMedia mediaItem) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: _getAspectRatio(mediaItem),
        child: _buildMediaItem(context, mediaItem, fullWidth: true),
      ),
    );
  }

  Widget _build2x2Grid(BuildContext context) {
    final displayMedia = media.take(4).toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1.0,
      ),
      itemCount: displayMedia.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: _buildMediaItem(context, displayMedia[index]),
        );
      },
    );
  }

  Widget _build3x3Grid(BuildContext context) {
    final displayMedia = media.take(9).toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1.0,
      ),
      itemCount: displayMedia.length,
      itemBuilder: (context, index) {
        final hasMore = media.length > 9 && index == 8;
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: _buildMediaItem(context, displayMedia[index]),
            ),
            if (hasMore)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Center(
                  child: Text(
                    '+${media.length - 9}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMediaItem(
    BuildContext context,
    PostMedia mediaItem, {
    bool fullWidth = false,
  }) {
    final imageUrl = mediaItem.thumbnailUrl ?? mediaItem.previewUrl ?? '';

    if (mediaItem.isVideo) {
      return Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholder();
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _buildPlaceholder();
              },
            )
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
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholder();
        },
      );
    }
  }

  Widget _buildPlaceholder() {
    return Container(
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

  double _getAspectRatio(PostMedia mediaItem) {
    if (mediaItem.width != null && mediaItem.height != null && mediaItem.height! > 0) {
      return mediaItem.width! / mediaItem.height!;
    }
    return 1.0; // 默认正方形
  }
}

