// lib/services/sync_job_manager.dart

import 'dart:io';
import 'dart:developer';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:mobile/data/datasources/local_db/enums.dart';
import 'package:mobile/data/models/media/media_model.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:path/path.dart' as p;
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/services/background_service_manager.dart';
import 'package:path_provider/path_provider.dart';

@lazySingleton
class SyncJobManager {
  final AppDatabase _db;
  final MediaAssetDao _mediaAssetDao;
  final SyncJobDao _syncJobDao;

  SyncJobManager(this._db)
    : _mediaAssetDao = _db.mediaAssetDao,
      _syncJobDao = _db.syncJobDao;

  Future<void> createUploadJobForNewAsset(
    AssetEntity asset, {
    required bool isAutoBackupEnabled,
  }) async {
    try {
      // 1. 防止重复处理
      final existingAsset = await (_mediaAssetDao.select(
        _mediaAssetDao.mediaAssets,
      )..where((tbl) => tbl.localId.equals(asset.id))).getSingleOrNull();

      if (existingAsset != null) {
        // 如果资产已存在，无需任何操作
        return;
      }

      // 2. 将 AssetEntity 转换为数据库实体
      final companion = await _assetEntityToCompanion(asset);
      if (companion == null) {
        log('[SyncJobManager] 无法处理资产 ${asset.id}，跳过。');
        return;
      }

      final newDbId = await _mediaAssetDao.insertMediaAsset(
        companion.copyWith(
          syncStatus: Value(
            isAutoBackupEnabled
                ? SyncStatus.uploading
                : SyncStatus.localOnlyNotSelected,
          ),
        ),
      );

      if (isAutoBackupEnabled) {
        final payload = jsonEncode({'filePath': companion.filePath.value});

        await _syncJobDao
            .into(_syncJobDao.syncJobs)
            .insert(
              SyncJobsCompanion.insert(
                assetId: Value(newDbId),
                jobType: JobType.upload,
                status: JobStatus.pending,
                priority: Value(1),
                payload: Value(payload),
              ),
            );
        log('[SyncJobManager] 已为新资产 ${asset.id} 创建上传任务。');
        BackgroundServiceManager.triggerImmediateSync();
      } else {
        log('[SyncJobManager] 已为新资产 ${asset.id} 创建本地记录。');
      }
    } catch (e, s) {
      log('[SyncJobManager] 创建上传任务时出错', error: e, stackTrace: s);
    }
  }

  Future<void> handleLocalAssetDeletion(String localId) async {
    final assetToDelete = await (_mediaAssetDao.select(
      _mediaAssetDao.mediaAssets,
    )..where((tbl) => tbl.localId.equals(localId))).getSingleOrNull();

    if (assetToDelete != null) {
      log('[SyncJobManager] 本地资产 $localId 已被删除，执行乐观删除...');
      await _mediaAssetDao.performOptimisticDelete(assetToDelete);

      BackgroundServiceManager.triggerImmediateSync();
    }
  }

  Future<void> createCloudChangesSyncJob({int priority = 0}) async {
    final existingJob =
        await (_syncJobDao.select(_syncJobDao.syncJobs)..where(
              (tbl) =>
                  tbl.jobType.equalsValue(JobType.syncCloudChanges) &
                  tbl.status.equalsValue(JobStatus.pending),
            ))
            .getSingleOrNull();

    if (existingJob != null) {
      log('[SyncJobManager] 已存在待处理的云端同步任务，跳过创建。');
      return;
    }

    await _syncJobDao
        .into(_syncJobDao.syncJobs)
        .insert(
          SyncJobsCompanion.insert(
            jobType: JobType.syncCloudChanges,
            status: JobStatus.pending,
            priority: Value(priority),
          ),
        );
    log('[SyncJobManager] 已创建检查云端变更的任务。');

    BackgroundServiceManager.triggerImmediateSync();
  }

