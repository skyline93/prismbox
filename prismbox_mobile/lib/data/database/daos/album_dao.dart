// lib/data/database/daos/album_dao.dart

import 'package:drift/drift.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/tables/local_album_entity.dart';
import 'package:prismbox/data/database/tables/remote_album_entity.dart';
import 'package:prismbox/data/database/tables/album_asset_entity.dart';
import 'package:prismbox/data/database/tables/local_album_asset_entity.dart';
import 'package:prismbox/data/database/tables/remote_asset_entity.dart';
import 'package:prismbox/data/database/tables/local_asset_entity.dart';
import 'package:prismbox/data/database/enums/album_type.dart';
import 'package:prismbox/data/database/enums/backup_selection.dart';

part 'album_dao.g.dart';

/// 相册数据访问对象
/// 提供相册的查询和操作接口
@DriftAccessor(tables: [
  LocalAlbumEntity,
  RemoteAlbumEntity,
  AlbumAssetEntity,
  LocalAlbumAssetEntity,
  RemoteAssetEntity,
  LocalAssetEntity,
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

  /// 添加本地资产到本地相册
  Future<void> addLocalAssetToAlbum(String assetId, String albumId) {
    return into(localAlbumAssetEntity).insert(
      LocalAlbumAssetEntityData(
        assetId: assetId,
        albumId: albumId,
      ),
    );
  }

  /// 从本地相册移除本地资产
  Future<bool> removeLocalAssetFromAlbum(String assetId, String albumId) async {
    final count = await (delete(localAlbumAssetEntity)
          ..where((t) => 
              t.assetId.equals(assetId) & 
              t.albumId.equals(albumId)))
        .go();
    return count > 0;
  }

  /// 获取本地相册的所有资产
  Future<List<LocalAssetEntityData>> getLocalAlbumAssets(String albumId) async {
    final albumAssets = await (select(localAlbumAssetEntity)
          ..where((t) => t.albumId.equals(albumId)))
        .get();
    
    if (albumAssets.isEmpty) {
      return [];
    }

    final assetIds = albumAssets.map((a) => a.assetId).toList();
    return (select(localAssetEntity)
          ..where((t) => t.id.isIn(assetIds)))
        .get();
  }

  /// 获取或创建本地加密空间相册
  /// 返回本地相册ID
  Future<String> getOrCreateLocalEncryptedSpaceAlbum() async {
    // 查找是否已存在本地加密空间相册
    final existingAlbum = await (select(localAlbumEntity)
          ..where((t) => 
              t.albumType.equalsValue(AlbumType.encryptedSpace) &
              t.isEncrypted.equals(true)))
        .getSingleOrNull();

    if (existingAlbum != null) {
      return existingAlbum.id;
    }

    // 创建新的本地加密空间相册
    final albumId = 'local_encrypted_space_${DateTime.now().millisecondsSinceEpoch}';
    final album = LocalAlbumEntityData(
      id: albumId,
      name: '加密空间',
      updatedAt: DateTime.now(),
      backupSelection: BackupSelection.none,
      isIosSharedAlbum: false,
      linkedRemoteAlbumId: null,
      isEncrypted: true,
      albumType: AlbumType.encryptedSpace,
    );

    await createLocalAlbum(album);
    return albumId;
  }
}

