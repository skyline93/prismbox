// lib/ui/group/widgets/feed_card/post_image_carousel.dart

import 'package:flutter/foundation.dart';
import 'package:tuple/tuple.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/ui/group/widgets/feed_card/post_widget.dart';
import 'package:mobile/providers/group_providers.dart';
import 'package:mobile/ui/group/widgets/photo_viewer_page.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart'; // 需要添加这个库

class PostImageCarousel extends ConsumerStatefulWidget {
  final String groupUuid;
  final List<UnifiedMediaEntity> attachments;
  final bool isDetailView; // [新增]

  const PostImageCarousel({
    super.key,
    required this.groupUuid,
    required this.attachments,
    this.isDetailView = false, // [新增]
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

  // 抽离出的图片构建逻辑
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

  // 图片点击事件
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

    // [新增] 如果是详情页视图，使用 PageView
    if (widget.isDetailView) {
      return _buildDetailPageView();
    }

    // 默认（Feed流）视图，使用 ListView
    return _buildFeedListView();
  }

  // Feed 流中的横向滚动列表
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

  // [修改] 详情页中的全宽滑动视图
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
              // [修改] 使用 Stack 来添加序号
              return Stack(
                fit: StackFit.expand,
                children: [
                  // 图片本身
                  GestureDetector(
                    onTap: () => _onImageTap(index),
                    child: _buildImage(attachment),
                  ),
                  // [新增] 序号指示器，仅在多张图片时显示
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
        // [修改] 指示器现在只用作底部的点，不再需要序号功能
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
