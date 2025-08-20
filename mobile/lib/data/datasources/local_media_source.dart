// lib/data/datasources/local_media_source.dart

import 'dart:async';

import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:mobile/services/sync_job_manager.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class LocalMediaDataSource {
  final MediaAssetDao _mediaAssetDao;
  final SyncJobManager _syncJobManager;

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
}
