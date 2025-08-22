// lib/data/repositories/media_repository_impl.dart

import 'dart:async';
import 'dart:typed_data';
import 'package:injectable/injectable.dart';
import 'package:drift/drift.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/domain/repositories/media_repository.dart';
import 'package:mobile/data/datasources/remote_media_source.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:mobile/services/sync_job_manager.dart';
import 'package:mobile/data/datasources/local_media_source.dart';
import 'package:mobile/domain/entities/unified_album_entity.dart';
import 'package:mobile/data/datasources/local_db/enums.dart';
import 'package:photo_manager/photo_manager.dart';

@LazySingleton(as: MediaRepository)
class MediaRepositoryImpl implements MediaRepository {
  final RemoteMediaDataSource _cloudDataSource;
  final MediaAssetDao _mediaAssetDao;
  final SyncJobManager _syncJobManager;
  final AlbumDao _albumDao;
  final LocalMediaDataSource _localMediaSource;

  MediaRepositoryImpl({
    required RemoteMediaDataSource cloudDataSource,
    required AppDatabase db,
    required SyncJobManager syncJobManager,
    required LocalMediaDataSource localMediaSource,
  }) : _cloudDataSource = cloudDataSource,
       _mediaAssetDao = db.mediaAssetDao,
       _albumDao = db.albumDao, // 新增：从 db 中获取 albumDao
       _localMediaSource = localMediaSource, // 新增
       _syncJobManager = syncJobManager;

  @override
  Stream<List<UnifiedMediaEntity>> getUnifiedMediaStream() {
    return _mediaAssetDao.watchAllMediaAssets().map((dbAssets) {
      return dbAssets.map(UnifiedMediaEntity.fromDbModel).toList();
    });
  }

