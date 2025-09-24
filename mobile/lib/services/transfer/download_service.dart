// lib/services/transfer/download_service.dart

import 'dart:convert';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:drift/drift.dart' as d;
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:mobile/core/enums.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:mobile/data/datasources/remote_media_source.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:uuid/uuid.dart';

@lazySingleton
class DownloadService {
  final DownloadJobDao _downloadJobDao;
  final MediaAssetDao _mediaAssetDao;
  final RemoteMediaDataSource _remoteMediaSource;

  final _log = Logger('DownloadService');
  final _uuid = const Uuid();

  DownloadService(AppDatabase db, this._remoteMediaSource)
    : _downloadJobDao = db.downloadJobDao,
      _mediaAssetDao = db.mediaAssetDao;

  Future<void> handleDownloadStatusUpdate(
    DownloadTask task,
    TaskStatus status,
    TaskException? exception,
  ) async {
    final Map<String, dynamic> metaData;
    try {
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
        'Received status update for task ${task.taskId} without mediaUuid or itemType.',
      );
      return;
    }
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

    final newStatus = _statusFromTaskStatus(status);
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
      _log.severe(
        'Download for MediaAsset ${asset.id} failed or was canceled',
        exception,
      );
    }
  }

  Future<void> handleDownloadProgressUpdate(
    DownloadTask task,
    double progress,
  ) async {
    final job = await _downloadJobDao.getJobByTaskId(task.taskId);
    if (job == null) {
      _log.finer('Received progress for an unknown taskId: ${task.taskId}');
      return;
    }
    await _downloadJobDao.updateJob(
      DownloadJobsCompanion(
        jobId: d.Value(job.jobId),
        progress: d.Value(progress),
      ),
    );
  }

  Future<void> startDownloadForAsset(UnifiedMediaEntity entity) async {
    final asset = await _mediaAssetDao.getAssetById(entity.id);

    if (asset == null) {
      _log.severe(
        'Attempted to download an asset that does not exist in the local DB. ID: ${entity.id}',
      );
      return;
    }

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
      await _mediaAssetDao.updateAssetStatus(asset.id, SyncStatus.downloading);
      _log.info('Updated media asset ${asset.id} status to downloading.');

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
      await _mediaAssetDao.updateAssetStatus(
        asset.id,
        SyncStatus.downloadFailed,
      );
    }
  }

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
        priority: 0,
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
}
