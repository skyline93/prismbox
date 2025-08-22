// lib/services/album_sync_service.dart

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:mobile/data/datasources/local_db/enums.dart';
import 'package:mobile/services/local_media_observer.dart';

@lazySingleton
class AlbumSyncService {
  // ignore: unused_field
  final AppDatabase _db;
  final AlbumDao _albumDao;
  final _log = Logger('AlbumSyncService');

  AlbumSyncService(this._db) : _albumDao = _db.albumDao;

  /// [核心方法] 同步所有来源的相册。
  /// 对于本地相册，它现在接收一个已从后台 Isolate 获取的列表。
  Future<void> syncAlbums({required List<AlbumData> localAlbums}) async {
    _log.info('Starting album synchronization process.');
    try {
      // 1. 同步本地相册 (数据由参数传入)
      await _syncLocalAlbums(localAlbums);

      // 2. 同步云端相册 (逻辑保持不变)
      //    可以根据需要决定是否每次都同步云端，或者有独立的触发机制
      await _syncRemoteAlbums();
    } catch (e, st) {
      _log.severe('Album synchronization failed.', e, st);
    }
  }

  /// [内部方法] 处理本地相册的数据库更新
  Future<void> _syncLocalAlbums(List<AlbumData> localAlbums) async {
    _log.info(
      'Syncing ${localAlbums.length} local albums from background reconcile result.',
    );
    await _albumDao.clearAlbumsBySource(AlbumSource.local);

    if (localAlbums.isEmpty) {
      return;
    }

    final companions = localAlbums
        .map(
          (album) => AlbumsCompanion.insert(
            id: album.id,
            name: album.name,
            assetCount: album.assetCount,
            source: AlbumSource.local,
            thumbnailId: const Value.absent(), // 封面ID逻辑依然可以在更高层处理
          ),
        )
        .toList();

    await _albumDao.upsertAlbums(companions);
    _log.info(
      'Successfully synced ${companions.length} local albums to database.',
    );
  }

  /// [内部方法] 处理云端相册的获取和数据库更新
  Future<void> _syncRemoteAlbums() async {
    _log.info('Fetching remote albums...');
    // final remoteAlbums = await _remoteMediaSource.getAlbums();
    // _log.info('Found ${remoteAlbums.length} remote albums.');
    // await _albumDao.clearAlbumsBySource(AlbumSource.remote);
    // ... (此处省略将云端相册转换为 Companion 并写入数据库的逻辑)
    _log.info('Remote album sync logic placeholder.');
  }
}
