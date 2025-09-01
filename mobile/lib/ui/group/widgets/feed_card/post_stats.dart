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

    if (statsText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Text(
      statsText.join(' · '),
      style: const TextStyle(color: Colors.grey, fontSize: 15),
    );
  }
}
