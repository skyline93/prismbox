// lib/data/repositories/media_repository_impl.dart

import 'dart:io';
import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/domain/repositories/media_repository.dart';
import 'package:mobile/data/datasources/remote_media_source.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:mobile/data/datasources/local_media_source.dart';
import 'package:mobile/domain/entities/unified_album_entity.dart';
import 'package:mobile/core/enums.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:mobile/data/models/media/media_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

@LazySingleton(as: MediaRepository)
class MediaRepositoryImpl implements MediaRepository {
  final RemoteMediaDataSource _cloudDataSource;
  final MediaAssetDao _mediaAssetDao;
  final AlbumDao _albumDao;
  final LocalMediaDataSource _localMediaSource;
  final _log = Logger('MediaRepositoryImpl');

  MediaRepositoryImpl({
    required RemoteMediaDataSource cloudDataSource,
    required AppDatabase db,
    required LocalMediaDataSource localMediaSource,
  }) : _cloudDataSource = cloudDataSource,
       _mediaAssetDao = db.mediaAssetDao,
       _albumDao = db.albumDao,
       _localMediaSource = localMediaSource;

  @override
  Stream<List<UnifiedMediaEntity>> getUnifiedMediaStream() {
    return _mediaAssetDao.watchAllMediaAssets().map((dbAssets) {
      return dbAssets.map(UnifiedMediaEntity.fromDbModel).toList();
    });
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
  Stream<UnifiedMediaEntity> watchMediaEntity(int id) {
    return _mediaAssetDao
        .watchMediaAssetById(id)
        .map((dbAsset) => UnifiedMediaEntity.fromDbModel(dbAsset));
  }

  @override
  Stream<List<UnifiedAlbumEntity>> watchAlbums() {
    return _albumDao.watchAllAlbums().map((dbAlbums) {
      return dbAlbums
          .map(
            (dbAlbum) => UnifiedAlbumEntity(
              id: dbAlbum.id,
              name: dbAlbum.name,
              assetCount: dbAlbum.assetCount,
              source: dbAlbum.source,
              thumbnailId: dbAlbum.thumbnailId,
            ),
          )
          .toList();
    });
  }

  @override
  Future<UnifiedMediaEntity?> getCoverForAlbum(UnifiedAlbumEntity album) async {
    switch (album.source) {
      case AlbumSource.local:
        final AssetEntity? latestAsset = await _localMediaSource
            .getLatestAssetFromAlbum(album.id);

        if (latestAsset == null) {
          return null;
        }

        return _createUnifiedEntityFromAsset(latestAsset);

      case AlbumSource.remote:
        throw UnimplementedError(
          'Remote album cover fetching is not yet implemented.',
        );
    }
  }

  Future<UnifiedMediaEntity> _createUnifiedEntityFromAsset(
    AssetEntity asset,
  ) async {
    final dbAsset = await _mediaAssetDao.getAssetByLocalId(asset.id);
    if (dbAsset != null) {
      return UnifiedMediaEntity.fromDbModel(
        dbAsset,
      ).copyWith(assetEntity: asset);
    } else {
      return UnifiedMediaEntity.fromAssetEntity(asset);
    }
  }

  @override
  Stream<List<UnifiedMediaEntity>> watchMediaFromAlbum(
    String albumId,
    AlbumSource source,
  ) async* {
    switch (source) {
      case AlbumSource.local:
        final List<AssetEntity> localAssets = await _localMediaSource
            .getMediaFromAlbum(albumId);

        if (localAssets.isEmpty) {
          yield [];
          return;
        }

        final List<String> localAssetIds = localAssets
            .map((a) => a.id)
            .toList();

        final Stream<List<MediaAsset>> dbAssetsStream = _mediaAssetDao
            .watchAssetsByLocalIds(localAssetIds);

        await for (final dbAssets in dbAssetsStream) {
          final Map<String, MediaAsset> dbAssetsMap = {
            for (var dbAsset in dbAssets) dbAsset.localId!: dbAsset,
          };

          final unifiedList = localAssets.map((asset) {
            final MediaAsset? correspondingDbAsset = dbAssetsMap[asset.id];

            if (correspondingDbAsset != null) {
              return UnifiedMediaEntity.fromDbModel(
                correspondingDbAsset,
              ).copyWith(assetEntity: asset);
            } else {
              return UnifiedMediaEntity.fromAssetEntity(asset);
            }
          }).toList();

          yield unifiedList;
        }
        break;

      case AlbumSource.remote:
        throw UnimplementedError(
          'Remote album streaming is not yet implemented.',
        );
    }
  }

  @override
  Future<UnifiedMediaEntity> uploadMedia(AssetEntity asset) async {
    final File? file = await asset.originFile;
    if (file == null) {
      throw Exception('Failed to get file from asset: ${asset.id}');
    }

    final mediaType = asset.type == AssetType.video
        ? MediaType.video
        : MediaType.image;

    final MediaResponse remoteMedia = await _cloudDataSource.uploadFile(
      file,
      mediaType,
    );

    return UnifiedMediaEntity.fromRemoteMedia(remoteMedia);
  }

  // [新增] 获取或创建回收站目录的辅助方法
  Future<Directory> _getTrashDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final trashDir = Directory(p.join(appDir.path, '.trash'));
    if (!await trashDir.exists()) {
      await trashDir.create(recursive: true);
      // 可选：在Android上创建 .nomedia 文件以防止被扫描
      if (Platform.isAndroid) {
        final noMediaFile = File(p.join(trashDir.path, '.nomedia'));
        await noMediaFile.create();
      }
    }
    return trashDir;
  }

