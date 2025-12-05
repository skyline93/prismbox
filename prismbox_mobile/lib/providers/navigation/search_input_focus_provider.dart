import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_input_focus_provider.g.dart';

/// 搜索输入框聚焦 Provider
@riverpod
class SearchInputFocus extends _$SearchInputFocus {
  @override
  bool build() => false;

  void focus() {
    state = !state; // 切换状态以触发监听
  }
}

