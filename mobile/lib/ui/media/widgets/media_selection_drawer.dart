// lib/ui/media/widgets/media_selection_drawer.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:mobile/providers/providers.dart';
import 'package:mobile/providers/transfer_providers.dart';
import 'package:mobile/routing/app_router.dart';
import 'package:auto_route/auto_route.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';

class MediaSelectionDrawer extends ConsumerWidget {
  final ScrollController scrollController;

  const MediaSelectionDrawer({super.key, required this.scrollController});

  // 定义大文件阈值 (1MB)
  static const int largeFileThreshold = 1 * 1024 * 1024;

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
                color: Colors.black.withOpacity(1),
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
                    ).colorScheme.onSurface.withOpacity(0.4),
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
                    onPressed: () async {
                      final transferService = ref.read(transferServiceProvider);
                      final selectionNotifier = ref.read(
                        selectionProvider.notifier,
                      );
                      final selectedItems = ref
                          .read(selectionProvider)
                          .selectedItems;
                      final messenger = ScaffoldMessenger.of(context);
                      final router = context.router;

                      final itemsToUploadCount = selectedItems.length;

                      for (final UnifiedMediaEntity entity in selectedItems) {
                        AssetEntity? asset;
                        if (entity.assetEntity != null) {
                          asset = entity.assetEntity;
                        } else if (entity.localId != null) {
                          asset = await AssetEntity.fromId(entity.localId!);
                        }

                        if (asset != null) {
                          final file = await asset.file;
                          if (file != null) {
                            final fileSize = await file.length();
                            if (fileSize > largeFileThreshold) {
                              transferService.uploadService.enqueueUploadJob(
                                file,
                                asset.id,
                              );
                            } else {
                              // TODO: 实现小文件的直接上传逻辑
                              debugPrint('小文件 (${file.path}) 将使用标准上传');
                              // 暂时也用大文件通道
                              transferService.uploadService.enqueueUploadJob(
                                file,
                                asset.id,
                              );
                            }
                          }
                        } else {
                          debugPrint('无法找到实体 ${entity.id} 的本地文件，跳过上传。');
                        }
                      }

                      if (!context.mounted) return;

                      selectionNotifier.clearSelection();
                      router.push(const TransferManagerRoute());

                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('$itemsToUploadCount 个文件已加入上传队列'),
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
                    onPressed: () => debugPrint('删除'),
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
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.38);

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
