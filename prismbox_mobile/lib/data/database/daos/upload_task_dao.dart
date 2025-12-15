// lib/data/database/daos/upload_task_dao.dart

import 'package:drift/drift.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/tables/upload_task_entity.dart';
import 'package:prismbox/data/database/enums/upload_task_status.dart';
import 'package:prismbox/data/database/enums/upload_task_type.dart';

part 'upload_task_dao.g.dart';

/// 上传任务数据访问对象
/// 提供上传任务的查询和操作接口
@DriftAccessor(tables: [UploadTaskEntity])
class UploadTaskDao extends DatabaseAccessor<AppDatabase>
    with _$UploadTaskDaoMixin {
  UploadTaskDao(AppDatabase db) : super(db);

  /// 根据任务ID获取任务
  Future<UploadTaskEntityData?> getTaskById(String taskId) {
    return (select(uploadTaskEntity)
          ..where((t) => t.id.equals(taskId)))
        .getSingleOrNull();
  }

  /// 根据用户ID和状态获取任务列表
  Future<List<UploadTaskEntityData>> getTasksByUserIdAndStatus(
    String userId,
    UploadTaskStatus status,
  ) {
    return (select(uploadTaskEntity)
          ..where((t) =>
              t.userId.equals(userId) & t.status.equalsValue(status)))
        .get();
  }

  /// 根据用户ID和任务类型获取任务列表
  Future<List<UploadTaskEntityData>> getTasksByUserIdAndType(
    String userId,
    UploadTaskType taskType,
  ) {
    return (select(uploadTaskEntity)
          ..where((t) =>
              t.userId.equals(userId) & t.taskType.equalsValue(taskType)))
        .get();
  }

  /// 获取待上传任务（按优先级排序）
  Future<List<UploadTaskEntityData>> getPendingTasksByUserId(String userId) {
    return (select(uploadTaskEntity)
          ..where((t) =>
              t.userId.equals(userId) &
              t.status.equalsValue(UploadTaskStatus.pending))
          ..orderBy([
            (t) => OrderingTerm(expression: t.priority),
            (t) => OrderingTerm(expression: t.createdAt),
          ]))
        .get();
  }

  /// 获取上传中的任务
  Future<List<UploadTaskEntityData>> getUploadingTasksByUserId(String userId) {
    return (select(uploadTaskEntity)
          ..where((t) =>
              t.userId.equals(userId) &
              t.status.equalsValue(UploadTaskStatus.uploading)))
        .get();
  }

  /// 根据资产ID和用户ID查询任务（用于冲突检测）
  Future<List<UploadTaskEntityData>> getTasksByAssetIdAndUserId(
    String userId,
    String assetId,
  ) {
    return (select(uploadTaskEntity)
          ..where((t) =>
              t.userId.equals(userId) & t.assetId.equals(assetId)))
        .get();
  }

  /// 根据本地资产ID查询任务（获取最新的任务）
  /// 用于查询资产的上传状态
  Future<UploadTaskEntityData?> getTaskByLocalAssetId(String localAssetId) {
    return (select(uploadTaskEntity)
          ..where((t) => t.assetId.equals(localAssetId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// 插入任务
  Future<void> insertTask(UploadTaskEntityData task) {
    return into(uploadTaskEntity).insert(task);
  }

  /// 批量插入任务
  Future<void> insertTasks(List<UploadTaskEntityData> tasks) {
    return batch((batch) {
      batch.insertAll(uploadTaskEntity, tasks);
    });
  }

  /// 更新任务状态
  Future<bool> updateTaskStatus(
    String taskId,
    UploadTaskStatus status, {
    String? errorMessage,
    DateTime? uploadedAt,
    int? progress,
  }) async {
    final count = await (update(uploadTaskEntity)
          ..where((t) => t.id.equals(taskId)))
        .write(UploadTaskEntityCompanion(
          status: Value(status),
          errorMessage: errorMessage != null ? Value(errorMessage) : const Value.absent(),
          uploadedAt: uploadedAt != null ? Value(uploadedAt) : const Value.absent(),
          progress: progress != null ? Value(progress) : const Value.absent(),
          updatedAt: Value(DateTime.now()),
        ));
    return count > 0;
  }

  /// 更新任务进度
  Future<bool> updateTaskProgress(String taskId, int progress) async {
    final count = await (update(uploadTaskEntity)
          ..where((t) => t.id.equals(taskId)))
        .write(UploadTaskEntityCompanion(
          progress: Value(progress),
          updatedAt: Value(DateTime.now()),
        ));
    return count > 0;
  }

  /// 更新任务本地路径
  Future<bool> updateTaskLocalPath(String taskId, String localPath) async {
    final count = await (update(uploadTaskEntity)
          ..where((t) => t.id.equals(taskId)))
        .write(UploadTaskEntityCompanion(
          localPath: Value(localPath),
          updatedAt: Value(DateTime.now()),
        ));
    return count > 0;
  }

  /// 增加重试次数
  Future<bool> incrementRetryCount(String taskId) async {
    final task = await getTaskById(taskId);
    if (task == null) return false;

    final count = await (update(uploadTaskEntity)
          ..where((t) => t.id.equals(taskId)))
        .write(UploadTaskEntityCompanion(
          retryCount: Value(task.retryCount + 1),
          updatedAt: Value(DateTime.now()),
        ));
    return count > 0;
  }

  /// 删除任务
  Future<bool> deleteTask(String taskId) {
    return (delete(uploadTaskEntity)
          ..where((t) => t.id.equals(taskId)))
        .go()
        .then((count) => count > 0);
  }

  /// 批量删除任务
  Future<int> deleteTasks(List<String> taskIds) {
    return (delete(uploadTaskEntity)
          ..where((t) => t.id.isIn(taskIds)))
        .go();
  }

  /// 清理已完成的任务（保留最近N条）
  Future<int> cleanupCompletedTasks({
    required String userId,
    Duration olderThan = const Duration(days: 7),
    int keepRecentCount = 1000,
  }) async {
    final cutoffDate = DateTime.now().subtract(olderThan);

    // 获取需要保留的最近任务ID
    final recentTasks = await (select(uploadTaskEntity)
          ..where((t) =>
              t.userId.equals(userId) &
              t.status.equalsValue(UploadTaskStatus.completed))
          ..orderBy([(t) => OrderingTerm.desc(t.uploadedAt)])
          ..limit(keepRecentCount))
        .get();

    final keepIds = recentTasks.map((t) => t.id).toSet();

    // 删除旧任务
    return (delete(uploadTaskEntity)
          ..where((t) =>
              t.userId.equals(userId) &
              t.status.equalsValue(UploadTaskStatus.completed) &
              t.uploadedAt.isSmallerThanValue(cutoffDate) &
              t.id.isIn(keepIds)))
        .go();
  }

  /// 获取队列状态统计
  Future<Map<UploadTaskStatus, int>> getQueueStatusByUserId(String userId) async {
    final tasks = await (select(uploadTaskEntity)
          ..where((t) => t.userId.equals(userId)))
        .get();

    final statusCounts = <UploadTaskStatus, int>{};
    for (final task in tasks) {
      statusCounts[task.status] = (statusCounts[task.status] ?? 0) + 1;
    }

    return statusCounts;
  }

  /// 监听用户任务变化
  Stream<List<UploadTaskEntityData>> watchTasksByUserId(String userId) {
    return (select(uploadTaskEntity)
          ..where((t) => t.userId.equals(userId)))
        .watch();
  }
}

