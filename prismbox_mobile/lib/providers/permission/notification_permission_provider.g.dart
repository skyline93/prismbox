// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_permission_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notificationPermissionNotifierHash() =>
    r'b461a961fa6ccbbb6bf0cbbedd4390f2f745cda7';

/// 通知权限状态管理器
///
/// Copied from [NotificationPermissionNotifier].
@ProviderFor(NotificationPermissionNotifier)
final notificationPermissionNotifierProvider = AutoDisposeAsyncNotifierProvider<
    NotificationPermissionNotifier, PermissionStatus>.internal(
  NotificationPermissionNotifier.new,
  name: r'notificationPermissionNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationPermissionNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$NotificationPermissionNotifier
    = AutoDisposeAsyncNotifier<PermissionStatus>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
