// lib/ui/trash/pages/trash_page.dart

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/providers/providers.dart';
import 'package:mobile/ui/trash/viewmodels/trash_viewmodel.dart';
import 'package:mobile/ui/trash/widgets/trash_item_widget.dart';

@RoutePage()
class TrashPage extends ConsumerWidget {
  const TrashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trashState = ref.watch(trashViewModelProvider);
    final selection = ref.watch(trashSelectionProvider);
    final isSelecting = selection.isSelecting;
    final selectedCount = selection.selectedItems.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSelecting ? '已选择 $selectedCount 项' : '回收站'),
        leading: isSelecting
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () =>
                    ref.read(trashSelectionProvider.notifier).clearSelection(),
              )
            : null,
        actions: [
          if (isSelecting) ...[
            IconButton(
              icon: const Icon(Icons.restore),
              tooltip: '恢复',
              onPressed: () async {
                final itemsToRestore = List.of(selection.selectedItems);
                ref.read(trashSelectionProvider.notifier).clearSelection();
                await ref
                    .read(trashViewModelProvider.notifier)
                    .restoreAssets(itemsToRestore);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: '永久删除',
              onPressed: () async {
                final itemsToDelete = List.of(selection.selectedItems);
                if (itemsToDelete.isEmpty) return;

                // 弹出确认对话框
                final bool? shouldDelete = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('永久删除'),
                      content: Text(
                        '你确定要永久删除这 ${itemsToDelete.length} 个项目吗？\n此操作无法撤销。',
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('取消'),
                          onPressed: () {
                            Navigator.of(context).pop(false); // 关闭对话框，返回 false
                          },
                        ),
                        TextButton(
                          child: Text(
                            '删除',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop(true); // 关闭对话框，返回 true
                          },
                        ),
                      ],
                    );
                  },
                );

                // 如果用户确认删除，则执行删除操作
                if (shouldDelete == true) {
                  ref.read(trashSelectionProvider.notifier).clearSelection();
                  // 在执行异步操作前检查 context 是否仍然有效
                  if (!context.mounted) return;

                  await ref
                      .read(trashViewModelProvider.notifier)
                      .permanentlyDeleteAssets(itemsToDelete);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${itemsToDelete.length} 个项目已被永久删除'),
                    ),
                  );
                }
              },
            ),
          ],
        ],
      ),
      body: trashState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error) => Center(child: Text(error)),
        data: (media) {
          if (media.isEmpty) {
            return const Center(child: Text('回收站是空的'));
          }
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 1,
              mainAxisSpacing: 1,
            ),
            itemCount: media.length,
            itemBuilder: (context, index) {
              return TrashItemWidget(entity: media[index]);
            },
          );
        },
      ),
    );
  }
}
