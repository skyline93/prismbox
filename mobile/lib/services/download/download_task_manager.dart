// lib/services/download/download_task_manager.dart

import 'package:background_downloader/background_downloader.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/enums/download_task_status.dart';
import 'package:prismbox/services/download/download_task_state_machine.dart';
import 'package:prismbox/services/download/download_save_to_album.dart';

/// 下载任务组
class DownloadTaskGroup {
  static const String prismboxDownload = 'prismbox_download';
}

/// 下载任务管理器：配置 FileDownloader、创建 DownloadTask、enqueue、注册回调，完成后触发后处理
class DownloadTaskManager {
  final AppDatabase _database;
  final DownloadTaskStateMachine _stateMachine;
  final DownloadSaveToAlbum _saveToAlbum;
  final Logger _logger = Logger('DownloadTaskManager');

  DownloadTaskManager({
    required AppDatabase database,
    required DownloadTaskStateMachine stateMachine,
    required DownloadSaveToAlbum saveToAlbum,
  })  : _database = database,
        _stateMachine = stateMachine,
        _saveToAlbum = saveToAlbum;

  /// 初始化：注册 prismbox_download 组回调
  Future<void> initialize() async {
    FileDownloader().registerCallbacks(
      group: DownloadTaskGroup.prismboxDownload,
      taskStatusCallback: _handleStatusUpdate,
      taskProgressCallback: _handleProgressUpdate,
    );
    FileDownloader().trackTasks();
    _logger.info('DownloadTaskManager initialized');
  }

  void _handleStatusUpdate(TaskStatusUpdate update) {
    final taskId = update.task.taskId;
    final status = update.status;

    _database.downloadTaskDao.getTaskById(_entityIdFromTaskId(taskId)).then(
      (entity) async {
        if (entity == null) {
          _logger.warning(
            'Download status update: entity not found for taskId=$taskId',
          );
          return;
        }
        await _applyStatusUpdate(entity, taskId, status, update);
      },
    ).catchError((e) {
      _logger.warning('Download status update error: taskId=$taskId, $e');
    });
  }

  /// taskId 格式：entityId 或 entityId_image / entityId_video
  String _entityIdFromTaskId(String taskId) {
    if (taskId.endsWith('_image')) {
      return taskId.substring(0, taskId.length - 6);
    }
    if (taskId.endsWith('_video')) {
      return taskId.substring(0, taskId.length - 6);
    }
    return taskId;
  }

  Future<void> _applyStatusUpdate(
    DownloadTaskEntityData entity,
    String taskId,
    TaskStatus status,
    TaskStatusUpdate update,
  ) async {
    final isImageTask = taskId.endsWith('_image');
    final isVideoTask = taskId.endsWith('_video');

    switch (status) {
      case TaskStatus.enqueued:
        try {
          await _stateMachine.transition(
            entity,
            DownloadTaskStatus.queued,
          );
        } catch (e) {
          _logger.warning('Transition to queued failed: $e');
        }
        break;
      case TaskStatus.running:
        try {
          await _stateMachine.transition(
            entity,
            DownloadTaskStatus.downloading,
          );
        } catch (e) {
          _logger.warning('Transition to downloading failed: $e');
        }
        break;
      case TaskStatus.complete:
        await _onDownloadComplete(
          entity,
          taskId,
          isImageTask,
          isVideoTask,
          update.task,
        );
        break;
      case TaskStatus.failed:
        final msg = update.exception?.toString() ?? 'Download failed';
        try {
          await _stateMachine.transition(
            entity,
            DownloadTaskStatus.failed,
            errorMessage: msg,
          );
        } catch (e) {
          _logger.warning('Transition to failed: $e');
        }
        break;
      case TaskStatus.canceled:
        try {
          await _stateMachine.transition(
            entity,
            DownloadTaskStatus.cancelled,
          );
        } catch (e) {
          _logger.warning('Transition to cancelled: $e');
        }
        break;
      default:
        break;
    }
  }

