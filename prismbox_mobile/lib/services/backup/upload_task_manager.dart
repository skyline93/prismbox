// lib/services/backup/upload_task_manager.dart

import 'dart:io';
import 'package:background_downloader/background_downloader.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/enums/upload_task_status.dart';
import 'package:prismbox/infrastructure/api/api_service.dart';

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
  final ApiService _apiService;
  final Logger _logger = Logger('UploadTaskManager');

  // 回调函数
  void Function(String taskId, TaskStatus status)? onStatusChange;
  void Function(String taskId, double progress)? onProgress;

  UploadTaskManager({required AppDatabase database, ApiService? apiService})
    : _database = database,
      _apiService = apiService ?? ApiService();

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

    _logger.fine(
      'Task status update: taskId=$taskId, '
      'status=$status, group=$group',
    );

    onStatusChange?.call(taskId, status);

    // 更新数据库中的任务状态
    _updateTaskStatus(taskId, status).catchError((error) {
      _logger.warning(
        'Failed to update task status: taskId=$taskId, error=$error',
      );
    });
  }

  /// 处理进度更新
  void _handleProgressUpdate(TaskProgressUpdate update) {
    final taskId = update.task.taskId;
    final progress = update.progress;

    _logger.fine(
      'Task progress update: taskId=$taskId, '
      'progress=$progress',
    );

    onProgress?.call(taskId, progress);

    // 更新数据库中的任务进度
    _updateTaskProgress(taskId, progress).catchError((error) {
      _logger.warning(
        'Failed to update task progress: taskId=$taskId, error=$error',
      );
    });
  }

  /// 更新数据库中的任务状态
  Future<void> _updateTaskStatus(String taskId, TaskStatus status) async {
    final task = await _database.uploadTaskDao.getTaskById(taskId);
    if (task == null) {
      _logger.warning('Task not found: taskId=$taskId');
      return;
    }

    UploadTaskStatus newStatus;
    DateTime? uploadedAt;

    switch (status) {
      case TaskStatus.enqueued:
      case TaskStatus.running:
        newStatus = UploadTaskStatus.uploading;
        break;
      case TaskStatus.complete:
        newStatus = UploadTaskStatus.completed;
        uploadedAt = DateTime.now();
        break;
      case TaskStatus.failed:
        newStatus = UploadTaskStatus.failed;
        break;
      case TaskStatus.canceled:
        newStatus = UploadTaskStatus.cancelled;
        break;
      case TaskStatus.notFound:
      case TaskStatus.paused:
      default:
        // 保持原状态
        return;
    }

    if (task.status != newStatus) {
      await _database.uploadTaskDao.updateTaskStatus(
        taskId,
        newStatus,
        uploadedAt: uploadedAt,
      );
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
