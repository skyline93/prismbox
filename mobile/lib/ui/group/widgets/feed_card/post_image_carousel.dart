// lib/ui/group/widgets/feed_card/post_image_carousel.dart

import 'package:tuple/tuple.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/ui/group/widgets/feed_card/post_widget.dart';
import 'package:mobile/providers/group_providers.dart';
import 'package:mobile/ui/group/widgets/photo_viewer_page.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class PostImageCarousel extends ConsumerStatefulWidget {
  final String groupUuid;
  final List<UnifiedMediaEntity> attachments;
  final bool isDetailView;

  const PostImageCarousel({
    super.key,
    required this.groupUuid,
    required this.attachments,
    this.isDetailView = false,
  });

  @override
  ConsumerState<PostImageCarousel> createState() => _PostImageCarouselState();
}

class _PostImageCarouselState extends ConsumerState<PostImageCarousel> {
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildImage(UnifiedMediaEntity attachment) {
    final thumbnailAsyncValue = ref.watch(
      groupPostThumbnailProvider(Tuple2(attachment, widget.groupUuid)),
    );

    return thumbnailAsyncValue.when(
      data: (thumbnailData) {
        if (thumbnailData != null && thumbnailData.isNotEmpty) {
          return Image.memory(
            thumbnailData,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          );
        }
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
      },
      loading: () => Container(
        color: Colors.grey.shade300,
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            color: Colors.white,
          ),
        ),
      ),
      error: (error, stackTrace) {
        debugPrint("帖子轮播照片加载失败 for entityId=${attachment.id}: $error");
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
    );
  }

  void _onImageTap(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoViewerPage(
          attachments: widget.attachments,
          initialIndex: index,
          groupUuid: widget.groupUuid,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    if (widget.isDetailView) {
      return _buildDetailPageView();
    }

    return _buildFeedListView();
  }

  Widget _buildFeedListView() {
    const double imageHeight = 220.0;
    const double imageGap = 4.0;
    const double imageBorderRadius = 8.0;

    return SizedBox(
      height: imageHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(
          left: PostWidget.contentLeftPadding,
          right: PostWidget.horizontalPadding,
        ),
        itemCount: widget.attachments.length,
        itemBuilder: (context, index) {
          final attachment = widget.attachments[index];
          return AspectRatio(
            aspectRatio: attachment.aspectRatio,
            child: Padding(
              padding: EdgeInsets.only(
                right: index == widget.attachments.length - 1 ? 0 : imageGap,
              ),
              child: GestureDetector(
                onTap: () => _onImageTap(index),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(imageBorderRadius),
                  child: _buildImage(attachment),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailPageView() {
    final firstAttachment = widget.attachments.first;
    final viewHeight =
        MediaQuery.of(context).size.width / firstAttachment.aspectRatio;

    return Column(
      children: [
        SizedBox(
          height: viewHeight.clamp(200, 450),
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.attachments.length,
            itemBuilder: (context, index) {
              final attachment = widget.attachments[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    onTap: () => _onImageTap(index),
                    child: _buildImage(attachment),
                  ),
                  if (widget.attachments.length > 1)
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
                          '${index + 1}/${widget.attachments.length}',
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
        if (widget.attachments.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: SmoothPageIndicator(
              controller: _pageController,
              count: widget.attachments.length,
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
}
