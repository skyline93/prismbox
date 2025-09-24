// lib/services/transfer/download_service.dart
import 'package:background_downloader/background_downloader.dart';
import '../../core/utils/logger.dart';
import '../../data/datasources/local/app_database.dart';
import '../../state/transfer_state.dart';

class DownloadService {
  final TransferStateNotifier _transferStateNotifier;

  DownloadService({required TransferStateNotifier transferStateNotifier})
    : _transferStateNotifier = transferStateNotifier;

  Future<void> startDownloads(
    List<MediaAsset> assets,
    String directoryPath,
  ) async {
    final tasks = assets
        .map(
          (asset) => DownloadTask(
            url: asset.downloadUrl,
            filename: asset.originalFilename,
            directory: directoryPath,
            group: 'downloads',
            priority: 0,
          ),
        )
        .toList();

    await FileDownloader().enqueueAll(tasks);
    _transferStateNotifier.addDownloadTasks(tasks);
  }

  void handleDownloadStatusUpdate(Task task, TaskStatus status) {
    _transferStateNotifier.processStatusUpdate(task, status);
    logger.i("Download Task ${task.taskId} finished with status: $status");
  }

  void handleDownloadProgressUpdate(Task task, double progress) {
    _transferStateNotifier.updateProgress(task, progress);
  }
}
