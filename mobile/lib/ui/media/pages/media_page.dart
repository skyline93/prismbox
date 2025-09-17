// lib/ui/media/pages/media_page.dart

import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/providers/providers.dart';
import 'package:mobile/ui/media/widgets/media_body.dart';
import 'package:mobile/ui/media/widgets/media_selection_drawer.dart';
import 'package:mobile/core/service_locator.dart';
import 'package:mobile/features/sync/coordinator/media_sync_service_proxy.dart';

@RoutePage()
class MediaPage extends HookConsumerWidget {
  const MediaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelecting = ref.watch(
      selectionProvider.select((s) => s.isSelecting),
    );

    // [NEW] 定义抽屉的初始高度常量
    const double drawerInitialSize = 0.22;

    // [NEW] 计算当处于选择模式时，内容区域所需的底部内边距
    final bottomPaddingForBody = isSelecting
        ? MediaQuery.of(context).size.height * drawerInitialSize
        : 0.0;

    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              getIt<MediaSyncServiceProxy>().triggerCloudSync();
            },
            // [MODIFIED] 将计算好的内边距传递给 MediaBody
            child: MediaBody(bottomPadding: bottomPaddingForBody),
          ),
          IgnorePointer(
            ignoring: !isSelecting,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: isSelecting ? 1.0 : 0.0,
              child: DraggableScrollableSheet(
                initialChildSize: drawerInitialSize,
                minChildSize: drawerInitialSize,
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
