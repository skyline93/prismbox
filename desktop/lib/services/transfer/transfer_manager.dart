// lib/services/transfer/transfer_manager.dart
import 'package:background_downloader/background_downloader.dart';
import '../../core/utils/logger.dart';
import 'download_service.dart';
import 'upload_service.dart';

class TransferManager {
  final DownloadService _downloadService;
  final UploadService _uploadService;

  TransferManager(this._downloadService, this._uploadService);

  void initialize() {
    FileDownloader().updates.listen(_onTaskUpdate);
    logger.i("TransferManager initialized and listening for updates.");
  }

  void _onTaskUpdate(TaskUpdate update) {
    if (update is TaskStatusUpdate) {
      _handleStatusUpdate(update.task, update.status);
    } else if (update is TaskProgressUpdate) {
      _handleProgressUpdate(update.task, update.progress);
    }
  }

  void _handleStatusUpdate(Task task, TaskStatus status) {
    if (task is UploadTask) {
      _uploadService.handleUploadStatusUpdate(task, status);
    } else if (task is DownloadTask) {
      _downloadService.handleDownloadStatusUpdate(task, status);
    } else {
      logger.i(
        'Received status update for an unhandled task type: ${task.runtimeType}',
      );
    }
  }

  void _handleProgressUpdate(Task task, double progress) {
    if (task is UploadTask) {
      _uploadService.handleUploadProgressUpdate(task, progress);
    } else if (task is DownloadTask) {
      _downloadService.handleDownloadProgressUpdate(task, progress);
    } else {
      logger.f(
        'Received progress update for an unhandled task type: ${task.runtimeType}',
      );
    }
  }
}
