// lib/ui/media/widgets/media_grid_body.dart

import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/routing/app_router.dart';
import 'package:mobile/ui/media/widgets/media_item.dart';

class MediaGridBody extends HookConsumerWidget {
  const MediaGridBody({super.key, required this.media});

  final List<UnifiedMediaEntity> media;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useAutomaticKeepAlive();

    return GridView.builder(
      key: const PageStorageKey('media_grid_body'),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: media.length,
      itemBuilder: (context, index) {
        final mediaEntity = media[index];
        return MediaItem(
          entity: mediaEntity,
          index: index,
          totalCount: media.length,
          onTap: () => {
            AutoRouter.of(
              context,
            ).push(GalleryRoute(media: media, initialIndex: index)),
          },
        );
      },
    );
  }
}
