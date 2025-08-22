// lib/data/datasources/local_db/daos/album_dao.dart

part of '../app_database.dart';

@DriftAccessor(tables: [Albums])
class AlbumDao extends DatabaseAccessor<AppDatabase> with _$AlbumDaoMixin {
  AlbumDao(super.db);

  /// 监听所有相册的变化。
  /// 返回一个数据流，这是实现响应式UI的关键。
  Stream<List<Album>> watchAllAlbums() => select(albums).watch();

  /// 批量更新或插入相册。
  /// 这将被同步服务用来将最新的相册数据写入数据库。
  Future<void> upsertAlbums(List<AlbumsCompanion> albumEntries) async {
    await batch((batch) {
      batch.insertAll(albums, albumEntries, mode: InsertMode.replace);
    });
  }

  /// 根据来源清除相册。
  /// 在每次同步前调用，以防止数据冗余。
  Future<void> clearAlbumsBySource(AlbumSource source) async {
    await (delete(
      albums,
    )..where((tbl) => tbl.source.equals(source.index))).go();
  }
}
