// lib/data/database/tables/local_album_entity.dart

import 'package:drift/drift.dart';
import 'package:prismbox/data/database/tables/mixins/drift_defaults_mixin.dart';
import 'package:prismbox/data/database/tables/remote_album_entity.dart';
import 'package:prismbox/data/database/enums/backup_selection.dart';
import 'package:prismbox/data/database/enums/album_type.dart';

/// 本地相册实体表
/// 存储设备上的相册信息
@DataClassName('LocalAlbumEntityData')
class LocalAlbumEntity extends Table with DriftDefaultsMixin {
  const LocalAlbumEntity();

  /// 主键（设备相册 ID）
  TextColumn get id => text()();
  
  /// 相册名称
  TextColumn get name => text()();
  
  /// 更新时间
  DateTimeColumn get updatedAt => dateTime()();
  
  /// 备份选择枚举（none/selected/excluded）
  IntColumn get backupSelection => intEnum<BackupSelection>()
      .withDefault(const Constant(0))(); // BackupSelection.none = 0
  
  /// 是否为 iOS 共享相册
  BoolColumn get isIosSharedAlbum => boolean()
      .withDefault(const Constant(false))();
  
  /// 关联的远程相册 ID
  TextColumn get linkedRemoteAlbumId => text()
      .nullable()
      .references(RemoteAlbumEntity, #id, onDelete: KeyAction.setNull)();

  /// 是否加密
  BoolColumn get isEncrypted => boolean()
      .withDefault(const Constant(false))();

  /// 相册类型枚举
  IntColumn get albumType => intEnum<AlbumType>()
      .withDefault(const Constant(0))(); // AlbumType.normal = 0

  @override
  Set<Column> get primaryKey => {id};
}

