// lib/features/remote_sync/providers/remote_sync_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:prismbox/features/remote_sync/services/checkpoint_store.dart';
import 'package:prismbox/features/remote_sync/services/remote_sync_coordinator.dart';
import 'package:prismbox/features/remote_sync/services/remote_sync_service.dart';
import 'package:prismbox/infrastructure/api/api_service.dart';
import 'package:prismbox/providers/infrastructure/database_provider.dart' as infra;

part 'remote_sync_providers.g.dart';

/// CheckpointStore Provider
@riverpod
Future<CheckpointStore> checkpointStore(CheckpointStoreRef ref) async {
  final database = await ref.watch(infra.databaseProvider.future);
  return CheckpointStore(database);
}

/// RemoteSyncService Provider
@riverpod
Future<RemoteSyncService> remoteSyncService(RemoteSyncServiceRef ref) async {
  final apiService = ApiService();
  final database = await ref.watch(infra.databaseProvider.future);
  final checkpointStore = await ref.watch(checkpointStoreProvider.future);
  return RemoteSyncService(
    apiService: apiService,
    database: database,
    checkpointStore: checkpointStore,
  );
}

/// RemoteSyncCoordinator Provider
/// 
/// 使用 keepAlive: true 确保全局单例
@Riverpod(keepAlive: true)
Future<RemoteSyncCoordinator> remoteSyncCoordinator(
  RemoteSyncCoordinatorRef ref,
) async {
  final syncService = await ref.watch(remoteSyncServiceProvider.future);
  final database = await ref.watch(infra.databaseProvider.future);
  final checkpointStore = await ref.watch(checkpointStoreProvider.future);
  return RemoteSyncCoordinator(
    syncService: syncService,
    database: database,
    checkpointStore: checkpointStore,
  );
}

