// lib/features/local_sync/models/timeline_content_filter_config.dart

/// 时间线内容过滤配置
///
/// 用于根据资产属性（如收藏状态、媒体类型）过滤时间线数据。
/// 内容过滤与本地/远程隔离过滤独立，可以组合使用。
///
/// **扩展接口预留**：
/// 未来可以添加更多过滤条件，如：
/// - `location: String?` - 按地点过滤
/// - `tags: List<String>?` - 按标签过滤
/// - `dateRange: DateTimeRange?` - 按日期范围过滤
class TimelineContentFilterConfig {
  /// 是否仅显示收藏资产
  /// - `null`: 不过滤收藏状态
  /// - `true`: 仅显示收藏资产
  /// - `false`: 仅显示非收藏资产（预留，当前未使用）
  final bool? favoriteOnly;

  /// 是否仅显示视频资产
  /// - `null`: 不过滤媒体类型
  /// - `true`: 仅显示视频资产
  /// - `false`: 仅显示非视频资产（预留，当前未使用）
  final bool? videoOnly;

  const TimelineContentFilterConfig({
    this.favoriteOnly,
    this.videoOnly,
  });

  /// 判断是否有任何内容过滤条件
  bool get hasContentFilter => favoriteOnly != null || videoOnly != null;

  /// 创建仅收藏的配置
  factory TimelineContentFilterConfig.favoriteOnly() {
    return const TimelineContentFilterConfig(favoriteOnly: true);
  }

  /// 创建仅视频的配置
  factory TimelineContentFilterConfig.videoOnly() {
    return const TimelineContentFilterConfig(videoOnly: true);
  }

  /// 创建无过滤的配置
  factory TimelineContentFilterConfig.none() {
    return const TimelineContentFilterConfig();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimelineContentFilterConfig &&
        other.favoriteOnly == favoriteOnly &&
        other.videoOnly == videoOnly;
  }

  @override
  int get hashCode => Object.hash(favoriteOnly, videoOnly);
}

