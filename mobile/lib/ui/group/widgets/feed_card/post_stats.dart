// lib/ui/group/widgets/feed_card/post_stats.dart

import 'package:flutter/material.dart';

class PostStats extends StatelessWidget {
  final int replies;
  final int likes;

  const PostStats({super.key, required this.replies, required this.likes});

  @override
  Widget build(BuildContext context) {
    final statsText = <String>[];
    if (replies > 0) {
      statsText.add('$replies replies');
    }
    if (likes > 0) {
      statsText.add('$likes likes');
    }

    // 如果没有回复和点赞，则不显示任何内容
    if (statsText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Text(
      statsText.join(' · '),
      // 精确的 TextStyle
      style: const TextStyle(color: Colors.grey, fontSize: 15),
    );
  }
}
