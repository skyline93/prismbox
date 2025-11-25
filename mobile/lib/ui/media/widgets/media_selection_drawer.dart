// lib/ui/media/widgets/media_selection_drawer.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/core/enums.dart';
import 'package:mobile/providers/providers.dart';
import 'package:mobile/routing/app_router.dart';
import 'package:auto_route/auto_route.dart';
import 'package:mobile/providers/transfer_providers.dart';

class MediaSelectionDrawer extends ConsumerWidget {
  final ScrollController scrollController;

  const MediaSelectionDrawer({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCount = ref.watch(
      selectionProvider.select((s) => s.selectedItems.length),
    );
    final bool hasSelection = selectedCount > 0;

    return Container(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: const BorderRadius.all(Radius.circular(24.0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(255),
                offset: const Offset(0, 4),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12.0),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(102),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(
                    context: context,
                    icon: Icons.cloud_upload_outlined,
                    label: '上传',
                    isEnabled: hasSelection,
                    // [重大修改] onPressed 回调现在非常简洁和快速
                    onPressed: () {
                      // 1. 读取所需的状态和对象
                      final selectionNotifier = ref.read(
                        selectionProvider.notifier,
                      );
                      final selectedItems = ref
                          .read(selectionProvider)
                          .selectedItems;
                      final router = context.router;

                      if (selectedItems.isEmpty) return;

                      // 2. 立即触发后台任务，不等待其完成
                      ref
                          .read(uploadOrchestratorProvider)
                          .processAndEnqueueUploads(
                            selectedItems.toList(),
                            UploadSource.manual,
                          );

                      // 3. 立即更新UI：清空选择并导航到新页面
                      selectionNotifier.clearSelection();
                      router.push(const TransferManagerRoute());

                      // 4. 立即给用户反馈，告知任务已开始
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('已开始准备 ${selectedItems.length} 个文件以上传'),
                        ),
                      );
                    },
                  ),
                  _buildActionButton(
                    context: context,
                    icon: Icons.share_outlined,
                    label: '分享',
                    isEnabled: hasSelection,
                    onPressed: () => debugPrint('分享'),
                  ),
                  _buildActionButton(
                    context: context,
                    icon: Icons.favorite_border,
                    label: '喜欢',
                    isEnabled: hasSelection,
                    onPressed: () => debugPrint('喜欢'),
                  ),
                  _buildActionButton(
                    context: context,
                    icon: Icons.delete_outline,
                    label: '删除',
                    isEnabled: hasSelection,
                    onPressed: () async {
                      final selectedItems = ref
                          .read(selectionProvider)
                          .selectedItems;
                      if (selectedItems.isEmpty) return;

                      // 弹出确认对话框
                      final bool? shouldDelete = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('确认删除'),
                            content: Text(
                              '你确定要删除这 ${selectedItems.length} 个项目吗？\n它将在回收站中保存30天, 之后将被永久删除。',
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('取消'),
                                onPressed: () {
                                  Navigator.of(
                                    context,
                                  ).pop(false); // 关闭对话框，返回 false
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
                                  Navigator.of(
                                    context,
                                  ).pop(true); // 关闭对话框，返回 true
                                },
                              ),
                            ],
                          );
                        },
                      );

                      // 如果用户确认删除，则执行删除操作
                      if (shouldDelete == true) {
                        await ref
                            .read(mediaRepositoryProvider)
                            .deleteAssets(selectedItems.toList());

                        // （可选）清空选择并给出反馈
                        ref.read(selectionProvider.notifier).clearSelection();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${selectedItems.length} 个项目已移至回收站'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.add_to_photos_outlined),
                title: const Text('添加到相册'),
                onTap: hasSelection ? () {} : null,
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('信息'),
                onTap: hasSelection ? () {} : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isEnabled,
    required VoidCallback onPressed,
  }) {
    final color = isEnabled
        ? Theme.of(context).colorScheme.onSurface
        : Theme.of(context).colorScheme.onSurface.withAlpha(97);

    return InkWell(
      onTap: isEnabled ? onPressed : null,
      borderRadius: BorderRadius.circular(12.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
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
