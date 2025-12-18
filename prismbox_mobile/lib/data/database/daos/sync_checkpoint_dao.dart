// lib/data/database/daos/sync_checkpoint_dao.dart

import 'package:drift/drift.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/tables/sync_checkpoint_entity.dart';

part 'sync_checkpoint_dao.g.dart';

/// 同步检查点数据访问对象
@DriftAccessor(tables: [SyncCheckpointEntity])
class SyncCheckpointDao extends DatabaseAccessor<AppDatabase>
    with _$SyncCheckpointDaoMixin {
  SyncCheckpointDao(AppDatabase db) : super(db);

  /// 获取检查点
  Future<SyncCheckpointEntityData?> getCheckpoint(
    String userId,
    String syncType,
  ) {
    return (select(syncCheckpointEntity)
          ..where((t) =>
              t.userId.equals(userId) & t.syncType.equals(syncType)))
        .getSingleOrNull();
  }

  /// 设置检查点
  Future<void> setCheckpoint(
    String userId,
    String syncType,
    String ack,
  ) async {
    final now = DateTime.now();
    
    // 先尝试获取现有记录
    final existing = await getCheckpoint(userId, syncType);
    
    if (existing != null) {
      // 更新现有记录（只更新 ack 和 updatedAt，createdAt 保持不变）
      await (update(syncCheckpointEntity)
            ..where((t) =>
                t.userId.equals(userId) & t.syncType.equals(syncType)))
          .write(SyncCheckpointEntityCompanion(
            ack: Value(ack),
            updatedAt: Value(now),
          ));
    } else {
      // 插入新记录，需要设置 createdAt 和 updatedAt
      await into(syncCheckpointEntity).insert(SyncCheckpointEntityCompanion(
        userId: Value(userId),
        syncType: Value(syncType),
        ack: Value(ack),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
    }
  }

  /// 清除检查点
  Future<bool> clearCheckpoint(String userId, String syncType) async {
    final count = await (delete(syncCheckpointEntity)
          ..where((t) =>
              t.userId.equals(userId) & t.syncType.equals(syncType)))
        .go();
    return count > 0;
  }

  /// 清除用户的所有检查点
  Future<bool> clearAllCheckpoints(String userId) async {
    final count = await (delete(syncCheckpointEntity)
          ..where((t) => t.userId.equals(userId)))
        .go();
    return count > 0;
  }
}

