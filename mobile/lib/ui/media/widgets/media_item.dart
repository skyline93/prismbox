// lib/ui/media/widgets/media_item.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/ui/media/viewmodels/media_item_viewmodel.dart';
import 'package:mobile/ui/media/widgets/media_item_placeholder.dart';
import 'package:mobile/ui/media/widgets/media_item_thumbnail.dart';

class MediaItem extends ConsumerWidget {
  final UnifiedMediaEntity entity;
  final int index;
  final int totalCount;
  final VoidCallback? onTap;

  const MediaItem({
    super.key,
    required this.entity,
    required this.index,
    required this.totalCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbnailAsyncValue = ref.watch(thumbnailProvider(entity));

    return GestureDetector(
      onTap: () {
        debugPrint(
          'Tapped on media id: ${entity.id}, status: ${entity.syncStatus}. Navigating...',
        );
        if (onTap != null) {
          onTap!();
        }
      },
      child: ClipRRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
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
          ],
        ),
      ),
    );
  }
}
