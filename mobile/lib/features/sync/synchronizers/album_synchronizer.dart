// lib/features/sync/synchronizers/album_synchronizer.dart

import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:mobile/core/enums.dart';
import 'package:mobile/features/sync/models/sync_models.dart';

@lazySingleton
class AlbumSynchronizer {
  final AppDatabase _db;
  final AlbumDao _albumDao;
  final _log = Logger('AlbumSynchronizer');

  AlbumSynchronizer(this._db) : _albumDao = _db.albumDao;

  /// 使用从本地对账中获取的最新列表来同步本地相册。
  /// Logic migrated from `AlbumSyncService.synchronizeLocalAlbums`.
  Future<void> synchronizeLocalAlbums(List<AlbumData> localAlbums) async {
    _log.info('Syncing ${localAlbums.length} local albums to the database.');

    try {
      await _db.transaction(() async {
        // 1. 清除所有旧的本地相册记录
        await _albumDao.clearAlbumsBySource(AlbumSource.local);

        if (localAlbums.isEmpty) {
          _log.warning('No local albums found to sync.');
          return;
        }

        // 2. 将新的相册数据转换为数据库实体
        final companions = localAlbums
            .map(
              (album) => AlbumsCompanion.insert(
                id: album.id,
                name: album.name,
                assetCount: album.assetCount,
                source: AlbumSource.local,
                thumbnailId: const Value.absent(),
              ),
            )
            .toList();

        // 3. 批量插入或更新新的相册记录
        await _albumDao.upsertAlbums(companions);
      });
      _log.info('Successfully synced ${localAlbums.length} local albums.');
    } catch (e, st) {
      _log.severe('Failed to synchronize local albums.', e, st);
      rethrow;
    }
  }

  /// 从远程服务器获取相册列表并同步到本地数据库。
  /// Logic migrated from `AlbumSyncService.synchronizeRemoteAlbums`.
  Future<void> synchronizeRemoteAlbums() async {
    _log.info('Starting remote album synchronization...');
    // TODO: 实现从远程 API 获取数据的逻辑
    _log.info('Remote album sync logic placeholder executed.');
  }
}
