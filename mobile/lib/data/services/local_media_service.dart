import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:photo_manager/photo_manager.dart';

final logger = Logger(
  printer: PrettyPrinter(
    dateTimeFormat: DateTimeFormat.dateAndTime,
    colors: true,
  ),
);

class LocalMediaService {
  /// 请求并检查权限。
  Future<bool> _requestPermission() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    return ps.isAuth;
  }

  // --- 查询 (Read) ---

  /// 获取所有媒体相册列表。
  ///
  /// 如果没有权限或没有相册，则返回空列表。
  Future<List<AssetPathEntity>> getAlbums() async {
    if (!await _requestPermission()) {
      logger.w("Storage permission has not been granted.");
      return [];
    }
    return await PhotoManager.getAssetPathList(type: RequestType.all);
  }

  /// 从指定相册中分页获取媒体资源。
  Future<List<AssetEntity>> getAssetsForAlbum({
    required AssetPathEntity album,
    int page = 0,
    int size = 50,
  }) async {
    return await album.getAssetListPaged(page: page, size: size);
  }

  /// 获取设备上最新的媒体资源（通常来自 "最近" 或 "所有照片" 相册）。
  Future<List<AssetEntity>> getLocalAssets({
    int page = 0,
    int size = 50,
  }) async {
    if (!await _requestPermission()) {
      logger.w("Storage permission has not been granted.");
      return [];
    }

    final albums = await PhotoManager.getAssetPathList(type: RequestType.all);
    if (albums.isEmpty) {
      return [];
    }

    final recentAlbum = albums.first;
    return await recentAlbum.getAssetListPaged(page: page, size: size);
  }

  // --- 新增 (Create) ---

  /// 保存图片到设备的相册中。
  ///
  /// [data] 是图片的 Uint8List 数据。
  /// [title] 是图片的标题 (在 photo_manager v3+ 中是必需的)。
  /// [albumName] (可选) 是希望保存到的相册名称。如果不存在，在iOS上会尝试创建。
  /// 成功时返回最终位置的 [AssetEntity]，失败则返回 null。
  Future<AssetEntity?> saveImage(
    Uint8List data, {
    required String title,
    String? albumName,
  }) async {
    if (!await _requestPermission()) {
      logger.w("Storage permission has not been granted for saving.");
      return null;
    }

    final AssetEntity? imageEntity = await PhotoManager.editor.saveImage(
      data,
      title: title,
      filename: title,
    );

    if (imageEntity == null) {
      logger.e("Failed to save image to default gallery.");
      return null;
    }

    if (albumName != null) {
      return await _copyAssetToAlbum(asset: imageEntity, albumName: albumName);
    }

    return imageEntity;
  }

  /// 保存视频文件到设备的相册中。
  ///
  /// [videoFile] 是视频的 File 对象。
  /// [title] 是视频的标题。
  /// [albumName] (可选) 是希望保存到的相册名称。
  Future<AssetEntity?> saveVideo(
    File videoFile, {
    required String title,
    String? albumName,
  }) async {
    if (!await _requestPermission()) {
      logger.w("Storage permission has not been granted for saving.");
      return null;
    }

    final AssetEntity? videoEntity = await PhotoManager.editor.saveVideo(
      videoFile,
      title: title,
    );

    if (videoEntity == null) {
      logger.e("Failed to save video to default gallery.");
      return null;
    }

    if (albumName != null) {
      return await _copyAssetToAlbum(asset: videoEntity, albumName: albumName);
    }

    return videoEntity;
  }

  // --- 修改 (Update/Move) ---

  /// 将指定的媒体资源拷贝到一个相册（私有辅助方法）。
  Future<AssetEntity?> _copyAssetToAlbum({
    required AssetEntity asset,
    required String albumName,
  }) async {
    AssetPathEntity? targetAlbum;

    final albums = await PhotoManager.getAssetPathList(type: RequestType.all);
    final existingAlbum = albums.where((path) => path.name == albumName);

    if (existingAlbum.isNotEmpty) {
      targetAlbum = existingAlbum.first;
    } else {
      // 如果相册不存在，尝试在 Darwin 平台（iOS/macOS）上创建它。
      if (Platform.isIOS || Platform.isMacOS) {
        final newAlbum = await PhotoManager.editor.darwin.createAlbum(
          albumName,
        );
        targetAlbum = newAlbum;
      } else {
        // 在 Android 上，photo_manager 不能直接创建空相册。
        // 它通常在保存文件到特定路径时自动创建。
        // 由于我们是拷贝，所以相册必须已存在。
        logger.w("Album '$albumName' does not exist. On Android, an album must exist before copying assets to it.");
        return null;
      }
    }

    if (targetAlbum == null) {
      logger.e("Could not find or create album '$albumName'.");
      return null;
    }

    return await PhotoManager.editor.copyAssetToPath(
      asset: asset,
      pathEntity: targetAlbum,
    );
  }

  // --- 删除 (Delete) ---

  /// 根据 ID 列表删除媒体资源。
  ///
  /// 注意：此操作会从设备上永久删除文件（或移入回收站）。
  Future<List<String>> deleteAssets(List<String> assetIds) async {
    if (!await _requestPermission()) {
      logger.w("Storage permission has not been granted for deletion.");
      return [];
    }
    if (assetIds.isEmpty) return [];

    return await PhotoManager.editor.deleteWithIds(assetIds);
  }
}
