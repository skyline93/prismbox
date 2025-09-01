// lib/ui/group/widgets/feed_card/post_content.dart

import 'package:flutter/material.dart';

class PostContent extends StatelessWidget {
  final String text;
  const PostContent({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Text(text, style: const TextStyle(fontSize: 16, height: 1.4));
  }
}
