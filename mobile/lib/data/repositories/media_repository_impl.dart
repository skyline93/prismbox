// lib/data/repositories/media_repository_impl.dart

import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:photo_manager/photo_manager.dart';

import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/domain/repositories/media_repository.dart';
import 'package:mobile/data/datasources/local_media_source.dart';
import 'package:mobile/data/datasources/remote_media_source.dart';
import 'package:mobile/data/datasources/app_database.dart';
import 'package:mobile/data/models/media/media_model.dart';
import 'package:mobile/core/storage/sync_state_service.dart';

class MediaRepositoryImpl implements MediaRepository {
  final LocalMediaDataSource _localDataSource;
  final RemoteMediaDataSource _cloudDataSource;
  final SyncStateService _syncStateService;
  final MediaAssetDao _mediaAssetDao;

  MediaRepositoryImpl({
    required LocalMediaDataSource localDataSource,
    required RemoteMediaDataSource cloudDataSource,
    required SyncStateService syncStateService,
    required AppDatabase db,
  }) : _localDataSource = localDataSource,
       _cloudDataSource = cloudDataSource,
       _syncStateService = syncStateService,
       _mediaAssetDao = db.mediaAssetDao;

  @override
  Future<void> loadAndIndexLocalMedia() {
    return _localDataSource.scanAndIndexLocalMedia();
  }

  @override
  Stream<List<UnifiedMediaEntity>> getUnifiedMediaStream() {
    return _mediaAssetDao.watchAllMediaAssets().map(
      (dbAssets) => dbAssets.map(UnifiedMediaEntity.fromDbModel).toList(),
    );
  }

  @override
  Future<void> syncWithCloud() async {
    print("Repository: 开始执行云端同步...");
    try {
      final lastSyncTimestamp = await _syncStateService.getLastSyncTimestamp();

      if (lastSyncTimestamp == null) {
        print("Repository: 执行首次全量同步, 清空旧云端数据...");
        await _mediaAssetDao.deleteAllCloudRelatedAssets();
        print("Repository: 旧云端数据已清空。");
      } else {
        print("Repository: 执行增量同步，since: $lastSyncTimestamp");
      }

      final MediaChangesResponse changes = await _cloudDataSource.getChanges(
        since: lastSyncTimestamp,
      );

      final List<MediaAssetsCompanion> companionsToUpsert = [
        ...changes.created,
        ...changes.updated,
      ].map(_convertMediaResponseToCompanion).toList();

      await _mediaAssetDao.applyCloudChanges(
        toUpsert: companionsToUpsert,
        uuidsToDelete: changes.deleted,
      );

      await _syncStateService.setLastSyncTimestamp(DateTime.now());
      print("Repository: 云端同步成功完成。");
    } catch (e) {
      print("Repository: 云端同步失败 - $e");
      rethrow;
    }
  }

  MediaAssetsCompanion _convertMediaResponseToCompanion(
    MediaResponse response,
  ) {
    final assetType = response.itemType.toUpperCase() == 'VIDEO'
        ? MediaType.video
        : MediaType.image;

    final fileName = p.basename(response.originalFilename);

    return MediaAssetsCompanion(
      cloudUuid: Value(response.uuid),
      assetType: Value(assetType),
      syncStatus: Value(SyncStatus.cloudOnly),
      fileName: Value(fileName),
      createdAt: Value(
        DateTime.tryParse(response.mediaTakenAt ?? response.createdAt) ??
            DateTime.now(),
      ),
      updatedAt: Value(DateTime.now()),
    );
  }

  @override
  Future<void> uploadLocalMedia(UnifiedMediaEntity entity) async {
    if (entity.filePath == null ||
        entity.syncStatus != SyncStatus.localOnlyNotSelected) {
      return;
    }
    try {
      await _mediaAssetDao.updateAssetStatus(entity.id, SyncStatus.uploading);
      final file = File(entity.filePath!);
      final fileBytes = await file.readAsBytes();
      final hash = sha1.convert(fileBytes).toString();
      final fileName = p.basename(file.path);

      final response = await uploadMedia(
        file: fileBytes,
        hash: hash,
        itemType: entity.isVideo ? MediaType.video : MediaType.image,
        originalFilename: fileName,
      );

      final companion = MediaAssetsCompanion(
        id: Value(entity.id),
        cloudUuid: Value(response.uuid),
        syncStatus: Value(SyncStatus.synced),
        fileName: Value(fileName),
        updatedAt: Value(DateTime.now()),
      );
      await _mediaAssetDao.updateAsset(companion);
    } catch (e) {
      await _mediaAssetDao.updateAssetStatus(entity.id, SyncStatus.error);
      rethrow;
    }
  }

