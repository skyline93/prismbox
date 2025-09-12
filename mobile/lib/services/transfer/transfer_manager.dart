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
    await FileDownloader().configure(
      androidConfig: [('logLevel', 'verbose'), ('network', 'any')],
    );
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
        _downloadService.handleDownloadStatusUpdate(task, status);
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
