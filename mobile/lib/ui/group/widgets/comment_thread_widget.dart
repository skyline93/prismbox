// lib/ui/group/widgets/comment_thread_widget.dart

import 'package:flutter/material.dart';
import 'package:mobile/ui/group/widgets/comment_widget.dart';
import 'package:mobile/domain/entities/comment_entity.dart';

class CommentThreadWidget extends StatelessWidget {
  final CommentEntity comment;
  final int depth;
  final bool isLast;
  final ValueChanged<CommentEntity> onReply;

  const CommentThreadWidget({
    super.key,
    required this.comment,
    required this.depth,
    required this.isLast,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    // 决定这条评论线是否应该继续向下延伸
    // 如果是本层的最后一条，并且它自己没有回复，那么线就到底了
    final bool shouldExtendLine = !(isLast && comment.replies.isEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 渲染当前评论
        CommentWidget(
          comment: comment,
          hasThreadLine: shouldExtendLine,
          depth: depth,
          onReplyTapped: () => onReply(comment),
        ),
        // 递归地渲染这条评论的回复
        if (comment.replies.isNotEmpty)
          for (int i = 0; i < comment.replies.length; i++)
            CommentThreadWidget(
              comment: comment.replies[i],
              depth: depth + 1,
              isLast: i == comment.replies.length - 1, // 判断是否是回复中的最后一条
              onReply: onReply,
            ),
      ],
    );
  }
}
