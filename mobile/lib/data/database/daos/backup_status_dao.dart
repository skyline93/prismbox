// lib/data/database/daos/backup_status_dao.dart

import 'package:drift/drift.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/tables/backup_status_entity.dart';

part 'backup_status_dao.g.dart';

/// 备份状态数据访问对象
/// 提供备份状态的查询和操作接口
@DriftAccessor(tables: [BackupStatusEntity])
class BackupStatusDao extends DatabaseAccessor<AppDatabase>
    with _$BackupStatusDaoMixin {
  BackupStatusDao(AppDatabase db) : super(db);

  /// 根据用户ID获取备份状态
  Future<BackupStatusEntityData?> getBackupStatusByUserId(String userId) {
    return (select(backupStatusEntity)
          ..where((t) => t.userId.equals(userId)))
        .getSingleOrNull();
  }

  /// 监听用户备份状态变化
  Stream<BackupStatusEntityData?> watchBackupStatusByUserId(String userId) {
    return (select(backupStatusEntity)
          ..where((t) => t.userId.equals(userId)))
        .watchSingleOrNull();
  }

  /// 插入或更新备份状态
  Future<void> insertOrUpdateBackupStatus(
      BackupStatusEntityData backupStatus) {
    return into(backupStatusEntity).insertOnConflictUpdate(backupStatus);
  }

  /// 更新最后备份时间
  Future<bool> updateLastBackupTime(String userId, DateTime lastBackupTime) async {
    final count = await (update(backupStatusEntity)
          ..where((t) => t.userId.equals(userId)))
        .write(BackupStatusEntityCompanion(
          lastBackupTime: Value(lastBackupTime),
          updatedAt: Value(DateTime.now()),
        ));
    return count > 0;
  }

  /// 更新备份配置
  Future<bool> updateBackupConfig(
    String userId,
    BackupStatusEntityCompanion companion,
  ) async {
    final count = await (update(backupStatusEntity)
          ..where((t) => t.userId.equals(userId)))
        .write(
          companion.copyWith(updatedAt: Value(DateTime.now())),
        );
    return count > 0;
  }

  /// 启用或禁用备份
  Future<bool> setBackupEnabled(String userId, bool enabled) async {
    final count = await (update(backupStatusEntity)
          ..where((t) => t.userId.equals(userId)))
        .write(BackupStatusEntityCompanion(
          enabled: Value(enabled),
          updatedAt: Value(DateTime.now()),
        ));
    return count > 0;
  }

  /// 删除备份状态（级联删除时会自动执行）
  Future<bool> deleteBackupStatus(String userId) {
    return (delete(backupStatusEntity)
          ..where((t) => t.userId.equals(userId)))
        .go()
        .then((count) => count > 0);
  }
}

