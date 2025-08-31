// lib/ui/media/pages/media_page.dart

import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/providers/providers.dart';
import 'package:mobile/ui/media/widgets/media_bar_top.dart';
import 'package:mobile/ui/media/widgets/media_body.dart';
import 'package:mobile/ui/media/widgets/media_selection_drawer.dart';

@RoutePage()
class MediaPage extends HookConsumerWidget {
  const MediaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelecting = ref.watch(
      selectionProvider.select((s) => s.isSelecting),
    );

    return Scaffold(
      appBar: const MediaAppBar(),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              final jobManager = ref.read(syncJobManagerProvider);
              await jobManager.createCloudChangesSyncJob();
            },
            child: const MediaBody(),
          ),

          // 使用 IgnorePointer 避免在未选择时，下方的抽屉（即使不可见）也能接收手势
          IgnorePointer(
            ignoring: !isSelecting,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: isSelecting ? 1.0 : 0.0,
              child: DraggableScrollableSheet(
                // [关键修改] 调整尺寸
                // 这个值需要你微调，确保初始高度刚好包裹住核心操作按钮
                initialChildSize: 0.22,
                minChildSize: 0.22,
                // 最大可以拉到屏幕的 90%
                maxChildSize: 0.9,
                builder: (context, scrollController) {
                  return MediaSelectionDrawer(
                    scrollController: scrollController,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
