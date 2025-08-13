import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:intl/intl.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/ui/media/widgets/media_thumbnail_widget.dart';
import 'package:mobile/routing/app_router.dart';

/// 媒体时间线视图组件
///
/// 此组件将媒体项按日期进行分组，并以时间倒序的列表形式展示。
class MediaTimelineView extends StatelessWidget {
  const MediaTimelineView({super.key, required this.media});

  final List<UnifiedMediaEntity> media;

  /// 按日期对媒体进行分组的辅助函数
  ///
  /// - 使用 `LinkedHashMap` 来保持日期顺序。
  /// - 遍历所有媒体项，将它们的创建日期（忽略时间）作为 Key。
  /// - 将相同日期的媒体项聚合到同一个 List 中。
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

    // ⭐️ 核心修复 #1: 对分组后的日期Key进行降序排序
    // b.compareTo(a) 会实现降序排序，确保最新的日期排在最前面。
    dates.sort((a, b) => b.compareTo(a));

    // 使用 ListView.builder 来构建日期分组列表
    return ListView.builder(
      // key 用于帮助 Flutter 识别和区分 Widget，在视图切换时可以提高性能
      key: const PageStorageKey('media_timeline_view'),
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final date = dates[index];
        final mediaForDate = groupedMedia[date]!;

        // ⭐️ 核心修复 #2: 对同一天内的照片也进行降序排序
        // 确保在网格视图中，最新的照片显示在最前面。
        mediaForDate.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // 使用 `intl` 包来格式化日期，使其更友好
        final formattedDate = DateFormat('y年M月d日 EEEE', 'zh_CN').format(date);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日期标题
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                formattedDate,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            // 当天的媒体网格
            GridView.builder(
              // shrinkWrap 和 physics 是必需的，因为 GridView 嵌套在 ListView 中
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
                // 避免与外部 index 变量名冲突
                final mediaEntity = mediaForDate[gridIndex];
                return MediaThumbnailWidget(
                  entity: mediaEntity,
                  // 这里的 index 和 totalCount 应该是相对于当天的列表
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
          media: sortedFullMedia, // 传递排序后的列表
          initialIndex: globalIndex,
        ),
      );
    }
  }
}
