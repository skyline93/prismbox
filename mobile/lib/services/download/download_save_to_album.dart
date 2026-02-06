// lib/services/download/download_save_to_album.dart

import 'dart:io';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart' hide AssetType;
import 'package:prismbox/data/database/app_database.dart';

/// 将下载完成的文件写入系统相册
class DownloadSaveToAlbum {
  final Logger _logger = Logger('DownloadSaveToAlbum');

  /// 请求相册权限，失败返回 false
  Future<bool> requestPermission() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
      _logger.warning(
        'Photo library permission not granted: ${permission.name}',
      );
      return false;
    }
    return true;
  }

  /// 根据任务类型执行写相册：普通图片/视频 或 Live Photo
  /// 返回错误信息，成功时返回 null
  Future<String?> saveToAlbum(DownloadTaskEntityData entity) async {
    final imagePath = entity.imageTempPath;
    final videoPath = entity.videoTempPath;
    final isLivePhoto = entity.livePhotoVideoUuid != null &&
        entity.livePhotoVideoUuid!.isNotEmpty;

    if (isLivePhoto && imagePath != null && videoPath != null) {
      return _saveLivePhoto(
        imagePath: imagePath,
        videoPath: videoPath,
        title: entity.filename,
      );
    }

    if (entity.itemType == 'VIDEO' && videoPath != null) {
      return _saveVideo(File(videoPath), entity.filename);
    }

    if ((entity.itemType == 'IMAGE' || entity.itemType.isEmpty) &&
        imagePath != null) {
      return _saveImage(imagePath, entity.filename);
    }

    return 'Missing temp file: image=$imagePath, video=$videoPath';
  }

  Future<String?> _saveImage(String filePath, String title) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return 'Image file not found: $filePath';
      }
      final bytes = await file.readAsBytes();
      await PhotoManager.editor.saveImage(
        bytes,
        title: title,
        filename: title,
      );
      return null;
    } catch (e, stack) {
      _logger.warning('saveImage failed: $e', e, stack);
      return e.toString();
    }
  }

  Future<String?> _saveVideo(File file, String title) async {
    try {
      if (!await file.exists()) {
        return 'Video file not found: ${file.path}';
      }
      await PhotoManager.editor.saveVideo(
        file,
        title: title,
      );
      return null;
    } catch (e, stack) {
      _logger.warning('saveVideo failed: $e', e, stack);
      return e.toString();
    }
  }

  /// Live Photo：iOS 尝试 saveLivePhoto，Android 降级为仅保存图片
  Future<String?> _saveLivePhoto({
    required String imagePath,
    required String videoPath,
    required String title,
  }) async {
    final imageFile = File(imagePath);
    final videoFile = File(videoPath);
    if (!await imageFile.exists()) {
      return 'Live Photo image file not found: $imagePath';
    }
    if (!await videoFile.exists()) {
      return 'Live Photo video file not found: $videoPath';
    }

    if (Platform.isIOS || Platform.isMacOS) {
      try {
        await PhotoManager.editor.darwin.saveLivePhoto(
          imageFile: imageFile,
          videoFile: videoFile,
          title: title,
        );
        return null;
      } catch (e, stack) {
        _logger.warning('saveLivePhoto failed, fallback to saveImage: $e', e, stack);
        return _saveImage(imagePath, title);
      }
    }

    // Android: 仅保存图片
    return _saveImage(imagePath, title);
  }

  /// 删除临时文件
  Future<void> deleteTempFiles(DownloadTaskEntityData entity) async {
    if (entity.imageTempPath != null) {
      try {
        final f = File(entity.imageTempPath!);
        if (await f.exists()) {
          await f.delete();
        }
      } catch (e) {
        _logger.warning('Failed to delete image temp: ${entity.imageTempPath}, $e');
      }
    }
    if (entity.videoTempPath != null) {
      try {
        final f = File(entity.videoTempPath!);
        if (await f.exists()) {
          await f.delete();
        }
      } catch (e) {
        _logger.warning('Failed to delete video temp: ${entity.videoTempPath}, $e');
      }
    }
  }
}
