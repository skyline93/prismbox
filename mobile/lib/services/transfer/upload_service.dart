// lib/services/transfer/upload_service.dart

import 'dart:convert';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:crypto/crypto.dart';
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
import 'package:photo_manager/photo_manager.dart';
import 'package:mobile/config/app_config.dart';
import 'package:mobile/extensions/asset_type_extensions.dart';

Future<String> _calculateFileHash(String filePath) async {
  final file = File(filePath);
  final stream = file.openRead();
  final hash = await sha256.bind(stream).first;
  return hash.toString();
}

@lazySingleton
class UploadService {
  final AppDatabase _db;
  final UploadJobDao _uploadJobDao;
  final MediaAssetDao _mediaAssetDao;
  final SecureStorageService _secureStorageService;

  final _log = Logger('UploadService');
  final _uuid = const Uuid();

  // --- ADDED ---
  // 持有从 TransferManager 传入的任务队列
  late final MemoryTaskQueue _taskQueue;
  // --- END ADDED ---

  UploadService(AppDatabase db, this._secureStorageService)
    : _db = db,
      _uploadJobDao = db.uploadJobDao,
      _mediaAssetDao = db.mediaAssetDao;

  // --- ADDED ---
  // 用于接收 TransferManager 传递的队列实例
  void setTaskQueue(MemoryTaskQueue queue) {
    _taskQueue = queue;
  }
  // --- END ADDED ---

  Future<void> enqueueMultipleJobs(List<UploadTaskPayload> tasks) async {
    _log.info('开始批量入队 ${tasks.length} 个上传任务。');

    final List<Map<String, dynamic>> jobsToProcess = [];

    await _db.transaction(() async {
      for (final task in tasks) {
        final jobId = _uuid.v4();
        final cloudUuid = _uuid.v4();

        await _mediaAssetDao.updateMediaAssetWithlocalId(
          task.assetId,
          MediaAssetsCompanion(
            cloudUuid: d.Value(cloudUuid),
            syncStatus: const d.Value(SyncStatus.uploading),
          ),
        );

        await _uploadJobDao.insertJob(
          UploadJobsCompanion(
            jobId: d.Value(jobId),
            filePath: d.Value(task.file.path),
            status: const d.Value(UploadJobStatus.pending),
            progress: const d.Value(0.0),
            createdAt: d.Value(DateTime.now()),
            fileHash: const d.Value(''),
            totalSize: const d.Value(0),
          ),
        );

        jobsToProcess.add({
          'jobId': jobId,
          'file': task.file,
          'assetId': task.assetId,
          'cloudUuid': cloudUuid,
          "mediaType": task.mediaType,
        });
      }
    });
    _log.info('批量入队 ${tasks.length} 个任务的数据库操作已完成。');

    for (final jobData in jobsToProcess) {
      _processUploadQueue(
        jobData['jobId'],
        jobData['file'],
        jobData['assetId'],
        jobData['cloudUuid'],
        jobData['mediaType'],
      );
    }
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

  Future<void> enqueueUploadJob(AssetEntity asset) async {
    final jobId = _uuid.v4();
    final cloudUuid = _uuid.v4();

    final file = await asset.originFile;
    final assetId = asset.id;

    try {
      _log.info(
        '为文件: ${file!.path} (资源 ID: $assetId) 启动新的上传任务 ($jobId)，预分配云端 UUID: $cloudUuid',
      );

      await _mediaAssetDao.updateMediaAssetWithlocalId(
        assetId,
        MediaAssetsCompanion(
          cloudUuid: d.Value(cloudUuid),
          syncStatus: const d.Value(SyncStatus.uploading),
        ),
      );

      await _uploadJobDao.insertJob(
        UploadJobsCompanion(
          jobId: d.Value(jobId),
          filePath: d.Value(file.path),
          status: const d.Value(UploadJobStatus.pending),
          progress: const d.Value(0.0),
          createdAt: d.Value(DateTime.now()),
          fileHash: const d.Value(''),
          totalSize: const d.Value(0),
        ),
      );

      _processUploadQueue(
        jobId,
        file,
        assetId,
        cloudUuid,
        asset.type.toMediaType(),
      );
    } catch (e, st) {
      _log.severe('入队上传任务 $jobId (资源 $assetId) 失败', e, st);
      await _mediaAssetDao.updateMediaAssetWithlocalId(
        assetId,
        MediaAssetsCompanion(syncStatus: d.Value(SyncStatus.uploadFailed)),
      );
      await _uploadJobDao.updateJob(
        UploadJobsCompanion(
          jobId: d.Value(jobId),
          status: const d.Value(UploadJobStatus.failed),
        ),
      );
    }
  }

  Future<void> _processUploadQueue(
    String jobId,
    File file,
    String assetId,
    String cloudUuid,
    MediaType mediaType,
  ) async {
    try {
      await _updateJobStatus(jobId, UploadJobStatus.initiating);
      final totalSize = await file.length();
      final fileHash = await compute(_calculateFileHash, file.path);
      final filename = p.basename(file.path);

      await _uploadJobDao.updateJob(
        UploadJobsCompanion(
          jobId: d.Value(jobId),
          totalSize: d.Value(totalSize),
          fileHash: d.Value(fileHash),
        ),
      );

      await _mediaAssetDao.updateMediaAssetWithlocalId(
        assetId,
        MediaAssetsCompanion(contentHash: d.Value(fileHash)),
      );

      await _updateJobStatus(jobId, UploadJobStatus.uploading);

      final accessToken = await _secureStorageService.getAccessToken();
      if (accessToken == null) {
        _log.severe('上传失败: 任务 $jobId 的访问令牌为空。');
        await _updateJobStatus(jobId, UploadJobStatus.failed);
        await _mediaAssetDao.updateMediaAssetWithlocalId(
          assetId,
          MediaAssetsCompanion(syncStatus: d.Value(SyncStatus.uploadFailed)),
        );
        return;
      }
      final headers = {'Authorization': 'Bearer $accessToken'};

      final fields = {
        'cloud_uuid': cloudUuid,
        'hash': fileHash,
        'item_type': mediaType.name,
        'original_filename': filename,
      };

      final task = UploadTask.fromFile(
        file: file,
        url: '${ApiConfig.baseUrl}/media/upload-stream',
        fileField: 'file',
        fields: fields,
        headers: headers,
        retries: 3,
        metaData: jsonEncode({'jobId': jobId, 'assetId': assetId}),
        updates: Updates.statusAndProgress,
        displayName: filename,
        priority: 1,
        group: 'upload',
      );

      // --- CHANGED ---
      // 将任务添加到上传队列中
      _taskQueue.add(task);
      // --- END CHANGED ---

      _log.info('已将任务 $jobId (资源 $assetId) 的单文件上传任务加入队列。');
    } catch (e, st) {
      _log.severe('处理上传任务 $jobId (资源 $assetId) 时出错', e, st);
      await _updateJobStatus(jobId, UploadJobStatus.failed);
      await _mediaAssetDao.updateMediaAssetWithlocalId(
        assetId,
        MediaAssetsCompanion(syncStatus: d.Value(SyncStatus.uploadFailed)),
      );
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
