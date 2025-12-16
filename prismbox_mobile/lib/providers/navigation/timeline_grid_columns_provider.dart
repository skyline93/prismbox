import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'timeline_grid_columns_provider.g.dart';

/// 时间线网格列数 Provider
/// 支持 2、3、4、5、6、7、8 列，默认 4 列
@riverpod
class TimelineGridColumns extends _$TimelineGridColumns {
  @override
  int build() => 4; // 默认 4 列

  /// 设置列数（限制在 2-8 之间）
  void setColumns(int columns) {
    if (columns >= 2 && columns <= 8) {
      state = columns;
    }
  }

  /// 增加列数
  void increase() {
    if (state < 8) {
      state = state + 1;
    }
  }

  /// 减少列数
  void decrease() {
    if (state > 2) {
      state = state - 1;
    }
  }

  /// 循环切换列数（2->3->4->5->6->7->8->2...）
  void cycle() {
    state = (state % 8) + 1;
    if (state < 2) state = 2;
    if (state > 8) state = 8;
  }
}
