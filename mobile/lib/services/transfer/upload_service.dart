// lib/services/transfer/upload_service.dart

import 'dart:convert';

import 'package:background_downloader/background_downloader.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart' as d;
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:mobile/core/enums.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
// [阶段三 新增]: 导入 SettingsService
import 'package:mobile/services/settings_service.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:mobile/services/transfer/upload_orchestrator.dart';
import 'package:mobile/config/app_config.dart';
import 'package:mobile/utils/hash.dart';
// [阶段三 新增]: 导入 DeviceUtils 以检查网络
import 'package:mobile/utils/device_utils.dart';
// [认证优化]: 导入认证处理器
import 'package:mobile/services/transfer/upload_auth_handler.dart';

@lazySingleton
class UploadService {
  final AppDatabase _db;
  final UploadJobDao _uploadJobDao;
  final MediaAssetDao _mediaAssetDao;
  // [阶段三 新增]: 注入 SettingsService
  final SettingsService _settingsService;
  // [认证优化]: 注入认证处理器
  final UploadAuthHandler _authHandler;

  final _log = Logger('UploadService');
  final _uuid = const Uuid();

  // 持有从 TransferManager 传入的任务队列
  // ignore: unused_field
  late final MemoryTaskQueue _taskQueue;

  // [阶段三 修改]: 更新构造函数以接收 SettingsService 和认证处理器
  UploadService(
    AppDatabase db,
    this._settingsService,
    this._authHandler,
  ) : _db = db,
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
      try {
        // [阶段三 修正]: 移除了未使用的 jobId 变量
        await _enqueueUploadJob(pl);
      } catch (e, st) {
        _log.severe('入队上传任务 (资源 ${pl.assetId}) 失败', e, st);
        await _mediaAssetDao.updateMediaAssetWithlocalId(
          pl.assetId,
          MediaAssetsCompanion(syncStatus: d.Value(SyncStatus.uploadFailed)),
        );
      }
    }
  }

  // [阶段三 修改]: 整个方法被重构以包含网络检查逻辑
  Future<String> _enqueueUploadJob(UploadTaskPayload taskPayload) async {
    final jobId = _uuid.v4();
    final cloudUuid = _uuid.v4();
    final totalSize = await taskPayload.file.length();
    final filename = p.basename(taskPayload.file.path);
    final fileHash = await compute(calculateFileHash, taskPayload.file);

    // 1. 获取用户设置和当前网络状态
    // [阶段三 修正]: 调用 watchBackupSettings().first 来从流中获取当前值
    final backupSettings = await _settingsService.watchBackupSettings().first;
    // [阶段三 修正]: 接收一个 List<ConnectivityResult>
    final connectivityResults = await DeviceUtils.checkConnectivity();

    bool canUpload = true;
    UploadJobStatus initialStatus = UploadJobStatus.uploading;

    // [阶段三 修正]: 检查列表中是否包含 Wi-Fi
    if (backupSettings.isBackupOnWifiOnly &&
        !connectivityResults.contains(ConnectivityResult.wifi)) {
      canUpload = false;
      initialStatus = UploadJobStatus.waitingForWifi;
      _log.info('任务 $jobId (资源 ${taskPayload.assetId}) 已暂存，等待 Wi-Fi 连接。');
    }

    await _db.transaction(() async {
      // 2. 无论网络状况如何，都先在数据库中创建记录
      await _mediaAssetDao.updateMediaAssetWithlocalId(
        taskPayload.assetId,
        MediaAssetsCompanion(
          cloudUuid: d.Value(cloudUuid),
          // 状态为 uploading 表示它在上传管道中，具体子状态由 UploadJob 决定
          syncStatus: const d.Value(SyncStatus.uploading),
          contentHash: d.Value(fileHash),
        ),
      );

      await _uploadJobDao.insertJob(
        UploadJobsCompanion(
          jobId: d.Value(jobId),
          filePath: d.Value(taskPayload.file.path),
          status: d.Value(initialStatus), // 使用我们决定的初始状态
          progress: const d.Value(0),
          createdAt: d.Value(DateTime.now()),
          fileHash: d.Value(fileHash),
          totalSize: d.Value(totalSize),
        ),
      );

      // 3. 如果网络条件不满足，则到此为止，不创建实际的上传任务
      if (!canUpload) {
        return;
      }

      // 4. 如果网络条件满足，则继续创建并入队后台上传任务
      // [认证优化]: 不再预先获取token，而是依赖onTaskStart回调动态处理
      final fields = {
        'cloud_uuid': cloudUuid,
        'hash': fileHash,
        'item_type': taskPayload.mediaType.name,
        'original_filename': filename,
      };

      // [认证优化]: 在任务创建时动态获取有效的token
      final accessToken = await _authHandler.getValidAccessToken();
      if (accessToken == null) {
        _log.severe('上传失败: 任务 $jobId 无法获取有效的访问令牌。');
        throw Exception('Cannot get valid access token for job $jobId');
      }

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
        // [认证优化]: 使用TaskOptions配置onTaskStart回调
        options: TaskOptions(
          onTaskStart: UploadAuthHandler.onTaskStart,
        ),
      );

      // _taskQueue.add(task);
      await FileDownloader().enqueue(task);
      _log.info('任务 $jobId 已成功加入后台上传队列。');
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
