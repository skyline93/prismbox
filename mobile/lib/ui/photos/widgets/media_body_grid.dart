import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/ui/media/widgets/media_thumbnail_widget.dart';
import 'package:mobile/routing/app_router.dart';

class MediaGridBody extends StatelessWidget {
  const MediaGridBody({super.key, required this.media});

  final List<UnifiedMediaEntity> media;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      key: const PageStorageKey('media_grid_body'),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
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
          onTap: () => {
            AutoRouter.of(
              context,
            ).push(MediaDetailRoute(media: media, initialIndex: index)),
          },
        );
      },
    );
  }
}
