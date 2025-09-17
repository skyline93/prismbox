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
  Future<void> moveAssetsToTrash(List<UnifiedMediaEntity> assets) async {
    _log.info(
      'Moving ${assets.length} assets to trash with thumbnail pre-generation...',
    );
    final trashDir = await _getTrashDirectory();
    final now = DateTime.now();

    for (final asset in assets) {
      if (asset.localId == null || asset.localId!.isEmpty) {
        _log.warning(
          'Asset ${asset.id} has no localId, cannot be moved. Skipping.',
        );
        continue;
      }

      final AssetEntity? retrievedAssetEntity = await AssetEntity.fromId(
        asset.localId!,
      );
      if (retrievedAssetEntity == null) {
        _log.warning(
          'Could not find AssetEntity with localId ${asset.localId}. Skipping.',
        );
        continue;
      }

      final sourceFile = await retrievedAssetEntity.file;
      if (sourceFile == null || !await sourceFile.exists()) {
        _log.warning('Source file for asset ${asset.id} not found. Skipping.');
        continue;
      }

      // 1. 确定主文件和缩略图的目标路径
      final newTrashPath = p.join(trashDir.path, p.basename(sourceFile.path));
      final newTrashThumbnailPath = _getThumbnailPathForRule(newTrashPath);

      try {
        // 2. 获取系统生成的缩略图数据
        final Uint8List? thumbData = await retrievedAssetEntity
            .thumbnailDataWithSize(
              const ThumbnailSize(256, 256), // 尺寸可以根据UI需求调整
              quality: 65,
            );

        // 3. 复制主文件
        await sourceFile.copy(newTrashPath);
        _log.fine('Copied main file to $newTrashPath');

        File? trashThumbnailFile;
        // 4. 如果成功获取到缩略图数据，就将其写入文件
        if (thumbData != null) {
          trashThumbnailFile = File(newTrashThumbnailPath);
          await trashThumbnailFile.writeAsBytes(thumbData);
          _log.fine('Saved system thumbnail to $newTrashThumbnailPath');
        }

        // 5. 从系统相册删除原资源
        final result = await PhotoManager.editor.deleteWithIds([
          retrievedAssetEntity.id,
        ]);
        if (result.isEmpty) {
          _log.warning(
            'Failed to delete asset ${retrievedAssetEntity.id} from system gallery.',
          );
          // 回滚：删除已复制的主文件和缩略图文件
          await File(newTrashPath).delete();
          if (trashThumbnailFile != null && await trashThumbnailFile.exists()) {
            await trashThumbnailFile.delete();
          }
          continue;
        }

        // 6. 更新数据库 (无需修改，因为不增加字段)
        final companion = MediaAssetsCompanion(
          id: Value(asset.id),
          lifecycleState: const Value(LifecycleState.trashed),
          lifecycleModifiedDate: Value(now),
          trashPath: Value(newTrashPath),
          localId: const Value(null),
        );
        await _mediaAssetDao.updateAsset(companion);
        _log.fine('Updated database for asset ${asset.id}.');
      } catch (e) {
        _log.severe('Error moving asset ${asset.id} to trash: $e');
        // 确保出错时清理文件
        if (await File(newTrashPath).exists()) {
          await File(newTrashPath).delete();
        }
        if (await File(newTrashThumbnailPath).exists()) {
          await File(newTrashThumbnailPath).delete();
        }
      }
    }
    _log.info('Finished moving assets to trash.');
  }

  // [重大修改] 同样需要更新 restore 和 permanentlyDelete 方法以处理文件
  @override
  Future<void> restoreAssetsFromTrash(List<UnifiedMediaEntity> assets) async {
    _log.info('Restoring ${assets.length} assets from trash.');
    final now = DateTime.now();

    for (final asset in assets) {
      if (asset.trashPath == null || asset.trashPath!.isEmpty) {
        _log.warning('Asset ${asset.id} has no trashPath. Skipping restore.');
        continue;
      }

      final trashedFile = File(asset.trashPath!);
      final trashedThumbnailFile = File(
        _getThumbnailPathForRule(asset.trashPath!),
      );
      if (!await trashedFile.exists()) {
        _log.warning(
          'Trashed file not found at ${asset.trashPath}. Skipping restore.',
        );
        // 文件已丢失，直接将其状态更新为 active 但无 localId
        final companion = MediaAssetsCompanion(
          id: Value(asset.id),
          lifecycleState: const Value(LifecycleState.active),
          lifecycleModifiedDate: Value(now),
          trashPath: const Value(null),
        );
        await _mediaAssetDao.updateAsset(companion);
        continue;
      }

      try {
        // 1. 将文件存回系统相册
        final AssetEntity newAssetEntity;

        if (!asset.isVideo) {
          newAssetEntity = await PhotoManager.editor.saveImage(
            await trashedFile.readAsBytes(),
            filename: p.basename(trashedFile.path),
          );
        } else {
          newAssetEntity = await PhotoManager.editor.saveVideo(
            trashedFile,
            title: p.basename(trashedFile.path),
          );
        }

        // 2. 更新数据库
        final companion = MediaAssetsCompanion(
          id: Value(asset.id),
          lifecycleState: const Value(LifecycleState.active),
          lifecycleModifiedDate: Value(now),
          localId: Value(newAssetEntity.id), // 设置新的 localId
          trashPath: const Value(null), // 清除 trashPath
        );
        await _mediaAssetDao.updateAsset(companion);

        // 3. 清理缩略图并删除回收站中的文件
        await trashedFile.delete();
        if (await trashedThumbnailFile.exists()) {
          await trashedThumbnailFile.delete();
        }

        _log.fine('Restored asset ${asset.id} successfully.');
      } catch (e) {
        _log.severe('Error restoring asset ${asset.id}: $e');
      }
    }
    _log.info('Finished restoring assets.');
  }

  @override
  Future<void> permanentlyDeleteAssets(List<UnifiedMediaEntity> assets) async {
    _log.info('Permanently deleting ${assets.length} assets.');

    for (final asset in assets) {
      // 1. 从文件系统删除文件
      if (asset.trashPath != null && asset.trashPath!.isNotEmpty) {
        final trashedFile = File(asset.trashPath!);
        final trashedThumbnailFile = File(
          _getThumbnailPathForRule(asset.trashPath!),
        );
        try {
          if (await trashedFile.exists()) {
            await trashedFile.delete();
            _log.fine('Deleted file from trash: ${asset.trashPath}');
          }

          if (await trashedThumbnailFile.exists()) {
            await trashedThumbnailFile.delete();
            _log.fine(
              'Deleted thumbnail from trash: ${trashedThumbnailFile.path}',
            );
          }
        } catch (e) {
          _log.severe('Failed to delete trashed file ${asset.trashPath}: $e');
        }
      }
    }

    // 2. 从数据库中彻底删除记录
    final idsToDelete = assets.map((a) => a.id).toList();
    await _mediaAssetDao.deleteAssetsByIds(idsToDelete);
    _log.info('Finished permanently deleting asset records from the database.');
  }
}
