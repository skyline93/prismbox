// lib/ui/media/widgets/media_item.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/providers/providers.dart';
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

    const double shrinkPadding = 6.0;

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
                ],
              ),
            ),
          ),

          // 第三层：固定位置的复选框 (只在选择模式下显示)
          if (isSelecting)
            Positioned(
              top: 2,
              left: 2,
              child: isSelected
                  // [修改]：当选中时，显示一个由蓝色圆圈和白色勾组成的自定义图标
                  ? Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        // 使用一个标准的蓝色，接近 Google Blue
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
                        color: Colors.white, // 勾的颜色为纯白色
                        size: 14, // 图标大小略小于背景圆圈
                      ),
                    )
                  // 未选中时的样式保持不变
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
