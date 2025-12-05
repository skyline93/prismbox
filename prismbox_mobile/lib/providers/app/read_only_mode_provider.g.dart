// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'read_only_mode_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$readOnlyModeHash() => r'ec4ba44b5b1a0eba17459edbecf3d63bbc5c6264';

/// 只读模式 Provider
/// 控制应用是否处于只读模式（禁用部分功能）
///
/// Copied from [ReadOnlyMode].
@ProviderFor(ReadOnlyMode)
final readOnlyModeProvider =
    AutoDisposeNotifierProvider<ReadOnlyMode, bool>.internal(
  ReadOnlyMode.new,
  name: r'readOnlyModeProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$readOnlyModeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ReadOnlyMode = AutoDisposeNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
