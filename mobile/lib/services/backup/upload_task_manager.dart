// lib/services/backup/upload_task_manager.dart

import 'dart:convert';
import 'dart:io';
import 'package:background_downloader/background_downloader.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/enums/upload_task_status.dart';
import 'package:prismbox/services/backup/upload_task_state_machine.dart';
import 'package:prismbox/services/backup/error_handler.dart';

/// 上传任务组常量
class UploadTaskGroup {
  static const String manual = 'prismbox_upload_manual';
  static const String auto = 'prismbox_upload_auto';
}

/// 上传任务管理器
///
/// **职责**：
/// - 配置 background_downloader
/// - 注册状态和进度回调
/// - 创建和入队上传任务
class UploadTaskManager {
  final AppDatabase _database;
  final UploadTaskStateMachine _stateMachine;
  final BackupErrorHandler _errorHandler; // 必需，用于统一错误处理
  final Logger _logger = Logger('UploadTaskManager');

  // 回调函数
  void Function(String taskId, TaskStatus status)? onStatusChange;
  void Function(String taskId, double progress)? onProgress;

  UploadTaskManager({
    required AppDatabase database,
    required UploadTaskStateMachine stateMachine,
    required BackupErrorHandler errorHandler,
  })  : _database = database,
        _stateMachine = stateMachine,
        _errorHandler = errorHandler;

  /// 初始化 FileDownloader 配置
  ///
  /// **配置项**：
  /// - 最大并发数：6
  /// - 每个主机最大并发数：6
  /// - 每个组最大并发数：3
  /// - Android 大文件（>256MB）在前台服务运行
  Future<void> initialize({
    void Function(String taskId, TaskStatus status)? onStatusChange,
    void Function(String taskId, double progress)? onProgress,
  }) async {
    this.onStatusChange = onStatusChange;
    this.onProgress = onProgress;

    // 配置 FileDownloader
    await FileDownloader().configure(
      globalConfig: [
        // maxConcurrent: 6, maxConcurrentByHost: 6, maxConcurrentByGroup: 3
        (Config.holdingQueue, (6, 6, 3)),
        // Android 大文件（>256MB）在前台服务运行
        (Config.runInForegroundIfFileLargerThan, 256),
      ],
    );

    // 注册回调
    await FileDownloader().registerCallbacks(
      group: UploadTaskGroup.manual,
      taskStatusCallback: _handleStatusUpdate,
      taskProgressCallback: _handleProgressUpdate,
    );

    await FileDownloader().registerCallbacks(
      group: UploadTaskGroup.auto,
      taskStatusCallback: _handleStatusUpdate,
      taskProgressCallback: _handleProgressUpdate,
    );

    // 开始跟踪任务
    await FileDownloader().trackTasks();

    _logger.info('UploadTaskManager initialized');
  }

  /// 处理状态更新
  void _handleStatusUpdate(TaskStatusUpdate update) {
    final taskId = update.task.taskId;
    final status = update.status;
    final group = update.task.group;

    // 异步获取任务详细信息用于日志记录
    _database.uploadTaskDao.getTaskById(taskId).then((task) {
      if (task != null) {
        final fileName = task.localPath.split('/').last;
        _logger.info(
          'Task status update from background_downloader: '
          'taskId=$taskId, '
          'assetId=${task.assetId}, '
          'userId=${task.userId}, '
          'filename=$fileName, '
          'status=$status, '
          'group=$group, '
          'currentDbStatus=${task.status}',
        );
      } else {
    _logger.info(
          'Task status update from background_downloader: '
          'taskId=$taskId, status=$status, group=$group (task not found in DB)',
        );
      }
    }).catchError((e) {
      _logger.warning(
        'Failed to get task info for logging: taskId=$taskId, error=$e',
    );
    });

    // 如果是失败状态，提取详细的错误信息
    String? errorMessage;
    if (status == TaskStatus.failed) {
      errorMessage = _extractErrorMessage(update);
      
      _logger.warning(
        'Upload task failed: taskId=$taskId, '
        'errorMessage=$errorMessage, '
        'exception=${update.exception}, '
        'responseStatusCode=${update.responseStatusCode}, '
        'responseBody=${update.responseBody}',
      );
    } else if (status == TaskStatus.complete) {
      // 记录成功信息
      _logger.info(
        'Upload task completed: taskId=$taskId, '
        'responseStatusCode=${update.responseStatusCode}, '
        'responseBody=${update.responseBody?.substring(0, update.responseBody!.length.clamp(0, 200))}',
      );
    } else if (status == TaskStatus.waitingToRetry) {
      // 记录重试信息
      _logger.warning(
        'Upload task waiting to retry: taskId=$taskId, '
        'exception=${update.exception}',
      );
    }

    onStatusChange?.call(taskId, status);

    // 更新数据库中的任务状态（包含错误信息）
    _updateTaskStatus(taskId, status, errorMessage: errorMessage).catchError((error) {
      _logger.warning(
        'Failed to update task status: taskId=$taskId, error=$error',
      );
    });
  }

