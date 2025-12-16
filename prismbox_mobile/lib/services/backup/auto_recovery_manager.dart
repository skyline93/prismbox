// lib/services/backup/auto_recovery_manager.dart

import 'package:logging/logging.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/enums/upload_task_status.dart';
import 'package:prismbox/services/backup/backup_query_builder.dart';
import 'package:prismbox/services/backup/upload_service.dart';
import 'package:prismbox/services/backup/error_handler.dart';
import 'package:prismbox/services/backup/asset_path_resolver.dart';
import 'package:prismbox/services/backup/upload_task_state_machine.dart';

/// 自动恢复管理器
/// 
/// **职责**：
/// - 恢复未完成任务（应用启动时）
/// - 检查任务有效性
/// - 自动重试失败任务（最多 3 次）
/// 
/// **恢复策略**：
/// - pending/failed 状态的任务：自动恢复
/// - uploading 状态的任务：标记为 failed，允许重试
/// - permanentlyFailed 状态的任务：不自动恢复（需要用户手动重试）
/// - cancelled 状态的任务：不恢复
class AutoRecoveryManager {
  final AppDatabase _database;
  final AssetPathResolver _pathResolver;
  final UploadTaskStateMachine _stateMachine;
  final Logger _logger = Logger('AutoRecoveryManager');

  /// 任务有效期（7 天）
  static const Duration _taskValidityPeriod = Duration(days: 7);

  AutoRecoveryManager({
    required AppDatabase database,
    UploadService? uploadService,
    BackupErrorHandler? errorHandler,
    required AssetPathResolver pathResolver,
    required UploadTaskStateMachine stateMachine,
  })  : _database = database,
        _pathResolver = pathResolver,
        _stateMachine = stateMachine;

  /// 恢复未完成任务
  /// 
  /// **参数**：
  /// - [userId] - 用户 ID（必须）
  /// 
  /// **执行流程**：
  /// 1. 获取未完成任务（pending、uploading、failed）
  /// 2. 检查任务有效性
  /// 3. 根据任务状态决定是否恢复
  /// 4. 自动重试失败任务（如果未达到最大重试次数）
  /// 
  /// **恢复规则**：
  /// - pending：直接恢复（状态不变）
  /// - uploading：标记为 failed，允许重试
  /// - failed：检查重试次数，未超限则恢复
  /// - permanentlyFailed：不恢复
  /// - cancelled：不恢复
  Future<RecoveryResult> recoverPendingTasks({
    required String userId,
  }) async {
    _logger.info('Starting task recovery for userId=$userId');

    final result = RecoveryResult();

    try {
      // 1. 获取未完成任务
      final pendingTasks = await BackupQueryBuilder(_database)
          .withUserId(userId)
          .buildTaskQuery(status: UploadTaskStatus.pending)
          .get();

      final uploadingTasks = await BackupQueryBuilder(_database)
          .withUserId(userId)
          .buildTaskQuery(status: UploadTaskStatus.uploading)
          .get();

      final failedTasks = await BackupQueryBuilder(_database)
          .withUserId(userId)
          .buildTaskQuery(status: UploadTaskStatus.failed)
          .get();

      final allTasks = [...pendingTasks, ...uploadingTasks, ...failedTasks];
      result.totalCount = allTasks.length;

      _logger.info(
        'Found ${allTasks.length} tasks to recover: '
        'pending=${pendingTasks.length}, uploading=${uploadingTasks.length}, '
        'failed=${failedTasks.length}',
      );

      // 2. 处理每个任务
      for (final task in allTasks) {
        try {
          // 检查任务有效性
          final isValid = await _isTaskValid(task);
          if (!isValid) {
            // 标记为永久失败
            await _markTaskAsPermanentlyFailed(
              task.id,
              'Task expired or invalid',
            );
            result.invalidCount++;
            continue;
          }

          // 根据任务状态决定恢复策略
          switch (task.status) {
            case UploadTaskStatus.pending:
              // pending 任务直接恢复（状态不变）
              result.recoveredCount++;
              _logger.fine('Recovered pending task: taskId=${task.id}');
              break;

            case UploadTaskStatus.uploading:
              // uploading 任务标记为 failed，允许重试（通过状态机）
              await _stateMachine.transition(
                task,
                UploadTaskStatus.failed,
                errorMessage: 'Application was terminated during upload',
              );
              result.recoveredCount++;
              _logger.fine(
                'Recovered uploading task (marked as failed): taskId=${task.id}',
              );
              break;

            case UploadTaskStatus.failed:
              // failed 任务检查重试次数
              if (task.retryCount >= task.maxRetries) {
                // 达到最大重试次数，标记为永久失败
                await _markTaskAsPermanentlyFailed(
                  task.id,
                  'Max retries exceeded',
                );
                result.permanentlyFailedCount++;
              } else {
                // 未达到最大重试次数，恢复任务
                result.recoveredCount++;
                _logger.fine('Recovered failed task: taskId=${task.id}');
              }
              break;

            default:
              // 其他状态不恢复
              result.skippedCount++;
              break;
          }
        } catch (e, stackTrace) {
          _logger.warning(
            'Failed to recover task: taskId=${task.id}, error=$e',
            e,
            stackTrace,
          );
          result.errorCount++;
        }
      }

      _logger.info(
        'Task recovery completed: total=${result.totalCount}, '
        'recovered=${result.recoveredCount}, invalid=${result.invalidCount}, '
        'permanentlyFailed=${result.permanentlyFailedCount}, '
        'skipped=${result.skippedCount}, errors=${result.errorCount}',
      );

      return result;
    } catch (e, stackTrace) {
      _logger.severe('Task recovery failed', e, stackTrace);
      result.errorCount = result.totalCount;
      return result;
    }
  }

