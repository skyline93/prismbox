// lib/ui/media/widgets/media_body_grid.dart
import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/providers.dart';
import 'package:mobile/routing/app_router.dart';
import 'package:mobile/ui/media/widgets/media_item.dart';
import 'package:drag_select_grid_view/drag_select_grid_view.dart';

class MediaGridBody extends HookConsumerWidget {
  final List<UnifiedMediaEntity> media;
  const MediaGridBody({super.key, required this.media});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useAutomaticKeepAlive();
    final sortedMedia = useMemoized(() {
      return List<UnifiedMediaEntity>.from(media)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }, [media]);

    final controller = useMemoized(() => DragSelectGridViewController());

    useEffect(() {
      void listener() {
        final selection = controller.value;
        final selectedItems = selection.selectedIndexes
            .map((i) => sortedMedia[i])
            .toSet();

        ref
            .read(selectionProvider.notifier)
            .setSelection(selection.isSelecting, selectedItems);
      }

      controller.addListener(listener);
      return () => controller.removeListener(listener);
    }, [controller, sortedMedia]);

    return DragSelectGridView(
      key: const PageStorageKey('media_grid_body_selectable'),
      // [错误修正] 将参数 `controller` 修改为正确的 `dragSelectController`
      gridController: controller,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 2.0,
        mainAxisSpacing: 2.0,
      ),
      itemCount: sortedMedia.length,
      itemBuilder: (context, index, selected) {
        final entity = sortedMedia[index];
        return MediaItem(
          entity: entity,
          index: index,
          totalCount: sortedMedia.length,
          onTap: () {
            final isSelecting = ref.read(selectionProvider).isSelecting;
            if (isSelecting) {
              ref.read(selectionProvider.notifier).toggleItem(entity);
            } else {
              AutoRouter.of(
                context,
              ).push(GalleryRoute(media: sortedMedia, initialIndex: index));
            }
          },
          // onLongPress 由 DragSelectGridView 自动处理，无需提供
        );
      },
    );
  }
}
