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
  const MediaGridBody({super.key, required this.media});

  final List<UnifiedMediaEntity> media;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useAutomaticKeepAlive();
    final itemScrollController = useMemoized(() => ItemScrollController());
    final itemPositionsListener = useMemoized(
      () => ItemPositionsListener.create(),
    );

    // --- 布局计算 ---
    const crossAxisCount = 4;
    // 计算每个网格单元的精确尺寸（宽度和高度）
    final itemSize = MediaQuery.of(context).size.width / crossAxisCount;
    // 计算总行数
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
        // 根据行号计算出该行第一个媒体资源的索引
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
        key: const PageStorageKey('media_grid_body'),
        itemScrollController: itemScrollController,
        itemPositionsListener: itemPositionsListener,
        itemCount: rowCount,
        itemBuilder: (context, rowIndex) {
          // 关键：为每一行提供固定的高度，确保滚动条计算精确
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

// [修改] 将 _MediaRowWidget 转换为 ConsumerWidget 以访问 Provider
class _MediaRowWidget extends ConsumerWidget {
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

    // 监听当前是否处于选择模式
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
              // [修改] onTap 行为根据选择模式动态变化
              onTap: () {
                if (isSelecting) {
                  // 在选择模式下，点击是切换选择
                  ref.read(selectionProvider.notifier).toggleItem(mediaEntity);
                } else {
                  // 否则，是打开画廊
                  AutoRouter.of(
                    context,
                  ).push(GalleryRoute(media: media, initialIndex: index));
                }
              },
              // [新增] onLongPress 用于启动选择模式
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
