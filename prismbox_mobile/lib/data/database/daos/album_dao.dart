// lib/data/database/daos/album_dao.dart

import 'package:drift/drift.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/tables/local_album_entity.dart';
import 'package:prismbox/data/database/tables/remote_album_entity.dart';
import 'package:prismbox/data/database/tables/album_asset_entity.dart';
import 'package:prismbox/data/database/tables/remote_asset_entity.dart';

part 'album_dao.g.dart';

/// 相册数据访问对象
/// 提供相册的查询和操作接口
@DriftAccessor(tables: [
  LocalAlbumEntity,
  RemoteAlbumEntity,
  AlbumAssetEntity,
  RemoteAssetEntity,
])
class AlbumDao extends DatabaseAccessor<AppDatabase>
    with _$AlbumDaoMixin {
  AlbumDao(AppDatabase db) : super(db);

  /// 获取所有远程相册
  Future<List<RemoteAlbumEntityData>> getAllRemoteAlbums() {
    return select(remoteAlbumEntity).get();
  }

  /// 根据 ID 获取相册
  Future<RemoteAlbumEntityData?> getAlbumById(String id) {
    return (select(remoteAlbumEntity)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// 获取相册的所有资产
  Future<List<RemoteAssetEntityData>> getAlbumAssets(String albumId) async {
    final albumAssets = await (select(albumAssetEntity)
          ..where((t) => t.albumId.equals(albumId)))
        .get();
    
    if (albumAssets.isEmpty) {
      return [];
    }

    final assetIds = albumAssets.map((a) => a.assetId).toList();
    return (select(remoteAssetEntity)
          ..where((t) => t.id.isIn(assetIds)))
        .get();
  }

  /// 添加资产到相册
  Future<void> addAssetToAlbum(String assetId, String albumId) {
    return into(albumAssetEntity).insert(
      AlbumAssetEntityData(
        assetId: assetId,
        albumId: albumId,
      ),
    );
  }

  /// 从相册移除资产
  Future<bool> removeAssetFromAlbum(String assetId, String albumId) async {
    final count = await (delete(albumAssetEntity)
          ..where((t) => 
              t.assetId.equals(assetId) & 
              t.albumId.equals(albumId)))
        .go();
    return count > 0;
  }

  /// 创建相册
  Future<void> createAlbum(RemoteAlbumEntityData album) {
    return into(remoteAlbumEntity).insert(album);
  }

  /// 更新相册
  Future<bool> updateAlbum(RemoteAlbumEntityData album) {
    return update(remoteAlbumEntity).replace(album);
  }

  /// 删除相册
  Future<bool> deleteAlbum(String id) async {
    final count = await (delete(remoteAlbumEntity)
          ..where((t) => t.id.equals(id)))
        .go();
    return count > 0;
  }

  /// 获取所有本地相册
  Future<List<LocalAlbumEntityData>> getAllLocalAlbums() {
    return select(localAlbumEntity).get();
  }

  /// 根据 ID 获取本地相册
  Future<LocalAlbumEntityData?> getLocalAlbumById(String id) {
    return (select(localAlbumEntity)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// 创建本地相册
  Future<void> createLocalAlbum(LocalAlbumEntityData album) {
    return into(localAlbumEntity).insert(album);
  }

  /// 更新本地相册
  Future<bool> updateLocalAlbum(LocalAlbumEntityData album) {
    return update(localAlbumEntity).replace(album);
  }

  /// 删除本地相册
  Future<bool> deleteLocalAlbum(String id) async {
    final count = await (delete(localAlbumEntity)
          ..where((t) => t.id.equals(id)))
        .go();
    return count > 0;
  }
}

