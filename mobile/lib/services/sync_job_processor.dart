// lib/services/sync_job_processor.dart

import 'dart:developer';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:mobile/core/enums.dart';
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
    // 建议保留我们在上一轮添加的网络检查逻辑
    // final connectivityResult = await (Connectivity().checkConnectivity());
    // if (connectivityResult == ConnectivityResult.none) {
    //   log('没有网络连接，跳过本次任务处理循环。', name: 'SyncJobProcessor');
    //   return false;
    // }

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
        case JobType.deleteCloud:
          await _handleDeleteCloudJob(job);
          break;
        case JobType.syncCloudChanges:
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
        '处理任务 #${job.id} 失败, stacktrace: $stacktrace',
        name: 'SyncJobProcessor',
        error: e,
        stackTrace: stacktrace,
        level: 1000,
      );

      await _syncJobDao.deleteJob(job.id);
    }
    return true;
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
          contentHash: Value(media.hash),
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
