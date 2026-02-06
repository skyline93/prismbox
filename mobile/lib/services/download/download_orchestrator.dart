// lib/services/download/download_orchestrator.dart

import 'package:logging/logging.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/infrastructure/api/api_service.dart';
import 'package:prismbox/services/download/download_task_manager.dart';

/// 下载编排器：取 pending 任务、创建并 enqueue DownloadTask，不阻塞
class DownloadOrchestrator {
  final AppDatabase _database;
  final DownloadTaskManager _taskManager;
  final ApiService _apiService;
  final Logger _logger = Logger('DownloadOrchestrator');

  static const String _downloadPath = '/api/v1/media';

  DownloadOrchestrator({
    required AppDatabase database,
    required DownloadTaskManager taskManager,
    ApiService? apiService,
  })  : _database = database,
        _taskManager = taskManager,
        _apiService = apiService ?? ApiService();

  /// 拉取该用户 pending/queued 任务并执行下载（创建并 enqueue），不等待完成
  Future<void> startDownload(String userId) async {
    final tasks = await _database.downloadTaskDao.getPendingTasksByUserId(userId);
    if (tasks.isEmpty) return;

    _logger.info('Start download: userId=$userId, pending=${tasks.length}');

    final baseUrl = _apiService.endpoint ?? '';
    if (baseUrl.isEmpty) {
      _logger.warning('Cannot start download: API endpoint is empty');
      return;
    }

    final headers = await ApiService.getRequestHeaders();

    for (final entity in tasks) {
      _executeDownload(entity, baseUrl, headers).catchError((e, stack) {
        _logger.warning(
          'Execute download failed: taskId=${entity.id}, $e',
          e,
          stack,
        );
      });
    }
  }

  Future<void> _executeDownload(
    DownloadTaskEntityData entity,
    String baseUrl,
    Map<String, String> headers,
  ) async {
    final isLivePhoto = entity.livePhotoVideoUuid != null &&
        entity.livePhotoVideoUuid!.isNotEmpty;

    if (isLivePhoto) {
      final imageUrl = '$baseUrl$_downloadPath/${entity.mediaUuid}/download/original';
      final videoUrl =
          '$baseUrl$_downloadPath/${entity.livePhotoVideoUuid}/download/original';

      final imageExt = entity.itemType == 'VIDEO' ? '.mov' : _extensionForImage();
      final imageTask = _taskManager.createDownloadTask(
        taskId: '${entity.id}_image',
        url: imageUrl,
        filename: '${entity.id}_image$imageExt',
        headers: headers,
      );
      final videoTask = _taskManager.createDownloadTask(
        taskId: '${entity.id}_video',
        url: videoUrl,
        filename: '${entity.id}_video.mov',
        headers: headers,
      );

      await _taskManager.enqueueTasks([imageTask, videoTask]);
    } else {
      final url = '$baseUrl$_downloadPath/${entity.mediaUuid}/download/original';
      final ext = entity.itemType == 'VIDEO' ? '.mov' : _extensionForImage();
      final task = _taskManager.createDownloadTask(
        taskId: entity.id,
        url: url,
        filename: '${entity.id}$ext',
        headers: headers,
      );
      await _taskManager.enqueueTask(task);
    }
  }

  String _extensionForImage() => '.jpg';
}
