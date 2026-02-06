// lib/presentation/widgets/posts/post_image_carousel.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/data/models/post/post_media.dart';
import 'package:prismbox/providers/auth/auth_state_provider.dart';
import 'package:prismbox/presentation/widgets/posts/post_media_image_provider.dart';
import 'package:prismbox/presentation/widgets/posts/photo_viewer_page.dart';
import 'package:prismbox/services/download/media_download_request.dart';
import 'package:prismbox/services/download/providers/download_providers.dart';
import 'package:prismbox/data/database/enums/media_download_source_type.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

/// 帖子图片轮播组件
/// 支持 Feed 流横向滚动和详情页 PageView 两种模式
class PostImageCarousel extends ConsumerStatefulWidget {
  final List<PostMedia> media;
  final bool isDetailView; // 是否为详情页视图

  const PostImageCarousel({
    super.key,
    required this.media,
    this.isDetailView = false,
  });

  @override
  ConsumerState<PostImageCarousel> createState() => _PostImageCarouselState();
}

class _PostImageCarouselState extends ConsumerState<PostImageCarousel> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<bool> _onDownload(PostMedia media) async {
    final authState = ref.read(authNotifierProvider).value;
    if (authState is! AuthStateAuthenticated) return false;
    final userId = authState.user.id.toString();
    final downloadService = await ref.read(downloadServiceProvider.future);
    final request = MediaDownloadRequest(
      userId: userId,
      sourceType: MediaDownloadSourceType.post_media,
      sourceId: media.uuid,
      mediaUuid: media.uuid,
      livePhotoVideoUuid: media.livePhotoVideoId,
      itemType: media.itemType,
      filename: media.originalFilename ?? media.filename ?? media.uuid,
    );
    return downloadService.addDownload(request);
  }

  void _onImageTap(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoViewerPage(
          media: widget.media,
          initialIndex: index,
          onDownload: _onDownload,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.media.isEmpty) {
      return const SizedBox.shrink();
    }

    // 如果是详情页视图，使用 PageView
    if (widget.isDetailView) {
      return _buildDetailPageView();
    }

    // 默认（Feed流）视图，使用 ListView
    return _buildFeedListView();
  }

  // Feed 流中的横向滚动列表（参考 Album 项目的实现）
  Widget _buildFeedListView() {
    const double imageHeight = 220.0; // 增大一倍：从 110.0 改为 220.0
    const double imageGap = 3.0; // 图片之间的间距缩小，更紧凑
    const double imageBorderRadius = 8.0;

    // 参考 Album 项目的 PostWidget 常量
    // PostWidget.contentLeftPadding = horizontalPadding (7) + avatarColumnWidth (30) + avatarContentGap (12) = 49
    // PostWidget.horizontalPadding = 7.0
    // 这样图片可以从内容开始位置显示，右侧可以滚动到屏幕边缘之外
    // 头像半径现在是 15.0，所以 avatarColumnWidth = 30.0
    const double contentLeftPadding = 7.0 + 30.0 + 12.0; // 与 PostCard.contentLeftPadding 保持一致
    const double horizontalPadding = 7.0; // 右侧只需要很小的间距

    return SizedBox(
      height: imageHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(
          left: contentLeftPadding,
          right: horizontalPadding,
        ),
        itemCount: widget.media.length,
        itemBuilder: (context, index) {
          final media = widget.media[index];
          final aspectRatio = media.width != null && media.height != null && media.height! > 0
              ? media.width! / media.height!
              : 1.0;

          return AspectRatio(
            aspectRatio: aspectRatio,
            child: Padding(
              padding: EdgeInsets.only(
                right: index == widget.media.length - 1 ? 0 : imageGap,
              ),
              child: GestureDetector(
                onTap: () => _onImageTap(index),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(imageBorderRadius),
                  child: _buildImage(media),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 详情页中的全宽滑动视图
  Widget _buildDetailPageView() {
    final firstMedia = widget.media.first;
    final aspectRatio = firstMedia.width != null && firstMedia.height != null && firstMedia.height! > 0
        ? firstMedia.width! / firstMedia.height!
        : 1.0;
    final viewHeight = MediaQuery.of(context).size.width / aspectRatio;

    return Column(
      children: [
        SizedBox(
          height: viewHeight.clamp(400, 900), // 增大一倍：从 clamp(200, 450) 改为 clamp(400, 900)
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.media.length,
            itemBuilder: (context, index) {
              final media = widget.media[index];
              // 使用 Stack 来添加序号
              return Stack(
                fit: StackFit.expand,
                children: [
                  // 图片本身
                  GestureDetector(
                    onTap: () => _onImageTap(index),
                    child: _buildImage(media),
                  ),
                  // 序号指示器，仅在多张图片时显示
                  if (widget.media.length > 1)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${index + 1}/${widget.media.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        // 指示器现在只用作底部的点
        if (widget.media.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: SmoothPageIndicator(
              controller: _pageController,
              count: widget.media.length,
              effect: const WormEffect(
                dotHeight: 8,
                dotWidth: 8,
                activeDotColor: Colors.black,
                dotColor: Colors.grey,
              ),
            ),
          ),
      ],
    );
  }

  // 构建图片
  Widget _buildImage(PostMedia media) {
    final imageUrl = media.thumbnailUrl ?? media.previewUrl ?? '';
    final isVideo = media.isVideo;

    if (imageUrl.isEmpty) {
      return Container(
        color: Colors.grey.shade300,
        child: const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: Colors.white,
            size: 32,
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image(
          image: PostMediaImageProvider(url: imageUrl),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            debugPrint("帖子图片加载失败 for media=${media.uuid}: $error");
            return Container(
              color: Colors.grey.shade300,
              child: const Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey.shade300,
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
        // 如果是视频，显示播放图标
        if (isVideo)
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
                size: 32,
              ),
            ),
          ),
      ],
    );
  }
}