  /// 从 TaskStatusUpdate 中提取错误信息
  String? _extractErrorMessage(TaskStatusUpdate update) {
    if (update.exception == null) {
      return 'Unknown error: No exception information available';
    }

    final exception = update.exception!;
    String? errorMessage;

    try {
      // 如果是 HTTP 异常，提取详细信息
      if (exception is TaskHttpException) {
        final httpException = exception;
        
        // 尝试解析 JSON 错误响应
        final description = httpException.description;
        if (description.isNotEmpty) {
          try {
            final json = jsonDecode(description) as Map<String, dynamic>?;
            errorMessage = json?['message'] as String? ?? 
                          json?['error'] as String? ?? 
                          description;
          } catch (_) {
            // 如果不是 JSON，直接使用描述
            errorMessage = description;
          }
        }
        
        // 添加 HTTP 状态码和异常类型信息
        final statusCode = httpException.httpResponseCode;
        final exceptionType = httpException.exceptionType;
        
        // 构建错误消息
        if (errorMessage == null || errorMessage.isEmpty) {
          errorMessage = 'Unknown error';
        }
        
        // 添加状态码和异常类型
        errorMessage = 'HTTP $statusCode ($exceptionType): $errorMessage';
        
        // 如果有响应体，也记录（responseBody 可能为 null）
        final responseBody = update.responseBody;
        if (responseBody != null && responseBody.isNotEmpty) {
          try {
            final responseJson = jsonDecode(responseBody) as Map<String, dynamic>?;
            final responseMessage = responseJson?['message'] as String? ?? 
                                   responseJson?['error'] as String?;
            if (responseMessage != null) {
              errorMessage = '$errorMessage (Response: $responseMessage)';
            }
          } catch (_) {
            // 忽略 JSON 解析错误
          }
        }
      } else {
        // 其他类型的异常
        errorMessage = exception.toString();
      }
    } catch (e) {
      _logger.warning('Failed to extract error message: $e');
      errorMessage = exception.toString();
    }

    return errorMessage;
  }

  /// 处理进度更新
  void _handleProgressUpdate(TaskProgressUpdate update) {
    final taskId = update.task.taskId;
    final progress = update.progress;

    // 记录详细的进度信息
    _logger.fine(
      'Task progress update: taskId=$taskId, '
      'progress=$progress, '
      'expectedFileSize=${update.expectedFileSize}, '
      'networkSpeed=${update.networkSpeed}',
    );

    // 特殊进度值处理（background_downloader 的特殊值）
    // -1.0 表示完成，-2.0 表示失败，-4.0 表示等待重试
    if (progress == -2.0) {
      _logger.warning('Task progress indicates failure: taskId=$taskId');
    } else if (progress == -1.0) {
      _logger.info('Task progress indicates completion: taskId=$taskId');
    } else if (progress == -4.0) {
      _logger.warning('Task progress indicates waiting to retry: taskId=$taskId');
    }

    onProgress?.call(taskId, progress);

    // 更新数据库中的任务进度
    _updateTaskProgress(taskId, progress).catchError((error) {
      // 使用统一的错误处理器记录错误
      final backupError = _errorHandler.handleError(
        error,
        context: 'upload_task_manager_progress_update',
      );
      _logger.warning(
        'Failed to update task progress: taskId=$taskId, '
        'errorType=${backupError.type}, errorMessage=${backupError.message}',
      );
    });
  }

