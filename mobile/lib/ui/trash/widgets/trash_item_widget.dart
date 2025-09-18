import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/ui/media/widgets/media_item_placeholder.dart';
import 'package:mobile/ui/trash/viewmodels/trash_viewmodel.dart';
import 'package:mobile/providers/providers.dart';
import 'package:path/path.dart' as p;
import 'package:mobile/ui/media/widgets/media_item_video_overlay.dart';
import 'package:mobile/ui/media/widgets/sync_status_icon.dart';

String _getThumbnailPathFromTrashPath(String trashPath) {
  final dir = p.dirname(trashPath);
  final filename = p.basenameWithoutExtension(trashPath);
  return p.join(dir, '${filename}_thumb.jpg');
}

final trashThumbnailProvider = FutureProvider.family
    .autoDispose<Uint8List?, UnifiedMediaEntity>((ref, entity) async {
      if (entity.isRemote) {
        try {
          final mediaRepo = ref.watch(mediaRepositoryProvider);
          return await mediaRepo.downloadThumbnail(entity.cloudUuid!);
        } catch (e) {
          debugPrint(
            'Failed to download cloud thumbnail for ${entity.cloudUuid}: $e',
          );
          return null; // 下载失败则返回 null
        }
      } else {
        // 对于有本地路径的资源，沿用旧逻辑，从本地文件读取
        final thumbnailPath = _getThumbnailPathFromTrashPath(entity.trashPath!);
        final file = File(thumbnailPath);
        if (await file.exists()) {
          return file.readAsBytes();
        }
        return null; // 如果本地缩略图文件不存在，返回 null
      }
    });

class TrashItemWidget extends ConsumerWidget {
  final UnifiedMediaEntity entity;

  const TrashItemWidget({super.key, required this.entity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbnailAsyncValue = ref.watch(trashThumbnailProvider(entity));

    final selectionState = ref.watch(trashSelectionProvider);
    final isSelecting = selectionState.isSelecting;
    final isSelected = selectionState.selectedItems.contains(entity);

    const double shrinkPadding = 6.0;

    return GestureDetector(
      onTap: () {
        if (isSelecting) {
          ref.read(trashSelectionProvider.notifier).toggleItem(entity);
        }
      },
      onLongPress: () {
        if (!isSelecting) {
          ref.read(trashSelectionProvider.notifier).startSelection(entity);
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 第一层：背景容器
          AnimatedOpacity(
            duration: const Duration(milliseconds: 100),
            opacity: isSelecting ? 1.0 : 0.0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
              ),
            ),
          ),

          // 第二层：可收缩的图片内容
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeInOut,
            padding: isSelected
                ? const EdgeInsets.all(shrinkPadding)
                : EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: isSelected
                  ? BorderRadius.circular(12.0)
                  : BorderRadius.zero,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 缩略图或占位符
                  thumbnailAsyncValue.when(
                    data: (thumbnailData) {
                      if (thumbnailData == null) {
                        return const MediaItemPlaceholder(
                          icon: Icons.broken_image,
                        );
                      }
                      // 使用 Image.memory 并添加加载动画
                      return Image.memory(
                        thumbnailData,
                        fit: BoxFit.cover,
                        frameBuilder:
                            (context, child, frame, wasSynchronouslyLoaded) {
                              if (wasSynchronouslyLoaded) return child;
                              return AnimatedOpacity(
                                opacity: frame == null ? 0 : 1,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                                child: child,
                              );
                            },
                      );
                    },
                    loading: () => MediaItemPlaceholder(
                      icon: entity.isVideo ? Icons.videocam : Icons.image,
                    ),
                    error: (err, stack) =>
                        const MediaItemPlaceholder(icon: Icons.broken_image),
                  ),

                  // 视频时长标识 (左下角)
                  if (entity.isVideo)
                    VideoOverlay(durationSec: entity.durationSec ?? 0),

                  // 同步状态图标 (右上角)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: SyncStatusIcon(status: entity.syncStatus),
                  ),

                  // RAW 格式标识 (右下角)
                  if (entity.isRAW)
                    Positioned(bottom: 4, right: 4, child: _buildRawBadge()),
                ],
              ),
            ),
          ),

          // 第三层：固定位置的复选框
          if (isSelecting)
            Positioned(
              top: 2,
              left: 2,
              child: isSelected
                  ? Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF4285F4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 14,
                      ),
                    )
                  : Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.3),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildRawBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'RAW',
        style: TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
