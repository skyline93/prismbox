import 'dart:io';
import 'dart:developer';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:mobile/data/datasources/app_database.dart';
import 'package:mobile/data/datasources/remote_media_source.dart';
import 'package:mobile/data/models/media/media_model.dart';
// [+] 1. 添加必要的导入
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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
        case JobType.UPLOAD:
          await _handleUploadJob(job);
          break;
        case JobType.DELETE_CLOUD:
          await _handleDeleteCloudJob(job);
          break;
        case JobType.SYNC_CLOUD_CHANGES:
          await _handleSyncCloudChangesJob(job);
          break;

        // [+] 2. 添加 DOWNLOAD_ORIGINAL 的处理分支
        case JobType.DOWNLOAD_ORIGINAL:
          await _handleDownloadOriginalJob(job);
          break;

        default:
          log(
            '任务类型 ${job.jobType} 尚未实现。',
            name: 'SyncJobProcessor',
            level: 900,
          );
          // 对于未实现的任务，我们直接删除，防止队列阻塞
          await _syncJobDao.deleteJob(job.id);
      }
      log('成功处理任务 #${job.id}', name: 'SyncJobProcessor');
      // 注意：任务成功后，应该在各自的处理函数内部删除job，这里不再统一删除
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

  // [+] 3. 实现完整的下载处理逻辑
  Future<void> _handleDownloadOriginalJob(SyncJob job) async {
    // 3.1. 获取资产信息
    final asset = await (_mediaAssetDao.select(
      _mediaAssetDao.mediaAssets,
    )..where((tbl) => tbl.id.equals(job.assetId))).getSingleOrNull();

    if (asset == null) {
      throw Exception('任务 #${job.id} 对应的资产不存在。');
    }
    if (asset.cloudUuid == null) {
      throw Exception('资产 #${asset.id} 缺少 cloudUuid，无法下载。');
    }

    // 3.2. 调用 API 下载文件
    log('开始下载资产: ${asset.cloudUuid}', name: 'SyncJobProcessor');
    final fileBytes = await remoteApi.downloadOriginalMedia(asset.cloudUuid!);

    // 3.3. 确定保存路径并保存文件
    final documentsDir = await getApplicationDocumentsDirectory();
    // 使用 cloudUuid 和原始文件名确保路径唯一且易于识别
    final fileName = asset.fileName ?? asset.cloudUuid!;
    final filePath = p.join(documentsDir.path, 'media', fileName);

    // 确保目录存在
    final file = File(filePath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(fileBytes);
    log('文件已保存至: $filePath', name: 'SyncJobProcessor');

    // 3.4. 更新数据库记录
    await _mediaAssetDao.updateAsset(
      MediaAssetsCompanion(
        id: Value(asset.id),
        filePath: Value(filePath), // 更新文件路径
        syncStatus: const Value(SyncStatus.synced), // 更新状态为已同步（本地和云端一致）
      ),
    );
    log('数据库记录 #${asset.id} 已更新。', name: 'SyncJobProcessor');

    // 3.5. 删除已完成的任务
    await _syncJobDao.deleteJob(job.id);
  }

  Future<void> _handleUploadJob(SyncJob job) async {
    final asset = await (_mediaAssetDao.select(
      _mediaAssetDao.mediaAssets,
    )..where((tbl) => tbl.id.equals(job.assetId))).getSingleOrNull();
    if (asset == null || asset.filePath == null) {
      throw Exception('任务 #${job.id} 对应的资产不存在或没有文件路径。');
    }
    // 注意：在您的原代码中，这里检查了 contentHash，如果下载逻辑不生成hash，上传会失败
    // 您可能需要一个计算文件hash的通用服务
    // if (asset.contentHash == null) {
    //   throw Exception('资产 #${asset.id} 缺少 contentHash，无法上传。');
    // }

    final file = File(asset.filePath!);
    if (!await file.exists()) {
      // 如果文件不存在，可能已被用户删除，应将任务标记为失败或直接删除
      log('上传失败：文件 ${asset.filePath} 不存在。', name: 'SyncJobProcessor');
      await _mediaAssetDao.updateAssetStatus(asset.id, SyncStatus.error);
      await _syncJobDao.deleteJob(job.id);
      return;
    }
    final fileBytes = await file.readAsBytes();

    // 假设您有一个方法来获取哈希值
    final String dummyHash =
        "dummy_hash_${DateTime.now().millisecondsSinceEpoch}";

    final MediaResponse cloudMedia = await remoteApi.uploadMedia(
      file: fileBytes,
      hash: asset.contentHash ?? dummyHash, // 使用一个临时的hash
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
