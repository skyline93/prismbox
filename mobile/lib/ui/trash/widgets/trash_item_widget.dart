// lib/ui/trash/widgets/trash_item_widget.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/ui/media/widgets/media_item_placeholder.dart';
import 'package:mobile/ui/trash/viewmodels/trash_viewmodel.dart';
import 'package:path/path.dart' as p;

String _getThumbnailPathFromTrashPath(String trashPath) {
  final dir = p.dirname(trashPath);
  final filename = p.basenameWithoutExtension(trashPath);
  return p.join(dir, '${filename}_thumb.jpg');
}

// [新增] 一个简单的 FutureProvider，只负责读取文件
final trashThumbnailFileProvider = FutureProvider.family
    .autoDispose<Uint8List?, String>((ref, trashPath) async {
      final thumbnailPath = _getThumbnailPathFromTrashPath(trashPath);
      final file = File(thumbnailPath);
      if (await file.exists()) {
        return file.readAsBytes();
      }
      return null; // 如果缩略图文件不存在，返回 null
    });

class TrashItemWidget extends ConsumerWidget {
  final UnifiedMediaEntity entity;

  const TrashItemWidget({super.key, required this.entity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 获取回收站的缩略图和选择状态
    final thumbnailAsyncValue = entity.trashPath != null
        ? ref.watch(trashThumbnailFileProvider(entity.trashPath!))
        : const AsyncValue<Uint8List?>.data(null);

    final selectionState = ref.watch(trashSelectionProvider);
    final isSelecting = selectionState.isSelecting;
    final isSelected = selectionState.selectedItems.contains(entity);

    // 2. 引入与 MediaItem 相同的收缩 padding
    const double shrinkPadding = 6.0;

    return GestureDetector(
      // 3. 采用与 MediaGridBody/_MediaRowWidget 相同的交互逻辑
      onTap: () {
        if (isSelecting) {
          // 如果在选择模式，单击用于切换选中状态
          ref.read(trashSelectionProvider.notifier).toggleItem(entity);
        } else {
          // 不在选择模式，单击不执行任何操作
        }
      },
      onLongPress: () {
        // 长按用于启动选择模式（如果尚未启动）
        if (!isSelecting) {
          ref.read(trashSelectionProvider.notifier).startSelection(entity);
        }
        // 注意：如果已在选择模式，长按不执行操作，这与 MediaItem 行为一致
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 4. 第一层：背景容器 (复制自 MediaItem)
          // 提供内缩后，空白区域的背景色
          AnimatedOpacity(
            duration: const Duration(milliseconds: 100),
            opacity: isSelecting ? 1.0 : 0.0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
              ),
            ),
          ),

          // 5. 第二层：可收缩的图片内容 (复制自 MediaItem)
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeInOut,
            padding:
                isSelected // 依赖 isSelected 状态
                ? const EdgeInsets.all(shrinkPadding)
                : EdgeInsets.zero,
            child: ClipRRect(
              borderRadius:
                  isSelected // 依赖 isSelected 状态
                  ? BorderRadius.circular(12.0)
                  : BorderRadius.zero,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 图片本体 (使用 TrashItemWidget 自己的 provider)
                  thumbnailAsyncValue.when(
                    data: (thumbnailData) {
                      if (thumbnailData == null) {
                        return const MediaItemPlaceholder(
                          icon: Icons.broken_image,
                        );
                      }
                      // MediaItemThumbnail 包含视频叠加层等逻辑
                      // 这里我们保持简单，只显示图片
                      return Image.memory(thumbnailData, fit: BoxFit.cover);
                    },
                    loading: () => MediaItemPlaceholder(
                      icon: entity.isVideo ? Icons.videocam : Icons.image,
                    ),
                    error: (err, stack) =>
                        const MediaItemPlaceholder(icon: Icons.broken_image),
                  ),
                ],
              ),
            ),
          ),

          // 6. 第三层：固定位置的复选框 (复制自 MediaItem)
          if (isSelecting) // 只在选择模式下显示
            Positioned(
              top: 2,
              left: 2,
              child:
                  isSelected // 区分选中和未选中样式
                  // [选中样式]：蓝色圆圈 + 白色勾
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
                  // [未选中样式]：透明背景 + 白色边框
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
}
