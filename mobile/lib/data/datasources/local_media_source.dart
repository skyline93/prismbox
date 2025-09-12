// lib/data/datasources/local_media_source.dart

import 'dart:async';
import 'dart:typed_data';

import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:mobile/services/sync_job_manager.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';

@lazySingleton
class LocalMediaDataSource {
  final MediaAssetDao _mediaAssetDao;
  final SyncJobManager _syncJobManager;
  final _log = Logger('LocalMediaDataSource');

  LocalMediaDataSource(AppDatabase db, this._syncJobManager)
    : _mediaAssetDao = db.mediaAssetDao;

  Future<void> performInitialScan() async {
    final ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth) {
      print("[InitialScan] 权限被拒绝，无法执行首次扫描。");
      return;
    }

    print("[InitialScan] 开始执行首次本地媒体扫描...");

    final List<AssetPathEntity> assetPaths =
        await PhotoManager.getAssetPathList(type: RequestType.common);
    if (assetPaths.isEmpty) {
      print("[InitialScan] 未发现任何相册。");
      return;
    }

    final query = _mediaAssetDao.selectOnly(_mediaAssetDao.mediaAssets)
      ..addColumns([_mediaAssetDao.mediaAssets.localId])
      ..where(_mediaAssetDao.mediaAssets.localId.isNotNull());
    final existingLocalIds =
        (await query
                .map((row) => row.read(_mediaAssetDao.mediaAssets.localId)!)
                .get())
            .toSet();
    print("[InitialScan] 数据库中已存在 ${existingLocalIds.length} 个本地媒体记录。");

    int newAssetsFound = 0;
    for (final path in assetPaths) {
      final int totalCount = await path.assetCountAsync;
      const int pageSize = 100;
      for (int i = 0; i < totalCount; i += pageSize) {
        final List<AssetEntity> assets = await path.getAssetListPaged(
          page: i ~/ pageSize,
          size: pageSize,
        );
        for (final asset in assets) {
          if (!existingLocalIds.contains(asset.id)) {
            await _syncJobManager.createUploadJobForNewAsset(
              asset,
              isAutoBackupEnabled: false,
            );
            newAssetsFound++;
          }
        }
        print(
          "[InitialScan] 已处理 ${i + assets.length} / $totalCount in ${path.name}...",
        );
      }
    }
    print("[InitialScan] 首次扫描完成，发现了 $newAssetsFound 个新媒体文件。");
  }

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
