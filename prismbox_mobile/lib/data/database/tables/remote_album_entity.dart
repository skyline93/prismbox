// lib/data/database/tables/remote_album_entity.dart

import 'package:drift/drift.dart';
import 'package:prismbox/data/database/tables/mixins/drift_defaults_mixin.dart';
import 'package:prismbox/data/database/tables/user_entity.dart';
import 'package:prismbox/data/database/tables/remote_asset_entity.dart';
import 'package:prismbox/data/database/enums/album_order.dart';

/// 远程相册实体表
/// 存储服务器端的相册信息
@DataClassName('RemoteAlbumEntityData')
class RemoteAlbumEntity extends Table with DriftDefaultsMixin {
  const RemoteAlbumEntity();

  /// 主键
  TextColumn get id => text()();
  
  /// 相册名称
  TextColumn get name => text()();
  
  /// 相册描述
  TextColumn get description => text().nullable()();
  
  /// 创建时间
  DateTimeColumn get createdAt => dateTime()();
  
  /// 更新时间
  DateTimeColumn get updatedAt => dateTime()();
  
  /// 所有者用户 ID
  TextColumn get ownerId => text()
      .references(UserEntity, #id, onDelete: KeyAction.cascade)();
  
  /// 缩略图资产 ID
  TextColumn get thumbnailAssetId => text()
      .nullable()
      .references(RemoteAssetEntity, #id, onDelete: KeyAction.setNull)();
  
  /// 是否启用活动功能
  BoolColumn get isActivityEnabled => boolean()
      .withDefault(const Constant(false))();
  
  /// 排序方式枚举
  IntColumn get order => intEnum<AlbumOrder>()
      .withDefault(const Constant(1))(); // AlbumOrder.createdAtDesc = 1

  @override
  Set<Column> get primaryKey => {id};
}

