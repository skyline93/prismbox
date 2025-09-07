// lib/ui/group/widgets/comment_input_field.dart

import 'package:flutter/material.dart';

class CommentInputField extends StatefulWidget {
  final Future<void> Function(String text) onSubmitted;
  final bool enabled;

  const CommentInputField({
    super.key,
    required this.onSubmitted,
    this.enabled = true,
  });

  @override
  State<CommentInputField> createState() => _CommentInputFieldState();
}

class _CommentInputFieldState extends State<CommentInputField> {
  final _controller = TextEditingController();
  bool _isSending = false;

  Future<void> _submitComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await widget.onSubmitted(text);
      _controller.clear();
    } catch (e) {
      // 错误提示由调用方处理
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: widget.enabled && !_isSending,
                decoration: InputDecoration(
                  hintText: '添加评论...',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: _isSending
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
              onPressed: (widget.enabled && !_isSending) ? _submitComment : null,
              color: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
