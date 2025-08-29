// lib/domain/repositories/media_repository.dart

import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';
import 'package:mobile/data/datasources/local_db/enums.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/domain/entities/unified_album_entity.dart';

abstract class MediaRepository {
  Stream<List<UnifiedMediaEntity>> getUnifiedMediaStream();

  Future<void> createDownloadJob(UnifiedMediaEntity entity);

  Future<void> createUploadJobForExistingAsset(UnifiedMediaEntity entity);

  Future<Uint8List> downloadThumbnail(String uuid);

  Future<Uint8List> downloadPreview(String uuid);

  Future<Set<String>> getAllSyncedLocalAssetIds();

  Stream<UnifiedMediaEntity> watchMediaEntity(int id);

  Stream<List<UnifiedAlbumEntity>> watchAlbums();

  Future<List<UnifiedMediaEntity>> getMediaFromAlbum(
    String albumId,
    AlbumSource source,
  );

  Future<Uint8List?> getThumbnailForLocalAsset(String id);

  Future<UnifiedMediaEntity?> getCoverForAlbum(UnifiedAlbumEntity album);

  Stream<List<UnifiedMediaEntity>> watchMediaFromAlbum(
    String albumId,
    AlbumSource source,
  );

    /// 直接上传指定的本地媒体资源，并返回它们在服务器上对应的 UUID 列表。
  ///
  /// 这个方法用于需要立即获取上传结果的交互场景（例如分享到圈子），
  /// 它会绕过后台同步队列，直接进行网络请求。
  ///
  /// @param assets 从 photo_manager 选择的资源列表。
  /// @return 上传成功后，服务器为每个资源生成的 UUID 列表。
  Future<List<String>> uploadAssets(List<AssetEntity> assets);
}
