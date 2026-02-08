// lib/data/database/tables/remote_asset_entity.dart

import 'package:drift/drift.dart';
import 'package:prismbox/data/database/tables/mixins/asset_entity_mixin.dart';
import 'package:prismbox/data/database/tables/mixins/drift_defaults_mixin.dart';
import 'package:prismbox/data/database/tables/user_entity.dart';
import 'package:prismbox/data/database/enums/asset_visibility.dart';

/// 远程资产实体表
/// 存储从服务器同步的资产信息
@DataClassName('RemoteAssetEntityData')
@TableIndex(name: 'idx_remote_asset_owner_checksum', columns: {#ownerId, #checksum})
@TableIndex(name: 'idx_remote_asset_checksum', columns: {#checksum})
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
  IntColumn get visibility => intEnum<AssetVisibility>()
      .withDefault(const Constant(1))(); // AssetVisibility.private = 1
  
  /// 堆叠 ID
  TextColumn get stackId => text().nullable()();
  
  /// 库 ID（支持多库）
  TextColumn get libraryId => text().nullable()();

  // ---------- 媒体详情（与本地资产一致，同步时写入） ----------
  /// 文件大小（字节）
  IntColumn get fileSize => integer().nullable()();
  /// 拍摄纬度
  RealColumn get latitude => real().nullable()();
  /// 拍摄经度
  RealColumn get longitude => real().nullable()();
  /// 设备品牌（EXIF Make）
  TextColumn get deviceMake => text().nullable()();
  /// 设备型号（EXIF Model）
  TextColumn get deviceModel => text().nullable()();
  /// 快门（EXIF ExposureTime）
  TextColumn get exifExposureTime => text().nullable()();
  /// 光圈（EXIF FNumber）
  RealColumn get exifFNumber => real().nullable()();
  /// ISO（EXIF ISOSpeedRatings）
  IntColumn get exifIso => integer().nullable()();
  /// 焦距 mm（EXIF FocalLength）
  RealColumn get exifFocalLength => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

