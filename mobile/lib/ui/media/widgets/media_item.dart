// lib/ui/media/widgets/media_item.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/providers.dart';
import 'package:mobile/ui/media/viewmodels/media_item_viewmodel.dart';
import 'package:mobile/ui/media/widgets/media_item_placeholder.dart';
import 'package:mobile/ui/media/widgets/media_item_thumbnail.dart';

class MediaItem extends ConsumerWidget {
  final UnifiedMediaEntity entity;
  final int index;
  final int totalCount;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const MediaItem({
    super.key,
    required this.entity,
    required this.index,
    required this.totalCount,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbnailAsyncValue = ref.watch(thumbnailProvider(entity));
    final selectionState = ref.watch(selectionProvider);
    final isSelecting = selectionState.isSelecting;
    final isSelected = selectionState.selectedItems.contains(entity);

    const double shrinkPadding = 3.0;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 第一层：背景容器 (只在选择模式下显示)
          // 提供内缩后，空白区域的背景色
          AnimatedOpacity(
            duration: const Duration(milliseconds: 100),
            opacity: isSelecting ? 1.0 : 0.0,
            child: Container(
              decoration: BoxDecoration(
                // 使用一个不易察觉但能区分层次的颜色
                color: Theme.of(context).colorScheme.surfaceContainer,
              ),
            ),
          ),

          // 第二层：可收缩的图片内容
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeInOut,
            padding: isSelecting
                ? const EdgeInsets.all(shrinkPadding)
                : EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: isSelecting
                  ? BorderRadius.circular(6.0)
                  : BorderRadius.zero,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 图片本体
                  thumbnailAsyncValue.when(
                    data: (thumbnailData) => MediaItemThumbnail(
                      thumbnailData: thumbnailData,
                      entity: entity,
                    ),
                    loading: () => MediaItemPlaceholder(
                      icon: entity.isVideo ? Icons.videocam : Icons.image,
                    ),
                    error: (error, stackTrace) {
                      debugPrint("缩略图加载失败 for entityId=${entity.id}: $error");
                      return const MediaItemPlaceholder(
                        icon: Icons.broken_image,
                      );
                    },
                  ),

                  // 图片上的半透明颜色遮罩
                  if (isSelecting)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.2)
                            : Colors.black.withOpacity(0.4),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 第三层：固定位置的复选框 (只在选择模式下显示)
          if (isSelecting)
            Positioned(
              top: 4,
              left: 4,
              child: isSelected
                  ? const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
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
}
