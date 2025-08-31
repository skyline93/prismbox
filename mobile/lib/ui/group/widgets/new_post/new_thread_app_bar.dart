// lib/ui/new_thread/widgets/new_thread_app_bar.dart
import 'package:flutter/material.dart';

class NewThreadAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onCancel;

  const NewThreadAppBar({super.key, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: TextButton(
        onPressed: onCancel,
        child: const Text('取消', style: TextStyle(fontSize: 14)),
      ),
      title: const Text(
        '新建串文',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      centerTitle: true,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
