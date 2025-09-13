// lib/data/repositories/media_repository_impl.dart

import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:injectable/injectable.dart';
import 'package:drift/drift.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/domain/repositories/media_repository.dart';
import 'package:mobile/data/datasources/remote_media_source.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:mobile/data/datasources/local_media_source.dart';
import 'package:mobile/domain/entities/unified_album_entity.dart';
import 'package:mobile/core/enums.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:mobile/data/models/media/media_model.dart';

@LazySingleton(as: MediaRepository)
class MediaRepositoryImpl implements MediaRepository {
  final RemoteMediaDataSource _cloudDataSource;
  final MediaAssetDao _mediaAssetDao;
  final AlbumDao _albumDao;
  final LocalMediaDataSource _localMediaSource;

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
    final File? file = await asset.file;
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
}
