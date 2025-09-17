// lib/ui/media/widgets/media_grid_body.dart

import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/providers/providers.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/routing/app_router.dart';
import 'package:mobile/ui/media/widgets/media_item.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:mobile/ui/media/widgets/draggable_scrollbar_custom.dart';

class MediaGridBody extends HookConsumerWidget {
  // [NEW] 添加 bottomPadding 属性
  final double bottomPadding;
  final List<UnifiedMediaEntity> media;

  // [MODIFIED] 更新构造函数以接收 padding
  const MediaGridBody({
    super.key,
    required this.media,
    this.bottomPadding = 0.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useAutomaticKeepAlive();
    final itemScrollController = useMemoized(() => ItemScrollController());
    final itemPositionsListener = useMemoized(
      () => ItemPositionsListener.create(),
    );

    // --- 布局计算 ---
    const crossAxisCount = 4;
    final itemSize = MediaQuery.of(context).size.width / crossAxisCount;
    final rowCount = (media.length / crossAxisCount).ceil();

    return DraggableScrollbar.semicircle(
      controller: itemScrollController,
      itemPositionsListener: itemPositionsListener,
      scrollStateListener: (scrolling) {},
      backgroundColor: Theme.of(context).primaryColor,
      heightScrollThumb: 48.0,
      labelConstraints: const BoxConstraints(minWidth: 90.0, maxHeight: 28.0),
      labelTextBuilder: (rowIndex) {
        if (media.isEmpty) {
          return const Text('');
        }
        final firstItemIndex = (rowIndex * crossAxisCount).clamp(
          0,
          media.length - 1,
        );
        final currentItem = media[firstItemIndex];
        final formattedDate = DateFormat.yMMMM(
          'zh_CN',
        ).format(currentItem.createdAt);

        return Text(
          formattedDate,
          softWrap: false,
          maxLines: 1,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        );
      },
      child: ScrollablePositionedList.builder(
        // [MODIFIED] 在这里应用 padding
        padding: EdgeInsets.only(bottom: bottomPadding),
        key: const PageStorageKey('media_grid_body'),
        itemScrollController: itemScrollController,
        itemPositionsListener: itemPositionsListener,
        itemCount: rowCount,
        itemBuilder: (context, rowIndex) {
          return SizedBox(
            height: itemSize,
            child: _MediaRowWidget(
              rowIndex: rowIndex,
              media: media,
              itemSize: itemSize,
              crossAxisCount: crossAxisCount,
            ),
          );
        },
      ),
    );
  }
}

// _MediaRowWidget 不需要修改
class _MediaRowWidget extends ConsumerWidget {
  // ... (代码无变化)
  final int rowIndex;
  final List<UnifiedMediaEntity> media;
  final double itemSize;
  final int crossAxisCount;

  const _MediaRowWidget({
    required this.rowIndex,
    required this.media,
    required this.itemSize,
    required this.crossAxisCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const spacing = 2.0;

    final isSelecting = ref.watch(
      selectionProvider.select((s) => s.isSelecting),
    );

    return Row(
      children: List.generate(crossAxisCount, (colIndex) {
        final index = rowIndex * crossAxisCount + colIndex;
        if (index >= media.length) {
          return SizedBox(width: itemSize);
        }

        final mediaEntity = media[index];
        return SizedBox(
          width: itemSize,
          height: itemSize,
          child: Padding(
            padding: const EdgeInsets.all(spacing / 2),
            child: MediaItem(
              entity: mediaEntity,
              index: index,
              totalCount: media.length,
              onTap: () {
                if (isSelecting) {
                  ref.read(selectionProvider.notifier).toggleItem(mediaEntity);
                } else {
                  AutoRouter.of(
                    context,
                  ).push(GalleryRoute(media: media, initialIndex: index));
                }
              },
              onLongPress: () {
                if (!isSelecting) {
                  ref
                      .read(selectionProvider.notifier)
                      .startSelection(mediaEntity);
                }
              },
            ),
          ),
        );
      }),
    );
  }
}
