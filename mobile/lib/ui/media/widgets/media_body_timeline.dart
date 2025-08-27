// lib/ui/media/widgets/media_body_timeline.dart

import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:intl/intl.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/routing/app_router.dart';
import 'package:mobile/ui/media/widgets/media_item.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:mobile/ui/media/widgets/draggable_scrollbar_custom.dart';
import 'package:collection/collection.dart';

// 视图模型定义 (保持不变)
sealed class TimelineItem {}

class DateTitleItem extends TimelineItem {
  final String formattedDate;
  DateTitleItem(this.formattedDate);
}

class MediaRowItem extends TimelineItem {
  final List<UnifiedMediaEntity> media;
  final int globalStartIndex;
  MediaRowItem(this.media, this.globalStartIndex);
}

class MediaTimelineBody extends HookConsumerWidget {
  final List<UnifiedMediaEntity> media;
  const MediaTimelineBody({super.key, required this.media});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Hooks 和数据处理逻辑 (保持不变)
    useAutomaticKeepAlive();
    final itemScrollController = useMemoized(() => ItemScrollController());
    final itemPositionsListener = useMemoized(
      () => ItemPositionsListener.create(),
    );
    const crossAxisCount = 4;
    final itemSize = MediaQuery.of(context).size.width / crossAxisCount;
    final sortedFullMedia = useMemoized(() {
      return List<UnifiedMediaEntity>.from(media)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }, [media]);
    final flatList = useMemoized(() {
      final items = <TimelineItem>[];
      int globalIndex = 0;
      final groupedByDate = groupBy(
        sortedFullMedia,
        (m) => DateTime(m.createdAt.year, m.createdAt.month, m.createdAt.day),
      );
      groupedByDate.forEach((date, mediaForDate) {
        final formattedDate = DateFormat('y年M月d日 EEEE', 'zh_CN').format(date);
        items.add(DateTitleItem(formattedDate));
        final chunks = mediaForDate.slices(crossAxisCount);
        for (final chunk in chunks) {
          items.add(MediaRowItem(chunk.toList(), globalIndex));
          globalIndex += chunk.length;
        }
      });
      return items;
    }, [sortedFullMedia]);
    final indexToDateMap = useMemoized(() {
      final map = <int, String>{};
      String currentDate = '';
      for (int i = 0; i < flatList.length; i++) {
        final item = flatList[i];
        if (item is DateTitleItem) {
          currentDate = item.formattedDate;
        }
        map[i] = currentDate;
      }
      return map;
    }, [flatList]);

    return DraggableScrollbar.semicircle(
      controller: itemScrollController,
      itemPositionsListener: itemPositionsListener,
      scrollStateListener: (scrolling) {},
      backgroundColor: Theme.of(context).primaryColor,
      heightScrollThumb: 48.0,

      // *** 关键修改 1: 提供自定义的 BoxConstraints ***
      // 我们设置了最小宽度，但没有设置最大宽度，允许标签容器自由伸展以适应内容
      labelConstraints: const BoxConstraints(minWidth: 90.0, maxHeight: 28.0),

      labelTextBuilder: (itemIndex) {
        if (itemIndex >= indexToDateMap.length || itemIndex < 0)
          return const Text('');
        final fullDate = indexToDateMap[itemIndex] ?? '';
        if (fullDate.isEmpty) return const Text('');

        String monthLabel = fullDate;
        final monthCharIndex = fullDate.indexOf('月');
        if (monthCharIndex != -1) {
          monthLabel = fullDate.substring(0, monthCharIndex + 1);
        }

        return Text(
          monthLabel,
          // *** 关键修改 2: 强制单行显示 ***
          // softWrap: false 和 maxLines: 1 确保文本不会换行
          softWrap: false,
          maxLines: 1,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            // 我们不再需要设置一个过小的字体大小了
          ),
        );
      },
      child: ScrollablePositionedList.builder(
        key: const PageStorageKey('media_timeline_body'),
        itemScrollController: itemScrollController,
        itemPositionsListener: itemPositionsListener,
        itemCount: flatList.length,
        itemBuilder: (context, index) {
          final item = flatList[index];

          switch (item) {
            case DateTitleItem():
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  item.formattedDate,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            case MediaRowItem():
              return SizedBox(
                height: itemSize,
                child: _TimelineMediaRow(
                  mediaForRow: item.media,
                  itemSize: itemSize,
                  globalStartIndex: item.globalStartIndex,
                  sortedFullMedia: sortedFullMedia,
                ),
              );
          }
        },
      ),
    );
  }
}

// _TimelineMediaRow Widget (保持不变)
class _TimelineMediaRow extends StatelessWidget {
  final List<UnifiedMediaEntity> mediaForRow;
  final double itemSize;
  final int globalStartIndex;
  final List<UnifiedMediaEntity> sortedFullMedia;

  const _TimelineMediaRow({
    required this.mediaForRow,
    required this.itemSize,
    required this.globalStartIndex,
    required this.sortedFullMedia,
  });

  @override
  Widget build(BuildContext context) {
    const crossAxisCount = 4;
    const spacing = 2.0;
    return Row(
      children: List.generate(crossAxisCount, (index) {
        if (index >= mediaForRow.length) {
          return SizedBox(width: itemSize);
        }
        final mediaEntity = mediaForRow[index];
        final globalIndex = globalStartIndex + index;
        return SizedBox(
          width: itemSize,
          height: itemSize,
          child: Padding(
            padding: const EdgeInsets.all(spacing / 2),
            child: MediaItem(
              entity: mediaEntity,
              index: globalIndex,
              totalCount: sortedFullMedia.length,
              onTap: () => AutoRouter.of(context).push(
                GalleryRoute(media: sortedFullMedia, initialIndex: globalIndex),
              ),
            ),
          ),
        );
      }),
    );
  }
}
