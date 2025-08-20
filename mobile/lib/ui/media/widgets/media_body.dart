// lib/ui/media/widgets/media_body.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/providers.dart';
import 'package:mobile/ui/media/widgets/media_body_grid.dart';
import 'package:mobile/ui/media/widgets/media_body_timeline.dart';
import 'package:mobile/ui/media/widgets/media_body_empty.dart';
import 'package:mobile/ui/media/widgets/media_body_error.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';

class MediaBody extends HookConsumerWidget {
  const MediaBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<UnifiedMediaEntity>> mediaAsyncValue = ref.watch(
      mediaStreamProvider,
    );
    mediaAsyncValue.whenData((media) {
      print("媒体流更新: ${media.map((e) => '${e.id}:${e.syncStatus}').toList()}");
    });

    final viewMode = ref.watch(mediaViewTypeProvider);

    return mediaAsyncValue.when(
      loading: () => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              '正在加载媒体库...',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              '请稍候',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
      data: (mediaList) {
        if (mediaList.isEmpty) {
          return EmptyMediaView(
            onSync: () {
              ref.read(syncJobManagerProvider).createCloudChangesSyncJob();
            },
          );
        }

        return IndexedStack(
          index: viewMode.index,
          children: [
            MediaGridBody(media: mediaList),
            MediaTimelineBody(media: mediaList),
          ],
        );
      },
      error: (err, stack) => ErrorMediaView(
        error: err.toString(),
        onRetry: () => ref.invalidate(mediaStreamProvider),
      ),
    );
  }
}
