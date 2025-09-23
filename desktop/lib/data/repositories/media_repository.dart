// lib/data/repositories/media_repository.dart

import '../datasources/local/app_database.dart';
import '../datasources/remote/api_client.dart';
import '../datasources/remote/models/media_model.dart';
import '../../core/utils/logger.dart';
import 'dart:convert';

class MediaRepository {
  final ApiClient _apiClient;
  final AppDatabase _db;

  MediaRepository(this._apiClient, this._db);

  // Provides a stream of media assets from the local database.
  Stream<List<MediaAsset>> watchLocalMediaAssets() {
    return _db.mediaAssetDao.watchAllAssets();
  }

  Future<void> syncRemoteMedia() async {
    final remoteMedia = await _apiClient.getMedias();

    // 使用 for 循环代替 .map() 以便在循环内部进行 try-catch
    final List<MediaAsset> localMediaAssets = [];
    for (final media in remoteMedia) {
      try {
        // 这是你的转换逻辑
        final asset = MediaAsset(
          uuid: media.uuid,
          filename: media.filename, // 假设这里可能会出错
          originalFilename: media.originalFilename,
          itemType: media.itemType,
          hash: media.hash,
          createdAt: media.createdAt,
          updatedAt: media.updatedAt,
          mediaTakenAt: media.mediaTakenAt,
          thumbnailUrl: media.thumbnailUrl,
          previewUrl: media.previewUrl,
          downloadUrl: media.downloadUrl,
        );
        localMediaAssets.add(asset);
      } catch (e, s) {
        // 当转换失败时，记录详细错误和导致问题的原始数据
        // logger.e(
        //   "Failed to convert a remote media object to a local MediaAsset.",
        //   error: e,
        //   stackTrace: s,
        // );
        print(
          "Failed to convert a remote media object to a local MediaAsset. error: $e, stackTrace: $s",
        );

        // 为了方便调试，打印出这个 problematic media object 的 JSON 形式
        // 注意：这需要你的 MediaModel 有一个 toJson() 方法，
        // 如果是用 json_serializable 生成的，那么它应该已经存在了。
        // 如果没有，你可以手动打印 media.uuid 或其他关键信息。
        try {
          // 假设 media.toJson() 存在
          logger.w("Problematic media data: ${jsonEncode(media.toJson())}");
          print("Problematic media data: ${jsonEncode(media.toJson())}");
        } catch (_) {
          logger.w("Problematic media UUID: ${media.uuid}");
          print("Problematic media UUID: ${media.uuid}");
        }

        // 重新抛出异常，让上层（ViewModel）知道同步失败了
        rethrow;
      }
    }

    await _db.mediaAssetDao.upsertAssets(localMediaAssets);
  }

  // Checks which file hashes already exist on the server.
  Future<List<String>> checkExistingHashes(List<String> hashes) async {
    if (hashes.isEmpty) return [];
    final response = await _apiClient.checkHashes(
      CheckHashesRequest(hashes: hashes),
    );
    return response.existingHashes;
  }
}
