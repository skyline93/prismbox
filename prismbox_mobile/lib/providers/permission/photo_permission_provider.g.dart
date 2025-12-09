// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_permission_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$photoPermissionNotifierHash() =>
    r'647dc0fa7f9088d398b53ef2a8c6a3744535792b';

/// 权限状态管理器
///
/// Copied from [PhotoPermissionNotifier].
@ProviderFor(PhotoPermissionNotifier)
final photoPermissionNotifierProvider = AutoDisposeAsyncNotifierProvider<
    PhotoPermissionNotifier, PhotoPermissionState>.internal(
  PhotoPermissionNotifier.new,
  name: r'photoPermissionNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$photoPermissionNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PhotoPermissionNotifier
    = AutoDisposeAsyncNotifier<PhotoPermissionState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
