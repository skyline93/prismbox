// lib/data/database/tables/album_session_entity.dart

import 'package:drift/drift.dart';
import 'package:prismbox/data/database/tables/mixins/drift_defaults_mixin.dart';
import 'package:prismbox/data/database/tables/remote_album_entity.dart';

/// 相册会话令牌表
/// 存储加密相册的会话令牌，用于访问控制
@DataClassName('AlbumSessionEntityData')
class AlbumSessionEntity extends Table with DriftDefaultsMixin {
  const AlbumSessionEntity();

  /// 主键
  TextColumn get id => text()();

  /// 相册 ID
  TextColumn get albumId => text()
      .references(RemoteAlbumEntity, #id, onDelete: KeyAction.cascade)();

  /// 会话令牌（加密存储）
  TextColumn get sessionToken => text()();

  /// 过期时间
  DateTimeColumn get expiresAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

