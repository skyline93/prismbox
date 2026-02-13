// lib/presentation/widgets/posts/photo_viewer_page.dart

import 'package:flutter/material.dart';
import 'package:prismbox/data/models/post/post_media.dart';
import 'package:prismbox/presentation/widgets/posts/post_media_image_provider.dart';
import 'package:prismbox/presentation/widgets/viewer/media_gallery_viewer.dart';
import 'package:prismbox/widgets/photo_view.dart';
import 'package:prismbox/widgets/photo_view_gallery.dart';

/// 帖子媒体预览页面（与照片预览页效果一致）
///
/// 使用 [MediaGalleryViewer] 实现：手势下滑渐变退出、双击放大、单击进入/退出沉浸式。
class PhotoViewerPage extends StatelessWidget {
  final List<PostMedia> media;
  final int initialIndex;
  /// 下载回调：参数为当前预览的 PostMedia，返回是否已加入队列
  final Future<bool> Function(PostMedia media)? onDownload;

  const PhotoViewerPage({
    super.key,
    required this.media,
    required this.initialIndex,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return MediaGalleryViewer(
      initialIndex: initialIndex.clamp(0, media.length - 1),
      itemCount: media.length,
      pageOptionsBuilder: (context, index, gestureCallbacks,
          {showControls = true, onToggleControls}) {
        return _buildPageOptions(
          context,
          index,
          gestureCallbacks,
          showControls: showControls,
          onToggleControls: onToggleControls,
        );
      },
      onPageChanged: (_) {},
      onDismiss: () => Navigator.of(context).pop(),
      controlsBuilder: _buildControls,
      gaplessPlayback: true,
    );
  }

  PhotoViewGalleryPageOptions _buildPageOptions(
    BuildContext context,
    int index,
    MediaGalleryGestureCallbacks gestureCallbacks, {
    bool showControls = true,
    VoidCallback? onToggleControls,
  }) {
    final mediaItem = media[index];
    final mediaSize = MediaQuery.sizeOf(context);

    if (mediaItem.isVideo) {
      final imageUrl = mediaItem.previewUrl ?? mediaItem.thumbnailUrl ?? '';
      if (imageUrl.isEmpty) {
        return PhotoViewGalleryPageOptions.customChild(
          onDragStart: gestureCallbacks.onDragStart,
          onDragUpdate: gestureCallbacks.onDragUpdate,
          onDragEnd: gestureCallbacks.onDragEnd,
          onTapDown: gestureCallbacks.onTapDown,
          initialScale: PhotoViewComputedScale.contained * 0.99,
          minScale: PhotoViewComputedScale.contained * 0.99,
          maxScale: 1.0,
          disableScaleGestures: true,
          heroAttributes: PhotoViewHeroAttributes(tag: 'post_media_${mediaItem.uuid}_$index'),
          child: Container(
            width: mediaSize.width,
            height: mediaSize.height,
            color: Colors.black,
            child: const Center(
              child: Icon(
                Icons.video_library_outlined,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
        );
      }
      return PhotoViewGalleryPageOptions.customChild(
        onDragStart: gestureCallbacks.onDragStart,
        onDragUpdate: gestureCallbacks.onDragUpdate,
        onDragEnd: gestureCallbacks.onDragEnd,
        onTapDown: gestureCallbacks.onTapDown,
        initialScale: PhotoViewComputedScale.contained * 0.99,
        minScale: PhotoViewComputedScale.contained * 0.99,
        maxScale: 1.0,
        disableScaleGestures: true,
        heroAttributes: PhotoViewHeroAttributes(tag: 'post_media_${mediaItem.uuid}_$index'),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Image(
                image: PostMediaImageProvider(url: imageUrl),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(
                    Icons.video_library_outlined,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
              ),
            ),
            const Center(
              child: Icon(
                Icons.play_circle_outline,
                color: Colors.white,
                size: 64,
              ),
            ),
          ],
        ),
      );
    }

    // 图片
    final imageUrl = mediaItem.previewUrl ??
        mediaItem.downloadUrl ??
        mediaItem.thumbnailUrl ??
        '';
    if (imageUrl.isEmpty) {
      return PhotoViewGalleryPageOptions.customChild(
        onDragStart: gestureCallbacks.onDragStart,
        onDragUpdate: gestureCallbacks.onDragUpdate,
        onDragEnd: gestureCallbacks.onDragEnd,
        onTapDown: gestureCallbacks.onTapDown,
        initialScale: PhotoViewComputedScale.contained * 0.99,
        minScale: PhotoViewComputedScale.contained * 0.99,
        maxScale: PhotoViewComputedScale.covered * 4.0,
        heroAttributes: PhotoViewHeroAttributes(tag: 'post_media_${mediaItem.uuid}_$index'),
        child: Container(
          width: mediaSize.width,
          height: mediaSize.height,
          color: Colors.black,
          child: const Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              color: Colors.white,
              size: 48,
            ),
          ),
        ),
      );
    }

    return PhotoViewGalleryPageOptions(
      key: ValueKey('post_media_${mediaItem.uuid}_$index'),
      imageProvider: PostMediaImageProvider(url: imageUrl),
      heroAttributes: PhotoViewHeroAttributes(
        tag: 'post_media_${mediaItem.uuid}_$index',
        transitionOnUserGestures: true,
      ),
      filterQuality: FilterQuality.high,
      tightMode: true,
      initialScale: PhotoViewComputedScale.contained * 0.99,
      minScale: PhotoViewComputedScale.contained * 0.99,
      maxScale: PhotoViewComputedScale.covered * 4.0,
      onDragStart: gestureCallbacks.onDragStart,
      onDragUpdate: gestureCallbacks.onDragUpdate,
      onDragEnd: gestureCallbacks.onDragEnd,
      onTapDown: gestureCallbacks.onTapDown,
      errorBuilder: (_, __, ___) => Container(
        width: mediaSize.width,
        height: mediaSize.height,
        color: Colors.black,
        child: const Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: Colors.white,
            size: 48,
          ),
        ),
      ),
    );
  }

  Future<void> _handleDownload(BuildContext context, int currentIndex) async {
    final callback = onDownload;
    if (callback == null) return;
    final mediaItem = media[currentIndex];
    final added = await callback(mediaItem);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(added ? '已加入下载队列' : '已在下载队列中'),
        ),
      );
    }
  }

  Widget? _buildControls(
    BuildContext context,
    int currentIndex,
    bool showControls,
    VoidCallback onToggleControls,
  ) {
    if (!showControls) return const SizedBox.shrink();

    // 控制栏仅在「显示控制」时出现，此时背景为白色；不透明背景避免放大时照片透出
    const iconColor = Colors.black87;
    const textColor = Colors.black87;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(
        left: 8,
        right: 8,
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: iconColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              '${currentIndex + 1} / ${media.length}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onDownload != null)
            IconButton(
              icon: Icon(Icons.download, color: iconColor),
              onPressed: () => _handleDownload(context, currentIndex),
            )
          else
            const SizedBox(width: 48, height: 48),
        ],
      ),
    );
  }
}