  // 定义一个静态或成员方法来根据主文件路径生成缩略图路径
  // 这样可以确保规则在整个应用中是统一的
  String _getThumbnailPathForRule(String mainPath) {
    final dir = p.dirname(mainPath);
    final filename = p.basenameWithoutExtension(mainPath);
    // 规则：在原文件名后加上 "_thumb.jpg"
    return p.join(dir, '${filename}_thumb.jpg');
  }

  @override
  Stream<List<UnifiedMediaEntity>> watchTrashedAssets() {
    return _mediaAssetDao.watchTrashedAssets().map(
      (dbAssets) => dbAssets.map(UnifiedMediaEntity.fromDbModel).toList(),
    );
  }

  @override
  Future<void> deleteAssets(List<UnifiedMediaEntity> assets) async {
    _log.info('Starting delete process for ${assets.length} assets.');

    // 1. 根据同步状态对资源进行分类
    final localOnlyAssets = <UnifiedMediaEntity>[];
    final cloudOnlyAssets = <UnifiedMediaEntity>[];
    final syncedAssets = <UnifiedMediaEntity>[];

    for (final asset in assets) {
      switch (asset.syncStatus) {
        case SyncStatus.localOnly:
          localOnlyAssets.add(asset);
          break;
        case SyncStatus.cloudOnly:
          cloudOnlyAssets.add(asset);
          break;
        case SyncStatus.synced:
          syncedAssets.add(asset);
          break;
        default:
          _log.warning(
            'Asset id:${asset.id} has unhandled sync status `${asset.syncStatus}` and will be skipped.',
          );
      }
    }

    _log.info(
      'Categorized assets: '
      '${localOnlyAssets.length} local-only, '
      '${cloudOnlyAssets.length} cloud-only, '
      '${syncedAssets.length} synced.',
    );

    // 2. 按分类执行删除逻辑
    if (localOnlyAssets.isNotEmpty) {
      await _handleLocalOnlyDeletion(localOnlyAssets);
    }
    if (cloudOnlyAssets.isNotEmpty) {
      await _handleCloudOnlyDeletion(cloudOnlyAssets);
    }
    if (syncedAssets.isNotEmpty) {
      await _handleSyncedDeletion(syncedAssets);
    }

    _log.info('Finished delete process.');
  }

  /// 处理仅本地资源的删除（移动到回收站）
  Future<void> _handleLocalOnlyDeletion(List<UnifiedMediaEntity> assets) async {
    _log.info(
      'Processing ${assets.length} local-only assets. Moving to local trash...',
    );
    // 直接复用原来的移动到回收站的逻辑
    await _moveLocalAssetsToTrash(assets);
  }

