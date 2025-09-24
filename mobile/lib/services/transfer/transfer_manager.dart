// lib/services/transfer_manager.dart

import 'package:background_downloader/background_downloader.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:mobile/services/transfer/download_service.dart';
import 'package:mobile/services/transfer/upload_service.dart';

@lazySingleton
class TransferManager {
  final DownloadService _downloadService;
  final UploadService _uploadService;
  final _log = Logger('TransferManager');

  TransferManager(this._downloadService, this._uploadService);

  Future<void> initialize() async {
    // 检查当前的通知权限状态.
    final permissionStatus = await FileDownloader().permissions.status(
      PermissionType.notifications,
    );
    _log.info('Current notification permission status is $permissionStatus');

    // 如果权限不是“已授予”，则向用户发起请求.
    // 这会触发一个系统级别的弹窗.
    if (permissionStatus != PermissionStatus.granted) {
      _log.info('Requesting notification permission from the user...');
      final newStatus = await FileDownloader().permissions.request(
        PermissionType.notifications,
      );
      _log.info('Notification permission status after request: $newStatus');
      // 如果用户拒绝，可以考虑给出提示，但不应强迫.
      if (newStatus != PermissionStatus.granted) {
        _log.warning('User did not grant notification permission.');
      }
    }

    // 1) plugin 配置：使用 record 列表传入 global/android 配置
    final configResult = await FileDownloader().configure(
      globalConfig: [
        // 要在后台显示前台服务通知（Android）时通常设置 runInForeground
        (Config.runInForeground, Config.always),
        // 当文件较大时也可强制前台模式（可选，单位字节）
        (Config.runInForegroundIfFileLargerThan, 5 * 1024 * 1024),
      ],
      androidConfig: [
        // 本地化通知 channel 名称/描述（可选）
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
        // Android 平台也再次确保运行前台服务
        (Config.runInForeground, Config.always),
      ],
    );
    _log.info('FileDownloader.configure returned: $configResult');

    // 2) 通用的通知样式（影响所有任务 / 除非单独为 group/task 覆盖）
    FileDownloader().configureNotification(
      running: TaskNotification('传输中', '{displayName} — {progress}'),
      complete: TaskNotification('传输完成', '{displayName}'),
      error: TaskNotification('传输失败', '{displayName}'),
      paused: TaskNotification('已暂停', '{displayName}'),
      canceled: TaskNotification('已取消', '{displayName}'),
      progressBar: true,
      // tapOpensFile: false // 若希望点击由自己处理，可设为 false 并注册回调
    );

    // 3) 注册通知点击回调（可选：点击通知打开文件或打开 app 的特定页面）
    FileDownloader().registerCallbacks(
      taskNotificationTapCallback: (task, type) async {
        _log.info('通知被点击: taskId=${task.taskId}, type=$type');
        try {
          if (type == NotificationType.complete) {
            // 尝试打开文件（可根据需要改成跳转到 app 页面）
            await FileDownloader().openFile(task: task);
          }
        } catch (e) {
          _log.warning('打开文件失败: $e');
        }
      },
    );

    // 4) 启动并监听更新（start 需要在 configure/notification 后启动）
    await FileDownloader().start();
    FileDownloader().updates.listen(_onTaskUpdate);
    _log.info("TransferManager initialized and listening for updates.");
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
