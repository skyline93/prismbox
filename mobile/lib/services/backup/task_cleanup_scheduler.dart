// lib/services/backup/task_cleanup_scheduler.dart

import 'dart:async';
import 'package:logging/logging.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/enums/upload_task_status.dart';
import 'package:prismbox/services/backup/backup_query_builder.dart';
import 'package:prismbox/services/backup/resource_manager.dart';

/// 任务清理调度器
/// 
/// **职责**：
/// - 自动清理已完成任务（7 天后）
/// - 自动清理永久失败任务（30 天后）
/// - 自动清理已取消任务（3 天后）
/// - 保留最近 1000 条记录
/// 
/// **清理时机**：
/// - 定时清理：每天凌晨 2 点执行清理
/// - 触发清理：队列满时立即执行清理
/// - 手动清理：用户可在设置中手动触发清理
class TaskCleanupScheduler {
  final AppDatabase _database;
  final ResourceManager _resourceManager;
  final Logger _logger = Logger('TaskCleanupScheduler');

  /// 定时器（用于定时清理）
  Timer? _cleanupTimer;

  /// 清理间隔（默认 24 小时）
  static const Duration _cleanupInterval = Duration(hours: 24);

  /// 清理时间（默认凌晨 2 点）
  static const int _cleanupHour = 2;

  TaskCleanupScheduler({
    required AppDatabase database,
    required ResourceManager resourceManager,
  })  : _database = database,
        _resourceManager = resourceManager;

  /// 启动定时清理
  /// 
  /// **职责**：
  /// - 设置定时器，每天执行清理
  /// - 计算下次清理时间（凌晨 2 点）
  void startScheduledCleanup() {
    _logger.info('Starting scheduled task cleanup');

    // 取消现有定时器
    _cleanupTimer?.cancel();

    // 计算下次清理时间（今天或明天的凌晨 2 点）
    final now = DateTime.now();
    var nextCleanup = DateTime(
      now.year,
      now.month,
      now.day,
      _cleanupHour,
      0,
      0,
    );

    if (nextCleanup.isBefore(now)) {
      // 今天已经过了凌晨 2 点，设置为明天
      nextCleanup = nextCleanup.add(const Duration(days: 1));
    }

    final delay = nextCleanup.difference(now);

    _logger.info(
      'Next cleanup scheduled at: $nextCleanup (in ${delay.inHours}h ${delay.inMinutes % 60}m)',
    );

    // 设置定时器
    _cleanupTimer = Timer(delay, () {
      _performScheduledCleanup();
      // 之后每 24 小时执行一次
      _cleanupTimer = Timer.periodic(_cleanupInterval, (_) {
        _performScheduledCleanup();
      });
    });
  }

  /// 停止定时清理
  void stopScheduledCleanup() {
    _logger.info('Stopping scheduled task cleanup');
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }

  /// 执行定时清理
  Future<void> _performScheduledCleanup() async {
    _logger.info('Performing scheduled task cleanup');

    try {
      // 获取所有用户（需要清理所有用户的任务）
      // 注意：这里简化处理，实际应该获取所有有任务的用户
      // TODO: 实现获取所有用户列表的逻辑

      // 清理临时文件
      await _resourceManager.cleanupOrphanedFiles();

      _logger.info('Scheduled task cleanup completed');
    } catch (e, stackTrace) {
      _logger.severe('Scheduled task cleanup failed', e, stackTrace);
    }
  }

  /// 清理已完成任务
  /// 
  /// **参数**：
  /// - [userId] - 用户 ID（必须）
  /// - [olderThan] - 清理多少天前的任务（默认 7 天）
  /// - [keepRecentCount] - 保留最近多少条记录（默认 1000）
  /// 
  /// **返回**：清理的任务数
  Future<int> cleanupCompletedTasks({
    required String userId,
    Duration olderThan = const Duration(days: 7),
    int keepRecentCount = 1000,
  }) async {
    _logger.info(
      'Cleaning up completed tasks: userId=$userId, '
      'olderThan=${olderThan.inDays} days, keepRecent=$keepRecentCount',
    );

    try {
      final cutoffDate = DateTime.now().subtract(olderThan);

      // 获取需要保留的最近任务ID
      final recentTasks = await BackupQueryBuilder(_database)
          .withUserId(userId)
          .buildTaskQuery(status: UploadTaskStatus.completed)
          .get();

      // 按完成时间排序
      final sortedTasks = recentTasks.toList()
        ..sort((a, b) => (b.uploadedAt ?? b.createdAt)
            .compareTo(a.uploadedAt ?? a.createdAt));

      // 保留最近 N 条
      final keepIds = sortedTasks
          .take(keepRecentCount)
          .map((t) => t.id)
          .toSet();

      // 删除旧任务
      int deletedCount = 0;
      for (final task in sortedTasks.skip(keepRecentCount)) {
        final taskDate = task.uploadedAt ?? task.createdAt;
        if (taskDate.isBefore(cutoffDate)) {
          await _database.uploadTaskDao.deleteTask(task.id);
          deletedCount++;
        }
      }

      _logger.info(
        'Completed tasks cleanup: deleted=$deletedCount, kept=${keepIds.length}',
      );

      return deletedCount;
    } catch (e, stackTrace) {
      _logger.severe('Failed to cleanup completed tasks', e, stackTrace);
      return 0;
    }
  }

