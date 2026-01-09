// lib/presentation/widgets/posts/new_post/new_post_bottom_bar.dart

import 'package:flutter/material.dart';

/// 新建帖子页面底部操作栏
class NewPostBottomBar extends StatelessWidget {
  final bool isPostButtonEnabled;
  final bool isLoading; // 加载状态
  final VoidCallback onPostTap;

  const NewPostBottomBar({
    super.key,
    required this.isPostButtonEnabled,
    required this.isLoading,
    required this.onPostTap,
  });

  @override
  Widget build(BuildContext context) {
    // 按钮是否可用的最终条件：外部传入的可用状态为true，且当前不处于加载中
    final isButtonActive = isPostButtonEnabled && !isLoading;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1, thickness: 0.5),
        SafeArea(
          top: false,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: isButtonActive ? onPostTap : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isButtonActive
                        ? Colors.blue
                        : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    elevation: 0,
                  ),
                  // 根据isLoading状态显示不同内容
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          '发布',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

