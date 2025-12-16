// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_filter_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$photoFilterModeHash() => r'e6275c537f5bb938a8ea221974929a72e2eb2b5a';

/// 照片筛选模式 Provider
///
/// 管理照片页面的筛选状态（全部/已备份/未备份）
///
/// Copied from [PhotoFilterMode].
@ProviderFor(PhotoFilterMode)
final photoFilterModeProvider =
    AutoDisposeNotifierProvider<PhotoFilterMode, PhotoFilterModeEnum>.internal(
  PhotoFilterMode.new,
  name: r'photoFilterModeProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$photoFilterModeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PhotoFilterMode = AutoDisposeNotifier<PhotoFilterModeEnum>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
