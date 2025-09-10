// lib/services/transfer_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:drift/drift.dart' as d;
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:mobile/core/enums.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:mobile/data/datasources/remote_media_source.dart';
import 'package:mobile/data/services/dio_client.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:uuid/uuid.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/data/services/media_api_service.dart';
import 'package:mobile/core/storage/secure_storage_service.dart';

// 这是一个顶层函数，以便可以在 Isolate 中运行
Future<String> _calculateFileHash(String filePath) async {
  final file = File(filePath);
  final stream = file.openRead();
  final hash = await sha256.bind(stream).first;
  return hash.toString();
}

// 这是一个顶层函数，以便可以在 Isolate 中运行
Future<List<String>> _createTempChunks(Map<String, dynamic> args) async {
  final String filePath = args['filePath'];
  final int chunkSize = args['chunkSize'];
  final String tempDir = args['tempDir'];

  final file = File(filePath);
  final fileSize = await file.length();
  final chunkPaths = <String>[];

  for (int i = 0; i * chunkSize < fileSize; i++) {
    final start = i * chunkSize;
    final end = (start + chunkSize > fileSize) ? fileSize : (start + chunkSize);
    final chunkFile = File(p.join(tempDir, '$i'));

    final fileStream = file.openRead(start, end);
    await fileStream.pipe(chunkFile.openWrite());
    chunkPaths.add(chunkFile.path);
  }
  return chunkPaths;
}

@lazySingleton
class TransferService {
  final DownloadJobDao _downloadJobDao;
  final UploadJobDao _uploadJobDao;
  final MediaAssetDao _mediaAssetDao;
  final RemoteMediaDataSource _remoteMediaSource;
  final MediaApiService _mediaApiService;
  final SecureStorageService _secureStorageService;

  final _log = Logger('TransferService');
  final _uuid = const Uuid();

  TransferService(
    AppDatabase db,
    this._remoteMediaSource,
    this._mediaApiService,
    this._secureStorageService,
  ) : _downloadJobDao = db.downloadJobDao,
      _uploadJobDao = db.uploadJobDao,
      _mediaAssetDao = db.mediaAssetDao;

  Future<void> initialize() async {
    await FileDownloader().configure(
      androidConfig: [('logLevel', 'verbose'), ('network', 'any')],
    );
    await FileDownloader().start();
    FileDownloader().updates.listen(_onTaskUpdate);
    _log.info("TransferService initialized and listening for updates.");
  }

  void _onTaskUpdate(dynamic update) {
    // 依然使用 switch 匹配更新的类型（状态或进度），这是最佳实践。
    switch (update) {
      case TaskStatusUpdate():
        // 获得 task 对象和 status
        final task = update.task;
        final status = update.status;

        // 使用嵌套的 switch 直接对 task 的运行时类型进行匹配
        // 这是最安全、最清晰的区分方式
        switch (task) {
          case DownloadTask():
            // 如果 task 是 DownloadTask 类型，调用下载状态处理器
            _handleDownloadStatusUpdate(task, status);
            break;

          case MultiUploadTask():
            // 如果 task 是 MultiUploadTask 类型，调用上传状态处理器
            _handleUploadStatusUpdate(task, status);
            break;

          // 如果您还使用了其他任务类型（如 UploadTask），可以在这里添加 case
          default:
            _log.info(
              'Received status update for an unhandled task type: ${task.runtimeType}',
            );
        }
        break;

      case TaskProgressUpdate():
        // 获得 task 对象和 progress
        final task = update.task;
        final progress = update.progress;

        // 同样，对 task 的类型进行匹配
        switch (task) {
          case DownloadTask():
            _handleDownloadProgressUpdate(task, progress);
            break;

          case MultiUploadTask():
            _handleUploadProgressUpdate(task, progress);
            break;

          default:
            _log.finer(
              'Received progress update for an unhandled task type: ${task.runtimeType}',
            );
        }
        break;

      default:
        _log.fine('Received an unhandled update type: ${update.runtimeType}');
    }
  }

