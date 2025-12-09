// lib/features/local_sync/models/timeline_section.dart

import 'package:prismbox/domain/entities/local_asset.dart';

/// 分组类型
enum SectionType {
  /// 按天分组（最近 3 个月）
  day,

  /// 按月分组（3 个月到 1 年）
  month,

  /// 按年分组（1 年以上）
  year,
}

/// 时间线分组数据模型
/// 
/// 表示一个时间段的照片分组，包含该时间段的所有媒体资源
class TimelineSection {
  /// 分组唯一标识（用于缓存和比较）
  /// 
  /// 格式：
  /// - day: "2024-01-15"
  /// - month: "2024-01"
  /// - year: "2024"
  final String sectionKey;

  /// 显示标题（如"今天"、"昨天"、"2024年1月"等）
  final String displayTitle;

  /// 该分组的基准时间
  final DateTime dateTime;

  /// 该分组下的所有媒体资源
  final List<LocalAsset> assets;

  /// 分组类型
  final SectionType sectionType;

  /// 该分组在列表中的索引（用于快速定位）
  final int index;

  TimelineSection({
    required this.sectionKey,
    required this.displayTitle,
    required this.dateTime,
    required this.assets,
    required this.sectionType,
    required this.index,
  });

  @override
  String toString() {
    return 'TimelineSection(sectionKey: $sectionKey, displayTitle: $displayTitle, '
        'dateTime: $dateTime, assetsCount: ${assets.length}, '
        'sectionType: $sectionType, index: $index)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimelineSection &&
        other.sectionKey == sectionKey &&
        other.displayTitle == displayTitle &&
        other.dateTime == dateTime &&
        other.sectionType == sectionType &&
        other.index == index;
  }

  @override
  int get hashCode {
    return Object.hash(
      sectionKey,
      displayTitle,
      dateTime,
      sectionType,
      index,
    );
  }
}

