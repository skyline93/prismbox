// lib/ui/group/widgets/feed_card/post_widget.dart

import 'package:flutter/material.dart';
import 'package:mobile/domain/entities/group_feed_item_entity.dart';
import 'package:mobile/ui/group/widgets/feed_card/post_actions.dart';
import 'package:mobile/ui/group/widgets/feed_card/post_content.dart';
import 'package:mobile/ui/group/widgets/feed_card/post_image_carousel.dart';
import 'package:mobile/ui/group/widgets/feed_card/post_stats.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostWidget extends StatelessWidget {
  final GroupFeedItemEntity item;
  final bool hasThreadLine;

  const PostWidget({super.key, required this.item, this.hasThreadLine = true});

  static const double avatarRadius = 15.0;
  static const double horizontalPadding = 7.0;
  static const double avatarColumnWidth = avatarRadius * 2;
  static const double avatarContentGap = 7.0;
  static const double contentLeftPadding =
      horizontalPadding + avatarColumnWidth + avatarContentGap;

  @override
  Widget build(BuildContext context) {
    return Container(
      // 精确边框样式: 颜色、宽度
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12, width: 0.7)),
      ),
      child: Stack(
        children: [
          // --- 左侧: 头像和竖线 ---
          Positioned(
            left: horizontalPadding,
            top: 12.0,
            bottom: 12.0,
            width: avatarColumnWidth,
            child: Column(
              children: [
                CircleAvatar(
                  radius: avatarRadius,
                  backgroundImage: item.author.avatarUrl != null
                      ? NetworkImage(item.author.avatarUrl!)
                      : null,
                  child: item.author.avatarUrl == null
                      ? const Icon(Icons.person, size: avatarRadius)
                      : null,
                ),
                if (hasThreadLine)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      // 精确竖线样式
                      child: Container(width: 2, color: Colors.grey.shade300),
                    ),
                  ),
              ],
            ),
          ),

          // --- 右侧: 主要内容区 ---
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部间距
              const SizedBox(height: 16.0),

              // --- 用户名和时间 ---
              Padding(
                padding: const EdgeInsets.only(
                  left: contentLeftPadding,
                  right: horizontalPadding,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      item.author.username,
                      // 精确字体样式
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      timeago.format(item.createdAt, locale: 'zh_CN'),
                      // 精确字体样式
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // 用户名和内容之间的间距
              const SizedBox(height: 4),

              // --- 帖子文本内容 ---
              if (item.content.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(
                    left: contentLeftPadding,
                    right: horizontalPadding,
                  ),
                  child: PostContent(text: item.content),
                ),

              // --- 图片轮播/列表 ---
              if (item.mediaAttachments.isNotEmpty) ...[
                // 内容和图片之间的间距
                const SizedBox(height: 12),
                PostImageCarousel(attachments: item.mediaAttachments),
              ],

              // --- 操作按钮和统计信息 ---
              Padding(
                padding: const EdgeInsets.only(
                  left: contentLeftPadding,
                  right: horizontalPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 图片/内容和操作按钮之间的间距
                    const SizedBox(height: 12),
                    const PostActions(),
                    // 操作按钮和统计之间的间距
                    const SizedBox(height: 8),
                    PostStats(
                      replies: item.commentsCount,
                      likes: item.likesCount,
                    ),
                  ],
                ),
              ),

              // 底部间距
              const SizedBox(height: 12.0),
            ],
          ),
        ],
      ),
    );
  }
}
