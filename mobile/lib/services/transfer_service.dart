import 'dart:convert'; // [!] 修复: 导入 dart:convert 库
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:drift/drift.dart' as d;
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:mobile/core/enums.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:mobile/data/datasources/remote_media_source.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:uuid/uuid.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';

@lazySingleton
class TransferService {
  final DownloadJobDao _downloadJobDao;
  final MediaAssetDao _mediaAssetDao; // [+] 注入 MediaAssetDao 用于状态同步
  final RemoteMediaDataSource _remoteMediaSource;
  final _log = Logger('TransferService');
  final _uuid = const Uuid();

  TransferService(AppDatabase db, this._remoteMediaSource)
    : _downloadJobDao = db.downloadJobDao,
      _mediaAssetDao = db.mediaAssetDao; // [+] 初始化 MediaAssetDao

  Future<void> initialize() async {
    await FileDownloader().configure(
      androidConfig: [('logLevel', 'verbose'), ('network', 'any')],
      // iOS 配置可以根据需要添加
    );
    await FileDownloader().start();
    FileDownloader().updates.listen(_onTaskUpdate);
    _log.info("TransferService initialized and listening for updates.");
  }

  void _onTaskUpdate(dynamic update) {
    final group = update.task.group;
    if (group == 'download') {
      _handleDownloadUpdate(update);
    } else if (group == 'upload') {
      _handleUploadUpdate(update);
    }
  }

  Future<void> startDownloadForAsset(UnifiedMediaEntity entity) async {
    // 1. 从数据库获取最新的、完整的 MediaAsset 对象
    final asset = await _mediaAssetDao.getAssetById(entity.id);

    if (asset == null) {
      _log.severe(
        'Attempted to download an asset that does not exist in the local DB. ID: ${entity.id}',
      );
      return;
    }

    // 防御性检查，确保资产可以被下载
    if (asset.cloudUuid == null) {
      _log.severe('Asset ${asset.id} has no cloudUuid, cannot download.');
      return;
    }
    if (asset.syncStatus == SyncStatus.synced ||
        asset.syncStatus == SyncStatus.downloading) {
      _log.info(
        'Asset ${asset.id} is already synced or downloading, skipping.',
      );
      return;
    }

    try {
      // 2. 立即更新数据库和UI状态为 "下载中"
      await _mediaAssetDao.updateAssetStatus(asset.id, SyncStatus.downloading);
      _log.info('Updated media asset ${asset.id} status to downloading.');

      // 3. 将任务加入内部处理队列
      await _enqueueDownloadJob(
        mediaUuid: asset.cloudUuid!,
        originalFilename: asset.fileName ?? 'untitled_${asset.cloudUuid}',
        itemType: asset.assetType.name,
      );
    } catch (e, stacktrace) {
      _log.severe(
        'Failed to start download process for asset ${asset.id}. Error: $e',
        e,
        stacktrace,
      );
      // 如果在入队阶段就失败，则将状态标记为失败
      await _mediaAssetDao.updateAssetStatus(
        asset.id,
        SyncStatus.downloadFailed,
      );
    }
  }

