// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remote_sync_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$checkpointStoreHash() => r'130e2a2e41ae92435e56bcf4c6e7515e22a3c89a';

/// CheckpointStore Provider
///
/// Copied from [checkpointStore].
@ProviderFor(checkpointStore)
final checkpointStoreProvider =
    AutoDisposeFutureProvider<CheckpointStore>.internal(
  checkpointStore,
  name: r'checkpointStoreProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$checkpointStoreHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CheckpointStoreRef = AutoDisposeFutureProviderRef<CheckpointStore>;
String _$remoteSyncServiceHash() => r'104436913aa43702d3d85b195d1be8752c0e34fb';

/// RemoteSyncService Provider
///
/// Copied from [remoteSyncService].
@ProviderFor(remoteSyncService)
final remoteSyncServiceProvider =
    AutoDisposeFutureProvider<RemoteSyncService>.internal(
  remoteSyncService,
  name: r'remoteSyncServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$remoteSyncServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef RemoteSyncServiceRef = AutoDisposeFutureProviderRef<RemoteSyncService>;
String _$remoteSyncCoordinatorHash() =>
    r'a682e857f14d04a16dc9ae6a34319ab1308e04fd';

/// RemoteSyncCoordinator Provider
///
/// 使用 keepAlive: true 确保全局单例
///
/// Copied from [remoteSyncCoordinator].
@ProviderFor(remoteSyncCoordinator)
final remoteSyncCoordinatorProvider =
    FutureProvider<RemoteSyncCoordinator>.internal(
  remoteSyncCoordinator,
  name: r'remoteSyncCoordinatorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$remoteSyncCoordinatorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef RemoteSyncCoordinatorRef = FutureProviderRef<RemoteSyncCoordinator>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
