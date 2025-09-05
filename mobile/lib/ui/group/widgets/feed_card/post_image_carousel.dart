// lib/ui/group/widgets/feed_card/post_image_carousel.dart

import 'package:flutter/foundation.dart';
import 'package:tuple/tuple.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/ui/group/widgets/feed_card/post_widget.dart';
import 'package:mobile/providers/group_providers.dart';
import 'package:mobile/ui/group/widgets/photo_viewer_page.dart'; // [NEW] 导入新的预览页面

class PostImageCarousel extends ConsumerWidget {
  final String groupUuid;
  final List<UnifiedMediaEntity> attachments;

  const PostImageCarousel({
    super.key,
    required this.groupUuid,
    required this.attachments,
  });

  static const double imageHeight = 220.0;
  static const double imageGap = 4.0;
  static const double imageBorderRadius = 8.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    Widget buildImageDisplay(UnifiedMediaEntity attachment) {
      final thumbnailAsyncValue = ref.watch(
        groupPostThumbnailProvider(Tuple2(attachment, groupUuid)),
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
        loading: () {
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

    final imageContent = ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(
        left: PostWidget.contentLeftPadding,
        right: PostWidget.horizontalPadding,
      ),
      itemCount: attachments.length,
      itemBuilder: (context, index) {
        final attachment = attachments[index];

        if (kDebugMode) {
          print(
            '[PostImageCarousel] Building image index $index for post.'
            ' AspectRatio from entity: ${attachment.aspectRatio}',
          );
        }

        return AspectRatio(
          aspectRatio: attachment.aspectRatio,
          child: Padding(
            padding: EdgeInsets.only(
              right: index == attachments.length - 1 ? 0 : imageGap,
            ),
            // [MODIFIED] 使用 GestureDetector 包裹图片以添加点击事件
            child: GestureDetector(
              onTap: () {
                // [NEW] 点击时导航到 PhotoViewerPage
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PhotoViewerPage(
                      attachments: attachments,
                      initialIndex: index,
                      groupUuid: groupUuid,
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(imageBorderRadius),
                child: buildImageDisplay(attachment),
              ),
            ),
          ),
        );
      },
    );

    return SizedBox(height: imageHeight, child: imageContent);
  }
}
