// lib/ui/group/widgets/comment_list.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/providers/group_providers.dart';

class CommentList extends ConsumerWidget {
  final int groupMediaId;

  const CommentList({super.key, required this.groupMediaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentsAsyncValue = ref.watch(commentsProvider(groupMediaId));

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
        return ListView.builder(
          // 禁用 ListView 的滚动，让外部的 Column 控制
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index];
            return ListTile(
              leading: CircleAvatar(
                // TODO: 替换为真实的头像 URL
                backgroundColor: Colors.grey.shade800,
                child: Text(comment.user.username.substring(0, 1)),
              ),
              title: Text(comment.user.username, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(comment.content),
              trailing: Text(
                // 简单的日期格式化
                _formatDate(comment.createdAt),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('加载评论失败: $error'),
      ),
    );
  }

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
