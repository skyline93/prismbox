// lib/data/database/tables/backup_status_entity.dart

import 'package:drift/drift.dart';
import 'package:prismbox/data/database/tables/mixins/drift_defaults_mixin.dart';
import 'package:prismbox/data/database/tables/user_entity.dart';
import 'package:prismbox/data/database/enums/auto_backup_mode.dart';

/// 备份状态实体表
/// 存储每个用户的备份配置和状态
@DataClassName('BackupStatusEntityData')
@TableIndex(name: 'idx_backup_status_user_id', columns: {#userId})
class BackupStatusEntity extends Table with DriftDefaultsMixin {
  const BackupStatusEntity();

  /// 用户 ID（主键，外键关联 UserEntity）
  TextColumn get userId => text()
      .references(UserEntity, #id, onDelete: KeyAction.cascade)();

  /// 最后自动备份时间（用于增量同步）
  DateTimeColumn get lastBackupTime => dateTime().nullable()();

  /// 该用户的自动备份是否启用
  BoolColumn get enabled => boolean()
      .withDefault(const Constant(false))();

  /// 自动备份模式枚举
  IntColumn get autoBackupMode => intEnum<AutoBackupMode>()
      .withDefault(const Constant(0))(); // AutoBackupMode.allUnbacked = 0

  /// 时间段起始（time_range 模式）
  DateTimeColumn get timeRangeStart => dateTime().nullable()();

  /// 时间段结束（time_range 模式）
  DateTimeColumn get timeRangeEnd => dateTime().nullable()();

  /// 创建时间
  DateTimeColumn get createdAt => dateTime()();

  /// 更新时间
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {userId};
}

