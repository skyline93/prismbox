// lib/data/database/tables/local_asset_entity.dart

import 'package:drift/drift.dart';
import 'package:prismbox/data/database/tables/mixins/asset_entity_mixin.dart';
import 'package:prismbox/data/database/tables/mixins/drift_defaults_mixin.dart';

/// 本地资产实体表
/// 存储设备上的原始媒体文件信息
@DataClassName('LocalAssetEntityData')
@TableIndex.sql(
  'CREATE INDEX IF NOT EXISTS idx_local_asset_checksum '
  'ON local_asset_entity (checksum)',
)
class LocalAssetEntity extends Table 
    with DriftDefaultsMixin, AssetEntityMixin {
  const LocalAssetEntity();

  /// 主键（设备资产 ID）
  TextColumn get id => text()();
  
  /// 文件哈希（用于与远程资产关联）
  TextColumn get checksum => text().nullable()();
  
  /// 文件路径
  TextColumn get path => text()();
  
  /// 是否收藏（用于备份时同步服务器状态）
  BoolColumn get isFavorite => boolean()
      .withDefault(const Constant(false))();
  
  /// 图片方向（0-8，EXIF 方向值）
  IntColumn get orientation => integer()
      .withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

