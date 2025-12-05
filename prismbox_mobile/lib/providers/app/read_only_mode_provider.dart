import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'read_only_mode_provider.g.dart';

/// 只读模式 Provider
/// 控制应用是否处于只读模式（禁用部分功能）
@riverpod
class ReadOnlyMode extends _$ReadOnlyMode {
  @override
  bool build() => false;

  void setReadOnlyMode(bool value) {
    state = value;
  }
}

