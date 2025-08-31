// lib/ui/group/widgets/feed_card/post_image_carousel.dart

import 'package:flutter/material.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/ui/group/widgets/feed_card/post_widget.dart';

class PostImageCarousel extends StatelessWidget {
  final List<UnifiedMediaEntity> attachments;

  const PostImageCarousel({super.key, required this.attachments});

  // --- 统一样式配置: 与参考项目完全一致 ---
  static const double imageHeight = 200.0;
  static const double imageWidth = 280.0;
  static const double imageGap = 8.0;
  static const double imageBorderRadius = 10.0;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    Widget imageContent;

    if (attachments.length == 1) {
      // 单张图片
      imageContent = Padding(
        padding: const EdgeInsets.only(left: PostWidget.contentLeftPadding),
        child: Align(
          alignment: Alignment.centerLeft,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(imageBorderRadius),
            child: Image.network(
              'https://picsum.photos/seed/${attachments.first.cloudUuid}/800/600',
              fit: BoxFit.cover,
              height: imageHeight,
            ),
          ),
        ),
      );
    } else {
      // 多张图片: 使用横向 ListView
      imageContent = ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(
          left: PostWidget.contentLeftPadding,
          right: PostWidget.horizontalPadding,
        ),
        itemCount: attachments.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(
              right: index == attachments.length - 1 ? 0 : imageGap,
            ),
            child: SizedBox(
              width: imageWidth,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(imageBorderRadius),
                child: Image.network(
                  'https://picsum.photos/seed/${attachments[index].cloudUuid}/800/600',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      );
    }

    return SizedBox(height: imageHeight, child: imageContent);
  }
}