  /// 处理仅云端资源的删除
  Future<void> _handleCloudOnlyDeletion(List<UnifiedMediaEntity> assets) async {
    _log.info('Processing ${assets.length} cloud-only assets.');
    final now = DateTime.now();

    for (final asset in assets) {
      if (asset.cloudUuid == null) {
        _log.warning(
          'Asset id:${asset.id} is cloud-only but has no cloudUuid. Skipping.',
        );
        continue;
      }

      _log.fine('Attempting to delete cloud asset uuid:${asset.cloudUuid}');
      try {
        // 1. 调用云端删除接口
        final success = await _cloudDataSource.deleteMedia(asset.cloudUuid!);
        if (success) {
          _log.info(
            'Successfully deleted cloud asset uuid:${asset.cloudUuid}. Marking local record as trashed.',
          );
          // 2. 云端删除成功后，更新本地数据库记录状态
          final companion = MediaAssetsCompanion(
            id: Value(asset.id),
            lifecycleState: const Value(LifecycleState.trashed),
            lifecycleModifiedDate: Value(now),
          );
          await _mediaAssetDao.updateAsset(companion);
        } else {
          // 虽然 deleteMedia 内部会抛出异常，但为了健壮性保留此分支
          _log.warning(
            'Cloud deletion failed for uuid:${asset.cloudUuid} but no exception was thrown.',
          );
        }
      } catch (e, st) {
        _log.severe(
          'Failed to delete cloud asset uuid:${asset.cloudUuid}. The local record will NOT be changed.',
          e,
          st,
        );
        // **关键**: 云端删除失败，不改变本地状态，保证数据一致性
      }
    }
  }

  /// 处理已同步资源的删除
  Future<void> _handleSyncedDeletion(List<UnifiedMediaEntity> assets) async {
    _log.info('Processing ${assets.length} synced assets.');

    for (final asset in assets) {
      if (asset.cloudUuid == null) {
        _log.warning(
          'Asset id:${asset.id} is synced but has no cloudUuid. Skipping cloud deletion.',
        );
        // 如果没有云端ID，只能尝试本地删除
        await _moveLocalAssetsToTrash([asset]);
        continue;
      }

      _log.fine(
        'Attempting to delete synced asset. Cloud uuid:${asset.cloudUuid}, Local id:${asset.localId}',
      );
      try {
        // 1. 先调用云端删除接口
        final success = await _cloudDataSource.deleteMedia(asset.cloudUuid!);
        if (success) {
          _log.info(
            'Successfully deleted cloud part for synced asset uuid:${asset.cloudUuid}. Now deleting local part.',
          );
          // 2. 云端删除成功后，再处理本地删除
          await _moveLocalAssetsToTrash([asset]);
        } else {
          _log.warning(
            'Cloud deletion failed for synced asset uuid:${asset.cloudUuid} but no exception was thrown.',
          );
        }
      } catch (e, st) {
        _log.severe(
          'Failed to delete cloud part for synced asset uuid:${asset.cloudUuid}. Aborting deletion for this asset to maintain consistency.',
          e,
          st,
        );
        // **关键**: 云端删除失败，则完全中止此资源的删除流程，不处理本地部分
      }
    }
  }

