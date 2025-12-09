// lib/features/media_loading/requests/local_image_request.dart

import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:prismbox/core/cache/thumbnail_cache_manager.dart';
import 'package:prismbox/features/media_loading/exceptions/file_system_image_exception.dart';
import 'package:prismbox/features/media_loading/exceptions/image_decode_exception.dart';
import 'package:prismbox/features/media_loading/requests/image_request.dart';

/// 本地图片请求
/// 用于加载本地资源的图片
class LocalImageRequest extends ImageRequest {
  final Logger _log = Logger('LocalImageRequest');
  
  /// photo_manager 的 AssetEntity
  final AssetEntity asset;
  
  /// 目标尺寸（可选）
  final Size? targetSize;
  
  /// 缓存管理器（可选）
  final ThumbnailImageCacheManager? cacheManager;
  
  /// 用户 ID（可选）
  final String? userId;
  
  /// 文件校验和（可选）
  final String? checksum;
  
  /// 是否为缩略图请求
  final bool isThumbnail;

  LocalImageRequest({
    required this.asset,
    this.targetSize,
    this.cacheManager,
    this.userId,
    this.checksum,
    this.isThumbnail = false,
  });

  @override
  void onCancel() {
    // 本地加载通常很快，不需要特殊处理
  }

  @override
  Future<ui.Codec> load(ImageDecoderCallback decode) async {
    checkCancelled();
    
    if (isThumbnail) {
      return _loadThumbnail(decode);
    } else {
      return _loadFullImage(decode);
    }
  }

  /// 加载缩略图
  Future<ui.Codec> _loadThumbnail(ImageDecoderCallback decode) async {
    try {
      // 生成缓存键
      final cacheKey = _generateCacheKey();
      
      // 检查磁盘缓存
      final cacheManager = this.cacheManager ?? ThumbnailImageCacheManager();
      final cachedFile = await cacheManager.getFileFromCache(cacheKey);
      
      if (cachedFile != null) {
        checkCancelled();
        _log.fine('Thumbnail cache hit: $cacheKey');
        try {
          final buffer = await ui.ImmutableBuffer.fromFilePath(cachedFile.file.path);
          checkCancelled();
          return await decode(buffer);
        } catch (e) {
          // 解码错误，清理损坏的缓存
          _log.warning('Failed to decode cached thumbnail, removing cache: $cacheKey', e);
          try {
            await cacheManager.removeFile(cacheKey);
          } catch (_) {
            // 忽略清理失败
          }
          // 继续执行，重新生成缩略图
        }
      }

      // 生成缩略图
      checkCancelled();
      _log.fine('Generating thumbnail for asset: ${asset.id}');
      final thumbnail = await asset.thumbnailDataWithSize(
        ThumbnailSize(
          targetSize?.width.toInt() ?? 200,
          targetSize?.height.toInt() ?? 200,
        ),
        quality: 80,
      );

      if (thumbnail == null) {
        throw FileSystemImageException(
          message: 'Failed to generate thumbnail for asset',
          filePath: asset.id,
        );
      }

      // 缓存缩略图
      try {
        await cacheManager.putFile(cacheKey, thumbnail);
      } catch (e) {
        _log.warning('Failed to cache thumbnail: $e');
      }

      // 解码图片
      checkCancelled();
      try {
        final buffer = await ui.ImmutableBuffer.fromUint8List(thumbnail);
        checkCancelled();
        return await decode(buffer);
      } catch (e) {
        // 解码错误，清理可能已缓存的损坏文件
        _log.warning('Failed to decode thumbnail, removing cache: $cacheKey', e);
        try {
          await cacheManager.removeFile(cacheKey);
        } catch (_) {
          // 忽略清理失败
        }
        throw ImageDecodeException(
          message: 'Failed to decode thumbnail',
          source: asset.id,
          originalException: e,
        );
      }
    } on FileSystemImageException {
      rethrow;
    } on ImageDecodeException {
      rethrow;
    } catch (e) {
      throw FileSystemImageException(
        message: 'Unexpected error while loading thumbnail: $e',
        filePath: asset.id,
      );
    }
  }

  /// 加载原图
  /// 
  /// 如果 targetSize 不为 null，对于图片类型也会生成指定尺寸的缩略图（用于渐进式加载）
  /// 如果 targetSize 为 null，对于图片类型直接读取原文件
  Future<ui.Codec> _loadFullImage(ImageDecoderCallback decode) async {
    try {
      if (asset.type == AssetType.image) {
        // 图片：如果指定了 targetSize，生成指定尺寸的缩略图；否则读取原文件
        if (targetSize != null) {
          // 生成指定尺寸的缩略图（用于渐进式加载的第二阶段）
          checkCancelled();
          final thumbnail = await asset.thumbnailDataWithSize(
            ThumbnailSize(
              targetSize!.width.toInt(),
              targetSize!.height.toInt(),
            ),
            quality: 90,
          );

          if (thumbnail == null) {
            throw FileSystemImageException(
              message: 'Failed to generate adapted image for asset',
              filePath: asset.id,
            );
          }

          checkCancelled();
          try {
            final buffer = await ui.ImmutableBuffer.fromUint8List(thumbnail);
            checkCancelled();
            return await decode(buffer);
          } catch (e) {
            throw ImageDecodeException(
              message: 'Failed to decode adapted image',
              source: asset.id,
              originalException: e,
            );
          }
        } else {
          // 直接读取原文件（用于渐进式加载的第三阶段）
          checkCancelled();
          final file = await asset.originFile;
          if (file == null) {
            throw FileSystemImageException(
              message: 'File not found for asset',
              filePath: asset.id,
            );
          }

          checkCancelled();
          try {
            final buffer = await ui.ImmutableBuffer.fromFilePath(file.path);
            checkCancelled();
            return await decode(buffer);
          } catch (e) {
            throw ImageDecodeException(
              message: 'Failed to decode image file',
              source: file.path,
              originalException: e,
            );
          }
        }
      } else {
        // 视频：生成指定尺寸的缩略图
        final targetSize = this.targetSize ?? const Size(1080, 1920);
        checkCancelled();
        final thumbnail = await asset.thumbnailDataWithSize(
          ThumbnailSize(
            targetSize.width.toInt(),
            targetSize.height.toInt(),
          ),
          quality: 80,
        );

        if (thumbnail == null) {
          throw FileSystemImageException(
            message: 'Failed to generate thumbnail for video',
            filePath: asset.id,
          );
        }

        checkCancelled();
        try {
          final buffer = await ui.ImmutableBuffer.fromUint8List(thumbnail);
          checkCancelled();
          return await decode(buffer);
        } catch (e) {
          throw ImageDecodeException(
            message: 'Failed to decode video thumbnail',
            source: asset.id,
            originalException: e,
          );
        }
      }
    } on FileSystemImageException {
      rethrow;
    } on ImageDecodeException {
      rethrow;
    } catch (e) {
      throw FileSystemImageException(
        message: 'Unexpected error while loading image: $e',
        filePath: asset.id,
      );
    }
  }

  /// 生成缓存键
  /// 格式：{userId}{localId}{checksum}{width}{height}
  String _generateCacheKey() {
    final userId = this.userId ?? 'unknown';
    final localId = asset.id;
    final checksum = this.checksum ?? '';
    final width = targetSize?.width.toInt() ?? 200;
    final height = targetSize?.height.toInt() ?? 200;
    return '${userId}${localId}${checksum}${width}${height}';
  }
}