  Future<void> createDownloadJob(UnifiedMediaEntity entity) async {
    final existingJob =
        await (_syncJobDao.select(_syncJobDao.syncJobs)..where(
              (tbl) =>
                  tbl.assetId.equals(entity.id) &
                  tbl.jobType.equalsValue(JobType.downloadOriginal) &
                  tbl.status.equalsValue(JobStatus.pending),
            ))
            .getSingleOrNull();

    if (existingJob != null) {
      log('[SyncJobManager] 资产 ${entity.id} 已存在待处理的下载任务，跳过。');
      return;
    }

    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final fileName = entity.fileName ?? entity.cloudUuid!;
      final destinationPath = p.join(documentsDir.path, 'media', fileName);

      final payload = jsonEncode({
        'destinationPath': destinationPath,
        'cloudUuid': entity.cloudUuid,
      });

      await _db.transaction(() async {
        await _mediaAssetDao.updateAssetStatus(
          entity.id,
          SyncStatus.downloading,
        );

        await _syncJobDao
            .into(_syncJobDao.syncJobs)
            .insert(
              SyncJobsCompanion.insert(
                assetId: Value(entity.id),
                jobType: JobType.downloadOriginal,
                status: JobStatus.pending,
                priority: Value(10),
                payload: Value(payload),
              ),
            );
      });
      log('[SyncJobManager] 已为资产 ${entity.id} 创建下载任务。');

      BackgroundServiceManager.triggerImmediateSync();
    } catch (e, s) {
      log('[SyncJobManager] 创建下载任务时出错', error: e, stackTrace: s);
      await _mediaAssetDao.updateAssetStatus(entity.id, SyncStatus.cloudOnly);
    }
  }

  Future<MediaAssetsCompanion?> _assetEntityToCompanion(
    AssetEntity asset,
  ) async {
    final File? file = await asset.file;
    if (file == null) {
      log("[SyncJobManager] 警告: 无法获取资产文件路径: ${asset.id}");
      return null;
    }
    return MediaAssetsCompanion.insert(
      localId: Value(asset.id),
      syncStatus: SyncStatus.localOnlyNotSelected,
      assetType: asset.type == AssetType.video
          ? MediaType.video
          : MediaType.image,
      filePath: Value(file.path),
      fileName: Value(p.basename(file.path)),
      width: Value(asset.width),
      height: Value(asset.height),
      durationSec: Value(asset.duration),
      createdAt: asset.createDateTime,
      updatedAt: DateTime.now(),
    );
  }

  // [+] 新增方法：为已存在的本地资产创建上传任务
  Future<void> createUploadJobForExistingAsset(
    UnifiedMediaEntity entity,
  ) async {
    // 1. 检查是否已有待处理的任务（上传或下载），避免重复
    final existingJob =
        await (_syncJobDao.select(_syncJobDao.syncJobs)..where(
              (tbl) =>
                  tbl.assetId.equals(entity.id) &
                  (tbl.jobType.equalsValue(JobType.upload) |
                      tbl.jobType.equalsValue(JobType.downloadOriginal)) &
                  (tbl.status.equalsValue(JobStatus.pending) |
                      tbl.status.equalsValue(JobStatus.inProgress)),
            ))
            .getSingleOrNull();

    if (existingJob != null) {
      log('[SyncJobManager] 资产 ${entity.id} 已存在待处理的同步任务，跳过创建。');
      return;
    }

    // [+] 确保文件路径存在
    if (entity.filePath == null) {
      log('[SyncJobManager] 资产 ${entity.id} 缺少文件路径，无法创建上传任务。');
      return;
    }

    // [+] 准备 payload
    final payload = jsonEncode({'filePath': entity.filePath});

    try {
      await _db.transaction(() async {
        await _mediaAssetDao.updateAssetStatus(entity.id, SyncStatus.uploading);
        await _syncJobDao
            .into(_syncJobDao.syncJobs)
            .insert(
              SyncJobsCompanion.insert(
                assetId: Value(entity.id),
                jobType: JobType.upload,
                status: JobStatus.pending,
                priority: Value(10),
                payload: Value(payload), // [+] 存储 payload
              ),
            );
      });
      log('[SyncJobManager] 已为资产 ${entity.id} 创建手动上传任务。');

      // 3. 触发后台服务立即处理任务队列
      BackgroundServiceManager.triggerImmediateSync();
    } catch (e, s) {
      log('[SyncJobManager] 创建手动上传任务时出错', error: e, stackTrace: s);
      // 如果失败，将状态恢复，避免UI卡在“上传中”
      await _mediaAssetDao.updateAssetStatus(
        entity.id,
        SyncStatus.localOnlyNotSelected,
      );
    }
  }
}