  // [重命名] 将 `moveAssetsToTrash` 修改为私有方法 `_moveLocalAssetsToTrash`
  // 它现在只负责处理本地文件和数据库状态更新，职责更单一
  Future<void> _moveLocalAssetsToTrash(List<UnifiedMediaEntity> assets) async {
    _log.info('Moving ${assets.length} local assets to app trash...');
    final trashDir = await _getTrashDirectory();
    final now = DateTime.now();

    for (final asset in assets) {
      if (asset.localId == null || asset.localId!.isEmpty) {
        _log.warning(
          'Asset id:${asset.id} has no localId, cannot be moved to local trash. Skipping.',
        );
        continue;
      }

      final AssetEntity? retrievedAssetEntity = await AssetEntity.fromId(
        asset.localId!,
      );
      if (retrievedAssetEntity == null) {
        _log.warning(
          'Could not find AssetEntity with localId ${asset.localId} in system gallery. Skipping.',
        );
        continue;
      }

      final sourceFile = await retrievedAssetEntity.file;
      if (sourceFile == null || !await sourceFile.exists()) {
        _log.warning(
          'Source file for asset id:${asset.id} not found. Skipping.',
        );
        continue;
      }

      final newTrashPath = p.join(trashDir.path, p.basename(sourceFile.path));
      final newTrashThumbnailPath = _getThumbnailPathForRule(newTrashPath);

      try {
        final Uint8List? thumbData = await retrievedAssetEntity
            .thumbnailDataWithSize(const ThumbnailSize(256, 256), quality: 65);

        await sourceFile.copy(newTrashPath);
        _log.fine('Copied main file to $newTrashPath');

        File? trashThumbnailFile;
        if (thumbData != null) {
          trashThumbnailFile = File(newTrashThumbnailPath);
          await trashThumbnailFile.writeAsBytes(thumbData);
          _log.fine('Saved system thumbnail to $newTrashThumbnailPath');
        }

        // 从系统相册删除
        final result = await PhotoManager.editor.deleteWithIds([
          retrievedAssetEntity.id,
        ]);
        if (result.isEmpty) {
          _log.warning(
            'Failed to delete asset ${retrievedAssetEntity.id} from system gallery. Rolling back file copy.',
          );
          await File(newTrashPath).delete();
          if (trashThumbnailFile != null && await trashThumbnailFile.exists()) {
            await trashThumbnailFile.delete();
          }
          continue; // 跳过此资源的数据库更新
        }

        final companion = MediaAssetsCompanion(
          id: Value(asset.id),
          lifecycleState: const Value(LifecycleState.trashed),
          lifecycleModifiedDate: Value(now),
          trashPath: Value(newTrashPath),
          localId: const Value(null), // localId 清空，因为它已不在系统相册
        );
        await _mediaAssetDao.updateAsset(companion);
        _log.fine(
          'Updated database for asset id:${asset.id} to trashed state.',
        );
      } catch (e, st) {
        _log.severe('Error moving asset id:${asset.id} to trash.', e, st);
        // 确保出错时清理已复制的文件
        if (await File(newTrashPath).exists()) {
          await File(newTrashPath).delete();
        }
        if (await File(newTrashThumbnailPath).exists()) {
          await File(newTrashThumbnailPath).delete();
        }
      }
    }
    _log.info('Finished moving local assets to app trash.');
  }

