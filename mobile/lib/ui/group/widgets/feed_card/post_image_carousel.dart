// ui/group/widgets/feed_card/post_image_carousel.dart

import 'package:flutter/foundation.dart'; // [NEW] 引入 debugPrint
import 'package:tuple/tuple.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/ui/group/widgets/feed_card/post_widget.dart';
import 'package:mobile/providers/group_providers.dart';

class PostImageCarousel extends ConsumerWidget {
  final String groupUuid;
  final List<UnifiedMediaEntity> attachments;

  const PostImageCarousel({
    super.key,
    required this.groupUuid,
    required this.attachments,
  });

  // 你可以在这里调整所有照片的统一显示高度
  static const double imageHeight = 220.0;

  static const double imageGap = 4.0;
  static const double imageBorderRadius = 8.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    // 一个通用的图片显示组件，用于处理加载、成功和失败状态
    Widget buildImageDisplay(UnifiedMediaEntity attachment) {
      final thumbnailAsyncValue = ref.watch(
        groupPostThumbnailProvider(Tuple2(attachment, groupUuid)),
      );

      return thumbnailAsyncValue.when(
        data: (thumbnailData) {
          if (thumbnailData != null && thumbnailData.isNotEmpty) {
            // 数据加载成功，使用 Image.memory 显示
            return Image.memory(
              thumbnailData,
              // 使用 BoxFit.contain 保证图片完整显示且不裁切
              // fit: BoxFit.contain,
              fit: BoxFit.cover,
              // [ADD] 为了让 cover 正确工作，需要给它一个尺寸
              width: double.infinity,
              height: double.infinity,
            );
          }
          // 数据为空或加载失败（但未抛出错误）
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
          // 加载中状态
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
          // 加载失败状态
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
      // 设置内边距
      padding: const EdgeInsets.only(
        left: PostWidget.contentLeftPadding,
        right: PostWidget.horizontalPadding,
      ),
      itemCount: attachments.length,
      itemBuilder: (context, index) {
        final attachment = attachments[index];

        // --- [LOGGING ADDED] ---
        // 在这里打印日志，以验证每次构建图片时使用的 aspectRatio 值。
        // 我们使用 kDebugMode 来确保这条日志只在调试版本中打印。
        if (kDebugMode) {
          print(
            '[PostImageCarousel] Building image index $index for post.'
            ' AspectRatio from entity: ${attachment.aspectRatio}',
          );
        }
        // -------------------------

        // 为了让加载和错误占位符也有一个合理的宽度，我们使用 AspectRatio
        // Image widget 在加载后会根据自身长宽比和 BoxFit.contain 自动调整
        // 但在 loading/error 状态下，它没有原始尺寸信息，所以我们需要提供一个
        return AspectRatio(
          // 使用实体中的真实长宽比
          aspectRatio: attachment.aspectRatio,
          child: Padding(
            // 设置图片之间的间距
            padding: EdgeInsets.only(
              right: index == attachments.length - 1 ? 0 : imageGap,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(imageBorderRadius),
              child: buildImageDisplay(attachment),
            ),
          ),
        );
      },
    );

    // 使用 SizedBox 约束轮播组件的整体高度，这是实现“高度一致”的核心
    return SizedBox(height: imageHeight, child: imageContent);
  }
}
