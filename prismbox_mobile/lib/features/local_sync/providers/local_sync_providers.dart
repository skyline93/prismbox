// lib/features/local_sync/providers/local_sync_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:prismbox/features/local_sync/services/asset_entity_loader.dart';
import 'package:prismbox/features/local_sync/services/data_source_selector.dart';
import 'package:prismbox/features/local_sync/services/local_sync_service.dart';
import 'package:prismbox/features/local_sync/services/sync_coordinator.dart';
import 'package:prismbox/features/local_sync/services/timeline_provider_service.dart';
import 'package:prismbox/providers/infrastructure/database_provider.dart' as infra;

part 'local_sync_providers.g.dart';

/// LocalSyncService Provider
@riverpod
Future<LocalSyncService> localSyncService(LocalSyncServiceRef ref) async {
  final database = await ref.watch(infra.databaseProvider.future);
  return LocalSyncService(database: database);
}

/// DataSourceSelector Provider
@riverpod
Future<DataSourceSelector> dataSourceSelector(DataSourceSelectorRef ref) async {
  final database = await ref.watch(infra.databaseProvider.future);
  return DataSourceSelector(database: database);
}

/// TimelineProviderService Provider
@riverpod
Future<TimelineProviderService> timelineProviderService(
  TimelineProviderServiceRef ref,
) async {
  final database = await ref.watch(infra.databaseProvider.future);
  final dataSourceSelector = await ref.watch(dataSourceSelectorProvider.future);
  return TimelineProviderService(
    database: database,
    dataSourceSelector: dataSourceSelector,
  );
}

/// SyncCoordinator Provider
/// 
/// 使用 keepAlive: true 确保全局单例
@Riverpod(keepAlive: true)
Future<SyncCoordinator> syncCoordinator(SyncCoordinatorRef ref) async {
  final syncService = await ref.watch(localSyncServiceProvider.future);
  final database = await ref.watch(infra.databaseProvider.future);
  return SyncCoordinator(
    syncService: syncService,
    database: database,
  );
}

/// AssetEntityLoader Provider
/// 
/// 提供 AssetEntity 的延迟获取和缓存功能
/// 单例模式，在整个应用生命周期中共享缓存
@riverpod
Future<AssetEntityLoader> assetEntityLoader(AssetEntityLoaderRef ref) async {
  final timelineService = await ref.watch(timelineProviderServiceProvider.future);
  return AssetEntityLoader(
    timelineProviderService: timelineService,
  );
}

