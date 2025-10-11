// lib/services/transfer/upload_service.dart

import 'dart:convert';

import 'package:background_downloader/background_downloader.dart';
import 'package:drift/drift.dart' as d;
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:mobile/core/enums.dart';
import 'package:mobile/core/storage/secure_storage_service.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:mobile/providers/upload_orchestrator.dart';
import 'package:mobile/config/app_config.dart';
import 'package:mobile/utils/hash.dart';

@lazySingleton
class UploadService {
  final AppDatabase _db;
  final UploadJobDao _uploadJobDao;
  final MediaAssetDao _mediaAssetDao;
  final SecureStorageService _secureStorageService;

  final _log = Logger('UploadService');
  final _uuid = const Uuid();

  // 持有从 TransferManager 传入的任务队列
  late final MemoryTaskQueue _taskQueue;

  UploadService(AppDatabase db, this._secureStorageService)
    : _db = db,
      _uploadJobDao = db.uploadJobDao,
      _mediaAssetDao = db.mediaAssetDao;

  // 用于接收 TransferManager 传递的队列实例
  void setTaskQueue(MemoryTaskQueue queue) {
    _taskQueue = queue;
  }

  Future<void> handleUploadStatusUpdate(
    Task task,
    TaskStatus status,
    TaskException? exception,
  ) async {
    if (task.metaData.isEmpty) return;
    final metadata = jsonDecode(task.metaData);
    final jobId = metadata['jobId'] as String?;
    final assetId = metadata['assetId'] as String?;

    if (jobId == null || assetId == null) {
      _log.warning('任务 ${task.taskId} 状态更新元数据不完整。');
      return;
    }

    final job = await _uploadJobDao.getJob(jobId);
    if (job == null) {
      _log.warning('收到未知 jobId 的状态更新: $jobId');
      await _mediaAssetDao.updateMediaAssetWithlocalId(
        assetId,
        MediaAssetsCompanion(syncStatus: d.Value(SyncStatus.uploadFailed)),
      );
      return;
    }

    _log.fine('上传任务 ${job.jobId} (资源 $assetId) 状态更新: $status');

    if (status == TaskStatus.complete) {
      _log.info('上传任务 ${job.jobId} (资源 $assetId) 成功完成。');
      await _updateJobStatus(job.jobId, UploadJobStatus.success, progress: 1.0);

      try {
        await _mediaAssetDao.updateMediaAssetWithlocalId(
          assetId,
          MediaAssetsCompanion(
            syncStatus: const d.Value(SyncStatus.synced),
            updatedAt: d.Value(DateTime.now()),
          ),
        );
        _log.info('MediaAsset $assetId 的状态已成功更新为 "synced"。');
      } catch (e, st) {
        _log.severe('更新 MediaAsset $assetId 状态时失败。', e, st);
        await _mediaAssetDao.updateMediaAssetWithlocalId(
          assetId,
          MediaAssetsCompanion(syncStatus: d.Value(SyncStatus.uploadFailed)),
        );
      }
    } else if (status == TaskStatus.failed || status == TaskStatus.canceled) {
      if (status == TaskStatus.failed) {
        _log.severe('上传任务 ${job.jobId} (资源 $assetId) 失败。', exception);
      } else {
        _log.warning('上传任务 ${job.jobId} (资源 $assetId) 已被用户取消。');
      }

      await _updateJobStatus(job.jobId, UploadJobStatus.failed);
      await _mediaAssetDao.updateMediaAssetWithlocalId(
        assetId,
        MediaAssetsCompanion(syncStatus: d.Value(SyncStatus.uploadFailed)),
      );

      try {
        await FileDownloader().cancelTasksWithIds([task.taskId]);
      } catch (e, st) {
        _log.warning('取消任务 ${task.taskId} 失败: $e', e, st);
      }
    }
  }

  Future<void> handleUploadProgressUpdate(Task task, double progress) async {
    if (task.metaData.isEmpty) return;
    final metadata = jsonDecode(task.metaData);
    final jobId = metadata['jobId'] as String?;

    if (jobId == null) {
      _log.finer('收到任务 ${task.taskId} 的进度更新，但元数据不完整。');
      return;
    }

    final job = await _uploadJobDao.getJob(jobId);
    if (job == null) {
      _log.finer('收到未知 jobId 的进度更新: $jobId');
      return;
    }

    await _uploadJobDao.updateJob(
      UploadJobsCompanion(
        jobId: d.Value(job.jobId),
        progress: d.Value(progress),
      ),
    );
  }

  Future<void> enqueueMultipleJobs(List<UploadTaskPayload> taskPayloads) async {
    _log.info('开始批量入队 ${taskPayloads.length} 个上传任务。');

    for (final pl in taskPayloads) {
      late final String jobId;

      try {
        jobId = await _enqueueUploadJob(pl);
      } catch (e, st) {
        _log.severe('入队上传任务 (资源 ${pl.assetId}) 失败', e, st);
        await _mediaAssetDao.updateMediaAssetWithlocalId(
          pl.assetId,
          MediaAssetsCompanion(syncStatus: d.Value(SyncStatus.uploadFailed)),
        );
        await _uploadJobDao.updateJob(
          UploadJobsCompanion(
            jobId: d.Value(jobId),
            status: const d.Value(UploadJobStatus.failed),
          ),
        );

        continue;
      }
    }
  }

  Future<String> _enqueueUploadJob(UploadTaskPayload taskPayload) async {
    final jobId = _uuid.v4();
    final cloudUuid = _uuid.v4();
    final totalSize = await taskPayload.file.length();
    final filename = p.basename(taskPayload.file.path);
    final fileHash = await compute(calculateFileHash, taskPayload.file);

    await _db.transaction(() async {
      await _mediaAssetDao.updateMediaAssetWithlocalId(
        taskPayload.assetId,
        MediaAssetsCompanion(
          cloudUuid: d.Value(cloudUuid),
          syncStatus: const d.Value(SyncStatus.uploading),
          contentHash: d.Value(fileHash),
        ),
      );

      await _uploadJobDao.insertJob(
        UploadJobsCompanion(
          jobId: d.Value(jobId),
          filePath: d.Value(taskPayload.file.path),
          status: const d.Value(UploadJobStatus.uploading),
          progress: const d.Value(0),
          createdAt: d.Value(DateTime.now()),
          fileHash: d.Value(fileHash),
          totalSize: d.Value(totalSize),
        ),
      );

      final accessToken = await _secureStorageService.getAccessToken();
      if (accessToken == null) {
        _log.severe('上传失败: 任务 $jobId 的访问令牌为空。');
        await _updateJobStatus(jobId, UploadJobStatus.failed);
        await _mediaAssetDao.updateMediaAssetWithlocalId(
          taskPayload.assetId,
          MediaAssetsCompanion(syncStatus: d.Value(SyncStatus.uploadFailed)),
        );
        return jobId;
      }

      final fields = {
        'cloud_uuid': cloudUuid,
        'hash': fileHash,
        'item_type': taskPayload.mediaType.name,
        'original_filename': filename,
      };

      final task = UploadTask.fromFile(
        file: taskPayload.file,
        url: '${ApiConfig.baseUrl}/media/upload-stream',
        fileField: 'file',
        fields: fields,
        headers: {'Authorization': 'Bearer $accessToken'},
        retries: 3,
        metaData: jsonEncode({'jobId': jobId, 'assetId': taskPayload.assetId}),
        updates: Updates.statusAndProgress,
        displayName: filename,
        priority: 1,
        group: 'upload',
      );

      _taskQueue.add(task);
      _log.info('任务$jobId已入队');
    });

    return jobId;
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
