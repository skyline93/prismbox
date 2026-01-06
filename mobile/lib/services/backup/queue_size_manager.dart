// lib/services/backup/queue_size_manager.dart

import 'package:logging/logging.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/enums/upload_task_status.dart';
import 'package:prismbox/services/backup/backup_query_builder.dart';

/// 队列大小管理器
/// 
/// **职责**：
/// - 队列大小限制（按任务数、总大小）
/// - 队列满时的处理策略
/// 
/// **限制策略**：
/// - 按任务数限制：默认最大 10000 个任务
/// - 按总大小限制：默认最大 100GB（所有待上传任务的总大小）
/// - 可配置：用户可在设置中调整限制（高级设置）
class QueueSizeManager {
  final AppDatabase _database;
  final Logger _logger = Logger('QueueSizeManager');

  /// 最大任务数（默认 10000）
  final int maxTaskCount;

  /// 最大总大小（默认 100GB）
  final int maxTotalSizeBytes;

  QueueSizeManager({
    required AppDatabase database,
    int? maxTaskCount,
    int? maxTotalSizeBytes,
  })  : _database = database,
        maxTaskCount = maxTaskCount ?? 10000,
        maxTotalSizeBytes = maxTotalSizeBytes ?? (100 * 1024 * 1024 * 1024);

  /// 检查是否可以添加任务
  /// 
  /// **参数**：
  /// - [taskSize] - 任务文件大小（字节）
  /// - [userId] - 用户 ID（必须）
  /// 
  /// **返回**：是否可以添加
  /// 
  /// **检查项**：
  /// - 当前任务数是否超过限制
  /// - 当前总大小是否超过限制
  Future<bool> canAddTask({
    required int taskSize,
    required String userId,
  }) async {
    try {
      // 1. 检查任务数
      final currentCount = await _getQueueSize(userId);
      if (currentCount >= maxTaskCount) {
        _logger.warning(
          'Queue full (task count): current=$currentCount, max=$maxTaskCount',
        );
        return false;
      }

      // 2. 检查总大小
      final currentSize = await _getQueueTotalSize(userId);
      if (currentSize + taskSize > maxTotalSizeBytes) {
        _logger.warning(
          'Queue full (total size): current=${currentSize / (1024 * 1024 * 1024)}GB, '
          'max=${maxTotalSizeBytes / (1024 * 1024 * 1024)}GB, '
          'taskSize=${taskSize / (1024 * 1024)}MB',
        );
        return false;
      }

      return true;
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to check if can add task',
        e,
        stackTrace,
      );
      // 出错时允许添加（避免阻塞）
      return true;
    }
  }

  /// 获取队列大小（任务数）
  /// 
  /// **参数**：
  /// - [userId] - 用户 ID（必须）
  /// 
  /// **返回**：任务数
  Future<int> _getQueueSize(String userId) async {
    final pendingTasks = await BackupQueryBuilder(_database)
        .withUserId(userId)
        .buildTaskQuery(status: UploadTaskStatus.pending)
        .get();

    final uploadingTasks = await BackupQueryBuilder(_database)
        .withUserId(userId)
        .buildTaskQuery(status: UploadTaskStatus.uploading)
        .get();

    return pendingTasks.length + uploadingTasks.length;
  }

  /// 获取队列总大小（字节）
  /// 
  /// **参数**：
  /// - [userId] - 用户 ID（必须）
  /// 
  /// **返回**：总大小（字节）
  Future<int> _getQueueTotalSize(String userId) async {
    final pendingTasks = await BackupQueryBuilder(_database)
        .withUserId(userId)
        .buildTaskQuery(status: UploadTaskStatus.pending)
        .get();

    final uploadingTasks = await BackupQueryBuilder(_database)
        .withUserId(userId)
        .buildTaskQuery(status: UploadTaskStatus.uploading)
        .get();

    int totalSize = 0;
    for (final task in [...pendingTasks, ...uploadingTasks]) {
      totalSize += task.fileSize;
    }

    return totalSize;
  }

  /// 获取队列统计信息
  /// 
  /// **参数**：
  /// - [userId] - 用户 ID（必须）
  /// 
  /// **返回**：队列统计信息
  Future<QueueStats> getQueueStats(String userId) async {
    final taskCount = await _getQueueSize(userId);
    final totalSize = await _getQueueTotalSize(userId);

    return QueueStats(
      taskCount: taskCount,
      totalSizeBytes: totalSize,
      maxTaskCount: maxTaskCount,
      maxTotalSizeBytes: maxTotalSizeBytes,
      usageRatio: taskCount / maxTaskCount,
      sizeUsageRatio: totalSize / maxTotalSizeBytes,
    );
  }

  /// 触发清理（当队列满时）
  /// 
  /// **参数**：
  /// - [userId] - 用户 ID（必须）
  /// 
  /// **职责**：
  /// - 清理已完成任务（如果超过保留数量）
  /// - 清理永久失败任务（如果超过保留时间）
  /// 
  /// **注意**：此方法由 TaskCleanupScheduler 调用
  Future<void> triggerCleanup(String userId) async {
    _logger.info('Triggering cleanup due to queue full: userId=$userId');

    // 清理逻辑由 TaskCleanupScheduler 负责
    // 这里只是触发清理的入口
  }
}

/// 队列统计信息
class QueueStats {
  /// 当前任务数
  final int taskCount;

  /// 当前总大小（字节）
  final int totalSizeBytes;

  /// 最大任务数
  final int maxTaskCount;

  /// 最大总大小（字节）
  final int maxTotalSizeBytes;

  /// 任务数使用率（0.0 - 1.0）
  final double usageRatio;

  /// 大小使用率（0.0 - 1.0）
  final double sizeUsageRatio;

  QueueStats({
    required this.taskCount,
    required this.totalSizeBytes,
    required this.maxTaskCount,
    required this.maxTotalSizeBytes,
    required this.usageRatio,
    required this.sizeUsageRatio,
  });

  /// 是否接近限制（使用率 > 80%）
  bool get isNearLimit => usageRatio > 0.8 || sizeUsageRatio > 0.8;

  /// 是否已满（使用率 >= 100%）
  bool get isFull => usageRatio >= 1.0 || sizeUsageRatio >= 1.0;
}