  /// 更新数据库中的任务状态
  Future<void> _updateTaskStatus(
    String taskId, 
    TaskStatus status, {
    String? errorMessage,
  }) async {
    final task = await _database.uploadTaskDao.getTaskById(taskId);
    if (task == null) {
      _logger.warning('Task not found: taskId=$taskId');
      return;
    }

    UploadTaskStatus newStatus;

    switch (status) {
      case TaskStatus.enqueued:
        // enqueued 状态映射到 queued，保持状态流转的完整性
        newStatus = UploadTaskStatus.queued;
        
        // 特殊处理：如果 background_downloader 报告 enqueued（映射到 queued），
        // 但当前状态已经是 uploading 或终态（completed, permanentlyFailed），
        // 说明这是重试时的重新入队，但状态不应该回退，应该忽略这个状态更新
        // 注意：如果当前状态是 failed，允许 failed -> queued（状态机已支持，用于重试）
        if (task.status == UploadTaskStatus.uploading ||
            task.status == UploadTaskStatus.completed ||
            task.status == UploadTaskStatus.permanentlyFailed) {
          _logger.fine(
            'Ignoring enqueued status update for retry: taskId=$taskId, '
            'currentStatus=${task.status}, this is a retry re-enqueue',
          );
          return;
        }
        break;
      case TaskStatus.running:
        // running 状态映射到 uploading
        newStatus = UploadTaskStatus.uploading;
        break;
      case TaskStatus.complete:
        newStatus = UploadTaskStatus.completed;
        // uploadedAt 由状态机自动设置
        break;
      case TaskStatus.failed:
        newStatus = UploadTaskStatus.failed;
        break;
      case TaskStatus.waitingToRetry:
        // waitingToRetry 明确表示失败后的重试等待，应该映射为 failed
        // 这样重试时可以从 failed -> queued -> uploading（合法转换）
        newStatus = UploadTaskStatus.failed;
        errorMessage ??= 'Upload failed, waiting to retry';
        break;
      case TaskStatus.canceled:
        newStatus = UploadTaskStatus.cancelled;
        break;
      case TaskStatus.notFound:
      case TaskStatus.paused:
        // 保持原状态（这些状态不需要更新数据库状态）
        return;
    }

    // 如果状态改变，或者有新的错误信息，通过状态机更新数据库
    if (task.status != newStatus || 
        (errorMessage != null && task.errorMessage != errorMessage)) {
      try {
        await _stateMachine.transition(
          task,
          newStatus,
          errorMessage: errorMessage,
        );
        
        // 记录详细的状态更新日志（状态机内部已记录详细日志，这里记录额外的上下文信息）
        final fileName = task.localPath.split('/').last;
        _logger.info(
          'Task status updated via state machine: '
          'taskId=$taskId, '
          'assetId=${task.assetId}, '
          'filename=$fileName, '
          'from=${task.status} -> to=$newStatus'
          '${errorMessage != null ? ", error: $errorMessage" : ""}',
        );
      } catch (e, stackTrace) {
        // 使用统一的错误处理器记录错误
        final error = _errorHandler.handleError(
          e,
          context: 'upload_task_manager_status_update',
        );
        _logger.warning(
          'Failed to update task status via state machine: taskId=$taskId, '
          'errorType=${error.type}, errorMessage=${error.message}',
          e,
          stackTrace,
        );
        // 如果状态机转换失败，记录错误但不抛出异常，避免影响回调流程
      }
    }
  }

  /// 更新数据库中的任务进度
  Future<void> _updateTaskProgress(String taskId, double progress) async {
    final task = await _database.uploadTaskDao.getTaskById(taskId);
    if (task == null) {
      return;
    }

    final progressInt = (progress * 100).round();
    if (task.progress != progressInt) {
      await _database.uploadTaskDao.updateTaskProgress(taskId, progressInt);
    }
  }

  /// 创建上传任务
  ///
  /// **参数**：
  /// - [taskId] - 任务 ID（对应数据库中的 UploadTaskEntityData.id）
  /// - [filePath] - 本地文件路径
  /// - [url] - 上传 URL
  /// - [headers] - 请求头
  /// - [fields] - 表单字段（如 hash, deviceAssetId 等）
  /// - [group] - 任务组（manual 或 auto）
  ///
  /// **返回**：UploadTask
  UploadTask createUploadTask({
    required String taskId,
    required String filePath,
    required String url,
    Map<String, String>? headers,
    Map<String, String>? fields,
    required String group,
  }) {
    final file = File(filePath);

    // 构建请求头
    final requestHeaders = <String, String>{...?headers};

    // 构建表单字段
    final formFields = <String, String>{...?fields};

    // 创建上传任务
    // 注意：使用 UploadTask.fromFile() 指定实际文件路径，而不是只传文件名
    // 否则 background_downloader 会尝试在应用内部存储中查找文件，导致文件不存在错误
    final task = UploadTask.fromFile(
      file: file, // 指定实际文件路径
      url: url,
      fileField: 'file',
      fields: formFields.isNotEmpty ? formFields : null,
      headers: requestHeaders.isNotEmpty ? requestHeaders : null,
      group: group,
      taskId: taskId,
      updates: Updates.statusAndProgress,
      // 允许重试
      retries: 3,
    );

    return task;
  }

