// lib/services/download/download_service.dart

import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/enums/download_task_status.dart';
import 'package:prismbox/services/download/media_download_request.dart';
import 'package:prismbox/services/download/download_orchestrator.dart';

/// 下载服务：addDownload、队列状态，冲突检测后插入并触发编排
class DownloadService {
  final AppDatabase _database;
  final DownloadOrchestrator _orchestrator;
  final Logger _logger = Logger('DownloadService');

  DownloadService({
    required AppDatabase database,
    required DownloadOrchestrator orchestrator,
  })  : _database = database,
        _orchestrator = orchestrator;

  /// 添加下载：冲突检测、插入 entity、乐观更新、触发 startDownload
  Future<bool> addDownload(MediaDownloadRequest request) async {
    final active = await _database.downloadTaskDao.getActiveTasksBySource(
      request.userId,
      request.sourceType,
      request.sourceId,
    );
    if (active.isNotEmpty) {
      _logger.info(
        'Download skipped (already in queue): sourceType=${request.sourceType}, '
        'sourceId=${request.sourceId}',
      );
      return false;
    }

    const uuid = Uuid();
    final taskId = 'download_${request.sourceId}_${uuid.v4().substring(0, 8)}';
    final now = DateTime.now();

    final entity = DownloadTaskEntityData(
      id: taskId,
      userId: request.userId,
      sourceType: request.sourceType,
      sourceId: request.sourceId,
      mediaUuid: request.mediaUuid,
      livePhotoVideoUuid: request.livePhotoVideoUuid,
      filename: request.filename,
      itemType: request.itemType,
      status: DownloadTaskStatus.pending,
      progress: 0,
      errorMessage: null,
      imageTempPath: null,
      videoTempPath: null,
      createdAt: now,
      updatedAt: now,
    );

    await _database.downloadTaskDao.insertTask(entity);
    _logger.info('Download task created: taskId=$taskId, sourceId=${request.sourceId}');

    _orchestrator.startDownload(request.userId);
    return true;
  }

  /// 获取用户下载队列状态
  Future<Map<DownloadTaskStatus, int>> getQueueStatus(String userId) async {
    return _database.downloadTaskDao.getQueueStatusByUserId(userId);
  }

  /// 监听用户下载任务列表
  Stream<List<DownloadTaskEntityData>> watchTasksByUserId(String userId) {
    return _database.downloadTaskDao.watchTasksByUserId(userId);
  }
}
