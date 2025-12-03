// lib/data/database/tables/remote_asset_entity.dart

import 'package:drift/drift.dart';
import 'package:prismbox/data/database/tables/mixins/asset_entity_mixin.dart';
import 'package:prismbox/data/database/tables/mixins/drift_defaults_mixin.dart';
import 'package:prismbox/data/database/tables/user_entity.dart';
import 'package:prismbox/data/database/enums/asset_visibility.dart';

/// 远程资产实体表
/// 存储从服务器同步的资产信息
@DataClassName('RemoteAssetEntityData')
@TableIndex.sql(
  'CREATE INDEX IF NOT EXISTS idx_remote_asset_owner_checksum '
  'ON remote_asset_entity (owner_id, checksum)',
)
@TableIndex.sql('''
CREATE UNIQUE INDEX IF NOT EXISTS UQ_remote_assets_owner_checksum
ON remote_asset_entity (owner_id, checksum)
WHERE (library_id IS NULL);
''')
@TableIndex.sql('''
CREATE UNIQUE INDEX IF NOT EXISTS UQ_remote_assets_owner_library_checksum
ON remote_asset_entity (owner_id, library_id, checksum)
WHERE (library_id IS NOT NULL);
''')
@TableIndex.sql(
  'CREATE INDEX IF NOT EXISTS idx_remote_asset_checksum '
  'ON remote_asset_entity (checksum)',
)
class RemoteAssetEntity extends Table 
    with DriftDefaultsMixin, AssetEntityMixin {
  const RemoteAssetEntity();

  /// 主键（服务器端资产 ID）
  TextColumn get id => text()();
  
  /// 文件哈希（必填，用于去重和关联）
  TextColumn get checksum => text()();
  
  /// 是否收藏
  BoolColumn get isFavorite => boolean()
      .withDefault(const Constant(false))();
  
  /// 所有者用户 ID
  TextColumn get ownerId => text()
      .references(UserEntity, #id, onDelete: KeyAction.cascade)();
  
  /// 本地拍摄时间
  DateTimeColumn get localDateTime => dateTime().nullable()();
  
  /// 缩略图哈希
  TextColumn get thumbHash => text().nullable()();
  
  /// 删除时间（软删除）
  DateTimeColumn get deletedAt => dateTime().nullable()();
  
  /// Live Photo 视频 ID
  TextColumn get livePhotoVideoId => text().nullable()();
  
  /// 可见性枚举
  IntColumn get visibility => integer()
      .map(intEnum<AssetVisibility>())
      .withDefault(const Constant(AssetVisibility.private))();
  
  /// 堆叠 ID
  TextColumn get stackId => text().nullable()();
  
  /// 库 ID（支持多库）
  TextColumn get libraryId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

