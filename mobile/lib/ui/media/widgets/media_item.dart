// lib/ui/media/widgets/media_item.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/datasources/app_database.dart'; // [+] Import SyncStatus
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
          // [+] Use a Stack to layer the thumbnail and status overlay
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
            // [+] Add the sync status overlay
            _buildSyncStatusOverlay(entity.syncStatus),
          ],
        ),
      ),
    );
  }

  /// [+] Helper widget to build the status overlay based on SyncStatus.
  Widget _buildSyncStatusOverlay(SyncStatus status) {
    Widget? content;
    switch (status) {
      case SyncStatus.uploading:
        content = const Icon(
          Icons.cloud_upload_outlined,
          color: Colors.white,
          size: 20,
        );
        break;
      case SyncStatus.downloading:
        content = const Icon(
          Icons.cloud_download_outlined,
          color: Colors.white,
          size: 20,
        );
        break;
      case SyncStatus.error:
        content = const Icon(
          Icons.error_outline,
          color: Colors.redAccent,
          size: 20,
        );
        break;
      case SyncStatus.synced:
      case SyncStatus.localOnlyNotSelected:
      case SyncStatus.cloudOnly:
        // No overlay for these states
        break;
    }

    if (content == null) {
      return const SizedBox.shrink(); // Return an empty widget if no overlay is needed
    }

    return Container(
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.3)),
      child: Center(child: content),
    );
  }
}
