// lib/ui/media/widgets/media_body.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/providers/providers.dart';
import 'package:mobile/ui/media/widgets/media_body_grid.dart';
import 'package:mobile/ui/media/widgets/media_body_timeline.dart';
import 'package:mobile/ui/media/widgets/media_body_empty.dart';
import 'package:mobile/ui/media/widgets/media_body_error.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/core/service_locator.dart';
import 'package:mobile/features/sync/coordinator/media_sync_service_proxy.dart';

class MediaBody extends HookConsumerWidget {
  const MediaBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<UnifiedMediaEntity>> mediaAsyncValue = ref.watch(
      mediaStreamProvider,
    );

    final viewMode = ref.watch(mediaViewTypeProvider);

    Widget makeScrollable(Widget widget) {
      // 使用 ListView 是让单个内容块支持 RefreshIndicator 的一种非常稳健的方式。
      return LayoutBuilder(
        builder: (context, constraints) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  // 确保内容区域至少和视口一样高
                  minHeight: constraints.maxHeight,
                ),
                // 将内容居中放置
                child: Center(child: widget),
              ),
            ],
          );
        },
      );
    }

    return mediaAsyncValue.when(
      loading: () => makeScrollable(
        // 将内容本身放入 Column 中，使其在 Center 中表现更好
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
              onSync: () {
                getIt<MediaSyncServiceProxy>().triggerCloudSync();
              },
            ),
          );
        }

        // 之前的 IndexedStack 索引安全检查依然保留
        final List<Widget> children = [
          MediaGridBody(media: mediaList),
          MediaTimelineBody(media: mediaList),
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
