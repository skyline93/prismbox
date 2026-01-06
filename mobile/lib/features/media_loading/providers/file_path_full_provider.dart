// lib/features/media_loading/providers/file_path_full_provider.dart

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/core/cache/thumbnail_cache_manager.dart';
import 'package:prismbox/core/settings/app_setting.dart';
import 'package:prismbox/features/media_loading/exceptions/file_system_image_exception.dart';
import 'package:prismbox/features/media_loading/exceptions/image_decode_exception.dart';
import 'package:image/image.dart' as img;

/// 基于文件路径的完整图片提供者
/// 用于加载已删除资源（在回收站中）的完整图片
/// 支持渐进式加载：先显示缩略图，再显示适配分辨率图片，最后根据设置决定是否加载原图
class FilePathFullProvider extends ImageProvider<FilePathFullProvider> {
  /// 文件路径
  final String filePath;

  /// 目标尺寸（可选，如果提供则加载适配分辨率的图片）
  final Size? targetSize;

  /// 缓存管理器（可选）
  final ThumbnailImageCacheManager? cacheManager;

  /// 用户 ID（可选）
  final String? userId;

  /// 文件校验和（可选）
  final String? checksum;

  /// 是否加载原图（可选，如果为 true 则在渐进式加载的最后阶段加载原图）
  final bool loadOriginal;

  final Logger _log = Logger('FilePathFullProvider');

  FilePathFullProvider({
    required this.filePath,
    this.targetSize,
    this.cacheManager,
    this.userId,
    this.checksum,
    this.loadOriginal = false,
  });

