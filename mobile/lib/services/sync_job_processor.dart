// lib/services/sync_job_processor.dart

import 'dart:io';
import 'dart:developer';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:mobile/data/datasources/app_database.dart';
import 'package:mobile/data/datasources/remote_media_source.dart';
import 'package:mobile/data/models/media/media_model.dart';

@injectable
class SyncJobProcessor {
  final AppDatabase db;
  final RemoteMediaDataSource remoteApi;

  SyncJobDao get _syncJobDao => db.syncJobDao;
  MediaAssetDao get _mediaAssetDao => db.mediaAssetDao;

  SyncJobProcessor({required this.db, required this.remoteApi});

  Future<bool> processNextJob() async {
    final job = await _syncJobDao.getNextPendingJob();

    if (job == null) {
      log('队列中没有待处理的任务。', name: 'SyncJobProcessor');
      return false;
    }

    log('开始处理任务 #${job.id}，类型: ${job.jobType}', name: 'SyncJobProcessor');
    await _syncJobDao.updateJob(
      job.id,
      const SyncJobsCompanion(status: Value(JobStatus.inProgress)),
    );

    try {
      switch (job.jobType) {
        case JobType.UPLOAD:
          await _handleUploadJob(job);
          break;
        case JobType.DELETE_CLOUD:
          await _handleDeleteCloudJob(job);
          break;
        case JobType.SYNC_CLOUD_CHANGES:
          await _handleSyncCloudChangesJob(job);
          break;
        default:
          log(
            '任务类型 ${job.jobType} 尚未实现。',
            name: 'SyncJobProcessor',
            level: 900,
          );
          await _syncJobDao.deleteJob(job.id);
      }
      log('成功处理任务 #${job.id}', name: 'SyncJobProcessor');
    } catch (e, stacktrace) {
      log(
        '处理任务 #${job.id} 失败',
        name: 'SyncJobProcessor',
        error: e,
        stackTrace: stacktrace,
        level: 1000,
      );
      await _syncJobDao.updateJobStatus(
        job.id,
        JobStatus.failed,
        errorMessage: e.toString(),
      );
    }
    return true;
  }

  Future<void> _handleUploadJob(SyncJob job) async {
    final asset = await (_mediaAssetDao.select(
      _mediaAssetDao.mediaAssets,
    )..where((tbl) => tbl.id.equals(job.assetId))).getSingleOrNull();
    if (asset == null || asset.filePath == null) {
      throw Exception('任务 #${job.id} 对应的资产不存在或没有文件路径。');
    }
    if (asset.contentHash == null) {
      throw Exception('资产 #${asset.id} 缺少 contentHash，无法上传。');
    }

    final file = File(asset.filePath!);
    if (!await file.exists()) {
      throw Exception('文件不存在于路径: ${asset.filePath}');
    }
    final fileBytes = await file.readAsBytes();

    final MediaResponse cloudMedia = await remoteApi.uploadMedia(
      file: fileBytes,
      hash: asset.contentHash!,
      itemType: asset.assetType,
      originalFilename: asset.fileName,
    );

    await _mediaAssetDao.updateAsset(
      MediaAssetsCompanion(
        id: Value(asset.id),
        cloudUuid: Value(cloudMedia.uuid),
        syncStatus: const Value(SyncStatus.synced),
      ),
    );

    await _syncJobDao.deleteJob(job.id);
  }

  Future<void> _handleDeleteCloudJob(SyncJob job) async {
    final cloudUuid = job.relatedCloudUuid;
    if (cloudUuid == null) {
      throw Exception('无法删除云端资产 (任务 #${job.id})，缺少 relatedCloudUuid。');
    }
    await remoteApi.deleteMedia(cloudUuid);
    await _syncJobDao.deleteJob(job.id);
  }

  Future<void> _handleSyncCloudChangesJob(SyncJob job) async {
    final MediaChangesResponse changes = await remoteApi.getChanges();

    final List<MediaAssetsCompanion> toUpsert = [];

    final allChangedMedia = [...changes.created, ...changes.updated];

    for (var media in allChangedMedia) {
      toUpsert.add(
        MediaAssetsCompanion(
          cloudUuid: Value(media.uuid),
          fileName: Value(media.originalFilename),

          assetType: Value(
            media.itemType.toUpperCase() == 'IMAGE'
                ? MediaType.image
                : MediaType.video,
          ),

          createdAt: Value(DateTime.parse(media.createdAt)),
          updatedAt: Value(DateTime.parse(media.updatedAt)),

          syncStatus: const Value(SyncStatus.cloudOnly),
        ),
      );
    }

    final uuidsToDelete = changes.deleted;

    await _mediaAssetDao.applyCloudChanges(
      toUpsert: toUpsert,
      uuidsToDelete: uuidsToDelete,
    );

    await _syncJobDao.deleteJob(job.id);
  }
}
