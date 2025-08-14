import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/providers.dart';
import 'package:mobile/ui/media/widgets/media_grid_view.dart';
import 'package:mobile/ui/media/widgets/media_timeline_view.dart';
import 'package:mobile/ui/photos/widgets/media_body_empty.dart';
import 'package:mobile/ui/photos/widgets/media_body_error.dart';

class MediaBody extends HookConsumerWidget {
  const MediaBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaState = ref.watch(mediaViewModelProvider);
    final viewModel = ref.read(mediaViewModelProvider.notifier);
    final viewMode = ref.watch(mediaViewTypeProvider);

    if (mediaState.isLoading) {
      return Center(
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
      );
    }

    if (mediaState.error != null) {
      return ErrorMediaView(
        error: mediaState.error!,
        onRetry: () => viewModel.retry(),
      );
    }

    if (mediaState.media.isEmpty) {
      return EmptyMediaView(onSync: () => viewModel.syncWithCloud());
    }

    switch (viewMode) {
      case MediaViewType.grid:
        return MediaGridView(media: mediaState.media);
      case MediaViewType.timeline:
        return MediaTimelineView(media: mediaState.media);
    }
  }
}
