// lib/ui/media/widgets/media_body.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/providers/providers.dart';
import 'package:mobile/ui/media/widgets/media_body_grid.dart';
import 'package:mobile/ui/media/widgets/media_body_timeline.dart';
import 'package:mobile/ui/media/widgets/media_body_empty.dart';
import 'package:mobile/ui/media/widgets/media_body_error.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/features/replicator/cloud_data_replicator_provider.dart';

class MediaBody extends HookConsumerWidget {
  // [NEW] 添加 bottomPadding 属性
  final double bottomPadding;

  // [MODIFIED] 更新构造函数以接收 padding
  const MediaBody({super.key, this.bottomPadding = 0.0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<UnifiedMediaEntity>> mediaAsyncValue = ref.watch(
      mediaStreamProvider,
    );

    final viewMode = ref.watch(mediaViewTypeProvider);

    Widget makeScrollable(Widget widget) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(child: widget),
              ),
            ],
          );
        },
      );
    }

    return mediaAsyncValue.when(
      loading: () => makeScrollable(
        Column(
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
          return makeScrollable(
            EmptyMediaView(
              onSync: () async {
                // getIt<MediaSyncServiceProxy>().triggerCloudSync();
                final cloudDataReplicatorService = await ref.read(
                  cloudDataReplicatorServiceProvider.future,
                );
                await cloudDataReplicatorService.syncMediaAssets();
              },
            ),
          );
        }

        // [MODIFIED] 将 bottomPadding 传递给子组件
        final List<Widget> children = [
          MediaGridBody(media: mediaList, bottomPadding: bottomPadding),
          MediaTimelineBody(media: mediaList, bottomPadding: bottomPadding),
        ];

        int safeIndex = viewMode.index;
        if (safeIndex < 0 || safeIndex >= children.length) {
          debugPrint(
            'Warning: viewMode.index ($safeIndex) is out of bounds. Defaulting to 0.',
          );
          safeIndex = 0;
        }

        return IndexedStack(index: safeIndex, children: children);
      },
      error: (err, stack) => makeScrollable(
        ErrorMediaView(
          error: err.toString(),
          onRetry: () => ref.invalidate(mediaStreamProvider),
        ),
      ),
    );
  }
}
