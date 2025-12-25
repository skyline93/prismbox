// lib/services/sync/providers/sync_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:prismbox/services/sync/asset_sync_service.dart';
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
