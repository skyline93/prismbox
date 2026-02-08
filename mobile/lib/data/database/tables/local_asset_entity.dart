// lib/data/database/tables/local_asset_entity.dart

import 'package:drift/drift.dart';
import 'package:prismbox/data/database/tables/mixins/asset_entity_mixin.dart';
import 'package:prismbox/data/database/tables/mixins/drift_defaults_mixin.dart';
import 'package:prismbox/data/database/enums/migration_status.dart';

/// 本地资产实体表
/// 存储设备上的原始媒体文件信息
@DataClassName('LocalAssetEntityData')
class LocalAssetEntity extends Table with DriftDefaultsMixin, AssetEntityMixin {
  const LocalAssetEntity();

  /// 主键（设备资产 ID）
  TextColumn get id => text()();

  /// 是否已上传（标识资产是否已成功上传到服务器）
  BoolColumn get isUploaded => boolean().withDefault(const Constant(false))();

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
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  /// 图片方向（0-8，EXIF 方向值）
  IntColumn get orientation => integer().withDefault(const Constant(0))();

  /// 是否在私有空间
  /// 标识文件是否已迁移到应用私有目录
  BoolColumn get isInPrivateSpace => boolean()
      .withDefault(const Constant(false))();

  /// 迁移状态枚举
  /// 用于跟踪迁移到私有空间或移回系统相册的操作状态
  IntColumn get migrationStatus => intEnum<MigrationStatus>()
      .withDefault(const Constant(0))(); // MigrationStatus.none = 0

  /// 删除时间（软删除）
  /// 用于标记资源是否已删除，NULL 表示未删除
  DateTimeColumn get deletedAt => dateTime().nullable()();

  /// 原始路径（删除前在系统相册的路径）
  /// 用于恢复时还原文件位置
  TextColumn get originalPath => text().nullable()();

  /// 回收站路径（在应用私有回收站空间的路径）
  /// 用于永久删除时定位文件
  TextColumn get trashPath => text().nullable()();

  /// Live Photo 关联视频 ID（仅图片类型，对应本地视频资产 ID）
  TextColumn get livePhotoVideoId => text().nullable()();

  // ---------- 媒体详细信息（策略一：同步时写入） ----------

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

  /// 快门（EXIF ExposureTime，如 "1/125"）
  TextColumn get exifExposureTime => text().nullable()();

  /// 光圈（EXIF FNumber）
  RealColumn get exifFNumber => real().nullable()();

  /// ISO（EXIF ISOSpeedRatings）
  IntColumn get exifIso => integer().nullable()();

  /// 焦距 mm（EXIF FocalLength）
  RealColumn get exifFocalLength => real().nullable()();

  /// 是否 HDR（EXIF/厂商标签，如 iOS HDR Image Type）
  BoolColumn get isHdr => boolean().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
