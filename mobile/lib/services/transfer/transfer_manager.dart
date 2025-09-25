import 'package:background_downloader/background_downloader.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:mobile/services/settings_service.dart'; // <-- 1. 导入 SettingsService
import 'package:mobile/services/transfer/download_service.dart';
import 'package:mobile/services/transfer/upload_service.dart';

@lazySingleton
class TransferManager {
  final DownloadService _downloadService;
  final UploadService _uploadService;
  final SettingsService _settingsService; // <-- 2. 添加 SettingsService 依赖
  final _log = Logger('TransferManager');

  final _downloader = FileDownloader();
  final _downloadQueue = MemoryTaskQueue();
  final _uploadQueue = MemoryTaskQueue();

  // <-- 3. 更新构造函数以接收 SettingsService
  TransferManager(
    this._downloadService,
    this._uploadService,
    this._settingsService,
  );

  Future<void> initialize() async {
    // --- START MODIFICATION ---
    // 1) 从 SettingsService 获取并发限制配置
    final initialDownloadLimit = await _settingsService
        .getMaxConcurrentDownloads();
    final initialUploadLimit = await _settingsService.getMaxConcurrentUploads();

    // 使用获取到的配置初始化队列
    _downloadQueue.maxConcurrent = initialDownloadLimit;
    _uploadQueue.maxConcurrent = initialUploadLimit;
    _log.info(
      'Task queues configured: Downloads maxConcurrent=$initialDownloadLimit, Uploads maxConcurrent=$initialUploadLimit',
    );
    // --- END MODIFICATION ---

    // 2) 将队列注册到下载器... (后续代码不变)
    _downloader.addTaskQueue(_downloadQueue);
    _downloader.addTaskQueue(_uploadQueue);

    // 3) 将队列实例传递给对应的服务
    _downloadService.setTaskQueue(_downloadQueue);
    _uploadService.setTaskQueue(_uploadQueue);
    _log.info('Task queues have been set for Download and Upload services.');

    // ... (文件的其余部分保持不变) ...
    final permissionStatus = await _downloader.permissions.status(
      PermissionType.notifications,
    );
    _log.info('Current notification permission status is $permissionStatus');

    if (permissionStatus != PermissionStatus.granted) {
      _log.info('Requesting notification permission from the user...');
      final newStatus = await _downloader.permissions.request(
        PermissionType.notifications,
      );
      _log.info('Notification permission status after request: $newStatus');
      if (newStatus != PermissionStatus.granted) {
        _log.warning('User did not grant notification permission.');
      }
    }

    final configResult = await _downloader.configure(
      globalConfig: [
        (Config.runInForeground, Config.always),
        (Config.runInForegroundIfFileLargerThan, 5 * 1024 * 1024),
      ],
      androidConfig: [
        (
          Config.localize,
          {
            'bg_downloader_notification_channel_name': '文件传输',
            'bg_downloader_notification_channel_description': '后台上传/下载任务',
            'bg_downloader_cancel': '取消',
            'bg_downloader_pause': '暂停',
            'bg_downloader_resume': '继续',
          },
        ),
        (Config.runInForeground, Config.always),
      ],
    );
    _log.info('FileDownloader.configure returned: $configResult');

    _downloader.configureNotification(
      running: TaskNotification('传输中', '{displayName} — {progress}'),
      complete: TaskNotification('传输完成', '{displayName}'),
      error: TaskNotification('传输失败', '{displayName}'),
      paused: TaskNotification('已暂停', '{displayName}'),
      canceled: TaskNotification('已取消', '{displayName}'),
      progressBar: true,
    );

    _downloader.registerCallbacks(
      taskNotificationTapCallback: (task, type) async {
        _log.info('通知被点击: taskId=${task.taskId}, type=$type');
        try {
          if (type == NotificationType.complete) {
            await _downloader.openFile(task: task);
          }
        } catch (e) {
          _log.warning('打开文件失败: $e');
        }
      },
    );

    await _downloader.start();
    _downloader.updates.listen(_onTaskUpdate);
    _log.info("TransferManager initialized and listening for updates.");
  }

  /// 动态更新上传和下载的并发限制
  void updateConcurrencyLimits({int? downloadLimit, int? uploadLimit}) {
    if (downloadLimit != null) {
      final oldLimit = _downloadQueue.maxConcurrent;
      _downloadQueue.maxConcurrent = downloadLimit;
      _log.info(
        'Download concurrency limit changed from $oldLimit to $downloadLimit',
      );
      if (downloadLimit > oldLimit) {
        _downloadQueue.advanceQueue();
      }
    }

    if (uploadLimit != null) {
      final oldLimit = _uploadQueue.maxConcurrent;
      _uploadQueue.maxConcurrent = uploadLimit;
      _log.info(
        'Upload concurrency limit changed from $oldLimit to $uploadLimit',
      );
      if (uploadLimit > oldLimit) {
        _uploadQueue.advanceQueue();
      }
    }
  }

  void _onTaskUpdate(dynamic update) {
    switch (update) {
      case TaskStatusUpdate():
        final task = update.task;
        final status = update.status;
        final exception = update.exception;
        _handleStatusUpdate(task, status, exception);
        break;
      case TaskProgressUpdate():
        final task = update.task;
        final progress = update.progress;
        _handleProgressUpdate(task, progress);
        break;
      default:
        _log.fine('Received an unhandled update type: ${update.runtimeType}');
    }
  }

  void _handleStatusUpdate(
    Task task,
    TaskStatus status,
    TaskException? exception,
  ) {
    switch (task) {
      case DownloadTask():
        _downloadService.handleDownloadStatusUpdate(task, status, exception);
        break;
      case UploadTask():
        _uploadService.handleUploadStatusUpdate(task, status, exception);
        break;
      default:
        _log.info(
          'Received status update for an unhandled task type: ${task.runtimeType}',
        );
    }
  }

  void _handleProgressUpdate(Task task, double progress) {
    switch (task) {
      case DownloadTask():
        _downloadService.handleDownloadProgressUpdate(task, progress);
        break;
      case UploadTask():
        _uploadService.handleUploadProgressUpdate(task, progress);
        break;
      default:
        _log.finer(
          'Received progress update for an unhandled task type: ${task.runtimeType}',
        );
    }
  }

  DownloadService get downloadService => _downloadService;
  UploadService get uploadService => _uploadService;
}
