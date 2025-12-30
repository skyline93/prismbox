// lib/data/database/tables/local_album_asset_entity.dart

import 'package:drift/drift.dart';
import 'package:prismbox/data/database/tables/local_asset_entity.dart';
import 'package:prismbox/data/database/tables/local_album_entity.dart';
import 'package:prismbox/data/database/tables/mixins/drift_defaults_mixin.dart';

/// 本地相册-资产关联表
/// 存储本地相册与本地资产的多对多关联关系
@DataClassName('LocalAlbumAssetEntityData')
class LocalAlbumAssetEntity extends Table with DriftDefaultsMixin {
  const LocalAlbumAssetEntity();

  /// 资产 ID（本地资产 ID）
  TextColumn get assetId => text()
      .references(LocalAssetEntity, #id, onDelete: KeyAction.cascade)();
  
  /// 相册 ID（本地相册 ID）
  TextColumn get albumId => text()
      .references(LocalAlbumEntity, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {assetId, albumId};
}

