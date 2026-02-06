// lib/data/database/daos/download_task_dao.dart

import 'package:drift/drift.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/tables/download_task_entity.dart';
import 'package:prismbox/data/database/enums/download_task_status.dart';
import 'package:prismbox/data/database/enums/media_download_source_type.dart';

part 'download_task_dao.g.dart';

/// 下载任务数据访问对象
@DriftAccessor(tables: [DownloadTaskEntity])
class DownloadTaskDao extends DatabaseAccessor<AppDatabase>
    with _$DownloadTaskDaoMixin {
  DownloadTaskDao(AppDatabase db) : super(db);

  /// 根据任务 ID 获取任务
  Future<DownloadTaskEntityData?> getTaskById(String taskId) {
    return (select(downloadTaskEntity)
          ..where((t) => t.id.equals(taskId)))
        .getSingleOrNull();
  }

  /// 获取用户待下载任务（pending / queued），按创建时间排序
  Future<List<DownloadTaskEntityData>> getPendingTasksByUserId(String userId) {
    return (select(downloadTaskEntity)
          ..where((t) =>
              t.userId.equals(userId) &
              (t.status.equalsValue(DownloadTaskStatus.pending) |
               t.status.equalsValue(DownloadTaskStatus.queued)))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .get();
  }

  /// 根据 userId + sourceType + sourceId 查询进行中的任务（用于冲突检测）
  Future<List<DownloadTaskEntityData>> getActiveTasksBySource(
    String userId,
    MediaDownloadSourceType sourceType,
    String sourceId,
  ) {
    return (select(downloadTaskEntity)
          ..where((t) =>
              t.userId.equals(userId) &
              t.sourceType.equalsValue(sourceType) &
              t.sourceId.equals(sourceId) &
              (t.status.equalsValue(DownloadTaskStatus.pending) |
               t.status.equalsValue(DownloadTaskStatus.queued) |
               t.status.equalsValue(DownloadTaskStatus.downloading) |
               t.status.equalsValue(DownloadTaskStatus.processing))))
        .get();
  }

  /// 插入任务
  Future<void> insertTask(DownloadTaskEntityData task) {
    return into(downloadTaskEntity).insert(task);
  }

  /// 更新任务状态
  Future<bool> updateTaskStatus(
    String taskId,
    DownloadTaskStatus status, {
    String? errorMessage,
    int? progress,
    String? imageTempPath,
    String? videoTempPath,
  }) async {
    final count = await (update(downloadTaskEntity)
          ..where((t) => t.id.equals(taskId)))
        .write(DownloadTaskEntityCompanion(
          status: Value(status),
          errorMessage: errorMessage != null
              ? Value(errorMessage)
              : const Value.absent(),
          progress: progress != null ? Value(progress) : const Value.absent(),
          imageTempPath: imageTempPath != null
              ? Value(imageTempPath)
              : const Value.absent(),
          videoTempPath: videoTempPath != null
              ? Value(videoTempPath)
              : const Value.absent(),
          updatedAt: Value(DateTime.now()),
        ));
    return count > 0;
  }

  /// 更新任务进度
  Future<bool> updateTaskProgress(String taskId, int progress) async {
    final count = await (update(downloadTaskEntity)
          ..where((t) => t.id.equals(taskId)))
        .write(DownloadTaskEntityCompanion(
          progress: Value(progress),
          updatedAt: Value(DateTime.now()),
        ));
    return count > 0;
  }

  /// 更新临时路径（主图或视频完成时）
  Future<bool> updateTempPath(
    String taskId, {
    String? imageTempPath,
    String? videoTempPath,
  }) async {
    final count = await (update(downloadTaskEntity)
          ..where((t) => t.id.equals(taskId)))
        .write(DownloadTaskEntityCompanion(
          imageTempPath: imageTempPath != null
              ? Value(imageTempPath)
              : const Value.absent(),
          videoTempPath: videoTempPath != null
              ? Value(videoTempPath)
              : const Value.absent(),
          updatedAt: Value(DateTime.now()),
        ));
    return count > 0;
  }

  /// 获取队列状态统计
  Future<Map<DownloadTaskStatus, int>> getQueueStatusByUserId(String userId) async {
    final tasks = await (select(downloadTaskEntity)
          ..where((t) => t.userId.equals(userId)))
        .get();

    final statusCounts = <DownloadTaskStatus, int>{};
    for (final task in tasks) {
      statusCounts[task.status] = (statusCounts[task.status] ?? 0) + 1;
    }

    return statusCounts;
  }

  /// 监听用户任务变化
  Stream<List<DownloadTaskEntityData>> watchTasksByUserId(String userId) {
    return (select(downloadTaskEntity)
          ..where((t) => t.userId.equals(userId)))
        .watch();
  }
}