  /// 内部方法，负责创建数据库记录和 background_downloader 任务
  Future<void> _enqueueDownloadJob({
    required String mediaUuid,
    required String originalFilename,
    required String itemType,
  }) async {
    final jobId = _uuid.v4();
    final saveDir = await getApplicationDocumentsDirectory();
    final savePath = p.join(saveDir.path, originalFilename);

    String? createdJobIdInDb;

    try {
      _log.info('Fetching media detail for mediaUuid: $mediaUuid');
      final mediaDetail = await _remoteMediaSource.getMediaDetail(mediaUuid);
      final downloadUrl = mediaDetail.downloadUrl;

      final newJob = DownloadJobsCompanion(
        jobId: d.Value(jobId),
        mediaUuid: d.Value(mediaUuid),
        savePath: d.Value(savePath),
        downloadUrl: d.Value(downloadUrl),
        status: const d.Value(DownloadJobStatus.pending),
        progress: const d.Value(0.0),
        createdAt: d.Value(DateTime.now()),
      );
      await _downloadJobDao.insertJob(newJob);
      createdJobIdInDb = jobId;
      _log.info('Download job created in DB with jobId: $jobId');

      final task = DownloadTask(
        url: downloadUrl,
        filename: originalFilename,
        directory: saveDir.path,
        group: 'download',
        updates: Updates.statusAndProgress,
        requiresWiFi: false,
        metaData: jsonEncode({'mediaUuid': mediaUuid, 'itemType': itemType}),
      );

      final result = await FileDownloader().enqueue(task);
      if (result) {
        await _downloadJobDao.updateJob(
          DownloadJobsCompanion(
            jobId: d.Value(jobId),
            taskId: d.Value(task.taskId),
          ),
        );
        _log.info(
          'Task enqueued with taskId: ${task.taskId} for jobId: $jobId',
        );
      } else {
        throw Exception('FileDownloader failed to enqueue the task.');
      }
    } catch (e) {
      _log.severe(
        'Failed to create or enqueue download for mediaUuid: $mediaUuid. Error: $e',
      );
      if (createdJobIdInDb != null) {
        await _downloadJobDao.updateJob(
          DownloadJobsCompanion(
            jobId: d.Value(createdJobIdInDb),
            status: const d.Value(DownloadJobStatus.failed),
          ),
        );
      }
      rethrow;
    }
  }

  /// 核心回调处理
  Future<void> _handleDownloadUpdate(dynamic update) async {
    final task = update.task as DownloadTask;

    final Map<String, dynamic> metaData;
    try {
      // [!] 修复: 检查 metaData 是否为空，如果为空则解码一个空对象
      final metaDataString = task.metaData.isEmpty ? '{}' : task.metaData;
      metaData = jsonDecode(metaDataString);
    } catch (e) {
      _log.warning('Could not parse metaData for task ${task.taskId}');
      return;
    }

    final String? mediaUuid = metaData['mediaUuid'];
    final String? itemType = metaData['itemType'];

    if (mediaUuid == null || itemType == null) {
      _log.warning(
        'Received update for task ${task.taskId} without mediaUuid or itemType in metaData.',
      );
      return;
    }

    // [!] 此处需要 DAO 支持
    final asset = await _mediaAssetDao.getAssetByCloudUuid(mediaUuid);
    if (asset == null) {
      _log.warning(
        'Could not find MediaAsset for cloudUuid: $mediaUuid. Cancelling task.',
      );
      await FileDownloader().cancelTasksWithIds([task.taskId]);
      return;
    }

    final job = await _downloadJobDao.getJobByTaskId(task.taskId);
    if (job == null) {
      _log.warning('Received update for an unknown taskId: ${task.taskId}');
      return;
    }

    if (update is TaskStatusUpdate) {
      final newStatus = _statusFromTaskStatus(update.status);
      await _downloadJobDao.updateJob(
        DownloadJobsCompanion(
          jobId: d.Value(job.jobId),
          status: d.Value(newStatus),
        ),
      );
      _log.fine(
        'Download job ${job.jobId} (asset ${asset.id}) status updated to $newStatus',
      );

      if (newStatus == DownloadJobStatus.success) {
        final realFilePath = await task.filePath();
        _log.info(
          'Task for asset ${asset.id} successful. File path: $realFilePath',
        );

        final savedAssetEntity = await _registerMediaToGallery(
          realFilePath,
          itemType,
        );

        if (savedAssetEntity != null) {
          final finalFile = await savedAssetEntity.file;
          if (finalFile != null) {
            await _mediaAssetDao.updateAsset(
              MediaAssetsCompanion(
                id: d.Value(asset.id),
                localId: d.Value(savedAssetEntity.id),
                filePath: d.Value(finalFile.path),
                syncStatus: const d.Value(SyncStatus.synced),
                updatedAt: d.Value(DateTime.now()),
              ),
            );
            _log.info(
              'MediaAsset ${asset.id} successfully updated with new local info.',
            );
          } else {
            _log.severe(
              'Failed to get file path from saved AssetEntity for asset ${asset.id}.',
            );
            await _mediaAssetDao.updateAssetStatus(
              asset.id,
              SyncStatus.downloadFailed,
            );
          }
        } else {
          _log.severe(
            'Failed to register downloaded media to gallery for asset ${asset.id}.',
          );
          await _mediaAssetDao.updateAssetStatus(
            asset.id,
            SyncStatus.downloadFailed,
          );
        }
      } else if (newStatus == DownloadJobStatus.failed ||
          newStatus == DownloadJobStatus.canceled) {
        await _mediaAssetDao.updateAssetStatus(
          asset.id,
          SyncStatus.downloadFailed,
        );
        _log.warning(
          'Download for MediaAsset ${asset.id} failed or was canceled.',
        );
      }
    } else if (update is TaskProgressUpdate) {
      await _downloadJobDao.updateJob(
        DownloadJobsCompanion(
          jobId: d.Value(job.jobId),
          progress: d.Value(update.progress),
        ),
      );
    }
  }

