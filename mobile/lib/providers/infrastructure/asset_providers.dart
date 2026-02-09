// lib/providers/infrastructure/asset_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:prismbox/data/database/daos/local_asset_dao.dart';
import 'package:prismbox/data/database/daos/remote_asset_dao.dart';
import 'package:prismbox/infrastructure/asset/asset_path_resolver.dart';
import 'package:prismbox/providers/infrastructure/database_provider.dart';
import 'package:prismbox/services/asset/asset_favorite_service.dart';
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

/// AssetFavoriteService Provider
@riverpod
Future<AssetFavoriteService> assetFavoriteService(
    AssetFavoriteServiceRef ref) async {
  final database = await ref.watch(databaseProvider.future);
  final localAssetDao = LocalAssetDao(database);
  return AssetFavoriteService(
    localAssetDao: localAssetDao,
  );
}

/// 按 assetId 从本地媒体表读取收藏状态，供缩略图等单独监听
/// 收藏/取消收藏成功后 invalidate 本 provider(assetId)，即可驱动所有显示该资产的收藏图标更新
@riverpod
Future<bool> assetFavoriteStatus(AssetFavoriteStatusRef ref, String assetId) async {
  final database = await ref.watch(databaseProvider.future);
  final dao = LocalAssetDao(database);
  final asset = await dao.getAssetById(assetId);
  return asset?.isFavorite ?? false;
}