  /// 清理永久失败任务
  /// 
  /// **参数**：
  /// - [userId] - 用户 ID（必须）
  /// - [olderThan] - 清理多少天前的任务（默认 30 天）
  /// 
  /// **返回**：清理的任务数
  Future<int> cleanupPermanentlyFailedTasks({
    required String userId,
    Duration olderThan = const Duration(days: 30),
  }) async {
    _logger.info(
      'Cleaning up permanently failed tasks: userId=$userId, '
      'olderThan=${olderThan.inDays} days',
    );

    try {
      final cutoffDate = DateTime.now().subtract(olderThan);

      final failedTasks = await BackupQueryBuilder(_database)
          .withUserId(userId)
          .buildTaskQuery(status: UploadTaskStatus.permanentlyFailed)
          .get();

      int deletedCount = 0;
      for (final task in failedTasks) {
        if (task.createdAt.isBefore(cutoffDate)) {
          await _database.uploadTaskDao.deleteTask(task.id);
          deletedCount++;
        }
      }

      _logger.info(
        'Permanently failed tasks cleanup: deleted=$deletedCount',
      );

      return deletedCount;
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to cleanup permanently failed tasks',
        e,
        stackTrace,
      );
      return 0;
    }
  }

  /// 清理已取消任务
  /// 
  /// **参数**：
  /// - [userId] - 用户 ID（必须）
  /// - [olderThan] - 清理多少天前的任务（默认 3 天）
  /// 
  /// **返回**：清理的任务数
  Future<int> cleanupCancelledTasks({
    required String userId,
    Duration olderThan = const Duration(days: 3),
  }) async {
    _logger.info(
      'Cleaning up cancelled tasks: userId=$userId, '
      'olderThan=${olderThan.inDays} days',
    );

    try {
      final cutoffDate = DateTime.now().subtract(olderThan);

      final cancelledTasks = await BackupQueryBuilder(_database)
          .withUserId(userId)
          .buildTaskQuery(status: UploadTaskStatus.cancelled)
          .get();

      int deletedCount = 0;
      for (final task in cancelledTasks) {
        if (task.createdAt.isBefore(cutoffDate)) {
          await _database.uploadTaskDao.deleteTask(task.id);
          deletedCount++;
        }
      }

      _logger.info('Cancelled tasks cleanup: deleted=$deletedCount');

      return deletedCount;
    } catch (e, stackTrace) {
      _logger.severe('Failed to cleanup cancelled tasks', e, stackTrace);
      return 0;
    }
  }

  /// 执行完整清理（所有类型的任务）
  /// 
  /// **参数**：
  /// - [userId] - 用户 ID（必须）
  /// 
  /// **返回**：清理结果
  Future<FullCleanupResult> performFullCleanup({
    required String userId,
  }) async {
    _logger.info('Performing full cleanup: userId=$userId');

    final result = FullCleanupResult();

    try {
      // 1. 清理已完成任务
      result.completedDeleted =
          await cleanupCompletedTasks(userId: userId);

      // 2. 清理永久失败任务
      result.permanentlyFailedDeleted =
          await cleanupPermanentlyFailedTasks(userId: userId);

      // 3. 清理已取消任务
      result.cancelledDeleted = await cleanupCancelledTasks(userId: userId);

      // 4. 清理孤立临时文件
      final fileCleanupResult = await _resourceManager.cleanupOrphanedFiles();
      result.orphanedFilesDeleted = fileCleanupResult.orphanedDeleted;
      result.expiredFilesDeleted = fileCleanupResult.expiredDeleted;

      _logger.info(
        'Full cleanup completed: completed=${result.completedDeleted}, '
        'permanentlyFailed=${result.permanentlyFailedDeleted}, '
        'cancelled=${result.cancelledDeleted}, '
        'orphanedFiles=${result.orphanedFilesDeleted}, '
        'expiredFiles=${result.expiredFilesDeleted}',
      );

      return result;
    } catch (e, stackTrace) {
      _logger.severe('Full cleanup failed', e, stackTrace);
      return result;
    }
  }

  /// 释放资源
  void dispose() {
    stopScheduledCleanup();
  }
}

/// 完整清理结果
class FullCleanupResult {
  /// 删除的已完成任务数
  int completedDeleted = 0;

  /// 删除的永久失败任务数
  int permanentlyFailedDeleted = 0;

  /// 删除的已取消任务数
  int cancelledDeleted = 0;

  /// 删除的孤立文件数
  int orphanedFilesDeleted = 0;

  /// 删除的过期文件数
  int expiredFilesDeleted = 0;
}