  // =======================================================================
  // ⭐️⭐️⭐️  核心修复区域: 重写 downloadAndSaveOriginal 方法  ⭐️⭐️⭐️
  // =======================================================================
  @override
  Future<UnifiedMediaEntity> downloadAndSaveOriginal(
    UnifiedMediaEntity entity,
  ) async {
    if (entity.cloudUuid == null || entity.syncStatus != SyncStatus.cloudOnly) {
      return entity;
    }

    File? tempFile;
    try {
      // 1. 更新数据库状态为 "下载中"，为UI提供即时反馈
      await _mediaAssetDao.updateAssetStatus(entity.id, SyncStatus.downloading);

      // 2. 下载文件字节
      final fileBytes = await downloadOrigin(entity.cloudUuid!);

      // 3. 将下载的字节写入一个临时文件
      // 这是因为 photo_manager 的 saveVideo/saveImage 方法需要一个文件作为输入
      final tempDir = await getTemporaryDirectory();
      final fileName = entity.fileName ?? '${entity.cloudUuid}.tmp';
      tempFile = File(p.join(tempDir.path, fileName));
      await tempFile.writeAsBytes(fileBytes);

      // 4. ⭐️ 使用 photo_manager 将临时文件保存到系统公共相册中
      // 这是最关键的一步。成功后，系统会为这个新文件建立索引，我们就能获得它的 `localId`
      debugPrint("正在将媒体保存到系统相册: ${tempFile.path}");
      AssetEntity? savedAsset;
      if (entity.isVideo) {
        savedAsset = await PhotoManager.editor.saveVideo(
          tempFile,
          title: fileName,
        );
      } else {
        // 对于图片，可以直接使用路径
        savedAsset = await PhotoManager.editor.saveImageWithPath(
          tempFile.path,
          title: fileName,
        );
      }
      debugPrint("成功获取到新的 AssetEntity, localId: ${savedAsset.id}");

      // 6. ⭐️ 从新生成的 AssetEntity 获取最终的文件路径
      final finalFile = await savedAsset.file;
      if (finalFile == null) {
        throw Exception('无法从新保存的 AssetEntity 获取文件路径。');
      }

      // 7. 将包含 localId 和新路径的所有信息更新回本地数据库
      final companion = MediaAssetsCompanion(
        id: Value(entity.id),
        localId: Value(savedAsset.id), // <-- 核心：保存新的 localId
        filePath: Value(finalFile.path), // <-- 保存系统相册中的实际路径
        syncStatus: Value(SyncStatus.synced),
        updatedAt: Value(DateTime.now()),
      );
      await _mediaAssetDao.updateAsset(companion);

      // 8. 返回一个包含所有最新信息的、完整的实体实例
      return entity.copyWith(
        localId: savedAsset.id, // 更新 localId
        filePath: finalFile.path, // 更新文件路径
        syncStatus: SyncStatus.synced,
      );
    } catch (e) {
      debugPrint("下载并保存媒体时出错: $e");
      // 如果出错，更新数据库状态为 "错误"
      await _mediaAssetDao.updateAssetStatus(entity.id, SyncStatus.error);
      // 将异常重新抛出，让 Notifier 的 AsyncValue.guard 能够捕获它
      rethrow;
    } finally {
      // 9. 无论成功与否，都尝试删除临时文件，保持清洁
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
        debugPrint("已清理临时文件: ${tempFile.path}");
      }
    }
  }

  @override
  Future<Uint8List> downloadThumbnail(String uuid) async {
    return _cloudDataSource.downloadThumbnail(uuid);
  }

  @override
  Future<Uint8List> downloadPreview(String uuid) async {
    return _cloudDataSource.downloadPreviewMedia(uuid);
  }

  @override
  Future<Uint8List> downloadOrigin(String uuid) async {
    return _cloudDataSource.downloadOriginalMedia(uuid);
  }

  @override
  Future<MediaResponse> uploadMedia({
    required Uint8List file,
    required String hash,
    required MediaType itemType,
    String? originalFilename,
  }) async {
    return _cloudDataSource.uploadMedia(
      file: file,
      hash: hash,
      itemType: itemType,
      originalFilename: originalFilename,
    );
  }
}
