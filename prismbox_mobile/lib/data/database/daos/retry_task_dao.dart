// lib/data/database/daos/retry_task_dao.dart

import 'package:drift/drift.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/tables/retry_task_entity.dart';

part 'retry_task_dao.g.dart';

/// 重试任务数据访问对象
@DriftAccessor(tables: [RetryTaskEntity])
class RetryTaskDao extends DatabaseAccessor<AppDatabase>
    with _$RetryTaskDaoMixin {
  RetryTaskDao(AppDatabase db) : super(db);

  /// 保存重试任务
  Future<void> saveTask(RetryTaskEntityData task) async {
    await into(retryTaskEntity).insertOnConflictUpdate(task);
  }

  /// 获取所有待处理的任务
  /// 优先处理最早的任务：
  /// 1. 从未重试过的任务（lastRetryAt 为 null）优先
  /// 2. 然后按最后重试时间升序排序（最早重试的优先）
  /// 3. 最后按ID排序（作为稳定排序）
  Future<List<RetryTaskEntityData>> getAllPendingTasks() async {
    // 先获取所有任务
    final allTasks = await select(retryTaskEntity).get();
    
    // 手动排序：null值优先，然后按时间升序
    allTasks.sort((a, b) {
      // null值优先（从未重试过的任务）
      if (a.lastRetryAt == null && b.lastRetryAt != null) return -1;
      if (a.lastRetryAt != null && b.lastRetryAt == null) return 1;
      if (a.lastRetryAt == null && b.lastRetryAt == null) {
        // 都是null，按ID排序
        return a.id.compareTo(b.id);
      }
      // 都有值，按时间升序排序
      final timeCompare = a.lastRetryAt!.compareTo(b.lastRetryAt!);
      if (timeCompare != 0) return timeCompare;
      // 时间相同，按ID排序
      return a.id.compareTo(b.id);
    });
    
    return allTasks;
  }

  /// 根据ID获取任务
  Future<RetryTaskEntityData?> getTaskById(String id) async {
    return await (select(retryTaskEntity)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// 更新任务
  Future<void> updateTask(RetryTaskEntityData task) async {
    await update(retryTaskEntity).replace(task);
  }

  /// 删除任务
  Future<void> deleteTask(String id) async {
    await (delete(retryTaskEntity)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  /// 删除所有任务
  Future<void> deleteAllTasks() async {
    await delete(retryTaskEntity).go();
  }
}

