// lib/ui/media/widgets/media_grid_view.dart

import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/ui/media/widgets/media_thumbnail_widget.dart';
import 'package:mobile/routing/app_router.dart';

/// 媒体网格视图组件
///
/// 这是一个无状态组件，专门负责以固定的网格形式展示媒体列表。
class MediaGridView extends StatelessWidget {
  const MediaGridView({
    super.key, 
    required this.media,
  });

  final List<UnifiedMediaEntity> media;

  @override
  Widget build(BuildContext context) {
    // 使用 GridView.builder 来高效地显示大量媒体项
    return GridView.builder(
      // key 用于帮助 Flutter 识别和区分 Widget，在视图切换时可以提高性能
      key: const PageStorageKey('media_grid_view'),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // 每行显示4个
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: media.length,
      itemBuilder: (context, index) {
        final mediaEntity = media[index];
        return MediaThumbnailWidget(
          entity: mediaEntity,
          index: index,
          totalCount: media.length,
          onTap: () => _navigateToDetail(context, index),
        );
      },
    );
  }

  void _navigateToDetail(BuildContext context, int index) {
    AutoRouter.of(context).push(
      MediaDetailRoute(
        media: media,
        initialIndex: index,
      ),
    );
  }
}
