// lib/providers/timeline/timeline_sort_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:prismbox/features/local_sync/models/timeline_sort_config.dart';

part 'timeline_sort_provider.g.dart';

/// 时间线排序配置 Provider
///
/// 使用 `family` 参数区分不同页面（如收藏、视频、最近添加等）。
/// 每个页面拥有独立的排序配置，页面切换时自动清理。
///
/// **页面标识符**：
/// - `'favorite'` - 收藏时间线页面
/// - `'video'` - 视频时间线页面
/// - `'recentlyAdded'` - 最近添加时间线页面（默认按更新时间降序）
/// - `'main'` - 主时间线页面（照片页面，默认按创建时间降序）
@riverpod
class TimelineSortConfigProvider extends _$TimelineSortConfigProvider {
  @override
  TimelineSortConfig build(String pageId) {
    // 根据页面 ID 设置默认配置
    switch (pageId) {
      case 'recentlyAdded':
        return const TimelineSortConfig(
          sortBy: TimelineSortField.updatedAt,
          order: SortOrder.desc,
        );
      case 'favorite':
      case 'video':
      case 'main':
      default:
        return const TimelineSortConfig();
    }
  }

  /// 设置排序字段
  void setSortBy(TimelineSortField sortBy) {
    state = TimelineSortConfig(sortBy: sortBy, order: state.order);
  }

  /// 设置排序顺序
  void setSortOrder(SortOrder order) {
    state = TimelineSortConfig(sortBy: state.sortBy, order: order);
  }

  /// 设置"最近添加"排序（按更新时间降序）
  void setRecentlyAdded() {
    state = const TimelineSortConfig(
      sortBy: TimelineSortField.updatedAt,
      order: SortOrder.desc,
    );
  }
}
