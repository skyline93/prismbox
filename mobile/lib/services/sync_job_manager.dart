// lib/services/sync_job_manager.dart

import 'dart:io';
import 'dart:developer';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:mobile/core/enums.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:path/path.dart' as p;
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/services/background_service_manager.dart';

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
      // 1. 检查此“文件实例”是否已被记录。这是唯一的“重复”检查。
      final existingAsset = await _mediaAssetDao.getAssetByLocalId(asset.id);
      if (existingAsset != null) {
        // 如果这个 localId 已经处理过，直接返回。
        // 补录哈希的逻辑仍然可以保留，以防上次处理失败。
        if (existingAsset.contentHash == null) {
          final contentHash = await _calculateFileHash(asset);
          if (contentHash != null) {
            final companion = MediaAssetsCompanion(
              id: Value(existingAsset.id),
              contentHash: Value(contentHash),
            );
            await (_mediaAssetDao.update(_mediaAssetDao.mediaAssets)
                  ..where((tbl) => tbl.id.equals(existingAsset.id)))
                .write(companion);
          }
        }
        return;
      }

      // 2. 为这个新文件计算哈希
      final contentHash = await _calculateFileHash(asset);
      if (contentHash == null) {
        log('[SyncJobManager] 无法计算资产 ${asset.id} 的哈希值，跳过。');
        return;
      }

      // 3. 将 AssetEntity 转换为数据库实体
      final companion = await _assetEntityToCompanion(asset);
      if (companion == null) {
        log('[SyncJobManager] 无法处理资产 ${asset.id}，跳过。');
        return;
      }

      // 4. 【核心逻辑】为这个新文件实例在本地数据库中创建一条全新的记录
      // 注意：我们不再检查 contentHash 是否重复来阻止插入。
      await _mediaAssetDao.insertMediaAsset(
        companion.copyWith(
          contentHash: Value(contentHash),
          syncStatus: Value(
            isAutoBackupEnabled
                ? SyncStatus.uploading
                : SyncStatus.localOnlyNotSelected,
          ),
        ),
      );

      // 5. 创建同步任务
      if (isAutoBackupEnabled) {
        // TODO
      }
    } catch (e, s) {
      log('[SyncJobManager] 创建上传任务时出错', error: e, stackTrace: s);
    }
  }

  Future<String?> _calculateFileHash(AssetEntity asset) async {
    try {
      // 【根本性修改】使用 asset.originFile
      // 它能可靠地提供一个文件对象，即使文件在云端也会先下载到本地。
      final File? file = await asset.originFile;

      if (file == null) {
        log('[SyncJobManager] 无法获取资产 ${asset.id} 的源文件。可能是网络或云端问题。');
        return null;
      }

      // 既然我们有了一个可靠的 File 对象，就可以安全地使用文件流来计算哈希，避免OOM。
      final stream = file.openRead();
      final hash = await sha256.bind(stream).first;
      return hash.toString();
    } catch (e, s) {
      // 捕获在下载或读取文件过程中可能发生的任何异常 (例如网络中断)。
      log(
        '[SyncJobManager] 在获取或哈希资产 ${asset.id} 的源文件时发生异常',
        error: e,
        stackTrace: s,
      );
      return null;
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

  // Future<void> createDownloadJob(UnifiedMediaEntity entity) async {
  //   final existingJob =
  //       await (_syncJobDao.select(_syncJobDao.syncJobs)..where(
  //             (tbl) =>
  //                 tbl.assetId.equals(entity.id) &
  //                 tbl.jobType.equalsValue(JobType.downloadOriginal) &
  //                 tbl.status.equalsValue(JobStatus.pending),
  //           ))
  //           .getSingleOrNull();

  //   if (existingJob != null) {
  //     log('[SyncJobManager] 资产 ${entity.id} 已存在待处理的下载任务，跳过。');
  //     return;
  //   }

  //   try {
  //     await _db.transaction(() async {
  //       await _mediaAssetDao.updateAssetStatus(
  //         entity.id,
  //         SyncStatus.downloading,
  //       );

  //       await _syncJobDao
  //           .into(_syncJobDao.syncJobs)
  //           .insert(
  //             SyncJobsCompanion.insert(
  //               assetId: Value(entity.id),
  //               jobType: JobType.downloadOriginal,
  //               status: JobStatus.pending,
  //               priority: Value(10),
  //             ),
  //           );
  //     });
  //     log('[SyncJobManager] 已为资产 ${entity.id} 创建下载任务。');

  //     BackgroundServiceManager.triggerImmediateSync();
  //   } catch (e, s) {
  //     log('[SyncJobManager] 创建下载任务时出错', error: e, stackTrace: s);
  //     await _mediaAssetDao.updateAssetStatus(entity.id, SyncStatus.cloudOnly);
  //   }
  // }

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

  Future<void> createUploadJobForExistingAsset(
    UnifiedMediaEntity entity,
  ) async {
    // 1. 检查是否已有待处理的任务（上传或下载），避免重复
    final existingJob =
        await (_syncJobDao.select(_syncJobDao.syncJobs)..where(
              (tbl) =>
                  tbl.assetId.equals(entity.id) &
                  (tbl.jobType.equalsValue(JobType.upload)) &
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