  @override
  Future<void> createDownloadJob(UnifiedMediaEntity entity) async {
    return _syncJobManager.createDownloadJob(entity);
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
  Future<Set<String>> getAllSyncedLocalAssetIds() async {
    final idsList = await _mediaAssetDao.getAllLocalAssetIds();
    return idsList.toSet();
  }

  @override
  Stream<UnifiedMediaEntity> watchMediaEntity(int id) {
    return _mediaAssetDao
        .watchMediaAssetById(id)
        .map((dbAsset) => UnifiedMediaEntity.fromDbModel(dbAsset));
  }

  @override
  Stream<List<UnifiedAlbumEntity>> watchAlbums() {
    // 1. 直接调用 AlbumDao 的 watch 方法来监听数据库中的相册表
    return _albumDao.watchAllAlbums().map((dbAlbums) {
      // 2. 将数据库模型流 (List<Album>) 映射并转换为业务实体流 (List<UnifiedAlbumEntity>)
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
  Future<List<UnifiedMediaEntity>> getMediaFromAlbum(
    String albumId,
    AlbumSource source,
  ) async {
    switch (source) {
      case AlbumSource.local:
        // 1. 从设备获取相册内容的权威清单 (AssetEntity 列表)
        final List<AssetEntity> localAssets = await _localMediaSource
            .getMediaFromAlbum(albumId);

        if (localAssets.isEmpty) {
          return [];
        }

        // 2. 提取所有 localId，准备查询我们的数据库
        final List<String> localAssetIds = localAssets
            .map((a) => a.id)
            .toList();

        // 3. 使用新创建的 DAO 方法，一次性查询出所有已知的媒体资源
        final List<MediaAsset> dbAssets = await _mediaAssetDao
            .getAssetsByLocalIds(localAssetIds);

        // 4. 为了快速查找，将数据库结果转换为一个 Map
        //    Key: localId, Value: MediaAsset (数据库模型)
        final Map<String, MediaAsset> dbAssetsMap = {
          for (var dbAsset in dbAssets) dbAsset.localId!: dbAsset,
        };

        // 5. 遍历权威清单 (localAssets)，并智能地创建 UnifiedMediaEntity
        return localAssets.map((asset) {
          final MediaAsset? correspondingDbAsset = dbAssetsMap[asset.id];

          if (correspondingDbAsset != null) {
            // **情况 A: 数据库中已存在此资源**
            // 我们以数据库中的信息为基础创建实体，因为它包含正确的状态。
            // 然后使用 .copyWith 将临时的 AssetEntity 附加回去，供UI层使用。
            return UnifiedMediaEntity.fromDbModel(
              correspondingDbAsset,
            ).copyWith(assetEntity: asset);
          } else {
            // **情况 B: 数据库中不存在此资源**
            // 这是一个全新的、我们应用从未见过的资源。
            // 我们使用 fromAssetEntity 工厂方法创建一个临时的、未同步状态的实体。
            return UnifiedMediaEntity.fromAssetEntity(asset);
          }
        }).toList();

      case AlbumSource.remote:
        throw UnimplementedError(
          'Remote album fetching is not yet implemented.',
        );
    }
  }

  @override
  Future<Uint8List?> getThumbnailForLocalAsset(String id) {
    // 将调用委托给 LocalMediaSource，它直接与 photo_manager 交互
    return _localMediaSource.getThumbnail(assetId: id);
  }

  // [新增] 实现获取相册封面的方法
  @override
  Future<UnifiedMediaEntity?> getCoverForAlbum(UnifiedAlbumEntity album) async {
    switch (album.source) {
      case AlbumSource.local:
        // 1. 调用数据源层获取最新的 AssetEntity
        final AssetEntity? latestAsset = await _localMediaSource
            .getLatestAssetFromAlbum(album.id);

        if (latestAsset == null) {
          return null; // 相册为空
        }

        // 2. 复用我们的智能合并逻辑，检查这张照片是否已在数据库中
        return _createUnifiedEntityFromAsset(latestAsset);

      case AlbumSource.remote:
        // TODO: 实现获取云端相册封面的逻辑
        // 例如：final remoteCover = await _cloudDataSource.getAlbumCover(album.id);
        // return UnifiedMediaEntity.fromRemoteDto(remoteCover);
        throw UnimplementedError(
          'Remote album cover fetching is not yet implemented.',
        );
    }
  }

  // [新增] 提取私有辅助方法以避免代码重复
  // 这个方法封装了我们之前实现的“智能合并”逻辑
  Future<UnifiedMediaEntity> _createUnifiedEntityFromAsset(
    AssetEntity asset,
  ) async {
    final dbAsset = await _mediaAssetDao.getAssetByLocalId(
      asset.id,
    ); // 假设你有这个单查方法
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
        // 1. [一次性操作] 首先，从设备获取相册内所有媒体的权威列表 (AssetEntity)
        final List<AssetEntity> localAssets = await _localMediaSource
            .getMediaFromAlbum(albumId);

        if (localAssets.isEmpty) {
          yield []; // 如果相册为空，立即产生一个空列表并结束流
          return;
        }

        // 2. 提取所有 localId
        final List<String> localAssetIds = localAssets
            .map((a) => a.id)
            .toList();

        // 3. [持续监听] 使用上一步创建的 DAO 方法来监听数据库中与这些 localId 匹配的所有资源
        final Stream<List<MediaAsset>> dbAssetsStream = _mediaAssetDao
            .watchAssetsByLocalIds(localAssetIds);

        // 4. 使用 await for 循环来处理来自数据库的每一个更新
        await for (final dbAssets in dbAssetsStream) {
          // [解释] 每当数据库中的任何相关照片状态改变时，下面的代码都会重新执行

          // a. 将数据库结果转换为一个易于查找的 Map
          final Map<String, MediaAsset> dbAssetsMap = {
            for (var dbAsset in dbAssets) dbAsset.localId!: dbAsset,
          };

          // b. 再次遍历权威的设备列表 (localAssets)，并与最新的数据库状态进行合并
          final unifiedList = localAssets.map((asset) {
            final MediaAsset? correspondingDbAsset = dbAssetsMap[asset.id];

            if (correspondingDbAsset != null) {
              // 数据库中存在：使用数据库的权威状态
              return UnifiedMediaEntity.fromDbModel(
                correspondingDbAsset,
              ).copyWith(assetEntity: asset);
            } else {
              // 数据库中不存在：这是一个仅存在于本地的全新资源
              return UnifiedMediaEntity.fromAssetEntity(asset);
            }
          }).toList();

          // c. `yield` 关键字将合并后的最新列表作为新事件推送到流中
          yield unifiedList;
        }
        break;

      case AlbumSource.remote:
        throw UnimplementedError(
          'Remote album streaming is not yet implemented.',
        );
    }
  }
}
