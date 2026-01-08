// lib/presentation/widgets/posts/post_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prismbox/data/models/post/post.dart';
import 'package:prismbox/presentation/widgets/posts/post_media_grid.dart';
import 'package:prismbox/presentation/widgets/user/user_circle_avatar.dart';
import 'package:prismbox/domain/entities/user_profile.dart';

/// 帖子卡片组件（Threads 风格）
/// 展示帖子信息：左侧头像列 + 右侧内容区
class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onTap;
  final VoidCallback? onCommentTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onShareTap;
  final bool hasAddIcon; // 头像上的加号图标

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onCommentTap,
    this.onLikeTap,
    this.onShareTap,
    this.hasAddIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // 左侧：头像列
          _buildAvatarColumn(context),
          const SizedBox(width: 12),
          // 右侧：内容区
          Expanded(
            child: _buildContentArea(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarColumn(BuildContext context) {
    // 创建 UserProfile 用于头像组件
    final userProfile = UserProfile(
      id: post.creator.userId,
      username: post.creator.username,
      email: '', // 帖子中的用户信息不包含 email
      avatarUrl: post.creator.avatarUrl,
    );

    return Column(
      children: [
        Stack(
      children: [
        UserCircleAvatar(
          user: userProfile,
          radius: 20,
        ),
            if (hasAddIcon)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_circle, color: Colors.black, size: 16),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildContentArea(BuildContext context) {
    return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 顶部：用户名、认证标、标签、时间、更多图标
        _buildUserHeader(context),
        // 帖子正文
        if (post.caption.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
            child: Text(
              post.caption,
              style: const TextStyle(fontSize: 15, height: 1.3),
            ),
          ),
        ],
        // 图片轮播区
        if (post.media.isNotEmpty) ...[
          PostMediaGrid(media: post.media),
        ],
        // 地点标签（如果有，暂时不显示，因为 Post 模型中没有 location 字段）
        // if (location != null)
        //   Padding(
        //     padding: const EdgeInsets.only(top: 8.0),
        //     child: Text(
        //       location!,
        //       style: TextStyle(color: Colors.grey[500], fontSize: 13),
        //     ),
        //   ),
        // 底部操作栏（图标）
        Padding(
          padding: const EdgeInsets.only(top: 6.0, bottom: 4.0),
          child: Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.favorite_border, size: 18),
                onPressed: onLikeTap,
              ),
              const SizedBox(width: 12),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                onPressed: onCommentTap,
              ),
              const SizedBox(width: 12),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.autorenew, size: 18),
                onPressed: () {
                  // TODO: 实现转发功能
                },
              ),
              const SizedBox(width: 12),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.send, size: 18),
                onPressed: onShareTap,
              ),
            ],
          ),
        ),
        // 点赞和回复数
        Row(
          children: [
            Text(
              '${_formatCount(post.likesCount)} likes',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            if (post.commentsCount > 0) ...[
              const SizedBox(width: 8),
              Text(
                '${_formatCount(post.commentsCount)} reply',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildUserHeader(BuildContext context) {
    return Row(
      children: [
        Text(
          post.creator.username,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Colors.black,
          ),
        ),
        // 认证标记（暂时不显示，因为 UserSimpleInfo 中没有 isVerified 字段）
        // if (isVerified) ...[
        //   const SizedBox(width: 4),
        //   const Icon(Icons.verified, color: Colors.blue, size: 14),
        // ],
        // 话题标签（暂时不显示，因为 Post 模型中没有 tagText 字段）
        // if (tagText != null) ...[
        //   const SizedBox(width: 4),
        //   Text(
        //     '› $tagText',
        //     style: TextStyle(color: Colors.grey[500], fontSize: 14),
        //   ),
        // ],
        const Spacer(),
        Text(
          _formatTime(post.createdAt),
          style: TextStyle(color: Colors.grey[500], fontSize: 14),
        ),
        const SizedBox(width: 12),
        const Icon(Icons.more_horiz, color: Colors.black, size: 20),
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
