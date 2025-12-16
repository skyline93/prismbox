import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'photo_filter_provider.g.dart';

/// 照片筛选模式枚举
enum PhotoFilterModeEnum {
  /// 显示全部照片
  all,

  /// 仅显示已备份的照片
  backedUp,

  /// 仅显示未备份的照片
  notBackedUp,
}

/// 照片筛选模式 Provider
///
/// 管理照片页面的筛选状态（全部/已备份/未备份）
@riverpod
class PhotoFilterMode extends _$PhotoFilterMode {
  @override
  PhotoFilterModeEnum build() => PhotoFilterModeEnum.all; // 默认显示全部

  /// 设置筛选模式
  void setMode(PhotoFilterModeEnum mode) {
    state = mode;
  }

  /// 切换到下一个模式（循环：全部 -> 已备份 -> 未备份 -> 全部）
  void cycle() {
    switch (state) {
      case PhotoFilterModeEnum.all:
        state = PhotoFilterModeEnum.backedUp;
        break;
      case PhotoFilterModeEnum.backedUp:
        state = PhotoFilterModeEnum.notBackedUp;
        break;
      case PhotoFilterModeEnum.notBackedUp:
        state = PhotoFilterModeEnum.all;
        break;
    }
  }

  /// 获取当前模式的显示文本
  String get displayText {
    switch (state) {
      case PhotoFilterModeEnum.all:
        return '全部';
      case PhotoFilterModeEnum.backedUp:
        return '已备份';
      case PhotoFilterModeEnum.notBackedUp:
        return '未备份';
    }
  }
}
