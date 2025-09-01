// lib/ui/group/widgets/feed_card/post_actions.dart

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class PostActions extends StatelessWidget {
  const PostActions({super.key});

  @override
  Widget build(BuildContext context) {
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
