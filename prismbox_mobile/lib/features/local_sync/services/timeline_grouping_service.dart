// lib/features/local_sync/services/timeline_grouping_service.dart

import 'package:prismbox/domain/entities/local_asset.dart';
import 'package:prismbox/features/local_sync/models/timeline_section.dart';

/// 时间分组服务
/// 
/// 负责将媒体资源按时间进行分组，并生成友好的标题显示
class TimelineGroupingService {
  /// 按天分组的阈值（天数）
  static const int dayGroupingThresholdDays = 90; // 3 个月

  /// 按月分组的阈值（天数）
  static const int monthGroupingThresholdDays = 365; // 1 年

  /// 将媒体资源列表按时间分组
  /// 
  /// [assets] 已按时间降序排序的媒体资源列表
  /// 返回按时间降序排序的分组列表
  List<TimelineSection> groupByTime(List<LocalAsset> assets) {
    if (assets.isEmpty) {
      return [];
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // 使用 Map 存储分组，key 为 sectionKey
    final sectionsMap = <String, List<LocalAsset>>{};

    // 遍历资产，按时间分组
    for (final asset in assets) {
      final createdAt = asset.createdAt;
      final assetDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
      final timeDiff = today.difference(assetDate).inDays;

      // 确定分组类型和 sectionKey
      final sectionInfo = _determineSectionInfo(createdAt, timeDiff);
      final sectionKey = sectionInfo['sectionKey'] as String;

      // 添加到对应分组
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

  /// 确定分组信息（sectionKey 和 sectionType）
  Map<String, dynamic> _determineSectionInfo(DateTime dateTime, int daysDiff) {
    String sectionKey;
    SectionType sectionType;

    if (daysDiff <= dayGroupingThresholdDays) {
      // 最近 3 个月：按天分组
      sectionType = SectionType.day;
      sectionKey = '${dateTime.year}-'
          '${dateTime.month.toString().padLeft(2, '0')}-'
          '${dateTime.day.toString().padLeft(2, '0')}';
    } else if (daysDiff <= monthGroupingThresholdDays) {
      // 3 个月到 1 年：按月分组
      sectionType = SectionType.month;
      sectionKey = '${dateTime.year}-'
          '${dateTime.month.toString().padLeft(2, '0')}';
    } else {
      // 1 年以上：按年分组
      sectionType = SectionType.year;
      sectionKey = '${dateTime.year}';
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

