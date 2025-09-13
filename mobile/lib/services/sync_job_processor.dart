// lib/services/sync_job_processor.dart

import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:mobile/core/enums.dart';
import 'package:mobile/data/datasources/remote_media_source.dart';
import 'package:mobile/data/models/media/media_model.dart';

@injectable
class SyncJobProcessor {
  // 创建一个 Logger 实例
  final _log = Logger('SyncJobProcessor');

  final AppDatabase db;
  final RemoteMediaDataSource remoteApi;

  SyncJobDao get _syncJobDao => db.syncJobDao;
  MediaAssetDao get _mediaAssetDao => db.mediaAssetDao;

  SyncJobProcessor({required this.db, required this.remoteApi});

  Future<bool> processNextJob() async {
    // 建议保留我们在上一轮添加的网络检查逻辑
    // final connectivityResult = await (Connectivity().checkConnectivity());
    // if (connectivityResult == ConnectivityResult.none) {
    //   _log.info('No network connection, skipping this processing cycle.');
    //   return false;
    // }

    _log.fine('Checking for the next pending job in the queue...');
    final job = await _syncJobDao.getNextPendingJob();

    if (job == null) {
      _log.fine('No pending jobs in the queue.');
      return false;
    }

    _log.info(
      'Starting to process job #${job.id}, Type: ${job.jobType}, AssetID: ${job.assetId}, CloudUUID: ${job.relatedCloudUuid}',
    );
    await _syncJobDao.updateJob(
      job.id,
      const SyncJobsCompanion(status: Value(JobStatus.inProgress)),
    );
    _log.fine('Job #${job.id} status updated to inProgress.');

    try {
      switch (job.jobType) {
        case JobType.deleteCloud:
          await _handleDeleteCloudJob(job);
          break;
        case JobType.syncCloudChanges:
          await _handleSyncCloudChangesJob(job);
          break;

        default:
          _log.warning(
            'Job type ${job.jobType} is not implemented yet. Deleting job #${job.id}.',
          );
          await _syncJobDao.deleteJob(job.id);
      }
      _log.info('Successfully processed and completed job #${job.id}.');
    } catch (e, stacktrace) {
      _log.severe(
        'Failed to process job #${job.id}. It will be deleted to prevent repeated failures.',
        e,
        stacktrace,
      );

      // 考虑增加重试逻辑而不是立即删除
      // 比如：增加一个 retryCount 字段，或者将状态设为 failed
      await _syncJobDao.deleteJob(job.id);
      _log.warning('Job #${job.id} has been deleted after failure.');
    }
    return true;
  }

  Future<void> _handleDeleteCloudJob(SyncJob job) async {
    _log.info('Handling deleteCloud job #${job.id}.');
    final cloudUuid = job.relatedCloudUuid;
    if (cloudUuid == null) {
      _log.severe(
        'Cannot delete cloud asset for job #${job.id}, relatedCloudUuid is missing.',
      );
      // 抛出异常以触发上层的 catch 块
      throw Exception(
        'Cannot delete cloud asset (job #${job.id}), missing relatedCloudUuid.',
      );
    }
    _log.info('Requesting remote API to delete media with UUID: $cloudUuid');
    await remoteApi.deleteMedia(cloudUuid);
    _log.info('Remote media with UUID: $cloudUuid deleted successfully.');

    await _syncJobDao.deleteJob(job.id);
    _log.fine('Local delete job #${job.id} removed from queue.');
  }

  Future<void> _handleSyncCloudChangesJob(SyncJob job) async {
    _log.info(
      'Handling syncCloudChanges job #${job.id}. Fetching changes from remote API...',
    );
    final MediaChangesResponse changes = await remoteApi.getChanges();
    _log.info(
      'Received cloud changes: ${changes.created.length} created, ${changes.updated.length} updated, ${changes.deleted.length} deleted.',
    );

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
    _log.fine('Prepared ${toUpsert.length} assets for upserting.');

    final uuidsToDelete = changes.deleted;
    _log.fine('Prepared ${uuidsToDelete.length} UUIDs for deletion.');

    await _mediaAssetDao.applyCloudChanges(
      toUpsert: toUpsert,
      uuidsToDelete: uuidsToDelete,
    );
    _log.info('Successfully applied cloud changes to the local database.');

    await _syncJobDao.deleteJob(job.id);
    _log.fine('Local syncCloudChanges job #${job.id} removed from queue.');
  }
}
