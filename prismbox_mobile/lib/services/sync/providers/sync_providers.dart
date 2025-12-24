// lib/services/sync/providers/sync_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:prismbox/services/sync/asset_sync_service.dart';
import 'package:prismbox/services/sync/background_sync_manager.dart';
import 'package:prismbox/features/local_sync/providers/local_sync_providers.dart';
import 'package:prismbox/providers/infrastructure/database_provider.dart' as infra;
import 'package:prismbox/providers/infrastructure/api_service_provider.dart' as infra;

part 'sync_providers.g.dart';

/// AssetSyncService Provider（独立模块）
@riverpod
Future<AssetSyncService> assetSyncService(AssetSyncServiceRef ref) async {
  final database = await ref.watch(infra.databaseProvider.future);
  final apiService = ref.watch(infra.apiServiceProvider);
  return AssetSyncService(
    database: database,
    apiService: apiService,
  );
}

/// BackgroundSyncManager Provider（独立模块）
@riverpod
Future<BackgroundSyncManager> backgroundSyncManager(
  BackgroundSyncManagerRef ref,
) async {
  final database = await ref.watch(infra.databaseProvider.future);
  final localSyncService = await ref.watch(localSyncServiceProvider.future);
  final apiService = ref.watch(infra.apiServiceProvider);
  return BackgroundSyncManager(
    database: database,
    localSyncService: localSyncService,
    apiService: apiService,
    // 不再需要 AssetPathResolver，因为未使用
  );
}

