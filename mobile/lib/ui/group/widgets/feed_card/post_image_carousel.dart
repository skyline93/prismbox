// lib/ui/group/widgets/feed_card/post_image_carousel.dart

import 'package:tuple/tuple.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/ui/group/widgets/feed_card/post_widget.dart';
import 'package:mobile/providers/group_providers.dart';

class PostImageCarousel extends ConsumerWidget {
  final String groupUuid;
  final List<UnifiedMediaEntity> attachments;

  const PostImageCarousel({super.key, required this.groupUuid, required this.attachments});

  static const double imageHeight = 200.0;
  static const double imageWidth = 280.0;
  static const double imageGap = 8.0;
  static const double imageBorderRadius = 10.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    // 一个通用的图片显示组件，用于处理加载、成功和失败状态
    Widget buildImageDisplay(UnifiedMediaEntity attachment) {
      final thumbnailAsyncValue = ref.watch(groupPostThumbnailProvider(Tuple2(attachment, groupUuid)));

      return thumbnailAsyncValue.when(
        data: (thumbnailData) {
          if (thumbnailData != null && thumbnailData.isNotEmpty) {
            // 数据加载成功，使用 Image.memory 显示
            return Image.memory(
              thumbnailData,
              fit: BoxFit.cover,
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
          // 加载中状态，显示一个简单的灰色背景和加载指示器
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
          // 加载失败状态，显示错误图标
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

    Widget imageContent;

    if (attachments.length == 1) {
      // 单张图片的布局
      imageContent = Padding(
        padding: const EdgeInsets.only(left: PostWidget.contentLeftPadding),
        child: Align(
          alignment: Alignment.centerLeft,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(imageBorderRadius),
            // 使用 AspectRatio 来为单张图片提供一个合理的尺寸
            child: AspectRatio(
              aspectRatio: imageWidth / imageHeight,
              child: buildImageDisplay(attachments.first),
            ),
          ),
        ),
      );
    } else {
      // 多张图片的水平滚动列表
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
                child: buildImageDisplay(attachments[index]),
              ),
            ),
          );
        },
      );
    }

    // 使用 SizedBox 约束轮播组件的整体高度
    return SizedBox(height: imageHeight, child: imageContent);
  }
}
