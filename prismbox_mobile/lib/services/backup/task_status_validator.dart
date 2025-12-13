// lib/services/backup/task_status_validator.dart

import 'package:logging/logging.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/enums/upload_task_status.dart';

/// 状态转换验证器
/// 
/// **设计目的**：确保任务状态转换的合法性。
/// 
/// **状态转换图**：
/// ```
/// pending
///   ├─→ uploading（开始上传）
///   └─→ cancelled（用户取消）
///
/// uploading
///   ├─→ completed（上传成功）
///   ├─→ failed（上传失败，可重试）
///   ├─→ permanentlyFailed（达到最大重试次数）
///   └─→ cancelled（用户取消）
///
/// failed
///   ├─→ uploading（重试）
///   ├─→ permanentlyFailed（达到最大重试次数）
///   └─→ cancelled（用户取消）
///
/// permanentlyFailed
///   └─→ uploading（用户手动重试）
///
/// cancelled（终态）
/// completed（终态）
/// ```
class TaskStatusValidator {
  final Logger _logger = Logger('TaskStatusValidator');

  /// 允许的状态转换映射
  static const Map<UploadTaskStatus, List<UploadTaskStatus>> _allowedTransitions = {
    UploadTaskStatus.pending: [
      UploadTaskStatus.uploading,
      UploadTaskStatus.cancelled,
    ],
    UploadTaskStatus.uploading: [
      UploadTaskStatus.completed,
      UploadTaskStatus.failed,
      UploadTaskStatus.permanentlyFailed,
      UploadTaskStatus.cancelled,
    ],
    UploadTaskStatus.failed: [
      UploadTaskStatus.uploading,
      UploadTaskStatus.permanentlyFailed,
      UploadTaskStatus.cancelled,
    ],
    UploadTaskStatus.permanentlyFailed: [
      UploadTaskStatus.uploading, // 用户手动重试
    ],
    // paused 状态（如果支持）
    UploadTaskStatus.paused: [
      UploadTaskStatus.uploading,
      UploadTaskStatus.cancelled,
    ],
    // 终态不能转换
    UploadTaskStatus.completed: [],
    UploadTaskStatus.cancelled: [],
  };

  /// 验证状态转换是否合法
  /// 
  /// **参数**：
  /// - [from] - 当前状态
  /// - [to] - 目标状态
  /// 
  /// **返回**：bool（是否合法）
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

  /// 验证并更新状态（如果转换不合法会抛出异常）
  /// 
  /// **参数**：
  /// - [database] - 数据库实例
  /// - [taskId] - 任务 ID
  /// - [from] - 当前状态
  /// - [to] - 目标状态
  /// 
  /// **异常**：如果转换不合法，会抛出 StateError
  /// 
  /// **使用示例**：
  /// ```dart
  /// // ✅ 正确使用
  /// await TaskStatusValidator().validateAndUpdate(
  ///   database: database,
  ///   taskId: taskId,
  ///   from: UploadTaskStatus.pending,
  ///   to: UploadTaskStatus.uploading,
  /// );
  ///
  /// // ❌ 错误使用（会抛出异常）
  /// await TaskStatusValidator().validateAndUpdate(
  ///   database: database,
  ///   taskId: taskId,
  ///   from: UploadTaskStatus.completed, // 终态不能转换
  ///   to: UploadTaskStatus.uploading,
  /// );
  /// ```
  Future<void> validateAndUpdate({
    required AppDatabase database,
    required String taskId,
    required UploadTaskStatus from,
    required UploadTaskStatus to,
  }) async {
    if (!canTransition(from, to)) {
      throw StateError(
        'Invalid state transition: $from -> $to for taskId=$taskId',
      );
    }

    // 更新状态
    final dao = database.uploadTaskDao;
    await dao.updateTaskStatus(taskId, to);

    _logger.info(
      'Task status updated: taskId=$taskId, $from -> $to',
    );
  }

  /// 验证状态转换（不更新，仅验证）
  /// 
  /// **参数**：
  /// - [from] - 当前状态
  /// - [to] - 目标状态
  /// 
  /// **异常**：如果转换不合法，会抛出 StateError
  void validate(UploadTaskStatus from, UploadTaskStatus to) {
    if (!canTransition(from, to)) {
      throw StateError(
        'Invalid state transition: $from -> $to',
      );
    }
  }
}

