// lib/ui/group/widgets/feed_card/post_content.dart

import 'package:flutter/material.dart';

class PostContent extends StatelessWidget {
  final String text;

  // 移除了 attachments，因为它现在由 PostWidget 直接处理
  const PostContent({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    // 移除了所有内边距，完全由父组件 PostWidget 控制
    return Text(text, style: const TextStyle(fontSize: 16, height: 1.4));
  }
}
