// lib/ui/media/widgets/media_body.dart

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
    // [-] viewModel 实例不再需要直接用于触发同步
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
          // [-] 旧的实现: return EmptyMediaView(onSync: () => viewModel.syncWithCloud());
          // [+] 新的实现:
          return EmptyMediaView(
            onSync: () {
              // 直接使用 syncJobManagerProvider 来创建后台任务
              ref.read(syncJobManagerProvider).createCloudChangesSyncJob();
            },
          );
        }

        return IndexedStack(
          index: viewMode.index,
          children: [
            MediaGridBody(media: media),
            MediaTimelineBody(media: media),
          ],
        );
      },
      error: (error) =>
          ErrorMediaView(error: error, onRetry: () => viewModel.retry()),
    );
  }
}
