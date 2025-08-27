// lib/ui/media/widgets/media_item.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/providers.dart'; // 引入我们创建的全局 Provider
import 'package:mobile/ui/media/viewmodels/media_item_viewmodel.dart';
import 'package:mobile/ui/media/widgets/media_item_placeholder.dart';
import 'package:mobile/ui/media/widgets/media_item_thumbnail.dart';

class MediaItem extends ConsumerWidget {
  final UnifiedMediaEntity entity;
  final int index;
  final int totalCount;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress; // 新增 onLongPress 回调

  const MediaItem({
    super.key,
    required this.entity,
    required this.index,
    required this.totalCount,
    this.onTap,
    this.onLongPress, // 在构造函数中添加 onLongPress
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听缩略图数据加载
    final thumbnailAsyncValue = ref.watch(thumbnailProvider(entity));

    // 监听全局选择状态
    final selectionState = ref.watch(selectionProvider);
    final isSelecting = selectionState.isSelecting;
    final isSelected = selectionState.selectedItems.contains(entity);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: ClipRRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 第一层：您原有的缩略图加载逻辑，保持不变
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
                return const MediaItemPlaceholder(icon: Icons.broken_image);
              },
            ),

            // 第二层：选择模式下的 UI 覆盖层
            if (isSelecting)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.0),
                  // 当图片被选中时，显示一个明显的边框
                  border: isSelected
                      ? Border.all(
                          color: Theme.of(context).primaryColor,
                          width: 2.5,
                        )
                      : null,
                  // 当图片被选中时，覆盖层颜色变浅；未选中时变深
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : Colors.black.withOpacity(0.4),
                ),
              ),

            // 第三层：勾选/未选中的图标指示器
            if (isSelecting)
              Positioned(
                top: 5,
                right: 5,
                child: isSelected
                    // 已选中：显示实心带阴影的勾选图标
                    ? const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                      )
                    // 未选中：显示带描边的空心圆圈
                    : Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.3),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
