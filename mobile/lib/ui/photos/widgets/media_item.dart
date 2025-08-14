import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/ui/photos/viewmodels/media_item_viewmodel.dart';
import 'package:mobile/ui/photos/widgets/media_item_placeholder.dart';
import 'package:mobile/ui/photos/widgets/media_item_thumbnail.dart';

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
          'Tapped on media id: ${entity.id}, index: $index/$totalCount. Navigating...',
        );
        if (onTap != null) {
          onTap!();
        } else {
          _navigateToDetail(context, index);
        }
      },
      child: ClipRRect(
        child: thumbnailAsyncValue.when(
          data: (thumbnailData) =>
              MediaItemThumbnail(thumbnailData: thumbnailData, entity: entity),
          loading: () => MediaItemPlaceholder(
            icon: entity.isVideo ? Icons.videocam : Icons.image,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ),
          error: (error, stackTrace) {
            debugPrint("缩略图加载失败 for entityId=${entity.id}: $error");
            return const MediaItemPlaceholder(icon: Icons.broken_image);
          },
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('点击了第 $index 个媒体项'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
