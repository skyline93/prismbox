// lib/presentation/widgets/posts/new_post/new_post_app_bar.dart

import 'package:flutter/material.dart';

/// 新建帖子页面 AppBar
class NewPostAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onCancel;

  const NewPostAppBar({
    super.key,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: TextButton(
        onPressed: onCancel,
        child: const Text(
          '取消',
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ),
      title: const Text(
        '新建串文',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
      centerTitle: true,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

