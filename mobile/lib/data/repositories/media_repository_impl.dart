// lib/data/repositories/media_repository_impl.dart

import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../domain/entities/unified_media_entity.dart';
import '../../domain/repositories/media_repository.dart';
import 'package:mobile/data/datasources/local_media_source.dart';
import 'package:mobile/data/datasources/remote_media_source.dart';
import 'package:mobile/data/datasources/app_database.dart';
import 'package:mobile/data/models/media/media_model.dart';
import 'package:mobile/core/storage/sync_state_service.dart';

// [修正] 严格实现接口
class MediaRepositoryImpl implements MediaRepository {
  final LocalMediaDataSource _localDataSource;
  final RemoteMediaDataSource _cloudDataSource;
  final SyncStateService _syncStateService;
  final MediaAssetDao _mediaAssetDao;
  String? _mediaStoragePath;

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
        // [修正] 调用新的、封装好的DAO方法，修复 void_result 错误
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

    // [修正] 使用 p.basename 安全地从路径中提取文件名
    // 这假设您的 response.originalPath 字段存在，如果不存在，请替换为实际包含文件名的字段
    final fileName = p.basename(response.originalFilename);

    return MediaAssetsCompanion(
      cloudUuid: Value(response.uuid),
      assetType: Value(assetType),
      syncStatus: Value(SyncStatus.cloudOnly),
      fileName: Value(fileName), // 现在可以正确保存文件名
      createdAt: Value(
        DateTime.tryParse(response.mediaTakenAt ?? response.createdAt) ??
            DateTime.now(),
      ),
      updatedAt: Value(DateTime.now()),
    );
  }

  Future<String> _getMediaStoragePath() async {
    if (_mediaStoragePath != null) return _mediaStoragePath!;
    final directory = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(p.join(directory.path, 'media_files'));
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    _mediaStoragePath = mediaDir.path;
    return _mediaStoragePath!;
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

  /// 下载原始文件，保存到本地，并返回更新后的实体。
  ///
  /// 这个函数现在返回一个 Future<UnifiedMediaEntity>，以便调用者（如 Notifier）
  /// 可以获取到最新的文件路径和同步状态。
  Future<UnifiedMediaEntity> downloadAndSaveOriginal(
    UnifiedMediaEntity entity,
  ) async {
    if (entity.cloudUuid == null || entity.syncStatus != SyncStatus.cloudOnly) {
      // 如果状态不正确，直接返回原始实体，不执行任何操作。
      return entity;
    }
    try {
      // 1. 更新数据库状态为 "下载中"
      await _mediaAssetDao.updateAssetStatus(entity.id, SyncStatus.downloading);
      // 注意：这里最好也 invalidate 一下 provider 列表，让UI可以显示下载中状态
      // ref.invalidate(mediaListProvider);

      // 2. 下载文件
      final fileBytes = await downloadOrigin(entity.cloudUuid!);
      final storagePath = await _getMediaStoragePath();

      final originalExtension = p.extension(entity.fileName ?? '.jpg');
      final localPath = p.join(
        storagePath,
        '${entity.cloudUuid}$originalExtension',
      );

      final localFile = File(localPath);
      await localFile.writeAsBytes(fileBytes);

      // 3. 将新信息更新到数据库
      final companion = MediaAssetsCompanion(
        id: Value(entity.id),
        filePath: Value(localPath),
        syncStatus: Value(SyncStatus.synced),
        updatedAt: Value(DateTime.now()),
      );
      await _mediaAssetDao.updateAsset(companion);

      // 4. ⭐️ 返回一个包含最新信息的新的实体实例
      // 使用我们刚刚创建的 copyWith 方法，既安全又方便。
      return entity.copyWith(
        filePath: localPath,
        syncStatus: SyncStatus.synced,
      );
    } catch (e) {
      // 如果出错，更新数据库状态为 "错误"
      await _mediaAssetDao.updateAssetStatus(entity.id, SyncStatus.error);
      // 将异常重新抛出，让 Notifier 的 AsyncValue.guard 能够捕获它
      rethrow;
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
