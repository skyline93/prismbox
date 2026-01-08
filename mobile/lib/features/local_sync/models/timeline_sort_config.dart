// lib/features/local_sync/models/timeline_sort_config.dart

/// 时间线排序字段枚举
enum TimelineSortField {
  /// 按创建时间排序
  createdAt,

  /// 按更新时间排序（用于"最近添加"）
  updatedAt,
}

/// 排序顺序枚举
enum SortOrder {
  /// 升序
  asc,

  /// 降序
  desc,
}

/// 时间线排序配置
///
/// 用于控制时间线数据的排序方式。
/// 排序独立于过滤配置，可以独立使用或与过滤组合使用。
///
/// **扩展接口预留**：
/// 未来可以添加更多排序字段，如：
/// - `name` - 按名称排序
/// - `size` - 按文件大小排序
/// - `duration` - 按时长排序（仅视频）
class TimelineSortConfig {
  /// 排序字段
  final TimelineSortField sortBy;

  /// 排序顺序
  final SortOrder order;

  const TimelineSortConfig({
    this.sortBy = TimelineSortField.createdAt,
    this.order = SortOrder.desc,
  });

  /// 创建"最近添加"排序配置（按更新时间降序）
  factory TimelineSortConfig.recentlyAdded() {
    return const TimelineSortConfig(
      sortBy: TimelineSortField.updatedAt,
      order: SortOrder.desc,
    );
  }

  /// 创建默认排序配置（按创建时间降序）
  factory TimelineSortConfig.defaultSort() {
    return const TimelineSortConfig();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimelineSortConfig &&
        other.sortBy == sortBy &&
        other.order == order;
  }

  @override
  int get hashCode => Object.hash(sortBy, order);
}