  Future<void> _onDownloadComplete(
    DownloadTaskEntityData entity,
    String taskId,
    bool isImageTask,
    bool isVideoTask,
    Task task,
  ) async {
    String? filePath;
    try {
      filePath = await task.filePath();
    } catch (e) {
      _logger.warning('Failed to get filePath for taskId=$taskId: $e');
    }
    if (filePath == null || filePath.isEmpty) {
      await _stateMachine.transition(
        entity,
        DownloadTaskStatus.failed,
        errorMessage: 'Could not get downloaded file path',
      );
      return;
    }

    if (isImageTask) {
      await _database.downloadTaskDao.updateTempPath(
        entity.id,
        imageTempPath: filePath,
      );
    } else if (isVideoTask) {
      await _database.downloadTaskDao.updateTempPath(
        entity.id,
        videoTempPath: filePath,
      );
    } else {
      if (entity.itemType == 'VIDEO') {
        await _database.downloadTaskDao.updateTempPath(
          entity.id,
          videoTempPath: filePath,
        );
      } else {
        await _database.downloadTaskDao.updateTempPath(
          entity.id,
          imageTempPath: filePath,
        );
      }
    }

    final updated = await _database.downloadTaskDao.getTaskById(entity.id);
    if (updated == null) return;

    final hasLiveVideo = updated.livePhotoVideoUuid != null &&
        updated.livePhotoVideoUuid!.isNotEmpty;
    if (hasLiveVideo) {
      if (updated.imageTempPath != null && updated.videoTempPath != null) {
        await _runPostProcessing(updated);
      }
    } else {
      await _runPostProcessing(updated);
    }
  }

  Future<void> _runPostProcessing(DownloadTaskEntityData entity) async {
    try {
      await _stateMachine.transition(
        entity,
        DownloadTaskStatus.processing,
      );
    } catch (e) {
      _logger.warning('Transition to processing failed: $e');
      return;
    }

    final updated = await _database.downloadTaskDao.getTaskById(entity.id);
    if (updated == null) return;

    final hasPermission = await _saveToAlbum.requestPermission();
    if (!hasPermission) {
      await _stateMachine.transition(
        updated,
        DownloadTaskStatus.failed,
        errorMessage: '相册权限未授予',
      );
      await _saveToAlbum.deleteTempFiles(updated);
      return;
    }

    final error = await _saveToAlbum.saveToAlbum(updated);
    await _saveToAlbum.deleteTempFiles(updated);

    if (error != null) {
      await _stateMachine.transition(
        updated,
        DownloadTaskStatus.failed,
        errorMessage: error,
      );
    } else {
      await _stateMachine.transition(updated, DownloadTaskStatus.completed);
    }
  }

  void _handleProgressUpdate(TaskProgressUpdate update) {
    final taskId = update.task.taskId;
    final progress = (update.progress * 100).round().clamp(0, 100);
    final entityId = _entityIdFromTaskId(taskId);
    _database.downloadTaskDao.updateTaskProgress(entityId, progress).catchError(
      (e) {
        _logger.warning('Update progress failed: taskId=$taskId, $e');
        return false;
      },
    );
  }

  /// 创建下载任务
  DownloadTask createDownloadTask({
    required String taskId,
    required String url,
    required String filename,
    Map<String, String>? headers,
  }) {
    return DownloadTask(
      url: url,
      taskId: taskId,
      filename: filename,
      headers: headers,
      directory: 'prismbox_download',
      baseDirectory: BaseDirectory.temporary,
      group: DownloadTaskGroup.prismboxDownload,
      updates: Updates.statusAndProgress,
      retries: 3,
    );
  }

  Future<bool> enqueueTask(DownloadTask task) async {
    try {
      await FileDownloader().enqueue(task);
      _logger.info('Download task enqueued: taskId=${task.taskId}');
      return true;
    } catch (e, stack) {
      _logger.warning(
        'Failed to enqueue download task: taskId=${task.taskId}, $e',
        e,
        stack,
      );
      return false;
    }
  }

  Future<List<bool>> enqueueTasks(List<DownloadTask> tasks) async {
    try {
      final results = await FileDownloader().enqueueAll(tasks);
      _logger.info(
        'Download tasks enqueued: ${tasks.length}, '
        'success=${results.where((r) => r).length}',
      );
      return results;
    } catch (e, stack) {
      _logger.warning('Failed to enqueue download tasks: $e', e, stack);
      return List.filled(tasks.length, false);
    }
  }
}