  Future<void> _handleDownloadStatusUpdate(
    DownloadTask task,
    TaskStatus status,
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
      _log.warning(
        'Download for MediaAsset ${asset.id} failed or was canceled.',
      );
    }
  }

  Future<void> _handleDownloadProgressUpdate(
    DownloadTask task,
    double progress,
  ) async {
    final job = await _downloadJobDao.getJobByTaskId(task.taskId);
    if (job == null) {
      // 在日志中记录，但可能不需要处理，因为状态更新会处理最终结果
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

  Future<void> _handleUploadStatusUpdate(Task task, TaskStatus status) async {
    final uploadId = task.group;

    final job = await _uploadJobDao.getJobByUploadId(uploadId);
    if (job == null) {
      _log.warning('Received status update for an unknown uploadId: $uploadId');
      return;
    }

    _log.fine('Upload chunk status update for job ${job.jobId}: $status');

    if (status == TaskStatus.complete) {
      await _checkAndCompleteUpload(uploadId);
    } else if (status == TaskStatus.failed || status == TaskStatus.canceled) {
      await _updateJobStatus(job.jobId, UploadJobStatus.failed);
      try {
        await FileDownloader().cancelTasksWithIds([task.taskId]);
      } catch (e, st) {
        _log.warning('Failed to cancel task ${task.taskId}: $e', e, st);
      }
    }
  }

  Future<void> _handleUploadProgressUpdate(Task task, double progress) async {
    final uploadId = task.group;

    final job = await _uploadJobDao.getJobByUploadId(uploadId);
    if (job == null) {
      _log.warning(
        'Received progress update for an unknown uploadId: $uploadId',
      );
      return;
    }

    // 手动计算该 group 的平均进度
    final records = await _recordsForGroup(uploadId);
    if (records.isNotEmpty) {
      final totalProgress = records.fold<double>(0.0, (sum, record) {
        try {
          return sum + (record.progress ?? 0.0);
        } catch (_) {
          return sum;
        }
      });
      final groupProgress = totalProgress / records.length;
      await _uploadJobDao.updateJob(
        UploadJobsCompanion(
          jobId: d.Value(job.jobId),
          progress: d.Value(groupProgress),
        ),
      );
    }
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

  /// 公共入口：为文件排队上传
  Future<void> enqueueUploadJob(File file) async {
    final jobId = _uuid.v4();
    try {
      _log.info('Starting new upload job ($jobId) for file: ${file.path}');
      await _uploadJobDao.insertJob(
        UploadJobsCompanion(
          jobId: d.Value(jobId),
          filePath: d.Value(file.path),
          status: const d.Value(UploadJobStatus.pending),
          progress: const d.Value(0.0),
          createdAt: d.Value(DateTime.now()),
          fileHash: const d.Value(''),
          totalSize: const d.Value(0),
          chunkSize: const d.Value(0),
          totalChunks: const d.Value(0),
        ),
      );
      _processUploadQueue(jobId, file);
    } catch (e, st) {
      _log.severe('Failed to enqueue upload job $jobId', e, st);
      await _uploadJobDao.updateJob(
        UploadJobsCompanion(
          jobId: d.Value(jobId),
          status: const d.Value(UploadJobStatus.failed),
        ),
      );
    }
  }

  /// 内部处理函数，执行实际的上传流程
  Future<void> _processUploadQueue(String jobId, File file) async {
    try {
      await _updateJobStatus(jobId, UploadJobStatus.initiating);
      final totalSize = await file.length();
      // 使用 compute 在独立 Isolate 中计算哈希，避免阻塞 UI
      final fileHash = await compute(_calculateFileHash, file.path);

      await _uploadJobDao.updateJob(
        UploadJobsCompanion(
          jobId: d.Value(jobId),
          totalSize: d.Value(totalSize),
          fileHash: d.Value(fileHash),
        ),
      );

      final filename = p.basename(file.path);
      final itemType =
          filename.toLowerCase().endsWith('.mp4') ||
              filename.toLowerCase().endsWith('.mov')
          ? 'VIDEO'
          : 'IMAGE';

      final initiateResponse = await _mediaApiService.initiateUpload(
        originalFilename: filename,
        hash: fileHash,
        totalSize: totalSize,
        itemType: itemType,
      );

      if (initiateResponse == null) {
        _log.info('Fast upload successful for job $jobId.');
        await _updateJobStatus(jobId, UploadJobStatus.success, progress: 1.0);
        return;
      }

      final uploadId = initiateResponse.uploadId;
      final chunkSize = initiateResponse.chunkSize;
      final totalChunks = (totalSize / chunkSize).ceil();
      await _uploadJobDao.updateJob(
        UploadJobsCompanion(
          jobId: d.Value(jobId),
          uploadId: d.Value(uploadId),
          chunkSize: d.Value(chunkSize),
          totalChunks: d.Value(totalChunks),
        ),
      );

      final tempBaseDir = await getApplicationSupportDirectory();
      final chunkDir = Directory(
        p.join(tempBaseDir.path, 'upload_chunks', jobId),
      );
      if (await chunkDir.exists()) await chunkDir.delete(recursive: true);
      await chunkDir.create(recursive: true);

      // 使用 compute 在独立 Isolate 中创建分片，避免阻塞 UI
      final chunkPaths = await compute<Map<String, dynamic>, List<String>>(
        _createTempChunks,
        {
          'filePath': file.path,
          'chunkSize': chunkSize,
          'tempDir': chunkDir.path,
        },
      );

      await _updateJobStatus(jobId, UploadJobStatus.uploading);

      final accessToken = await _secureStorageService.getAccessToken();
      if (accessToken == null) {
        _log.severe('Upload failed: Access token is null for job $jobId.');
        await _updateJobStatus(jobId, UploadJobStatus.failed);
        return;
      }
      final headers = {'Authorization': 'Bearer $accessToken'};

      final tasks = <Task>[]; // 使用 Task 基类列表

      for (int i = 0; i < chunkPaths.length; i++) {
        if (initiateResponse.uploadedChunks.contains(i)) {
          _log.fine('Skipping already uploaded chunk $i for job $jobId');
          continue;
        }

        // 使用官方 MultiUploadTask：files 参数传入 list，每个元素为 (fileField, path) 或 (fileField, path, mimeType)
        // 这里用 ['chunk', chunkPaths[i]] 的形式（Dart 中用 List 表示“record”）：
        tasks.add(
          MultiUploadTask(
            url: '${DioClient.getBaseUrl()}/media/upload/chunk',
            group: uploadId,
            files: [('chunk', chunkPaths[i])],
            fields: {'upload_id': uploadId, 'chunk_index': i.toString()},
            headers: headers,
            retries: 3,
            metaData: jsonEncode({'jobId': jobId}),
            updates: Updates.statusAndProgress,
          ),
        );
      }

      if (tasks.isNotEmpty) {
        // 当有大量任务时，官方建议使用 enqueueAll(tasks) 以避免阻塞
        await FileDownloader().enqueueAll(tasks);
        _log.info(
          'Enqueued ${tasks.length} chunk tasks for job $jobId (uploadId: $uploadId).',
        );
      } else {
        _log.info(
          'All chunks were already uploaded for job $jobId. Triggering completion.',
        );
        await _checkAndCompleteUpload(uploadId);
      }
    } catch (e, st) {
      _log.severe('Error processing upload job $jobId', e, st);
      await _updateJobStatus(jobId, UploadJobStatus.failed);
    }
  }

  /// Helper：从数据库所有记录中过滤出属于某个 group 的记录（因为 plugin 没有直接的 recordsForGroup API）
  Future<List<TaskRecord>> _recordsForGroup(String group) async {
    final all = await FileDownloader().database.allRecords();
    final filtered = all.where((record) {
      try {
        // record.task.group 在 TaskRecord 中应存在
        final rg = record.task.group;
        return rg == group;
      } catch (_) {
        return false;
      }
    }).toList();
    return filtered;
  }

  /// 检查组内所有任务是否完成，并触发合并
  Future<void> _checkAndCompleteUpload(String uploadId) async {
    final records = await _recordsForGroup(uploadId);
    final allDone =
        records.isNotEmpty &&
        records.every((rec) {
          try {
            return rec.status == TaskStatus.complete;
          } catch (_) {
            return false;
          }
        });

    if (allDone) {
      final job = await _uploadJobDao.getJobByUploadId(uploadId);
      if (job == null ||
          job.status == UploadJobStatus.completing ||
          job.status == UploadJobStatus.success) {
        return;
      }

      _log.info(
        'All chunks uploaded for job ${job.jobId}. Starting completion...',
      );
      await _updateJobStatus(job.jobId, UploadJobStatus.completing);

      try {
        final filename = p.basename(job.filePath);
        final itemType =
            filename.toLowerCase().endsWith('.mp4') ||
                filename.toLowerCase().endsWith('.mov')
            ? 'VIDEO'
            : 'IMAGE';

        await _mediaApiService.completeUpload(
          uploadId: uploadId,
          originalFilename: filename,
          hash: job.fileHash,
          itemType: itemType,
        );

        await _updateJobStatus(
          job.jobId,
          UploadJobStatus.success,
          progress: 1.0,
        );
        _log.info('Upload job ${job.jobId} completed successfully.');
      } catch (e, st) {
        _log.severe('Failed to complete upload for job ${job.jobId}', e, st);
        await _updateJobStatus(job.jobId, UploadJobStatus.failed);
      } finally {
        await _cleanupTempChunks(job.jobId);
      }
    }
  }

  Future<void> _cleanupTempChunks(String jobId) async {
    try {
      final tempBaseDir = await getApplicationSupportDirectory();
      final chunkDir = Directory(
        p.join(tempBaseDir.path, 'upload_chunks', jobId),
      );
      if (await chunkDir.exists()) {
        await chunkDir.delete(recursive: true);
        _log.info('Cleaned up temporary chunk directory for job $jobId');
      }
    } catch (e, st) {
      _log.severe('Error cleaning up temp chunks for job $jobId', e, st);
    }
  }

  Future<void> _updateJobStatus(
    String jobId,
    UploadJobStatus status, {
    double? progress,
  }) {
    return _uploadJobDao.updateJob(
      UploadJobsCompanion(
        jobId: d.Value(jobId),
        status: d.Value(status),
        progress: progress != null ? d.Value(progress) : const d.Value.absent(),
      ),
    );
  }
}
