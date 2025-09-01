// lib/ui/group/widgets/comment_list.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/providers/group_providers.dart';

// 1. [核心改造] 将 CommentList 从与 "媒体" 耦合改为与 "帖子" 耦合
class CommentList extends ConsumerWidget {
  // 2. [参数变更] 构造函数现在接收 postId，而不是 groupMediaId
  final int postId;

  const CommentList({super.key, required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 3. [逻辑更新] 使用 postId 来 watch commentsProvider
    // 这会触发对 GET /posts/{postId}/comments 的 API 请求
    final commentsAsyncValue = ref.watch(commentsProvider(postId));

    return commentsAsyncValue.when(
      data: (comments) {
        if (comments.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: Text(
                '还没有评论，快来抢沙发吧！',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }
        // UI 渲染逻辑保持不变，因为它只关心数据显示
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index];
            return ListTile(
              leading: CircleAvatar(
                // TODO: 替换为真实的头像 URL
                backgroundColor: Colors.grey.shade800,
                child: Text(
                  comment.user.username.isNotEmpty
                      ? comment.user.username.substring(0, 1)
                      : "",
                ),
              ),
              title: Text(
                comment.user.username,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(comment.content),
              trailing: Text(
                _formatDate(comment.createdAt),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('加载评论失败: $error')),
    );
  }

  // 日期格式化逻辑保持不变
  String _formatDate(String dateStr) {
    try {
      final dateTime = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}天前';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}小时前';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}分钟前';
      } else {
        return '刚刚';
      }
    } catch (e) {
      return '';
    }
  }
}
