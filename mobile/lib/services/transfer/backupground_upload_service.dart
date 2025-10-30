// lib/services/transfer/upload_service.dart

import 'dart:convert';

import 'dart:io';
import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart' as d;
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:mobile/core/enums.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:mobile/services/settings_service.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:mobile/services/transfer/upload_orchestrator.dart';
import 'package:mobile/config/app_config.dart';
import 'package:mobile/utils/hash.dart';
import 'package:mobile/utils/device_utils.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/extensions/asset_type_extensions.dart';
// [认证优化]: 导入认证处理器
import 'package:mobile/services/transfer/upload_auth_handler.dart';

@injectable
class AutoBackupHandler {
  final _log = Logger('AutoBackupHandler');

  // ignore: unused_field
  final AppDatabase _db;
  final SettingsService _settingsService;
  final MediaAssetDao _mediaAssetDao;

  AutoBackupHandler(this._settingsService, this._db)
    : _mediaAssetDao = _db.mediaAssetDao;

  Future<String> handle(dynamic payload) async {
    _log.info('Starting automatic media backup check...');

    // 1. 检查功能是否开启
    final settings = await _settingsService.watchBackupSettings().first;

    // 2. 扫描仅本地状态的媒体资源，并传入时间段
    _log.info(
      'Scanning for local assets from ${settings.backupStartDate} to ${settings.backupEndDate}',
    );
    final localAssets = await _mediaAssetDao.getLocalOnlyAssets(
      startDate: settings.backupStartDate,
      endDate: settings.backupEndDate,
    );

    if (localAssets.isEmpty) {
      _log.info('No new local media assets to back up in the given timeframe.');
      return 'No new assets found.';
    }

    _log.info('Found ${localAssets.length} local media assets to back up.');

    // 3. 将 List<MediaAsset> 转换为 List<UnifiedMediaEntity>
    final List<UnifiedMediaEntity> entitiesToUpload = localAssets
        .map((asset) => UnifiedMediaEntity.fromDbModel(asset))
        .toList();

    if (entitiesToUpload.isEmpty) {
      _log.warning(
        'Found local assets but failed to convert them to entities. Skipping enqueue.',
      );
      return 'Assets found but could not be converted.';
    }

    // 4. 调用接口加入上传队列

    final uploadService = getIt<BackupgroundUploadService>();
    await uploadService.enqueueMultipleJobs(entitiesToUpload);

    _log.info(
      'Successfully enqueued ${entitiesToUpload.length} assets for upload.',
    );
    return 'Enqueued ${entitiesToUpload.length} assets.';
  }
}

@lazySingleton
class BackupgroundUploadService {
  final AppDatabase _db;
  final UploadJobDao _uploadJobDao;
  final MediaAssetDao _mediaAssetDao;
  final SettingsService _settingsService;
  // [认证优化]: 注入认证处理器
  final UploadAuthHandler _authHandler;
  final _downloaderCompleter = Completer<FileDownloader>();

  final _log = Logger('BackupgroundUploadService');
  final _uuid = const Uuid();

  BackupgroundUploadService(
    AppDatabase db,
    this._settingsService,
    this._authHandler,
  ) : _db = db,
      _uploadJobDao = db.uploadJobDao,
      _mediaAssetDao = db.mediaAssetDao;

  Future<FileDownloader> _getDownloader() {
    if (!_downloaderCompleter.isCompleted) {
      _initializeDownloader();
    }
    return _downloaderCompleter.future;
  }

  Future<void> _initializeDownloader() async {
    _log.info('Initializing FileDownloader for UploadService...');
    final downloader = FileDownloader();

    final permissionStatus = await downloader.permissions.status(
      PermissionType.notifications,
    );
    if (permissionStatus != PermissionStatus.granted) {
      await downloader.permissions.request(PermissionType.notifications);
    }

    // 4. 全局和平台特定配置 (从 TransferManager 迁移)
    await downloader.configure(
      globalConfig: [
        (Config.holdingQueue, (1, 1, 1)),
        (Config.runInForeground, Config.always),
        (Config.runInForegroundIfFileLargerThan, 256),
      ],
      androidConfig: [
        (
          Config.localize,
          {
            'bg_downloader_notification_channel_name': '文件传输',
            'bg_downloader_notification_channel_description':
                '后台上传任务', // 可以细化为上传
            'bg_downloader_cancel': '取消',
            'bg_downloader_pause': '暂停',
            'bg_downloader_resume': '继续',
          },
        ),
      ],
      // [认证优化]: 移除onTaskStart配置，改为在任务创建时使用Auth对象
    );

    // 5. 通知配置 (从 TransferManager 迁移)
    downloader.configureNotification(
      running: TaskNotification('上传中', '{displayName} — {progress}'),
      complete: TaskNotification('上传完成', '{displayName}'),
      error: TaskNotification('上传失败', '{displayName}'),
      paused: TaskNotification('已暂停', '{displayName}'),
      canceled: TaskNotification('已取消', '{displayName}'),
      progressBar: true,
    );

    // 6. 注册回调 (从 TransferManager 迁移, 但仅处理与上传相关的逻辑)
    downloader.registerCallbacks(
      taskNotificationTapCallback: (task, type) async {
        _log.info(
          'Upload notification tapped: taskId=${task.taskId}, type=$type',
        );
        // 上传完成的点击事件通常不需要做什么，可以留空或自定义逻辑
      },
    );

    // 7. 设置认证失败回调
    _authHandler.setAuthFailureCallback(() {
      _log.warning('后台上传任务认证失败，可能需要重新登录');
      // 这里可以触发全局的认证失败处理
      // 例如：通知用户重新登录
    });

    // 8. 启动下载器并监听更新
    await downloader.start();
    downloader.updates.listen(_onTaskUpdate);

    _log.info(
      "FileDownloader for UploadService initialized and listening for updates.",
    );

    // 9. 完成 Completer，让等待的调用可以获取到实例
    _downloaderCompleter.complete(downloader);
  }

