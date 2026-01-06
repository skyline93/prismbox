// lib/features/media_loading/providers/file_path_thumb_provider.dart

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/core/cache/thumbnail_cache_manager.dart';
import 'package:prismbox/features/media_loading/exceptions/file_system_image_exception.dart';
import 'package:prismbox/features/media_loading/exceptions/image_decode_exception.dart';
import 'package:image/image.dart' as img;

/// 基于文件路径的缩略图提供者
/// 用于加载已删除资源（在回收站中）的缩略图
/// 不依赖 AssetEntity，直接从文件路径加载
class FilePathThumbProvider extends ImageProvider<FilePathThumbProvider> {
  /// 文件路径
  final String filePath;

  /// 目标尺寸
  final Size size;

  /// 缓存管理器（可选）
  final ThumbnailImageCacheManager? cacheManager;

  /// 用户 ID（可选，用于多用户场景）
  final String? userId;

  /// 文件校验和（可选，用于检测文件变更）
  final String? checksum;

  final Logger _log = Logger('FilePathThumbProvider');

  FilePathThumbProvider({
    required this.filePath,
    required this.size,
    this.cacheManager,
    this.userId,
    this.checksum,
  });

  @override
  Future<FilePathThumbProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(this);
  }

  @override
  ImageStreamCompleter loadImage(
    FilePathThumbProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadThumbnail(key, decode),
      scale: 1.0,
    );
  }

  /// 加载缩略图
  ///
  /// 从文件路径读取图片，生成指定尺寸的缩略图
  Future<ui.Codec> _loadThumbnail(
    FilePathThumbProvider key,
    ImageDecoderCallback decode,
  ) async {
    try {
      // 检查文件是否存在
      final file = File(key.filePath);
      if (!await file.exists()) {
        throw FileSystemImageException(
          message: 'File not found',
          filePath: key.filePath,
        );
      }

      // 检查缓存
      final cacheManager = key.cacheManager ?? ThumbnailImageCacheManager();
      final cacheKey = _getCacheKey(key);
      final cachedFile = await cacheManager.getFileFromCache(cacheKey);

      if (cachedFile != null && await cachedFile.file.exists()) {
        _log.fine('Loading thumbnail from cache: $cacheKey');
        try {
          final buffer = await ui.ImmutableBuffer.fromFilePath(
            cachedFile.file.path,
          );
          return await decode(buffer);
        } catch (e) {
          _log.warning('Failed to load cached thumbnail, regenerating', e);
          await cacheManager.removeFile(cacheKey);
        }
      }

      // 读取原始图片
      final imageBytes = await file.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        throw ImageDecodeException(
          message: 'Failed to decode image',
          source: key.filePath,
        );
      }

      // 生成缩略图
      final thumbnail = img.copyResize(
        originalImage,
        width: key.size.width.toInt(),
        height: key.size.height.toInt(),
        interpolation: img.Interpolation.linear,
      );

      // 编码缩略图
      final thumbnailBytes = img.encodeJpg(thumbnail, quality: 90);

      // 保存到缓存
      await cacheManager.putFile(cacheKey, thumbnailBytes);

      // 解码并返回
      final buffer = await ui.ImmutableBuffer.fromUint8List(thumbnailBytes);
      return await decode(buffer);
    } on FileSystemImageException {
      rethrow;
    } on ImageDecodeException {
      rethrow;
    } catch (e, stackTrace) {
      _log.severe('Failed to load thumbnail from file path', e, stackTrace);
      throw FileSystemImageException(
        message: 'Unexpected error while loading thumbnail: $e',
        filePath: key.filePath,
      );
    }
  }

  /// 生成缓存键
  String _getCacheKey(FilePathThumbProvider key) {
    final parts = [
      'file_path_thumb',
      key.filePath,
      '${key.size.width.toInt()}x${key.size.height.toInt()}',
      if (key.checksum != null) key.checksum,
    ];
    return parts.where((p) => p != null).join('_');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilePathThumbProvider &&
          runtimeType == other.runtimeType &&
          filePath == other.filePath &&
          size == other.size &&
          userId == other.userId &&
          checksum == other.checksum;

  @override
  int get hashCode => Object.hash(filePath, size, userId, checksum);
}
