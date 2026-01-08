// lib/providers/timeline/timeline_content_filter_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:prismbox/features/local_sync/models/timeline_content_filter_config.dart';

part 'timeline_content_filter_provider.g.dart';

/// 时间线内容过滤配置 Provider
///
/// 使用 `family` 参数区分不同页面（如收藏、视频、最近添加等）。
/// 每个页面拥有独立的过滤配置，页面切换时自动清理。
///
/// **页面标识符**：
/// - `'favorite'` - 收藏时间线页面
/// - `'video'` - 视频时间线页面
/// - `'recentlyAdded'` - 最近添加时间线页面
/// - `'main'` - 主时间线页面（照片页面，默认无内容过滤）
@riverpod
class TimelineContentFilterConfigProvider
    extends _$TimelineContentFilterConfigProvider {
  @override
  TimelineContentFilterConfig build(String pageId) {
    // 根据页面 ID 设置默认配置
    switch (pageId) {
      case 'favorite':
        return const TimelineContentFilterConfig(favoriteOnly: true);
      case 'video':
        return const TimelineContentFilterConfig(videoOnly: true);
      case 'recentlyAdded':
      case 'main':
      default:
        return const TimelineContentFilterConfig();
    }
  }

  /// 设置仅收藏过滤
  void setFavoriteOnly() {
    state = const TimelineContentFilterConfig(favoriteOnly: true);
  }

  /// 设置仅视频过滤
  void setVideoOnly() {
    state = const TimelineContentFilterConfig(videoOnly: true);
  }

  /// 清除所有内容过滤
  void clear() {
    state = const TimelineContentFilterConfig();
  }
}
