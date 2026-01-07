// lib/providers/infrastructure/asset_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:prismbox/data/database/daos/local_asset_dao.dart';
import 'package:prismbox/data/database/daos/remote_asset_dao.dart';
import 'package:prismbox/infrastructure/asset/asset_path_resolver.dart';
import 'package:prismbox/providers/infrastructure/database_provider.dart';
import 'package:prismbox/services/asset/asset_service.dart';

part 'asset_providers.g.dart';

/// AssetPathResolver Provider
@riverpod
Future<AssetPathResolver> assetPathResolver(AssetPathResolverRef ref) async {
  final database = await ref.watch(databaseProvider.future);
  return AssetPathResolver(database: database);
}

/// AssetService Provider
@riverpod
Future<AssetService> assetService(AssetServiceRef ref) async {
  final database = await ref.watch(databaseProvider.future);
  final localAssetDao = LocalAssetDao(database);
  final remoteAssetDao = RemoteAssetDao(database);
  return AssetService(
    localAssetDao: localAssetDao,
    remoteAssetDao: remoteAssetDao,
  );
}
