// lib/services/backup/upload_task_state_machine.dart

import 'package:logging/logging.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/enums/upload_task_status.dart';

/// 上传任务状态机
///
/// **职责**：
/// - 统一状态流转管理，所有状态变更必须通过状态机
/// - 验证状态转换的合法性
/// - 更新数据库状态
/// - 提供状态转换查询接口
///
/// **状态转换规则**：
/// ```
/// pending → queued → uploading → completed
///   ↓         ↓         ↓            ↑
///   ↓      failed ──────┘            │
///   ↓         ↓                      │
/// cancelled   permanentlyFailed ─────┘
/// ```
class UploadTaskStateMachine {
  final AppDatabase _database;
  final Logger _logger = Logger('UploadTaskStateMachine');

  /// 允许的状态转换映射
  /// 
  /// 键：当前状态
  /// 值：允许转换到的状态集合
  static const Map<UploadTaskStatus, Set<UploadTaskStatus>> _allowedTransitions = {
    // pending 可以转换为 queued（入队）、cancelled（取消）
    UploadTaskStatus.pending: {
      UploadTaskStatus.queued,
      UploadTaskStatus.cancelled,
    },
    // queued 可以转换为 uploading（开始上传）、failed（失败）、cancelled（取消）
    UploadTaskStatus.queued: {
      UploadTaskStatus.uploading,
      UploadTaskStatus.failed,
      UploadTaskStatus.cancelled,
    },
    // uploading 可以转换为 completed（完成）、failed（失败）、permanentlyFailed（永久失败）、cancelled（取消）、paused（暂停）
    UploadTaskStatus.uploading: {
      UploadTaskStatus.completed,
      UploadTaskStatus.failed,
      UploadTaskStatus.permanentlyFailed,
      UploadTaskStatus.cancelled,
      UploadTaskStatus.paused,
    },
    // paused 可以转换为 uploading（恢复）、cancelled（取消）
    UploadTaskStatus.paused: {
      UploadTaskStatus.uploading,
      UploadTaskStatus.cancelled,
    },
    // failed 可以转换为 uploading（直接重试）、queued（重试时重新入队）、permanentlyFailed（达到最大重试次数）、cancelled（取消）
    // 注意：queued 转换用于 background_downloader 自动重试机制，重试时会先报告 enqueued（映射到 queued）
    UploadTaskStatus.failed: {
      UploadTaskStatus.uploading,
      UploadTaskStatus.queued,  // 允许重试时重新入队
      UploadTaskStatus.permanentlyFailed,
      UploadTaskStatus.cancelled,
    },
    // permanentlyFailed 可以转换为 uploading（用户手动重试）
    UploadTaskStatus.permanentlyFailed: {
      UploadTaskStatus.uploading,
    },
    // 终态不能转换
    UploadTaskStatus.completed: {},
    UploadTaskStatus.cancelled: {},
  };

  UploadTaskStateMachine({
    required AppDatabase database,
  }) : _database = database;

  /// 检查状态转换是否合法
  ///
  /// **参数**：
  /// - [from] - 当前状态
  /// - [to] - 目标状态
  ///
  /// **返回**：bool（是否允许转换）
  bool canTransition(UploadTaskStatus from, UploadTaskStatus to) {
    // 相同状态允许（幂等操作）
    if (from == to) {
      return true;
    }

    final allowed = _allowedTransitions[from];
    if (allowed == null) {
      _logger.warning('Unknown source status: $from');
      return false;
    }

    return allowed.contains(to);
  }

  /// 获取允许的状态转换列表
  ///
  /// **参数**：
  /// - [current] - 当前状态
  ///
  /// **返回**：允许转换到的状态列表
  List<UploadTaskStatus> getAllowedTransitions(UploadTaskStatus current) {
    final allowed = _allowedTransitions[current];
    if (allowed == null) {
      _logger.warning('Unknown status: $current');
      return [];
    }
    return allowed.toList();
  }

  /// 执行状态转换
  ///
  /// **参数**：
  /// - [task] - 任务实体
  /// - [newStatus] - 目标状态
  /// - [errorMessage] - 错误信息（可选，失败状态时使用）
  ///
  /// **返回**：更新后的任务实体
  ///
  /// **异常**：如果转换不合法，会抛出 StateError
  Future<UploadTaskEntityData> transition(
    UploadTaskEntityData task,
    UploadTaskStatus newStatus, {
    String? errorMessage,
  }) async {
    final currentStatus = task.status;

    // 验证状态转换
    if (!canTransition(currentStatus, newStatus)) {
      throw StateError(
        'Invalid state transition: $currentStatus -> $newStatus '
        'for taskId=${task.id}',
      );
    }

    // 如果状态没有变化，直接返回
    if (currentStatus == newStatus) {
      return task;
    }

    // 更新数据库
    final dao = _database.uploadTaskDao;
    DateTime? uploadedAt;

    // 如果转换为 completed，设置 uploadedAt
    if (newStatus == UploadTaskStatus.completed) {
      uploadedAt = DateTime.now();
    }

    final success = await dao.updateTaskStatus(
      task.id,
      newStatus,
      errorMessage: errorMessage,
      uploadedAt: uploadedAt,
    );

    if (!success) {
      throw StateError(
        'Failed to update task status: taskId=${task.id}, '
        '$currentStatus -> $newStatus',
      );
    }

    // 提取文件名（从路径中获取）
    final fileName = task.localPath.split('/').last;
    
    // 记录详细的状态转换日志，包含所有关键信息
    _logger.info(
      'Task status transitioned: '
      'taskId=${task.id}, '
      'assetId=${task.assetId}, '
      'userId=${task.userId}, '
      'filename=$fileName, '
      'taskType=${task.taskType}, '
      'retryCount=${task.retryCount}/${task.maxRetries}, '
      'progress=${task.progress}%, '
      '$currentStatus -> $newStatus'
      '${errorMessage != null ? ", error: $errorMessage" : ""}',
    );

    // 重新获取任务实体（确保数据最新）
    final updatedTask = await dao.getTaskById(task.id);
    if (updatedTask == null) {
      throw StateError('Task not found after status update: taskId=${task.id}');
    }

    return updatedTask;
  }

  /// 批量执行状态转换
  ///
  /// **参数**：
  /// - [tasks] - 任务实体列表
  /// - [newStatus] - 目标状态
  /// - [errorMessage] - 错误信息（可选）
  ///
  /// **返回**：更新后的任务实体列表
  ///
  /// **注意**：如果某个任务转换失败，会记录错误但继续处理其他任务
  Future<List<UploadTaskEntityData>> transitionBatch(
    List<UploadTaskEntityData> tasks,
    UploadTaskStatus newStatus, {
    String? errorMessage,
  }) async {
    final results = <UploadTaskEntityData>[];

    for (final task in tasks) {
      try {
        final updated = await transition(
          task,
          newStatus,
          errorMessage: errorMessage,
        );
        results.add(updated);
      } catch (e, stackTrace) {
        final fileName = task.localPath.split('/').last;
        _logger.warning(
          'Failed to transition task: '
          'taskId=${task.id}, '
          'assetId=${task.assetId}, '
          'filename=$fileName, '
          'currentStatus=${task.status}, '
          'targetStatus=$newStatus, '
          'error=$e',
          e,
          stackTrace,
        );
        // 继续处理其他任务
      }
    }

    return results;
  }
}

