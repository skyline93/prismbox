// lib/data/database/tables/album_asset_entity.dart

import 'package:drift/drift.dart';
import 'package:prismbox/data/database/tables/remote_asset_entity.dart';
import 'package:prismbox/data/database/tables/remote_album_entity.dart';

/// 相册-资产关联表
/// 存储相册与资产的多对多关联关系
@DataClassName('AlbumAssetEntityData')
class AlbumAssetEntity extends Table {
  const AlbumAssetEntity();

  /// 资产 ID
  TextColumn get assetId => text()
      .references(RemoteAssetEntity, #id, onDelete: KeyAction.cascade)();
  
  /// 相册 ID
  TextColumn get albumId => text()
      .references(RemoteAlbumEntity, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {assetId, albumId};
}

