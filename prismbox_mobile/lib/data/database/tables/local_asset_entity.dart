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
  
  /// 文件路径（本地文件系统的完整路径）
  /// 
  /// **用途**：
  /// - 用于读取文件内容（图片/视频显示）
  /// - 用于上传任务（备份模块需要文件路径）
  /// - 用于文件存在性检查
  /// 
  /// **注意**：此字段为必填，因为本地资产必须知道文件的实际位置
  /// 才能进行读取、上传等操作。虽然可以通过 photo_manager 的 AssetEntity
  /// 通过 ID 获取文件，但存储路径可以避免每次查询，提升性能。
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

