// lib/services/download/download_task_state_machine.dart

import 'package:logging/logging.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/enums/download_task_status.dart';

/// 下载任务状态机
///
/// 状态转换规则：
/// pending → queued → downloading → processing → completed
/// 任意阶段可 → failed / permanentlyFailed / cancelled
/// failed 可重试 → queued
class DownloadTaskStateMachine {
  final AppDatabase _database;
  final Logger _logger = Logger('DownloadTaskStateMachine');

  static const Map<DownloadTaskStatus, Set<DownloadTaskStatus>>
      _allowedTransitions = {
    DownloadTaskStatus.pending: {
      DownloadTaskStatus.queued,
      DownloadTaskStatus.cancelled,
    },
    DownloadTaskStatus.queued: {
      DownloadTaskStatus.downloading,
      DownloadTaskStatus.completed,
      DownloadTaskStatus.failed,
      DownloadTaskStatus.cancelled,
    },
    DownloadTaskStatus.downloading: {
      DownloadTaskStatus.processing,
      DownloadTaskStatus.failed,
      DownloadTaskStatus.permanentlyFailed,
      DownloadTaskStatus.cancelled,
    },
    DownloadTaskStatus.processing: {
      DownloadTaskStatus.completed,
      DownloadTaskStatus.failed,
      DownloadTaskStatus.permanentlyFailed,
    },
    DownloadTaskStatus.failed: {
      DownloadTaskStatus.queued,
      DownloadTaskStatus.permanentlyFailed,
      DownloadTaskStatus.cancelled,
    },
    DownloadTaskStatus.permanentlyFailed: {
      DownloadTaskStatus.queued,
    },
    DownloadTaskStatus.completed: {},
    DownloadTaskStatus.cancelled: {},
  };

  DownloadTaskStateMachine({required AppDatabase database})
      : _database = database;

  bool canTransition(DownloadTaskStatus from, DownloadTaskStatus to) {
    if (from == to) return true;
    final allowed = _allowedTransitions[from];
    if (allowed == null) {
      _logger.warning('Unknown source status: $from');
      return false;
    }
    return allowed.contains(to);
  }

  Future<DownloadTaskEntityData> transition(
    DownloadTaskEntityData task,
    DownloadTaskStatus newStatus, {
    String? errorMessage,
    int? progress,
  }) async {
    final currentStatus = task.status;

    if (!canTransition(currentStatus, newStatus)) {
      throw StateError(
        'Invalid state transition: $currentStatus -> $newStatus '
        'for taskId=${task.id}',
      );
    }

    if (currentStatus == newStatus) {
      return task;
    }

    final success = await _database.downloadTaskDao.updateTaskStatus(
      task.id,
      newStatus,
      errorMessage: errorMessage,
      progress: progress,
    );

    if (!success) {
      throw StateError(
        'Failed to update task status: taskId=${task.id}, '
        '$currentStatus -> $newStatus',
      );
    }

    _logger.info(
      'Task status transitioned: taskId=${task.id}, '
      'sourceId=${task.sourceId}, $currentStatus -> $newStatus'
      '${errorMessage != null ? ", error: $errorMessage" : ""}',
    );

    final updatedTask = await _database.downloadTaskDao.getTaskById(task.id);
    if (updatedTask == null) {
      throw StateError('Task not found after status update: taskId=${task.id}');
    }

    return updatedTask;
  }
}
