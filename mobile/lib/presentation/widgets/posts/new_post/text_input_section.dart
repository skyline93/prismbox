// lib/presentation/widgets/posts/new_post/text_input_section.dart

import 'package:flutter/material.dart';

/// 文本输入区域组件
class TextInputSection extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onTextChanged;
  final FocusNode focusNode;

  const TextInputSection({
    super.key,
    required this.controller,
    required this.onTextChanged,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onTextChanged,
      focusNode: focusNode,
      maxLines: null,
      style: const TextStyle(fontSize: 16),
      decoration: const InputDecoration.collapsed(
        hintText: '添加串文（可选）...',
        hintStyle: TextStyle(color: Colors.grey),
      ),
    );
  }
}

