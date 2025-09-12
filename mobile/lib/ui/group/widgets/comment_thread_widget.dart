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
    final bool shouldExtendLine = !(isLast && comment.replies.isEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommentWidget(
          comment: comment,
          hasThreadLine: shouldExtendLine,
          depth: depth,
          onReplyTapped: () => onReply(comment),
        ),
        if (comment.replies.isNotEmpty)
          for (int i = 0; i < comment.replies.length; i++)
            CommentThreadWidget(
              comment: comment.replies[i],
              depth: depth + 1,
              isLast: i == comment.replies.length - 1,
              onReply: onReply,
            ),
      ],
    );
  }
}
