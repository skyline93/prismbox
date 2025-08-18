// lib/data/datasources/local_media_source.dart

import 'dart:async';

// import 'package:drift/drift.dart';
import 'package:mobile/data/datasources/app_database.dart';
import 'package:mobile/services/sync_job_manager.dart'; // 依赖注入 SyncJobManager
import 'package:photo_manager/photo_manager.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class LocalMediaDataSource {
  final MediaAssetDao _mediaAssetDao;
  final SyncJobManager _syncJobManager;

  // 构造函数注入 SyncJobManager
  LocalMediaDataSource(AppDatabase db, this._syncJobManager)
    : _mediaAssetDao = db.mediaAssetDao;

  /// [REMOVED] 旧的 `scanAndIndexLocalMedia` 方法已被完全移除。
  /// 其功能被 `LocalMediaObserver` 的实时监听和下面的 `performInitialScan` 取代。

  /// [ADDED] 为应用首次安装或需要全量检查时执行一次性扫描。
  /// 这个方法只负责将本地数据库中不存在的媒体记录下来，
  /// 它 **不会** 自动创建上传任务。上传任务由用户后续操作或设置决定。
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

    // 获取数据库中所有已知的 localId
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
            // 使用 SyncJobManager 统一处理新资产的记录，但不创建上传任务
            await _syncJobManager.createUploadJobForNewAsset(
              asset,
              isAutoBackupEnabled: false, // 关键：首次扫描不触发上传
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