  /// 检查任务是否有效
  /// 
  /// **参数**：
  /// - [task] - 上传任务
  /// 
  /// **返回**：是否有效
  /// 
  /// **检查项**：
  /// - 文件是否存在
  /// - 任务是否过期（超过 7 天）
  Future<bool> _isTaskValid(UploadTaskEntityData task) async {
    // 1. 检查文件是否存在
    if (!await _pathResolver.validateFileExists(task.localPath)) {
      _logger.warning('Task file not found: taskId=${task.id}, path=${task.localPath}');
      return false;
    }

    // 2. 检查任务是否过期
    final daysSinceCreation =
        DateTime.now().difference(task.createdAt).inDays;
    if (daysSinceCreation > _taskValidityPeriod.inDays) {
      _logger.warning(
        'Task expired: taskId=${task.id}, '
        'daysSinceCreation=$daysSinceCreation',
      );
      return false;
    }

    return true;
  }

  /// 标记任务为永久失败
  /// 
  /// **参数**：
  /// - [taskId] - 任务 ID
  /// - [reason] - 失败原因
  Future<void> _markTaskAsPermanentlyFailed(
    String taskId,
    String reason,
  ) async {
    // 通过状态机更新状态
    final task = await _database.uploadTaskDao.getTaskById(taskId);
    if (task != null) {
      await _stateMachine.transition(
        task,
        UploadTaskStatus.permanentlyFailed,
        errorMessage: reason,
      );
      _logger.info('Marked task as permanently failed: taskId=$taskId, reason=$reason');
    }
  }

  /// 清理过期任务
  /// 
  /// **参数**：
  /// - [userId] - 用户 ID（必须）
  /// 
  /// **清理规则**：
  /// - 永久失败任务：30 天后清理
  /// - 已取消任务：3 天后清理
  /// - 已完成任务：7 天后清理（但保留最近 1000 条）
  Future<CleanupResult> cleanupExpiredTasks({
    required String userId,
  }) async {
    _logger.info('Starting task cleanup for userId=$userId');

    final result = CleanupResult();
    final now = DateTime.now();

    try {
      // 1. 清理永久失败任务（30 天后）
      final permanentlyFailedCutoff =
          now.subtract(const Duration(days: 30));
      final permanentlyFailedTasks = await BackupQueryBuilder(_database)
          .withUserId(userId)
          .buildTaskQuery(status: UploadTaskStatus.permanentlyFailed)
          .get();

      int permanentlyFailedDeleted = 0;
      for (final task in permanentlyFailedTasks) {
        if (task.createdAt.isBefore(permanentlyFailedCutoff)) {
          await _database.uploadTaskDao.deleteTask(task.id);
          permanentlyFailedDeleted++;
        }
      }
      result.permanentlyFailedDeleted = permanentlyFailedDeleted;

      // 2. 清理已取消任务（3 天后）
      final cancelledCutoff = now.subtract(const Duration(days: 3));
      final cancelledTasks = await BackupQueryBuilder(_database)
          .withUserId(userId)
          .buildTaskQuery(status: UploadTaskStatus.cancelled)
          .get();

      int cancelledDeleted = 0;
      for (final task in cancelledTasks) {
        if (task.createdAt.isBefore(cancelledCutoff)) {
          await _database.uploadTaskDao.deleteTask(task.id);
          cancelledDeleted++;
        }
      }
      result.cancelledDeleted = cancelledDeleted;

      // 3. 清理已完成任务（7 天后，但保留最近 1000 条）
      final completedCutoff = now.subtract(const Duration(days: 7));
      final completedTasks = await BackupQueryBuilder(_database)
          .withUserId(userId)
          .buildTaskQuery(status: UploadTaskStatus.completed)
          .get();

      // 按完成时间排序，保留最近 1000 条
      final sortedCompleted = completedTasks.toList()
        ..sort((a, b) => (b.uploadedAt ?? b.createdAt)
            .compareTo(a.uploadedAt ?? a.createdAt));

      int completedDeleted = 0;
      for (int i = 1000; i < sortedCompleted.length; i++) {
        final task = sortedCompleted[i];
        if ((task.uploadedAt ?? task.createdAt).isBefore(completedCutoff)) {
          await _database.uploadTaskDao.deleteTask(task.id);
          completedDeleted++;
        }
      }
      result.completedDeleted = completedDeleted;

      _logger.info(
        'Task cleanup completed: permanentlyFailed=$permanentlyFailedDeleted, '
        'cancelled=$cancelledDeleted, completed=$completedDeleted',
      );

      return result;
    } catch (e, stackTrace) {
      _logger.severe('Task cleanup failed', e, stackTrace);
      return result;
    }
  }
}

/// 恢复结果
class RecoveryResult {
  /// 总任务数
  int totalCount = 0;

  /// 恢复的任务数
  int recoveredCount = 0;

  /// 无效的任务数
  int invalidCount = 0;

  /// 永久失败的任务数
  int permanentlyFailedCount = 0;

  /// 跳过的任务数
  int skippedCount = 0;

  /// 错误数
  int errorCount = 0;
}

/// 清理结果
class CleanupResult {
  /// 删除的永久失败任务数
  int permanentlyFailedDeleted = 0;

  /// 删除的已取消任务数
  int cancelledDeleted = 0;

  /// 删除的已完成任务数
  int completedDeleted = 0;
}

