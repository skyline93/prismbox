// lib/ui/group/widgets/feed_card/post_actions.dart

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart'; // 导入新的图标库

class PostActions extends StatelessWidget {
  const PostActions({super.key});

  @override
  Widget build(BuildContext context) {
    // 父组件 PostWidget 已经处理了边距, 这里只负责图标的排列和间距
    return Row(
      children: const [
        Icon(Iconsax.heart, size: 24, color: Colors.black),
        SizedBox(width: 16),
        Icon(Iconsax.message, size: 24, color: Colors.black),
        SizedBox(width: 16),
        Icon(Iconsax.repeat, size: 24, color: Colors.black),
        SizedBox(width: 16),
        Icon(Iconsax.send_2, size: 24, color: Colors.black),
      ],
    );
  }
}
