import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:intl/intl.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/ui/media/widgets/media_thumbnail_widget.dart';
import 'package:mobile/routing/app_router.dart';

class MediaTimelineView extends StatelessWidget {
  final List<UnifiedMediaEntity> media;

  const MediaTimelineView({super.key, required this.media});

  Map<DateTime, List<UnifiedMediaEntity>> _groupMediaByDate() {
    final groupedMedia = LinkedHashMap<DateTime, List<UnifiedMediaEntity>>();

    for (final m in media) {
      // 从时间戳中提取年月日，忽略时分秒
      final date = DateTime(
        m.createdAt.year,
        m.createdAt.month,
        m.createdAt.day,
      );

      if (groupedMedia[date] == null) {
        groupedMedia[date] = [];
      }
      groupedMedia[date]!.add(m);
    }
    return groupedMedia;
  }

  @override
  Widget build(BuildContext context) {
    final groupedMedia = _groupMediaByDate();
    final dates = groupedMedia.keys.toList();

    dates.sort((a, b) => b.compareTo(a));

    return ListView.builder(
      key: const PageStorageKey('media_timeline_body'),
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final date = dates[index];
        final mediaForDate = groupedMedia[date]!;
        final formattedDate = DateFormat('y年M月d日 EEEE', 'zh_CN').format(date);

        mediaForDate.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                formattedDate,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 2),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: mediaForDate.length,
              itemBuilder: (context, gridIndex) {
                final mediaEntity = mediaForDate[gridIndex];
                return MediaThumbnailWidget(
                  entity: mediaEntity,
                  index: gridIndex,
                  totalCount: mediaForDate.length,
                  onTap: () => _navigateToDetail(context, mediaEntity),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToDetail(BuildContext context, UnifiedMediaEntity entity) {
    // ⭐️ 优化: 因为我们已经对 mediaForDate 进行了排序，所以我们可以直接
    // 传递排序后的完整列表，以确保详情页的左右滑动顺序与时间线视图一致。

    // 1. 先对完整的 `media` 列表进行一次最终排序，确保它与时间线视图的显示顺序完全一致
    final sortedFullMedia = List<UnifiedMediaEntity>.from(media);
    sortedFullMedia.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // 2. 在排序后的列表中找到当前点击项的索引
    final globalIndex = sortedFullMedia.indexOf(entity);

    if (globalIndex != -1) {
      AutoRouter.of(context).push(
        MediaDetailRoute(
          media: sortedFullMedia,
          initialIndex: globalIndex,
        ),
      );
    }
  }
}
