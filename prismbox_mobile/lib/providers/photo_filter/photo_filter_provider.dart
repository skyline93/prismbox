import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'photo_filter_provider.g.dart';

/// 照片筛选模式枚举
enum PhotoFilterModeEnum {
  /// 仅显示本地媒体资源（包括已上传和未上传的）
  all,

  /// 仅显示已上传的本地媒体资源（isUploaded == true）
  backedUp,

  /// 仅显示未上传的本地媒体资源（isUploaded == false）
  notBackedUp,

  /// 仅显示远程服务端的媒体资源
  remoteOnly,
}

/// 照片筛选模式 Provider
///
/// 管理照片页面的筛选状态（全部/已备份/未备份/仅云端）
@riverpod
class PhotoFilterMode extends _$PhotoFilterMode {
  @override
  PhotoFilterModeEnum build() => PhotoFilterModeEnum.all; // 默认显示全部

  /// 设置筛选模式
  void setMode(PhotoFilterModeEnum mode) {
    state = mode;
  }

  /// 切换到下一个模式（循环：全部 -> 已备份 -> 未备份 -> 仅云端 -> 全部）
  void cycle() {
    switch (state) {
      case PhotoFilterModeEnum.all:
        state = PhotoFilterModeEnum.backedUp;
        break;
      case PhotoFilterModeEnum.backedUp:
        state = PhotoFilterModeEnum.notBackedUp;
        break;
      case PhotoFilterModeEnum.notBackedUp:
        state = PhotoFilterModeEnum.remoteOnly;
        break;
      case PhotoFilterModeEnum.remoteOnly:
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
      case PhotoFilterModeEnum.remoteOnly:
        return '仅云端';
    }
  }
}
