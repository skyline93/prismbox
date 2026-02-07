// lib/providers/timeline/timeline_grouping_mode_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:prismbox/features/local_sync/models/timeline_section.dart';

part 'timeline_grouping_mode_provider.g.dart';

/// 时间线分组粒度 Provider
///
/// 当前默认按日分组；后续可在设置或时间线页提供切换入口，
/// 通过 [setMode] 切换为按日/月/年。
@riverpod
class TimelineGroupingModeNotifier extends _$TimelineGroupingModeNotifier {
  @override
  TimelineGroupingMode build() => TimelineGroupingMode.day;

  /// 设置分组粒度（预留：由设置页或时间线筛选栏调用）
  void setMode(TimelineGroupingMode mode) {
    state = mode;
  }
}
