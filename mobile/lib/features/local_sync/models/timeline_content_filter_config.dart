// lib/features/local_sync/models/timeline_content_filter_config.dart

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

  /// 是否仅显示 RAW 照片
  ///
  /// - `null`: 不按 RAW 属性过滤
  /// - `true`: 仅显示 RAW 照片（且为图片类型）
  /// - `false`: 仅显示非 RAW 照片（预留，当前未使用）
  final bool? rawOnly;

  /// 是否仅显示 Live Photo
  ///
  /// - `null`: 不按 Live 属性过滤
  /// - `true`: 仅显示 Live Photo（底层通过 isMotionPhoto 判断）
  /// - `false`: 仅显示非 Live 资产（预留，当前未使用）
  final bool? liveOnly;

  const TimelineContentFilterConfig({
    this.favoriteOnly,
    this.videoOnly,
    this.rawOnly,
    this.liveOnly,
  });

  /// 判断是否有任何内容过滤条件
  bool get hasContentFilter => favoriteOnly != null ||
      videoOnly != null ||
      rawOnly != null ||
      liveOnly != null;

  /// 创建仅收藏的配置
  factory TimelineContentFilterConfig.favoriteOnly() {
    return const TimelineContentFilterConfig(favoriteOnly: true);
  }

  /// 创建仅视频的配置
  factory TimelineContentFilterConfig.videoOnly() {
    return const TimelineContentFilterConfig(videoOnly: true);
  }

  /// 创建仅 RAW 照片的配置
  factory TimelineContentFilterConfig.rawOnly() {
    return const TimelineContentFilterConfig(rawOnly: true);
  }

  /// 创建仅 Live Photo 的配置
  factory TimelineContentFilterConfig.liveOnly() {
    return const TimelineContentFilterConfig(liveOnly: true);
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
        other.videoOnly == videoOnly &&
        other.rawOnly == rawOnly &&
        other.liveOnly == liveOnly;
  }

  @override
  int get hashCode =>
      Object.hash(favoriteOnly, videoOnly, rawOnly, liveOnly);
}