  /// 入队上传任务
  ///
  /// **参数**：
  /// - [task] - 上传任务
  ///
  /// **返回**：是否成功入队
  Future<bool> enqueueTask(UploadTask task) async {
    try {
      await FileDownloader().enqueue(task);
      _logger.info('Task enqueued: taskId=${task.taskId}');
      return true;
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to enqueue task: taskId=${task.taskId}, error=$e',
        e,
        stackTrace,
      );
      return false;
    }
  }

  /// 批量入队上传任务
  ///
  /// **参数**：
  /// - [tasks] - 上传任务列表
  ///
  /// **返回**：每个任务的入队结果（true 表示成功）
  Future<List<bool>> enqueueTasks(List<UploadTask> tasks) async {
    try {
      final results = await FileDownloader().enqueueAll(tasks);
      _logger.info(
        'Tasks enqueued: total=${tasks.length}, '
        'success=${results.where((r) => r).length}',
      );
      return results;
    } catch (e, stackTrace) {
      _logger.warning('Failed to enqueue tasks: error=$e', e, stackTrace);
      return List.filled(tasks.length, false);
    }
  }

  /// 取消任务
  ///
  /// **参数**：
  /// - [taskId] - 任务 ID
  ///
  /// **返回**：是否成功取消
  ///
  /// **注意**：需要先获取任务对象，然后取消
  Future<bool> cancelTask(String taskId) async {
    try {
      // 通过组取消所有任务，或通过数据库查找任务
      // 注意：background_downloader 的 cancel 方法需要 Task 对象
      // 这里简化实现，实际使用时需要根据 background_downloader 的 API 调整
      _logger.warning('cancelTask not fully implemented, taskId=$taskId');
      return false;
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to cancel task: taskId=$taskId, error=$e',
        e,
        stackTrace,
      );
      return false;
    }
  }

  /// 取消组内所有任务
  ///
  /// **参数**：
  /// - [group] - 任务组
  ///
  /// **返回**：是否成功取消
  Future<bool> cancelGroup(String group) async {
    try {
      final result = await FileDownloader().cancelAll(group: group);
      _logger.info('Group cancelled: group=$group, result=$result');
      return result;
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to cancel group: group=$group, error=$e',
        e,
        stackTrace,
      );
      return false;
    }
  }

  /// 暂停任务
  ///
  /// **参数**：
  /// - [taskId] - 任务 ID
  ///
  /// **返回**：是否成功暂停
  ///
  /// **注意**：需要先获取任务对象，然后调用 pause
  Future<bool> pauseTask(String taskId) async {
    try {
      // 通过数据库查找任务，然后暂停
      // 注意：background_downloader 的 pause 方法需要 Task 对象
      // 这里简化实现，实际使用时需要根据 background_downloader 的 API 调整
      _logger.warning('pauseTask not fully implemented, taskId=$taskId');
      return false;
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to pause task: taskId=$taskId, error=$e',
        e,
        stackTrace,
      );
      return false;
    }
  }

  /// 恢复任务
  ///
  /// **参数**：
  /// - [taskId] - 任务 ID
  ///
  /// **返回**：是否成功恢复
  ///
  /// **注意**：需要先获取任务对象，然后调用 resume
  Future<bool> resumeTask(String taskId) async {
    try {
      // 通过数据库查找任务，然后恢复
      // 注意：background_downloader 的 resume 方法需要 Task 对象
      // 这里简化实现，实际使用时需要根据 background_downloader 的 API 调整
      _logger.warning('resumeTask not fully implemented, taskId=$taskId');
      return false;
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to resume task: taskId=$taskId, error=$e',
        e,
        stackTrace,
      );
      return false;
    }
  }
}
