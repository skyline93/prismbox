// lib/ui/group/widgets/feed_card/post_widget.dart

import 'package:auto_route/auto_route.dart'; // 导入 auto_route
import 'package:flutter/material.dart';
import 'package:mobile/domain/entities/group_feed_item_entity.dart';
import 'package:mobile/routing/app_router.dart';
import 'package:mobile/ui/group/widgets/feed_card/post_actions.dart';
import 'package:mobile/ui/group/widgets/feed_card/post_content.dart';
import 'package:mobile/ui/group/widgets/feed_card/post_image_carousel.dart';
import 'package:mobile/ui/group/widgets/feed_card/post_stats.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostWidget extends StatelessWidget {
  final String groupUuid;
  final GroupFeedItemEntity item;
  final bool hasThreadLine;
  final bool isDetailView;

  const PostWidget({
    super.key,
    required this.groupUuid,
    required this.item,
    this.hasThreadLine = true,
    this.isDetailView = false,
  });

  static const double avatarRadius = 15.0;
  static const double horizontalPadding = 7.0;
  static const double avatarColumnWidth = avatarRadius * 2;
  static const double avatarContentGap = 7.0;
  static const double contentLeftPadding =
      horizontalPadding + avatarColumnWidth + avatarContentGap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isDetailView
          ? null
          : () {
              AutoRouter.of(
                context,
              ).push(GroupPostDetailRoute(groupUuid: groupUuid, post: item));
            },
      child: Container(
        decoration: BoxDecoration(
          border: isDetailView
              ? null
              : const Border(
                  bottom: BorderSide(color: Colors.black12, width: 0.7),
                ),
        ),
        child: Stack(
          children: [
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
                  if (hasThreadLine && !isDetailView)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Container(width: 2, color: Colors.grey.shade300),
                      ),
                    ),
                ],
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16.0),

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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        timeago.format(item.createdAt, locale: 'zh_CN'),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                if (item.content.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: contentLeftPadding,
                      right: horizontalPadding,
                    ),
                    child: PostContent(text: item.content),
                  ),

                if (item.mediaAttachments.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  PostImageCarousel(
                    groupUuid: groupUuid,
                    attachments: item.mediaAttachments,
                    isDetailView: isDetailView,
                  ),
                ],

                Padding(
                  padding: const EdgeInsets.only(
                    left: contentLeftPadding,
                    right: horizontalPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      const PostActions(),
                      const SizedBox(height: 8),
                      PostStats(
                        replies: item.commentsCount,
                        likes: item.likesCount,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12.0),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
