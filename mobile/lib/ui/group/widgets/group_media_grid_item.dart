// lib/ui/group/widgets/group_media_grid_item.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/data/models/group/group_models.dart';
import 'package:mobile/data/models/media/media_model.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/data/datasources/local_db/enums.dart';

import 'package:mobile/ui/media/viewmodels/media_item_viewmodel.dart';
import 'package:mobile/ui/media/widgets/media_item_placeholder.dart';
import 'package:mobile/ui/media/widgets/media_item_thumbnail.dart';

import 'package:auto_route/auto_route.dart';
import 'package:mobile/routing/app_router.dart';

class GroupMediaGridItem extends ConsumerWidget {
  final GroupMediaModel groupMedia;
  // final VoidCallback? onTap;

  const GroupMediaGridItem({
    super.key,
    required this.groupMedia,
    // this.onTap,
  });

  int _parseDuration(String? duration) {
    if (duration == null) return 0;
    try {
      final parts = duration.split(':');
      final secondsParts = parts.last.split('.');
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      final seconds = int.parse(secondsParts[0]);
      return hours * 3600 + minutes * 60 + seconds;
    } catch (e) {
      debugPrint("Error parsing duration: $duration");
      return 0;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MediaResponse remoteMedia = groupMedia.mediaDetails;
    final UnifiedMediaEntity mediaEntity = UnifiedMediaEntity(
      id: 0,
      localId: null,
      cloudUuid: remoteMedia.uuid,
      syncStatus: SyncStatus.synced,
      assetType: remoteMedia.itemType == 'video'
          ? MediaType.video
          : MediaType.image,
      fileName: remoteMedia.filename,
      width: null,
      height: null,
      durationSec: _parseDuration(null),

      createdAt: DateTime.parse(remoteMedia.createdAt),
      assetEntity: null,
    );

    final thumbnailAsyncValue = ref.watch(thumbnailProvider(mediaEntity));

    return GestureDetector(
      onTap: () {
        // 使用 AutoRouter 导航到 MediaItemPage，并传递完整的 groupMedia 对象
        AutoRouter.of(context).push(MediaItemRoute(groupMedia: groupMedia));
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 图片本体
          thumbnailAsyncValue.when(
            data: (thumbnailData) => MediaItemThumbnail(
              thumbnailData: thumbnailData,
              entity: mediaEntity,
            ),
            loading: () => MediaItemPlaceholder(
              icon: mediaEntity.isVideo ? Icons.videocam : Icons.image,
            ),
            error: (error, stackTrace) {
              debugPrint("Group media thumbnail error: $error");
              return const MediaItemPlaceholder(icon: Icons.broken_image);
            },
          ),

          // 底部上传者信息
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 12, 6, 4),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Text(
                groupMedia.uploader.username,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  shadows: [Shadow(blurRadius: 2, color: Colors.black54)],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
