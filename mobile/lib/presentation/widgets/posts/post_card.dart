// lib/presentation/widgets/posts/post_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prismbox/data/models/post/post.dart';
import 'package:prismbox/presentation/widgets/posts/post_image_carousel.dart';
import 'package:prismbox/presentation/widgets/user/user_circle_avatar.dart';
import 'package:prismbox/domain/entities/user_profile.dart';

/// 帖子卡片组件（参考 Album 项目的布局方式）
/// 展示帖子信息：左侧头像列 + 右侧内容区，图片不受屏幕左右限制
class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onTap;
  final VoidCallback? onCommentTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onShareTap;
  /// 点击「来自 XX 圈子」区域时回调（用于 Feed 页切换选中圈子或跳转）
  final VoidCallback? onGroupTap;
  final bool hasAddIcon; // 头像上的加号图标

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onCommentTap,
    this.onLikeTap,
    this.onShareTap,
    this.onGroupTap,
    this.hasAddIcon = false,
  });

  // 布局常量（参考 Album 项目的设计）
  static const double avatarRadius = 15.0; // 缩小头像，从 20.0 缩小到 15.0
  static const double horizontalPadding = 7.0;
  static const double avatarColumnWidth = avatarRadius * 2;
  static const double avatarContentGap = 12.0;
  static const double contentLeftPadding =
      horizontalPadding + avatarColumnWidth + avatarContentGap;

  @override
  Widget build(BuildContext context) {
    // 参考 Album 项目的布局方式：使用 Stack + Positioned，没有外层 padding
    // 这样图片可以不受屏幕左右限制
    return InkWell(
      onTap: onTap,
      child: Container(
        // 底部边框
        decoration: BoxDecoration(
          border: const Border(
            bottom: BorderSide(color: Colors.black12, width: 0.7),
          ),
        ),
        child: Stack(
          children: [
            // --- 左侧: 头像列 ---
            Positioned(
              left: horizontalPadding,
              top: 8.0,
              bottom: 8.0,
              width: avatarColumnWidth,
              child: _buildAvatarColumn(context),
            ),

            // --- 右侧: 主要内容区 ---
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 顶部间距
                const SizedBox(height: 12.0),

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
                        post.creator.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.black,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            _formatTime(post.createdAt),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.more_horiz, color: Colors.black, size: 20),
                        ],
                      ),
                    ],
                  ),
                ),
                // 用户名和内容之间的间距
                const SizedBox(height: 2),

                // --- 所属圈子标签（全部 Feed 时展示「来自 XX」）---
                if (post.groupName != null && post.groupName!.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                      left: contentLeftPadding,
                      right: horizontalPadding,
                    ),
                    child: GestureDetector(
                      onTap: onGroupTap,
                      behavior: HitTestBehavior.opaque,
                      child: Text(
                        '来自 ${post.groupName}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                ],

                // --- 帖子正文 ---
                if (post.caption.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                      left: contentLeftPadding,
                      right: horizontalPadding,
                    ),
                    child: Text(
                      post.caption,
                      style: const TextStyle(fontSize: 15, height: 1.3),
                    ),
                  ),
                ],

                // --- 图片轮播/列表（不受屏幕左右限制）---
                if (post.media.isNotEmpty) ...[
                  // 内容和图片之间的间距
                  const SizedBox(height: 6),
                  PostImageCarousel(
                    media: post.media,
                    isDetailView: false, // Feed流中不是详情页
                  ),
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
                      const SizedBox(height: 15),
                      // 底部操作栏（图标 + 统计数）
                      Row(
                        children: [
                          // 点赞按钮 + 点赞数
                          GestureDetector(
                            onTap: onLikeTap,
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.favorite_border, size: 18),
                                if (post.likesCount > 0) ...[
                                  const SizedBox(width: 2),
                                  Text(
                                    _formatCount(post.likesCount),
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          // 回复按钮 + 回复数
                          GestureDetector(
                            onTap: onCommentTap,
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.chat_bubble_outline, size: 18),
                                if (post.commentsCount > 0) ...[
                                  const SizedBox(width: 2),
                                  Text(
                                    _formatCount(post.commentsCount),
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          // 转发按钮
                          GestureDetector(
                            onTap: () {
                              // TODO: 实现转发功能
                            },
                            behavior: HitTestBehavior.opaque,
                            child: const Icon(Icons.autorenew, size: 18),
                          ),
                          const SizedBox(width: 20),
                          // 分享按钮
                          GestureDetector(
                            onTap: onShareTap,
                            behavior: HitTestBehavior.opaque,
                            child: const Icon(Icons.send, size: 18),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 底部间距
                const SizedBox(height: 15.0),
              ],
            ),
          ],
        ),
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
              radius: avatarRadius,
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
