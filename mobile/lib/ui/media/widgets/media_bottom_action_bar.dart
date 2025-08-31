// lib/ui/media/widgets/media_bottom_action_bar.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/providers/providers.dart';

class MediaBottomActionBar extends ConsumerWidget {
  const MediaBottomActionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCount = ref.watch(
      selectionProvider.select((s) => s.selectedItems.length),
    );
    final bool hasSelection = selectedCount > 0;

    // [关键修改]：使用 SafeArea + Container 替代 BottomAppBar
    // 1. SafeArea 确保我们的UI不会被系统UI（如iPhone底部横条）遮挡
    return SafeArea(
      // 我们只关心底部的安全距离
      top: false,
      child: Container(
        // 2. Container 的高度将由其子组件 Row 自动撑开，实现自适应
        padding: const EdgeInsets.symmetric(vertical: 8.0), // 给内容一个垂直内边距
        decoration: BoxDecoration(
          // 3. 使用 BoxDecoration 复刻出 BottomAppBar 的外观
          color: Theme.of(context).colorScheme.surfaceContainer,
          boxShadow: [
            BoxShadow(
              // 模拟 elevation 效果
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2), // 阴影向上
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildActionButton(
              context: context,
              icon: Icons.share_outlined,
              label: '分享',
              isEnabled: hasSelection,
              onPressed: () {
                debugPrint('分享 ${selectedCount} 个项目');
              },
            ),
            _buildActionButton(
              context: context,
              icon: Icons.add_to_photos_outlined,
              label: '添加到相册',
              isEnabled: hasSelection,
              onPressed: () {
                debugPrint('添加到相册 ${selectedCount} 个项目');
              },
            ),
            _buildActionButton(
              context: context,
              icon: Icons.delete_outline,
              label: '删除',
              isEnabled: hasSelection,
              onPressed: () {
                debugPrint('删除 ${selectedCount} 个项目');
              },
            ),
          ],
        ),
      ),
    );
  }

  // 辅助方法，用于构建一个带图标和文本的按钮
  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isEnabled,
    required VoidCallback onPressed,
  }) {
    final color = isEnabled
        ? Theme.of(context).colorScheme.onSurface
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.38);

    return InkWell(
      onTap: isEnabled ? onPressed : null,
      borderRadius: BorderRadius.circular(12.0),
      // [修改]：去掉了外层的Padding，把它放在了父级Container上
      // 这样整个按钮的可点击区域更大
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          // mainAxisSize.min 确保 Column 的高度刚好包裹其内容
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
