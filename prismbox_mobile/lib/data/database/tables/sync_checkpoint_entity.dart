// lib/data/database/tables/sync_checkpoint_entity.dart

import 'package:drift/drift.dart';
import 'package:prismbox/data/database/tables/mixins/drift_defaults_mixin.dart';
import 'package:prismbox/data/database/tables/user_entity.dart';

/// 同步检查点实体表
/// 存储每个用户的同步状态和 checkpoint
@DataClassName('SyncCheckpointEntityData')
class SyncCheckpointEntity extends Table with DriftDefaultsMixin {
  const SyncCheckpointEntity();

  /// 用户 ID
  TextColumn get userId => text()
      .references(UserEntity, #id, onDelete: KeyAction.cascade)();

  /// 同步类型（如 "assets_v1"）
  TextColumn get syncType => text()();

  /// Checkpoint ID（由服务器生成）
  TextColumn get ack => text()();

  /// 创建时间
  DateTimeColumn get createdAt => dateTime()();

  /// 更新时间
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {userId, syncType};
}