  void _onTaskUpdate(dynamic update) {
    // 这个监听器现在只接收到这个 downloader 实例的任务更新
    switch (update) {
      case TaskStatusUpdate():
        // 由于这个 downloader 只处理上传，我们不需要再检查 task 类型
        handleUploadStatusUpdate(update.task, update.status, update.exception);
        break;
      case TaskProgressUpdate():
        handleUploadProgressUpdate(update.task, update.progress);
        break;
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

  Future<void> enqueueMultipleJobs(
    List<UnifiedMediaEntity> unifiedMediaEntity,
  ) async {
    final List<UploadTaskPayload> uploadTasks =
        await _prepareUploadTasksInMainIsolate(unifiedMediaEntity);

    if (uploadTasks.isEmpty) {
      debugPrint("后台任务：没有找到可上传的文件。");
      return;
    }

    _log.info('开始批量入队 ${uploadTasks.length} 个上传任务。');

    final downloader = await _getDownloader();

    for (final pl in uploadTasks) {
      try {
        await _enqueueUploadJob(pl, downloader);
      } catch (e, st) {
        _log.severe('入队上传任务 (资源 ${pl.assetId}) 失败', e, st);
        await _mediaAssetDao.updateMediaAssetWithlocalId(
          pl.assetId,
          MediaAssetsCompanion(syncStatus: d.Value(SyncStatus.uploadFailed)),
        );
      }
    }
  }

  Future<String> _enqueueUploadJob(
    UploadTaskPayload taskPayload,
    FileDownloader downloader,
  ) async {
    final jobId = _uuid.v4();
    final cloudUuid = _uuid.v4();
    final totalSize = await taskPayload.file.length();
    final filename = p.basename(taskPayload.file.path);
    final fileHash = await compute(calculateFileHash, taskPayload.file);

    final backupSettings = await _settingsService.watchBackupSettings().first;
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
        _log.severe("当前网络环境不满足上传条件");
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
        group: 'backupground_upload_group',
        // [认证优化]: 使用TaskOptions配置onTaskStart回调
        options: TaskOptions(
          onTaskStart: UploadAuthHandler.onTaskStart,
        ),
      );

      // _taskQueue.add(task);
      await downloader.enqueue(task);
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

  Future<List<UploadTaskPayload>> _prepareUploadTasksInMainIsolate(
    List<UnifiedMediaEntity> entities,
  ) async {
    final List<Future<UploadTaskPayload?>> futures = entities.map((
      entity,
    ) async {
      try {
        AssetEntity? asset;
        if (entity.assetEntity != null) {
          asset = entity.assetEntity;
        } else if (entity.localId != null) {
          asset = await AssetEntity.fromId(entity.localId!);
        }

        if (asset == null) {
          debugPrint('无法为实体 ${entity.id} 找到 AssetEntity，跳过上传。');
          return null;
        }

        final File? file = await asset.originFile;

        if (file != null) {
          return UploadTaskPayload(
            file: file,
            assetId: asset.id,
            mediaType: asset.type.toMediaType(),
            mediaTakenAt: asset.createDateTime, // 使用 AssetEntity 的 createDateTime（拍摄时间或创建时间）
          );
        } else {
          debugPrint('无法为 Asset ${asset.id} 获取文件，跳过上传。');
          return null;
        }
      } catch (e) {
        debugPrint('处理实体 ${entity.id} 时发生错误: $e');
        return null;
      }
    }).toList();

    final List<UploadTaskPayload?> results = await Future.wait(futures);

    return results.whereType<UploadTaskPayload>().toList();
  }
}

class UploadFileInput {
  final File file;
  final String assetId;
  final MediaType mediaType;
  final DateTime mediaTakenAt;
  UploadFileInput({
    required this.file,
    required this.assetId,
    required this.mediaType,
    required this.mediaTakenAt,
  });
}

extension BackupgroundUploadServiceExtensions on BackupgroundUploadService {
  Future<void> enqueueFromFiles(List<UploadFileInput> inputs) async {
    if (inputs.isEmpty) return;
    final downloader = await _getDownloader();
    for (final i in inputs) {
      final payload = UploadTaskPayload(
        file: i.file,
        assetId: i.assetId,
        mediaType: i.mediaType,
        mediaTakenAt: i.mediaTakenAt,
      );
      try {
        await _enqueueUploadJob(payload, downloader);
      } catch (e, st) {
        _log.severe('入队上传任务 (资源 ${i.assetId}) 失败', e, st);
        await _mediaAssetDao.updateMediaAssetWithlocalId(
          i.assetId,
          MediaAssetsCompanion(syncStatus: d.Value(SyncStatus.uploadFailed)),
        );
      }
    }
  }
}
