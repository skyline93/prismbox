// lib/ui/media/widgets/media_timeline_view.dart

import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/ui/media/widgets/media_thumbnail_widget.dart';

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

    // 使用 ListView.builder 来构建日期分组列表
    return ListView.builder(
      // key 用于帮助 Flutter 识别和区分 Widget，在视图切换时可以提高性能
      key: const PageStorageKey('media_timeline_view'),
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final date = dates[index];
        final mediaForDate = groupedMedia[date]!;
        // 使用 `intl` 包来格式化日期，使其更友好
        // 需要在 pubspec.yaml 中添加 `intl` 依赖
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
              itemBuilder: (context, index) {
                final mediaEntity = mediaForDate[index];
                return MediaThumbnailWidget(entity: mediaEntity);
              },
            ),
          ],
        );
      },
    );
  }
}
