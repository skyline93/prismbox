// lib/data/datasources/local_media_source.dart

import 'dart:async';
import 'dart:typed_data';

import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';

@lazySingleton
class LocalMediaDataSource {
  final _log = Logger('LocalMediaDataSource');

  LocalMediaDataSource(AppDatabase db);

  Future<List<AssetEntity>> getMediaFromAlbum(String albumId) async {
    try {
      final AssetPathEntity album = await AssetPathEntity.fromId(albumId);

      final List<AssetEntity> assets = [];
      final int totalCount = await album.assetCountAsync;
      const int pageSize = 200;
      final int pageCount = (totalCount / pageSize).ceil();

      for (int i = 0; i < pageCount; i++) {
        final List<AssetEntity> pagedAssets = await album.getAssetListPaged(
          page: i,
          size: pageSize,
        );
        assets.addAll(pagedAssets);
      }
      _log.info(
        'Successfully fetched ${assets.length} assets from album: ${album.name} ($albumId)',
      );
      return assets;
    } catch (e, st) {
      _log.severe('Failed to get media from album $albumId.', e, st);
      return [];
    }
  }

  Future<Uint8List?> getThumbnail({
    required String assetId,
    int width = 200,
    int height = 200,
  }) async {
    final asset = await AssetEntity.fromId(assetId);
    if (asset == null) return null;
    final data = await asset.thumbnailDataWithSize(
      ThumbnailSize(width, height),
    );
    return data;
  }

  Future<AssetEntity?> getLatestAssetFromAlbum(String albumId) async {
    try {
      final AssetPathEntity album = await AssetPathEntity.fromId(albumId);
      final List<AssetEntity> assets = await album.getAssetListRange(
        start: 0,
        end: 1,
      );
      if (assets.isNotEmpty) {
        return assets.first;
      }
      return null;
    } catch (e) {
      print('Error getting latest asset from album $albumId: $e');
      return null;
    }
  }
}
