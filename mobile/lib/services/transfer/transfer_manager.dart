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
    // 配置并启动 FileDownloader
    await FileDownloader().configure(
      androidConfig: [('logLevel', 'verbose'), ('network', 'any')],
    );
    await FileDownloader().start();
    // 监听所有任务更新
    FileDownloader().updates.listen(_onTaskUpdate);
    _log.info("TransferManager initialized and listening for updates.");
  }

  void _onTaskUpdate(dynamic update) {
    switch (update) {
      case TaskStatusUpdate():
        final task = update.task;
        final status = update.status;
        // [修改] 从 update 对象中提取 exception
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

  // [修改] 方法签名增加了 TaskException? exception 参数
  void _handleStatusUpdate(
    Task task,
    TaskStatus status,
    TaskException? exception,
  ) {
    switch (task) {
      case DownloadTask():
        // 注意：这里我们假设 DownloadService 中的方法也将被更新以接收 exception 参数。
        // 您可能需要对 download_service.dart 进行类似的修改。
        _downloadService.handleDownloadStatusUpdate(task, status);
        break;
      case UploadTask():
        // [修改] 将 exception 参数传递给 UploadService
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

  // 公开方法可以保持在这里，或者直接通过 service locator 调用具体的 service
  // 为了更好的职责分离，建议在UI层直接注入并调用 DownloadService 或 UploadService
  // 这里为了平滑迁移，暂时保留代理方法

  DownloadService get downloadService => _downloadService;
  UploadService get uploadService => _uploadService;
}
