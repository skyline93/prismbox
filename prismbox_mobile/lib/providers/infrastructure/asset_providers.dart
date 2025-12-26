// lib/providers/infrastructure/asset_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:prismbox/infrastructure/asset/asset_path_resolver.dart';
import 'package:prismbox/infrastructure/asset/checksum_service.dart';
import 'package:prismbox/providers/infrastructure/database_provider.dart';

part 'asset_providers.g.dart';

/// AssetPathResolver Provider
@riverpod
Future<AssetPathResolver> assetPathResolver(AssetPathResolverRef ref) async {
  final database = await ref.watch(databaseProvider.future);
  return AssetPathResolver(database: database);
}

/// ChecksumService Provider
@riverpod
Future<ChecksumService> checksumService(ChecksumServiceRef ref) async {
  final database = await ref.watch(databaseProvider.future);
  return ChecksumService(database: database);
}

