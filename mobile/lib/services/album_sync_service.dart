// lib/services/album_sync_service.dart


import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:mobile/data/datasources/local_db/enums.dart';
// 确保这里的导入路径正确
import 'package:mobile/services/background_tasks/local_media_reconciliation.dart'; 


@lazySingleton
class AlbumSyncService {
  final AppDatabase _db;
  final AlbumDao _albumDao;
  final _log = Logger('AlbumSyncService');

  AlbumSyncService(this._db) : _albumDao = _db.albumDao;

  /// [便利方法] 同步所有来源（本地和远程）的相册。
  /// 这是一个高阶操作，适用于需要进行全面刷新的场景。
  Future<void> synchronizeAllSources({required List<AlbumData> localAlbums}) async {
    _log.info('Starting full album synchronization for all sources.');
    try {
      // 1. 同步本地相册 (数据由参数传入)
      await synchronizeLocalAlbums(localAlbums);

      // 2. 同步云端相册
      await synchronizeRemoteAlbums();
      _log.info('Full album synchronization completed successfully.');
    } catch (e, st) {
      _log.severe('Full album synchronization failed.', e, st);
    }
  }

  /// [核心方法] 使用从后台任务获取的最新列表来同步本地相册。
  /// 此操作在一个数据库事务中完成，以确保数据一致性。
  /// 
  /// [localAlbums] 是从设备扫描得到的最新相册列表。
  Future<void> synchronizeLocalAlbums(List<AlbumData> localAlbums) async {
    _log.info('Syncing ${localAlbums.length} local albums to the database.');
    
    try {
      // 使用事务来确保操作的原子性：要么全部成功，要么全部失败。
      // 这可以防止在清空旧数据后，插入新数据前发生错误导致数据丢失。
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
                // 封面ID的更新逻辑可以保持独立，此处不处理
                thumbnailId: const Value.absent(), 
              ),
            )
            .toList();

        // 3. 批量插入或更新新的相册记录
        await _albumDao.upsertAlbums(companions);
      });

      _log.info(
        'Successfully synced ${localAlbums.length} local albums within a transaction.',
      );
    } catch (e, st) {
      _log.severe('Failed to synchronize local albums.', e, st);
      // 向上抛出异常，让调用方知道操作失败
      rethrow;
    }
  }

  /// [核心方法] 从远程服务器获取相册列表并同步到本地数据库。
  /// TODO: 实现从远程 API 获取数据的逻辑。
  Future<void> synchronizeRemoteAlbums() async {
    _log.info('Starting remote album synchronization...');
    
    // 同样建议在事务中执行，保证数据一致性
    try {
      await _db.transaction(() async {
        // 1. 从远程数据源获取相册
        // final remoteAlbums = await _remoteMediaSource.getAlbums();
        // _log.info('Found ${remoteAlbums.length} remote albums.');

        // 2. 清除所有旧的远程相册记录
        // await _albumDao.clearAlbumsBySource(AlbumSource.remote);

        // 3. 将远程相册模型转换为 AlbumsCompanion 并插入数据库
        // final companions = remoteAlbums.map(...).toList();
        // await _albumDao.upsertAlbums(companions);
      });
      _log.info('Remote album sync logic placeholder executed.');
    } catch (e, st) {
      _log.severe('Failed to synchronize remote albums.', e, st);
      rethrow;
    }
  }
}