  @override
  Future<void> restoreAssetsFromTrash(List<UnifiedMediaEntity> assets) async {
    _log.info('Starting restore process for ${assets.length} trashed assets.');
    final now = DateTime.now();

    for (final asset in assets) {
      _log.fine(
        'Processing asset id:${asset.id}, syncStatus: ${asset.syncStatus}',
      );

      bool cloudRestoreSuccess = false;
      bool localRestoreSuccess = false;

      try {
        // 步骤 1: 处理需要云端恢复的资源 (cloudOnly, synced)
        if (asset.syncStatus == SyncStatus.cloudOnly ||
            asset.syncStatus == SyncStatus.synced) {
          if (asset.cloudUuid == null) {
            _log.warning(
              'Asset id:${asset.id} requires cloud restore but has no cloudUuid. Skipping.',
            );
            continue;
          }
          _log.info(
            'Attempting to restore cloud part for asset uuid:${asset.cloudUuid}',
          );
          cloudRestoreSuccess = await _cloudDataSource.restoreMedia(
            asset.cloudUuid!,
          );
          if (!cloudRestoreSuccess) {
            _log.warning(
              'Cloud restore failed for asset uuid:${asset.cloudUuid}. Aborting restore for this asset.',
            );
            continue; // 云端恢复失败，则不进行任何本地操作
          }
          _log.info(
            'Cloud part restored successfully for asset uuid:${asset.cloudUuid}',
          );
        }

        // 步骤 2: 处理需要本地文件恢复的资源 (之前是 localOnly 或 synced)
        // 仅当资源有 trashPath 时才需要本地恢复
        if (asset.trashPath != null && asset.trashPath!.isNotEmpty) {
          _log.info('Attempting to restore local file from ${asset.trashPath}');
          localRestoreSuccess = await _restoreSingleLocalAsset(asset);
          if (!localRestoreSuccess) {
            _log.severe(
              'Local file restore failed for asset id:${asset.id}. The cloud part was restored but local failed. Manual intervention may be needed.',
            );
            // 这是一个临界情况：云端已恢复但本地失败。
            // 理想情况下，可以尝试回滚云端操作，但这会增加复杂性。
            // 目前我们只记录严重错误日志。
            continue;
          }
          _log.info(
            'Local file restored successfully for asset id:${asset.id}',
          );
        }

        // 步骤 3: 更新数据库状态
        // 只有在所有必要步骤都成功后才更新数据库
        // - localOnly: 只需要 localRestoreSuccess
        // - cloudOnly: 只需要 cloudRestoreSuccess
        // - synced: 需要 cloudRestoreSuccess AND localRestoreSuccess

        final isLocalOnly =
            asset.syncStatus != SyncStatus.cloudOnly && asset.trashPath != null;
        final isCloudOnly = asset.syncStatus == SyncStatus.cloudOnly;

        if ((isLocalOnly && localRestoreSuccess) ||
            (isCloudOnly && cloudRestoreSuccess) ||
            (localRestoreSuccess && cloudRestoreSuccess)) {
          // 在 _restoreSingleLocalAsset 内部已经更新了数据库
          // 所以这里只处理 cloudOnly 的情况
          if (isCloudOnly) {
            final companion = MediaAssetsCompanion(
              id: Value(asset.id),
              lifecycleState: const Value(LifecycleState.active),
              lifecycleModifiedDate: Value(now),
              // trashPath 已经是 null, 无需改动
            );
            await _mediaAssetDao.updateAsset(companion);
            _log.fine(
              'Database state updated to active for cloud-only asset id:${asset.id}',
            );
          }
        }
      } catch (e, st) {
        _log.severe(
          'An unexpected error occurred while restoring asset id:${asset.id}.',
          e,
          st,
        );
      }
    }
    _log.info('Finished restore process.');
  }

  /// 辅助方法：恢复单个本地文件到系统相册并更新数据库
  /// 返回 bool 表示是否成功
  Future<bool> _restoreSingleLocalAsset(UnifiedMediaEntity asset) async {
    final now = DateTime.now();
    if (asset.trashPath == null || asset.trashPath!.isEmpty) {
      _log.warning(
        'Asset id:${asset.id} has no trashPath. Skipping local restore.',
      );
      return false;
    }

    final trashedFile = File(asset.trashPath!);
    final trashedThumbnailFile = File(
      _getThumbnailPathForRule(asset.trashPath!),
    );

    if (!await trashedFile.exists()) {
      _log.warning(
        'Trashed file for asset id:${asset.id} not found at ${asset.trashPath}. Cannot restore.',
      );
      // 文件已丢失，我们仍然可以将其状态更新为 active，但它将没有本地文件
      final companion = MediaAssetsCompanion(
        id: Value(asset.id),
        lifecycleState: const Value(LifecycleState.active),
        lifecycleModifiedDate: Value(now),
        trashPath: const Value(null),
      );
      await _mediaAssetDao.updateAsset(companion);
      return false; // 返回 false 因为文件没有被真正恢复
    }

    try {
      final AssetEntity newAssetEntity;
      final fileName = p.basename(trashedFile.path);

      if (!asset.isVideo) {
        newAssetEntity = await PhotoManager.editor.saveImage(
          await trashedFile.readAsBytes(),
          filename: fileName,
        );
      } else {
        newAssetEntity = await PhotoManager.editor.saveVideo(
          trashedFile,
          title: fileName,
        );
      }

      final companion = MediaAssetsCompanion(
        id: Value(asset.id),
        lifecycleState: const Value(LifecycleState.active),
        lifecycleModifiedDate: Value(now),
        localId: Value(newAssetEntity.id), // 设置新的 localId
        trashPath: const Value(null), // 清除 trashPath
      );
      await _mediaAssetDao.updateAsset(companion);

      await trashedFile.delete();
      if (await trashedThumbnailFile.exists()) {
        await trashedThumbnailFile.delete();
      }

      return true;
    } catch (e, st) {
      _log.severe(
        'Error saving file to system gallery for asset id:${asset.id}.',
        e,
        st,
      );
      return false;
    }
  }

