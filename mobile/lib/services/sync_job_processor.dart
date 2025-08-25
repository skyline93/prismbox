// lib/services/sync_job_processor.dart

import 'dart:io';
import 'dart:developer';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:mobile/data/datasources/local_db/enums.dart';
import 'package:mobile/data/datasources/remote_media_source.dart';
import 'package:mobile/data/models/media/media_model.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

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
        case JobType.upload:
          await _handleUploadJob(job);
          break;
        case JobType.deleteCloud:
          await _handleDeleteCloudJob(job);
          break;
        case JobType.syncCloudChanges:
          await _handleSyncCloudChangesJob(job);
          break;
        case JobType.downloadOriginal:
          await _handleDownloadOriginalJob(job);
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
      await _syncJobDao.updateJobStatus(
        job.id,
        JobStatus.failed,
        errorMessage: e.toString(),
      );
    }
    return true;
  }

  Future<void> _handleDownloadOriginalJob(SyncJob job) async {
    final assetId = job.assetId;
    if (assetId == null) {
      throw Exception('任务 #${job.id} (downloadOriginal) 缺少必需的 assetId。');
    }

    // [+] 从 payload 解析参数
    final payload = jsonDecode(job.payload);
    final String? cloudUuid = payload['cloudUuid'];
    final String? destinationPath = payload['destinationPath'];

    if (cloudUuid == null || destinationPath == null) {
      throw Exception('任务 #${job.id} 的 payload 无效。');
    }

    final asset = await (_mediaAssetDao.select(
      _mediaAssetDao.mediaAssets,
    )..where((tbl) => tbl.id.equals(assetId))).getSingleOrNull();

    if (asset == null) {
      throw Exception('任务 #${job.id} 对应的资产不存在。');
    }
    if (asset.cloudUuid == null) {
      throw Exception('资产 #${asset.id} 缺少 cloudUuid，无法下载。');
    }

    log('开始下载资产: ${asset.cloudUuid}', name: 'SyncJobProcessor');
    final fileBytes = await remoteApi.downloadOriginalMedia(asset.cloudUuid!);

    final file = File(destinationPath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(fileBytes);
    log('文件已保存至: $destinationPath', name: 'SyncJobProcessor');

    await _mediaAssetDao.updateAsset(
      MediaAssetsCompanion(
        id: Value(asset.id),
        filePath: Value(destinationPath),
        syncStatus: const Value(SyncStatus.synced),
        updatedAt: Value(DateTime.now()),
      ),
    );
    log('数据库记录 #${asset.id} 已更新。', name: 'SyncJobProcessor');

    await _syncJobDao.deleteJob(job.id);
  }

  Future<void> _handleUploadJob(SyncJob job) async {
    final assetId = job.assetId;
    if (assetId == null) {
      throw Exception('任务 #${job.id} (upload) 缺少必需的 assetId。');
    }

    // [+] 从 payload 解析参数
    final payload = jsonDecode(job.payload);
    final String filePath = payload['filePath'];

    final asset = await (_mediaAssetDao.select(
      _mediaAssetDao.mediaAssets,
    )..where((tbl) => tbl.id.equals(assetId))).getSingleOrNull();

    if (asset == null || asset.filePath == null) {
      throw Exception('任务 #${job.id} 对应的资产不存在或没有文件路径。');
    }
    // 注意：在您的原代码中，这里检查了 contentHash，如果下载逻辑不生成hash，上传会失败
    // 您可能需要一个计算文件hash的通用服务
    // if (asset.contentHash == null) {
    //   throw Exception('资产 #${asset.id} 缺少 contentHash，无法上传。');
    // }

    final file = File(filePath);
    if (!await file.exists()) {
      log('上传失败：文件 $filePath 不存在。', name: 'SyncJobProcessor');
      await _mediaAssetDao.updateAssetStatus(asset.id, SyncStatus.error);
      await _syncJobDao.deleteJob(job.id);
      return;
    }
    final fileBytes = await file.readAsBytes();

    // 2. 计算真实的 SHA256 哈希值
    final String realHash = sha256.convert(fileBytes).toString();

    // 3. 将 MediaType 枚举转换为后端期望的字符串
    final String itemTypeString = asset.assetType == MediaType.video
        ? 'VIDEO'
        : 'IMAGE';

    log(
      '准备上传: hash=$realHash, type=$itemTypeString, filename=${asset.fileName}',
    );

    final MediaResponse cloudMedia = await remoteApi.uploadMedia(
      file: fileBytes,
      hash: realHash,
      itemType: asset.assetType,
      originalFilename: asset.fileName,
    );

    await _mediaAssetDao.updateAsset(
      MediaAssetsCompanion(
        id: Value(asset.id),
        cloudUuid: Value(cloudMedia.uuid),
        contentHash: Value(realHash),
        syncStatus: const Value(SyncStatus.synced),
        updatedAt: Value(DateTime.now()),
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
