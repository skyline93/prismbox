// lib/ui/group/widgets/comment_widget.dart

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/ui/group/widgets/feed_card/post_content.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:mobile/domain/entities/comment_entity.dart';

class CommentWidget extends StatelessWidget {
  final CommentEntity comment;
  final bool hasThreadLine;
  final int depth;
  final VoidCallback? onReplyTapped;

  const CommentWidget({
    super.key,
    required this.comment,
    this.hasThreadLine = true,
    this.depth = 0,
    this.onReplyTapped,
  });

  static const double avatarRadius = 15.0;
  static const double horizontalPadding = 7.0;
  static const double avatarColumnWidth = avatarRadius * 2;
  static const double avatarContentGap = 7.0;
  static const double indentWidth = 20.0; // [新增] 每级回复的缩进量

  // [修改] 计算内容的左边距
  double get contentLeftPadding =>
      horizontalPadding +
      avatarColumnWidth +
      avatarContentGap +
      (depth * indentWidth);

  // [修改] 计算头像和竖线的左边距
  double get avatarLeftPadding => horizontalPadding + (depth * indentWidth);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 12.0),
      child: Stack(
        children: [
          // --- 左侧: 头像和竖线 ---
          Positioned(
            left: avatarLeftPadding, // [修改] 使用计算后的边距
            top: 0,
            bottom: 0,
            width: avatarColumnWidth,
            child: Column(
              children: [
                CircleAvatar(
                  radius: avatarRadius,
                  backgroundImage: comment.author.avatarUrl != null
                      ? NetworkImage(comment.author.avatarUrl!)
                      : null,
                  child: comment.author.avatarUrl == null
                      ? const Icon(Icons.person, size: avatarRadius)
                      : null,
                ),
                if (hasThreadLine)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Container(width: 2, color: Colors.grey.shade300),
                    ),
                  ),
              ],
            ),
          ),
          // --- 右侧: 评论内容区 ---
          Padding(
            padding: EdgeInsets.only(
              left: contentLeftPadding, // [修改] 使用计算后的边距
              right: horizontalPadding,
              bottom: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 用户名和时间 ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      comment.author.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      timeago.format(comment.createdAt, locale: 'zh_CN'),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // --- 评论文本内容 ---
                PostContent(text: comment.content),
                const SizedBox(height: 12),
                // --- [修改] 评论操作 (点赞和回复) ---
                Row(
                  children: [
                    const Icon(Iconsax.heart, size: 22, color: Colors.black),
                    const SizedBox(width: 16),
                    // [新增] 回复按钮
                    GestureDetector(
                      onTap: onReplyTapped,
                      child: const Icon(
                        Iconsax.message,
                        size: 22,
                        color: Colors.black,
                      ),
                    ),
                    if (comment.likesCount > 0) ...[
                      const SizedBox(width: 16),
                      Text(
                        '${comment.likesCount} likes',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