  /// 将下载到私有目录的文件注册到系统相册
  Future<AssetEntity?> _registerMediaToGallery(
    String originalFilePath,
    String itemType,
  ) async {
    final sourceFile = File(originalFilePath);
    if (!await sourceFile.exists()) {
      _log.severe("Downloaded file does not exist at path: $originalFilePath");
      return null;
    }

    final tempDir = await getTemporaryDirectory();
    final tempFileName = p.basename(originalFilePath);
    final tempFile = await sourceFile.copy(p.join(tempDir.path, tempFileName));

    try {
      final ps = await PhotoManager.requestPermissionExtend();
      if (ps != PermissionState.authorized && ps != PermissionState.limited) {
        _log.warning('Gallery permission not granted. Cannot save file.');
        return null;
      }

      _log.info('Registering file ($originalFilePath) to system gallery...');
      AssetEntity? asset;
      if (itemType.toUpperCase() == 'IMAGE') {
        asset = await PhotoManager.editor.saveImageWithPath(
          tempFile.path,
          title: tempFileName,
        );
      } else if (itemType.toUpperCase() == 'VIDEO') {
        asset = await PhotoManager.editor.saveVideo(
          tempFile,
          title: tempFileName,
        );
      }

      if (asset != null) {
        _log.info(
          'Successfully registered file to gallery. New Asset ID: ${asset.id}',
        );
      } else {
        _log.warning(
          'Failed to register file to gallery. The returned asset was null.',
        );
      }
      return asset;
    } catch (e, stacktrace) {
      _log.severe('Error while registering file to gallery: $e', e, stacktrace);
      return null;
    } finally {
      if (await tempFile.exists()) await tempFile.delete();
      if (await sourceFile.exists()) await sourceFile.delete();
    }
  }

  DownloadJobStatus _statusFromTaskStatus(TaskStatus status) {
    switch (status) {
      case TaskStatus.enqueued:
      case TaskStatus.running:
      case TaskStatus.waitingToRetry:
        return DownloadJobStatus.running;
      case TaskStatus.complete:
        return DownloadJobStatus.success;
      case TaskStatus.notFound:
      case TaskStatus.failed:
        return DownloadJobStatus.failed;
      case TaskStatus.canceled:
        return DownloadJobStatus.canceled;
      case TaskStatus.paused:
        return DownloadJobStatus.paused;
    }
  }

  // --- 公共控制 API ---
  // ... (pause, resume, cancel 方法保持不变) ...
  Future<void> pauseDownload(String jobId) async {
    final job = await _downloadJobDao.getJob(jobId);
    if (job != null && job.taskId != null) {
      final record = await FileDownloader().database.recordForId(job.taskId!);
      if (record != null) {
        await FileDownloader().pause(record.task as DownloadTask);
      }
    }
  }

  Future<void> resumeDownload(String jobId) async {
    final job = await _downloadJobDao.getJob(jobId);
    if (job != null && job.taskId != null) {
      final record = await FileDownloader().database.recordForId(job.taskId!);
      if (record != null) {
        await FileDownloader().resume(record.task as DownloadTask);
      }
    }
  }

  Future<void> cancelDownload(String jobId) async {
    final job = await _downloadJobDao.getJob(jobId);
    if (job != null && job.taskId != null) {
      await FileDownloader().cancelTasksWithIds([job.taskId!]);
    }
  }

  void _handleUploadUpdate(dynamic update) {
    // 待实现
    _log.info("Received upload update: $update");
  }
}
