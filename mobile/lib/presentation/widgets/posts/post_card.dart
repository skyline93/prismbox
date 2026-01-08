// lib/presentation/widgets/posts/post_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prismbox/data/models/post/post.dart';
import 'package:prismbox/presentation/widgets/posts/post_media_grid.dart';
import 'package:prismbox/presentation/widgets/user/user_circle_avatar.dart';
import 'package:prismbox/domain/entities/user_profile.dart';

/// 帖子卡片组件
/// 展示帖子信息：用户信息、文字、媒体、互动按钮
class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onTap;
  final VoidCallback? onCommentTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onShareTap;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onCommentTap,
    this.onLikeTap,
    this.onShareTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 用户信息
              _buildUserHeader(context),
              const SizedBox(height: 12),
              // 文字内容
              if (post.caption.isNotEmpty) ...[
                Text(
                  post.caption,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              // 媒体网格
              if (post.media.isNotEmpty) ...[
                PostMediaGrid(media: post.media),
                const SizedBox(height: 12),
              ],
              // 互动按钮
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context) {
    // 创建 UserProfile 用于头像组件
    final userProfile = UserProfile(
      id: post.creator.userId,
      username: post.creator.username,
      email: '', // 帖子中的用户信息不包含 email
      avatarUrl: post.creator.avatarUrl,
    );

    return Row(
      children: [
        UserCircleAvatar(
          user: userProfile,
          radius: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.creator.username,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatTime(post.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        // 点赞按钮（预留）
        // IconButton(
        //   icon: Icon(
        //     Icons.favorite_border,
        //     color: Colors.grey.shade600,
        //     size: 24,
        //   ),
        //   onPressed: onLikeTap,
        // ),
        // Text(
        //   _formatCount(post.likesCount),
        //   style: TextStyle(
        //     fontSize: 14,
        //     color: Colors.grey.shade600,
        //   ),
        // ),
        // const SizedBox(width: 16),
        // 评论按钮
        IconButton(
          icon: Icon(
            Icons.comment_outlined,
            color: Colors.grey.shade600,
            size: 24,
          ),
          onPressed: onCommentTap,
        ),
        Text(
          _formatCount(post.commentsCount),
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const Spacer(),
        // 分享按钮（预留）
        // IconButton(
        //   icon: Icon(
        //     Icons.share_outlined,
        //     color: Colors.grey.shade600,
        //     size: 24,
        //   ),
        //   onPressed: onShareTap,
        // ),
      ],
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

  String _formatCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}w';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    } else {
      return count.toString();
    }
  }
}

