// lib/ui/new_thread/widgets/new_thread_bottom_bar.dart
import 'package:flutter/material.dart';
import 'package:mobile/domain/entities/reply_permission.dart';

class NewThreadBottomBar extends StatelessWidget {
  final ReplyPermission selectedPermission;
  final bool isPostButtonEnabled;
  final bool isLoading; // 新增: 接收加载状态
  final VoidCallback onPermissionTap;
  final VoidCallback onPostTap;

  const NewThreadBottomBar({
    super.key,
    required this.selectedPermission,
    required this.isPostButtonEnabled,
    required this.isLoading, // 新增
    required this.onPermissionTap,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  // 发布时禁用权限选择
                  onPressed: isLoading ? null : onPermissionTap,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    alignment: Alignment.centerLeft,
                  ),
                  child: Text(
                    selectedPermission.displayText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
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
                  // 核心改动：根据isLoading状态显示不同内容
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
