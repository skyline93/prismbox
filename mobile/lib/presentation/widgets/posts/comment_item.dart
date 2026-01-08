// lib/presentation/widgets/posts/comment_item.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prismbox/data/models/post/comment.dart';
import 'package:prismbox/presentation/widgets/user/user_circle_avatar.dart';
import 'package:prismbox/domain/entities/user_profile.dart';

/// 评论项组件
/// 展示评论信息：头像、用户名、内容、时间
/// 支持嵌套回复（缩进显示）
class CommentItem extends StatelessWidget {
  final Comment comment;
  final int depth; // 嵌套深度
  final VoidCallback? onReplyTap;
  final VoidCallback? onDeleteTap;
  final bool canDelete; // 是否可以删除

  const CommentItem({
    super.key,
    required this.comment,
    this.depth = 0,
    this.onReplyTap,
    this.onDeleteTap,
    this.canDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: depth > 0 ? 48.0 : 0.0, // 回复缩进
        bottom: 12.0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像
          UserCircleAvatar(
            user: UserProfile(
              id: comment.author.userId,
              username: comment.author.username,
              email: '', // 评论中的用户信息不包含 email
              avatarUrl: comment.author.avatarUrl,
            ),
            radius: 16,
          ),
          const SizedBox(width: 12),
          // 评论内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 用户名和内容
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(
                        text: comment.author.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (depth > 0) ...[
                        TextSpan(
                          text: ' 回复 ',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        // 注意：这里需要父评论的用户名，但 Comment 模型中没有
                        // 如果需要显示，需要在数据模型中添加
                      ],
                      const TextSpan(text: ' '),
                      TextSpan(
                        text: comment.content,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // 时间和操作
                Row(
                  children: [
                    Text(
                      _formatTime(comment.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (onReplyTap != null) ...[
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: onReplyTap,
                        child: Text(
                          '回复',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                    if (canDelete && onDeleteTap != null) ...[
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: onDeleteTap,
                        child: Text(
                          '删除',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade400,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                // 回复列表
                if (comment.replies.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...comment.replies.map(
                    (reply) => CommentItem(
                      comment: reply,
                      depth: depth + 1,
                      onReplyTap: onReplyTap,
                      onDeleteTap: onDeleteTap,
                      canDelete: canDelete,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 7) {
      return DateFormat('yyyy-MM-dd').format(time);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
}

