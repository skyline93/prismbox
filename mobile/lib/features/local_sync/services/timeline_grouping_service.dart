// lib/features/local_sync/services/timeline_grouping_service.dart

import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/features/local_sync/models/timeline_section.dart';

/// 时间分组服务
///
/// 负责将媒体资源按时间进行分组，并生成友好的标题显示。
/// 支持按日/月/年三种粒度，由 [TimelineGroupingMode] 决定，后续可对接设置项。
class TimelineGroupingService {
  /// 将媒体资源列表按时间分组
  ///
  /// [assets] 已按时间降序排序的媒体资源列表
  /// [mode] 分组粒度，默认按日；后续可从设置或 UI 传入
  /// 返回按时间降序排序的分组列表
  List<TimelineSection> groupByTime(
    List<BaseAsset> assets, {
    TimelineGroupingMode mode = TimelineGroupingMode.day,
  }) {
    if (assets.isEmpty) {
      return [];
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 使用 Map 存储分组，key 为 sectionKey
    final sectionsMap = <String, List<BaseAsset>>{};

    // 遍历资产，按当前 mode 分组
    for (final asset in assets) {
      final createdAt = asset.createdAt;
      final assetDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
      final timeDiff = today.difference(assetDate).inDays;

      final sectionInfo = _determineSectionInfo(createdAt, timeDiff, mode);
      final sectionKey = sectionInfo['sectionKey'] as String;

      sectionsMap.putIfAbsent(sectionKey, () => []).add(asset);
    }

    // 转换为 TimelineSection 列表
    final result = <TimelineSection>[];
    int index = 0;

    for (final entry in sectionsMap.entries) {
      final sectionKey = entry.key;
      final sectionAssets = entry.value;
      
      // 确保分组内的资产按时间降序排序
      sectionAssets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      final firstAsset = sectionAssets.first;
      final sectionType = _determineSectionTypeFromKey(sectionKey);
      
      result.add(TimelineSection(
        sectionKey: sectionKey,
        displayTitle: _formatSectionTitle(firstAsset.createdAt, sectionKey),
        dateTime: firstAsset.createdAt,
        assets: sectionAssets,
        sectionType: sectionType,
        index: index++,
      ));
    }

    // 按时间降序排序（最新的在前）
    result.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    
    // 更新索引
    for (int i = 0; i < result.length; i++) {
      result[i] = TimelineSection(
        sectionKey: result[i].sectionKey,
        displayTitle: result[i].displayTitle,
        dateTime: result[i].dateTime,
        assets: result[i].assets,
        sectionType: result[i].sectionType,
        index: i,
      );
    }

    return result;
  }

  /// 根据 [mode] 确定分组信息（sectionKey 与 SectionType）
  Map<String, dynamic> _determineSectionInfo(
    DateTime dateTime,
    int daysDiff,
    TimelineGroupingMode mode,
  ) {
    String sectionKey;
    SectionType sectionType;

    switch (mode) {
      case TimelineGroupingMode.day:
        sectionType = SectionType.day;
        sectionKey = '${dateTime.year}-'
            '${dateTime.month.toString().padLeft(2, '0')}-'
            '${dateTime.day.toString().padLeft(2, '0')}';
        break;
      case TimelineGroupingMode.month:
        sectionType = SectionType.month;
        sectionKey = '${dateTime.year}-'
            '${dateTime.month.toString().padLeft(2, '0')}';
        break;
      case TimelineGroupingMode.year:
        sectionType = SectionType.year;
        sectionKey = '${dateTime.year}';
        break;
    }

    return {
      'sectionKey': sectionKey,
      'sectionType': sectionType,
    };
  }

  /// 从 sectionKey 确定分组类型
  SectionType _determineSectionTypeFromKey(String sectionKey) {
    final parts = sectionKey.split('-');
    if (parts.length == 3) {
      return SectionType.day;
    } else if (parts.length == 2) {
      return SectionType.month;
    } else {
      return SectionType.year;
    }
  }

  /// 格式化分组标题
  /// 
  /// [dateTime] 该分组的基准时间
  /// [sectionKey] 分组键（用于确定分组类型）
  String _formatSectionTitle(DateTime dateTime, String sectionKey) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final daysDiff = today.difference(date).inDays;

    // 解析 sectionKey 确定分组类型
    final parts = sectionKey.split('-');

    if (parts.length == 3) {
      // 按天分组
      if (daysDiff == 0) {
        return '今天';
      } else if (daysDiff == 1) {
        return '昨天';
      } else if (daysDiff <= 7) {
        // 本周
        final weekday = dateTime.weekday;
        final weekdayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
        return '本周${weekdayNames[weekday - 1]}';
      } else if (dateTime.year == now.year) {
        // 今年
        return '${dateTime.month}月${dateTime.day}日';
      } else {
        // 跨年
        return '${dateTime.year}年${dateTime.month}月${dateTime.day}日';
      }
    } else if (parts.length == 2) {
      // 按月分组
      return '${dateTime.year}年${dateTime.month}月';
    } else {
      // 按年分组
      return '${dateTime.year}年';
    }
  }
}

