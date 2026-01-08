// lib/data/database/daos/post_task_dao.dart

import 'package:drift/drift.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/tables/post_task_entity.dart';
import 'package:prismbox/data/database/enums/post_task_status.dart';

part 'post_task_dao.g.dart';

/// 帖子任务数据访问对象
/// 提供帖子任务的查询和操作接口
@DriftAccessor(tables: [PostTaskEntity])
class PostTaskDao extends DatabaseAccessor<AppDatabase>
    with _$PostTaskDaoMixin {
  PostTaskDao(AppDatabase db) : super(db);

  /// 根据任务ID获取任务
  Future<PostTaskEntityData?> getTaskById(String taskId) {
    return (select(postTaskEntity)
          ..where((t) => t.id.equals(taskId)))
        .getSingleOrNull();
  }

  /// 根据用户ID和状态获取任务列表
  Future<List<PostTaskEntityData>> getTasksByUserIdAndStatus(
    String userId,
    PostTaskStatus status,
  ) {
    return (select(postTaskEntity)
          ..where((t) =>
              t.userId.equals(userId) & t.status.equalsValue(status)))
        .get();
  }

  /// 获取待处理的任务（按创建时间排序）
  Future<List<PostTaskEntityData>> getPendingTasksByUserId(String userId) {
    return (select(postTaskEntity)
          ..where((t) =>
              t.userId.equals(userId) &
              (t.status.equalsValue(PostTaskStatus.pending) |
               t.status.equalsValue(PostTaskStatus.uploadingMedia) |
               t.status.equalsValue(PostTaskStatus.creatingPost)))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .get();
  }

  /// 获取失败的任务
  Future<List<PostTaskEntityData>> getFailedTasksByUserId(String userId) {
    return (select(postTaskEntity)
          ..where((t) =>
              t.userId.equals(userId) &
              t.status.equalsValue(PostTaskStatus.failed))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  /// 根据圈子ID获取任务列表
  Future<List<PostTaskEntityData>> getTasksByGroupId(String groupId) {
    return (select(postTaskEntity)
          ..where((t) => t.groupId.equals(groupId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  /// 创建任务
  Future<void> createTask(PostTaskEntityCompanion task) async {
    await into(postTaskEntity).insert(task);
  }

  /// 更新任务
  Future<void> updateTask(String taskId, PostTaskEntityCompanion updates) async {
    await (update(postTaskEntity)..where((t) => t.id.equals(taskId)))
        .write(updates);
  }

  /// 更新任务状态
  Future<void> updateTaskStatus(
    String taskId,
    PostTaskStatus status, {
    String? errorMessage,
    int? progress,
  }) async {
    final updates = PostTaskEntityCompanion(
      status: Value(status),
      updatedAt: Value(DateTime.now()),
      errorMessage: errorMessage != null ? Value(errorMessage) : const Value.absent(),
      progress: progress != null ? Value(progress) : const Value.absent(),
    );
    await updateTask(taskId, updates);
  }

  /// 更新任务进度
  Future<void> updateTaskProgress(String taskId, int progress) async {
    await updateTask(
      taskId,
      PostTaskEntityCompanion(
        progress: Value(progress),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 更新媒体 UUID 列表
  Future<void> updateMediaUuids(String taskId, List<String> mediaUuids) async {
    final mediaUuidsJson = mediaUuids.join(',');
    await updateTask(
      taskId,
      PostTaskEntityCompanion(
        mediaUuids: Value(mediaUuidsJson),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 删除任务
  Future<void> deleteTask(String taskId) async {
    await (delete(postTaskEntity)..where((t) => t.id.equals(taskId))).go();
  }

  /// 删除已完成的任务（清理旧数据）
  Future<void> deleteCompletedTasks(String userId, {Duration? olderThan}) async {
    final query = delete(postTaskEntity)
      ..where((t) =>
          t.userId.equals(userId) &
          t.status.equalsValue(PostTaskStatus.completed));

    if (olderThan != null) {
      final cutoffTime = DateTime.now().subtract(olderThan);
      query.where((t) => t.createdAt.isSmallerThanValue(cutoffTime));
    }

    await query.go();
  }
}

