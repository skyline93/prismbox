import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'timeline_scroll_to_top_provider.g.dart';

/// 时间线滚动到顶部 Provider
@riverpod
class TimelineScrollToTop extends _$TimelineScrollToTop {
  @override
  bool build() => false;

  void scrollToTop() {
    state = !state; // 切换状态以触发监听
  }
}