  @override
  Future<void> permanentlyDeleteAssets(List<UnifiedMediaEntity> assets) async {
    _log.info('Starting permanent deletion for ${assets.length} assets.');

    // 用于记录那些可以安全地从本地数据库中删除的资源的ID。
    // 只有在其云端对应部分（如果存在）被成功清除后，一个资源才是安全的。
    final List<int> idsToDeleteFromDb = [];

    for (final asset in assets) {
      _log.fine('Processing permanent deletion for asset id:${asset.id}');
      bool isSafeToDeleteFromDb = true;

      // 1. 如果是云端资源，则从云端永久删除。
      // 这是最关键的一步。如果失败，我们绝不能删除本地数据库记录，
      // 以避免在服务器上产生孤儿文件。
      if (asset.isRemote) {
        _log.info(
          'Asset id:${asset.id} has a cloud component (uuid: ${asset.cloudUuid}). Attempting to purge from cloud.',
        );
        try {
          final success = await _cloudDataSource.purgeMedia(asset.cloudUuid!);
          if (success) {
            _log.info(
              'Successfully purged cloud asset uuid:${asset.cloudUuid}.',
            );
          } else {
            // 正常情况下，远端数据源在失败时应抛出异常，但作为保险措施：
            _log.warning(
              'Cloud purge for uuid:${asset.cloudUuid} returned false without an exception.',
            );
            isSafeToDeleteFromDb = false;
          }
        } catch (e, st) {
          _log.severe(
            'Failed to purge cloud asset uuid:${asset.cloudUuid}. The local database record will be kept to maintain consistency.',
            e,
            st,
          );
          // 将此资源标记为不安全，不能从本地数据库删除。
          isSafeToDeleteFromDb = false;
        }
      }

      // 2. 无论云端操作是否成功，都删除本地回收站中的文件。
      // 用户的意图是清空回收站。即使云端清除失败，我们也应尝试清理本地文件。
      if (asset.trashPath != null && asset.trashPath!.isNotEmpty) {
        final trashedFile = File(asset.trashPath!);
        final trashedThumbnailFile = File(
          _getThumbnailPathForRule(asset.trashPath!),
        );
        try {
          if (await trashedFile.exists()) {
            await trashedFile.delete();
            _log.fine(
              'Deleted trashed file for asset id:${asset.id} at ${asset.trashPath}',
            );
          }

          if (await trashedThumbnailFile.exists()) {
            await trashedThumbnailFile.delete();
            _log.fine(
              'Deleted trashed thumbnail for asset id:${asset.id} at ${trashedThumbnailFile.path}',
            );
          }
        } catch (e, st) {
          // 记录错误，但不阻塞流程。
          _log.warning(
            'Could not delete local trashed file for asset id:${asset.id} at ${asset.trashPath}.',
            e,
            st,
          );
        }
      }

      // 3. 如果所有关键操作都成功了，将ID添加到列表中以便后续从数据库删除。
      if (isSafeToDeleteFromDb) {
        idsToDeleteFromDb.add(asset.id);
      }
    }

    // 4. 对所有成功处理的资源，执行批量数据库删除操作。
    if (idsToDeleteFromDb.isNotEmpty) {
      _log.info(
        'Permanently deleting ${idsToDeleteFromDb.length} asset records from the local database.',
      );
      await _mediaAssetDao.deleteAssetsByIds(idsToDeleteFromDb);
    } else {
      _log.info('No assets were cleared for database deletion.');
    }

    _log.info('Finished permanent deletion process.');
  }
}
