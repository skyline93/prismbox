// lib/ui/media/widgets/media_bar_top.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/providers.dart';

class MediaAppBar extends HookConsumerWidget implements PreferredSizeWidget {
  const MediaAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听选择状态
    final selectionState = ref.watch(selectionProvider);
    final isSelecting = selectionState.isSelecting;
    final selectedCount = selectionState.selectedItems.length;

    // 如果处于选择模式，返回一个不同的 AppBar UI
    if (isSelecting) {
      return AppBar(
        // leading 显示一个关闭按钮，用于退出选择模式
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ref.read(selectionProvider.notifier).clearSelection();
          },
        ),
        // 标题显示已选中的数量
        title: Text('已选择 $selectedCount 项'),
        // 操作按钮变为对选中项可执行的动作
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: selectedCount > 0
                ? () {
                    // TODO: 在这里添加分享逻辑
                    debugPrint('分享 ${selectedCount} 个项目');
                  }
                : null, // 如果没有选中项，则禁用按钮
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: selectedCount > 0
                ? () {
                    // TODO: 在这里添加删除逻辑
                    debugPrint('删除 ${selectedCount} 个项目');
                  }
                : null, // 如果没有选中项，则禁用按钮
          ),
        ],
      );
    }

    // --- 正常模式下的 AppBar ---
    // 这部分保留了您原有的视图切换逻辑
    final viewMode = ref.watch(mediaViewTypeProvider);

    return AppBar(
      title: const Text('所有照片'),
      actions: [
        IconButton(
          tooltip: '切换视图', // 增加工具提示
          icon: Icon(
            viewMode == MediaViewType.grid
                ? Icons.view_timeline_outlined
                : Icons.grid_view_outlined,
          ),
          onPressed: () {
            final notifier = ref.read(mediaViewTypeProvider.notifier);
            notifier.state = viewMode == MediaViewType.grid
                ? MediaViewType.timeline
                : MediaViewType.grid;
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
