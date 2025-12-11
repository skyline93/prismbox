// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_sync_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$localSyncServiceHash() => r'ad80875e6c40a7dadf8e2b01331f69e036d12ba3';

/// LocalSyncService Provider
///
/// Copied from [localSyncService].
@ProviderFor(localSyncService)
final localSyncServiceProvider =
    AutoDisposeFutureProvider<LocalSyncService>.internal(
  localSyncService,
  name: r'localSyncServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$localSyncServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef LocalSyncServiceRef = AutoDisposeFutureProviderRef<LocalSyncService>;
String _$dataSourceSelectorHash() =>
    r'0900a0237afa77696dbc7f63cdd5665b647d106d';

/// DataSourceSelector Provider
///
/// Copied from [dataSourceSelector].
@ProviderFor(dataSourceSelector)
final dataSourceSelectorProvider =
    AutoDisposeFutureProvider<DataSourceSelector>.internal(
  dataSourceSelector,
  name: r'dataSourceSelectorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dataSourceSelectorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DataSourceSelectorRef
    = AutoDisposeFutureProviderRef<DataSourceSelector>;
String _$timelineProviderServiceHash() =>
    r'9d955c2c6465db7bdbf94c9c3bc6b5e3b6b70002';

/// TimelineProviderService Provider
///
/// Copied from [timelineProviderService].
@ProviderFor(timelineProviderService)
final timelineProviderServiceProvider =
    AutoDisposeFutureProvider<TimelineProviderService>.internal(
  timelineProviderService,
  name: r'timelineProviderServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$timelineProviderServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TimelineProviderServiceRef
    = AutoDisposeFutureProviderRef<TimelineProviderService>;
String _$syncCoordinatorHash() => r'4ade885654e27bea051c9756debaca52a6338da3';

/// SyncCoordinator Provider
///
/// 使用 keepAlive: true 确保全局单例
///
/// Copied from [syncCoordinator].
@ProviderFor(syncCoordinator)
final syncCoordinatorProvider = FutureProvider<SyncCoordinator>.internal(
  syncCoordinator,
  name: r'syncCoordinatorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$syncCoordinatorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SyncCoordinatorRef = FutureProviderRef<SyncCoordinator>;
String _$assetEntityLoaderHash() => r'8ea3efab8aaa98ea240a5e7fe2af244352ad0d76';

/// AssetEntityLoader Provider
///
/// 提供 AssetEntity 的延迟获取和缓存功能
/// 单例模式，在整个应用生命周期中共享缓存
///
/// Copied from [assetEntityLoader].
@ProviderFor(assetEntityLoader)
final assetEntityLoaderProvider =
    AutoDisposeFutureProvider<AssetEntityLoader>.internal(
  assetEntityLoader,
  name: r'assetEntityLoaderProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$assetEntityLoaderHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AssetEntityLoaderRef = AutoDisposeFutureProviderRef<AssetEntityLoader>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