  @override
  Future<FilePathFullProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(this);
  }

  @override
  ImageStreamCompleter loadImage(
    FilePathFullProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiImageStreamCompleter(
      codec: _loadImage(key, decode),
      scale: 1.0,
    );
  }

  /// 加载图片（支持渐进式加载）
  /// 阶段 1：加载缩略图（从缓存或生成）
  /// 阶段 2：加载适配设备分辨率的图片
  /// 阶段 3：根据 loadOriginal 参数或全局设置决定是否加载原图
  Stream<ui.Codec> _loadImage(
    FilePathFullProvider key,
    ImageDecoderCallback decode,
  ) async* {
    try {
      // 检查文件是否存在
      final file = File(key.filePath);
      if (!await file.exists()) {
        throw FileSystemImageException(
          message: 'File not found',
          filePath: key.filePath,
        );
      }

      // 如果 loadOriginal 为 true，强制加载原图；否则使用全局设置
      final shouldLoadOriginal =
          key.loadOriginal || AppSetting.get(Setting.loadOriginal);
      final cacheManager = key.cacheManager ?? ThumbnailImageCacheManager();

      // 阶段 1：加载缩略图
      final thumbCodec = await _loadThumbnail(key, decode, cacheManager);
      yield thumbCodec;

      // 阶段 2：加载适配设备分辨率的图片
      final adaptedCodec = await _loadAdaptedImage(key, decode, cacheManager);
      yield adaptedCodec;

      // 阶段 3：根据 loadOriginal 参数或全局设置决定是否加载原图
      if (shouldLoadOriginal) {
        final originalCodec = await _loadOriginalImage(key, decode);
        yield originalCodec;
      }
    } on FileSystemImageException {
      rethrow;
    } on ImageDecodeException {
      rethrow;
    } catch (e, stackTrace) {
      _log.severe('Failed to load full image from file path', e, stackTrace);
      throw FileSystemImageException(
        message: 'Unexpected error while loading image: $e',
        filePath: key.filePath,
      );
    }
  }

  /// 加载缩略图（阶段 1）
  Future<ui.Codec> _loadThumbnail(
    FilePathFullProvider key,
    ImageDecoderCallback decode,
    ThumbnailImageCacheManager cacheManager,
  ) async {
    return await _loadThumbnailFromPath(
      key.filePath,
      const Size(200, 200),
      decode,
      cacheManager,
      key.userId,
      key.checksum,
    );
  }

  /// 加载适配设备分辨率的图片（阶段 2）
  Future<ui.Codec> _loadAdaptedImage(
    FilePathFullProvider key,
    ImageDecoderCallback decode,
    ThumbnailImageCacheManager cacheManager,
  ) async {
    final targetSize = key.targetSize ?? _getDeviceResolution();

    return await _loadThumbnailFromPath(
      key.filePath,
      targetSize,
      decode,
      cacheManager,
      key.userId,
      key.checksum,
    );
  }

  /// 从文件路径加载缩略图（共享逻辑）
  Future<ui.Codec> _loadThumbnailFromPath(
    String filePath,
    Size size,
    ImageDecoderCallback decode,
    ThumbnailImageCacheManager cacheManager,
    String? userId,
    String? checksum,
  ) async {
    try {
      // 检查文件是否存在
      final file = File(filePath);
      if (!await file.exists()) {
        throw FileSystemImageException(
          message: 'File not found',
          filePath: filePath,
        );
      }

      // 生成缓存键
      final cacheKey = _getCacheKey(filePath, size, checksum);

      // 检查缓存
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
          source: filePath,
        );
      }

      // 生成缩略图
      final thumbnail = img.copyResize(
        originalImage,
        width: size.width.toInt(),
        height: size.height.toInt(),
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
        filePath: filePath,
      );
    }
  }

  /// 生成缓存键
  String _getCacheKey(String filePath, Size size, String? checksum) {
    final parts = <String>[
      'file_path_thumb',
      filePath,
      '${size.width.toInt()}x${size.height.toInt()}',
    ];
    if (checksum != null) {
      parts.add(checksum);
    }
    return parts.join('_');
  }

  /// 加载原图（阶段 3）
  Future<ui.Codec> _loadOriginalImage(
    FilePathFullProvider key,
    ImageDecoderCallback decode,
  ) async {
    try {
      final file = File(key.filePath);
      if (!await file.exists()) {
        throw FileSystemImageException(
          message: 'File not found',
          filePath: key.filePath,
        );
      }

      final buffer = await ui.ImmutableBuffer.fromFilePath(file.path);
      return await decode(buffer);
    } catch (e) {
      throw ImageDecodeException(
        message: 'Failed to decode image file',
        source: key.filePath,
        originalException: e,
      );
    }
  }

  /// 获取设备分辨率
  Size _getDeviceResolution() {
    try {
      final views = ui.PlatformDispatcher.instance.views;
      if (views.isNotEmpty) {
        final view = views.first;
        final physicalSize = view.physicalSize;
        final devicePixelRatio = view.devicePixelRatio;

        return Size(
          physicalSize.width / devicePixelRatio,
          physicalSize.height / devicePixelRatio,
        );
      }
    } catch (e) {
      _log.warning('Failed to get device resolution, using default', e);
    }

    return const Size(1080, 1920);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilePathFullProvider &&
          runtimeType == other.runtimeType &&
          filePath == other.filePath &&
          targetSize == other.targetSize &&
          userId == other.userId &&
          checksum == other.checksum &&
          loadOriginal == other.loadOriginal;

  @override
  int get hashCode =>
      Object.hash(filePath, targetSize, userId, checksum, loadOriginal);
}

/// 多图片流完成器
/// 支持渐进式加载：先显示缩略图，再显示适配分辨率图片，最后显示原图
class MultiImageStreamCompleter extends ImageStreamCompleter {
  final Stream<ui.Codec> codec;
  bool _isDisposed = false;

  MultiImageStreamCompleter({required this.codec, required double scale})
    : super() {
    _loadImages();
  }

  void _loadImages() async {
    try {
      await for (final codec in codec) {
        if (_isDisposed) {
          codec.dispose();
          continue;
        }

        try {
          final frame = await codec.getNextFrame();
          if (!_isDisposed) {
            setImage(ImageInfo(image: frame.image, scale: 1.0));
          }
        } catch (e) {
          if (!_isDisposed) {
            reportError(exception: e, stack: StackTrace.current);
          }
        }
      }
    } catch (e, stackTrace) {
      if (!_isDisposed) {
        reportError(exception: e, stack: stackTrace);
      }
    }
  }
}
