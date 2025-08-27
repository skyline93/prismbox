// lib/ui/media/widgets/media_bar_top.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/providers.dart';

class MediaAppBar extends HookConsumerWidget implements PreferredSizeWidget {
  const MediaAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectionState = ref.watch(selectionProvider);
    final isSelecting = selectionState.isSelecting;
    final selectedCount = selectionState.selectedItems.length;

    // 选择模式下的 AppBar
    if (isSelecting) {
      // [修改] AppBar 现在是透明的，并且没有操作按钮
      return AppBar(
        backgroundColor: Colors.transparent, // 背景透明
        elevation: 0, // 移除阴影
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ref.read(selectionProvider.notifier).clearSelection();
          },
        ),
        title: Text('已选择 $selectedCount 项'),
      );
    }

    // 默认状态下的 AppBar
    final viewMode = ref.watch(mediaViewTypeProvider);

    return AppBar(
      title: const Text('所有照片'),
      actions: [
        IconButton(
          tooltip: '切换视图',
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
