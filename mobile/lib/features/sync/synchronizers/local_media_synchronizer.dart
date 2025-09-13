// lib/features/sync/synchronizers/local_media_synchronizer.dart

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:mobile/features/sync/models/sync_models.dart';
import 'package:photo_manager/photo_manager.dart';

@lazySingleton
class LocalMediaSynchronizer {
  final MediaAssetDao _mediaAssetDao;
  final _log = Logger('LocalMediaSynchronizer');

  LocalMediaSynchronizer(AppDatabase db) : _mediaAssetDao = db.mediaAssetDao;

  /// 执行全量对账。
  /// 发现本地设备上的所有媒体与数据库中的记录之间的差异。
  /// Logic migrated from `local_media_reconciliation.dart`.
  Future<LocalReconciliationResult> runFullReconciliation() async {
    _log.info('Starting full local media reconciliation...');

    // 1. 从数据库获取所有已知的本地资产ID
    final dbAssetIds = (await _mediaAssetDao.getAllLocalAssetIds()).toSet();
    _log.info('Found ${dbAssetIds.length} assets in the local database.');

    final Set<String> deviceAssetIds = {};
    final List<AlbumData> albumList = [];

    try {
      // 2. 获取设备上的所有相册（路径）
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: RequestType.common,
      );
      _log.info('Found ${paths.length} asset paths (albums) on device.');

      // 3. 分页遍历每个相册，收集所有资产ID
      for (final path in paths) {
        final int count = await path.assetCountAsync;
        albumList.add(
          AlbumData(id: path.id, name: path.name, assetCount: count),
        );

        if (count == 0) continue;

        const int pageSize = 200;
        final int pageCount = (count / pageSize).ceil();

        for (int i = 0; i < pageCount; i++) {
          final List<AssetEntity> assets = await path.getAssetListPaged(
            page: i,
            size: pageSize,
          );
          for (final asset in assets) {
            deviceAssetIds.add(asset.id);
          }
        }
      }

      // 4. 计算差异
      final newIds = deviceAssetIds.difference(dbAssetIds);
      final deletedIds = dbAssetIds.difference(deviceAssetIds);

      _log.info(
        'Reconciliation complete. Total device assets: ${deviceAssetIds.length}. New: ${newIds.length}, Deleted: ${deletedIds.length}.',
      );

      return LocalReconciliationResult(
        newAssetIds: newIds,
        deletedAssetIds: deletedIds,
        localAlbums: albumList,
      );
    } catch (e, s) {
      _log.severe(
        'A critical error occurred during local media reconciliation.',
        e,
        s,
      );
      // 在出错时返回一个空结果，以防止对数据库进行错误的操作
      return LocalReconciliationResult(
        newAssetIds: {},
        deletedAssetIds: {},
        localAlbums: [],
      );
    }
  }
}
