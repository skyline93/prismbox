import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/providers.dart';
import 'package:mobile/ui/media/widgets/media_body_grid.dart';
import 'package:mobile/ui/media/widgets/media_body_timeline.dart';
import 'package:mobile/ui/media/widgets/media_body_empty.dart';
import 'package:mobile/ui/media/widgets/media_body_error.dart';

class MediaBody extends HookConsumerWidget {
  const MediaBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaState = ref.watch(mediaViewModelProvider);
    final viewModel = ref.read(mediaViewModelProvider.notifier);
    final viewMode = ref.watch(mediaViewTypeProvider);

    return mediaState.when(
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
      data: (media) {
        if (media.isEmpty) {
          return EmptyMediaView(onSync: () => viewModel.syncWithCloud());
        }

        return switch (viewMode) {
          MediaViewType.grid => MediaGridBody(media: media),
          MediaViewType.timeline => MediaTimelineBody(media: media),
        };
      },
      error: (error) =>
          ErrorMediaView(error: error, onRetry: () => viewModel.retry()),
    );
  }
}
