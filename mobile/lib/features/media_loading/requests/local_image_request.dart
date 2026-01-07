// lib/features/media_loading/requests/local_image_request.dart

import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:prismbox/core/cache/thumbnail_cache_manager.dart';
import 'package:prismbox/features/media_loading/exceptions/file_system_image_exception.dart';
import 'package:prismbox/features/media_loading/exceptions/image_decode_exception.dart';
import 'package:prismbox/features/media_loading/mixins/cancellable_image_provider_mixin.dart';
import 'package:prismbox/features/media_loading/requests/image_request.dart';
import 'package:prismbox/platform/thumbnail_api_service.dart';

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

  /// 原生解码服务
  final ThumbnailApiService _thumbnailApiService = ThumbnailApiService();

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
    // 原生解码支持取消，但这里我们使用 ThumbnailApiService 的内部请求 ID
    // 如果需要取消原生解码，可以在 ThumbnailApiService 中实现
  }

  /// 判断是否应该使用原生解码
  ///
  /// **规则**：
  /// - 统一使用原生解码，不区分格式和尺寸
  /// - 原生 API 已经能够高效处理各种格式（包括 RAW 格式）和任意尺寸
  /// - 原生层已经实现了采样缩放，优化内存使用
  /// - 如果原生解码失败，会自动降级到 Flutter 层处理
  bool _shouldUseNativeDecode() {
    // 统一使用原生解码，不区分格式和尺寸
    // 原生 API（Android ImageDecoder、iOS PHImageManager）已经能够处理任意尺寸的图片
    return true;
  }

  /// 检测是否为 RAW 格式
  ///
  /// 通过文件扩展名检测常见的 RAW 格式
  /// 如果 asset.title 为空，尝试从 originFile 获取文件名
  Future<bool> _isRawFormat() async {
    // 首先尝试从 asset.title 获取文件名
    String? fileName = asset.title;
    String? source = 'title';

    // 如果 title 为空，尝试从 originFile 获取
    if (fileName == null || fileName.isEmpty) {
      try {
        final file = await asset.originFile;
        if (file != null) {
          final path = file.path;
          // 从路径中提取文件名
          fileName = path.split('/').last;
          // 移除可能的查询参数（iOS 临时文件可能包含）
          if (fileName.contains('?')) {
            fileName = fileName.split('?').first;
          }
          source = 'originFile';
        }
      } catch (e) {
        _log.warning('Failed to get originFile for RAW format detection: $e');
      }
    }

    _log.fine(
      'RAW format detection: fileName=$fileName, source=$source, assetId=${asset.id}',
    );

    if (fileName == null || fileName.isEmpty) {
      _log.fine('Cannot detect RAW format: fileName is empty');
      return false;
    }

    final extension = fileName.toLowerCase();

    // 常见 RAW 格式扩展名
    const rawExtensions = [
      '.dng',
      '.cr2',
      '.cr3',
      '.nef',
      '.arw',
      '.orf',
      '.raf',
      '.rw2',
      '.pef',
      '.srw',
      '.3fr',
      '.erf',
      '.mrw',
      '.nrw',
      '.kdc',
      '.dcr',
      '.raw',
      '.x3f',
      '.fff',
      '.iiq',
      '.ari',
      '.cap',
      '.cin',
      '.crw',
    ];

    final isRaw = rawExtensions.any((ext) => extension.endsWith(ext));

    _log.fine(
      'RAW format detection result: isRaw=$isRaw, extension=${extension.isEmpty ? "none" : extension}, fileName=$fileName',
    );

    return isRaw;
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
  ///
  /// 优先使用原生解码（如果满足条件），失败时降级到 Flutter 层处理
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
          final buffer = await ui.ImmutableBuffer.fromFilePath(
            cachedFile.file.path,
          );
          checkCancelled();
          return await decode(buffer);
        } catch (e) {
          // 解码错误，清理损坏的缓存
          _log.warning(
            'Failed to decode cached thumbnail, removing cache: $cacheKey',
            e,
          );
          try {
            await cacheManager.removeFile(cacheKey);
          } catch (_) {
            // 忽略清理失败
          }
          // 继续执行，重新生成缩略图
        }
      }

      // 统一使用原生解码
      // 原生 API 已经能够高效处理各种格式（包括 RAW 格式）和任意尺寸
      if (_shouldUseNativeDecode()) {
        try {
          checkCancelled();

          // 检测格式类型并记录日志
          final isRaw = await _isRawFormat();
          final formatType = isRaw ? 'RAW' : 'standard';
          final fileName = asset.title ?? asset.id;
          final targetWidth = (targetSize?.width ?? 200).toInt();
          final targetHeight = (targetSize?.height ?? 200).toInt();
          final isVideo = asset.type == AssetType.video;

          _log.info(
            'Using native decode for $formatType format thumbnail: $fileName (${targetWidth}x$targetHeight, ${isVideo ? "video" : "image"})',
          );

          // 使用原生解码，直接获取 Codec
          final codec = await _thumbnailApiService.requestImageCodec(
            assetId: asset.id,
            width: targetWidth,
            height: targetHeight,
            isVideo: isVideo,
          );

          if (codec == null) {
            // 请求被取消
            throw CancelledException('Image request was cancelled');
          }

          checkCancelled();

          // 原生解码成功，记录成功日志
          _log.info(
            'Native decode succeeded for $formatType format: $fileName',
          );

          // 原生解码成功，直接返回 Codec
          // 注意：原生解码的结果不经过缓存，因为原生层已经处理了缓存逻辑
          // 如果需要缓存原生解码结果，可以在这里添加缓存逻辑
          // 注意：不要在这里测试 getNextFrame()，因为它会消耗第一帧，
          // 导致 MultiFrameImageStreamCompleter 再次调用时失败
          return codec;
        } catch (e, stackTrace) {
          // 原生解码失败，降级到 Flutter 层
          if (e is CancelledException) {
            rethrow;
          }
          final isRaw = await _isRawFormat();
          final formatType = isRaw ? 'RAW' : 'standard';
          final fileName = asset.title ?? asset.id;

          _log.warning(
            'Native decode failed for $formatType format, falling back to Flutter layer: $e',
            e,
            stackTrace,
          );
          
          // 记录详细的错误信息
          if (e is PlatformException) {
            _log.warning(
              'PlatformException details: code=${e.code}, message=${e.message}, details=${e.details}',
            );
          } else if (e is Exception) {
            _log.warning(
              'Exception type: ${e.runtimeType}, message: ${e.toString()}',
            );
          }
          
          if (isRaw) {
            _log.warning(
              'RAW format detected but native decode failed, using Flutter fallback: $fileName',
            );
          }
          
          _log.info('Attempting Flutter layer fallback: $fileName');
          return await _loadThumbnailFlutter(decode, cacheManager, cacheKey);
        }
      } else {
        // 使用 Flutter 层处理
        return await _loadThumbnailFlutter(decode, cacheManager, cacheKey);
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

  /// 使用 Flutter 层加载缩略图（降级方案）
  Future<ui.Codec> _loadThumbnailFlutter(
    ImageDecoderCallback decode,
    ThumbnailImageCacheManager cacheManager,
    String cacheKey,
  ) async {
    // 生成缩略图
    checkCancelled();
    _log.fine('Generating thumbnail with Flutter layer for asset: ${asset.id}');

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
  }

  /// 加载原图
  ///
  /// 如果 targetSize 不为 null，对于图片类型也会生成指定尺寸的缩略图（用于渐进式加载）
  /// 如果 targetSize 为 null，对于图片类型直接读取原文件（使用 Flutter 层，避免跨层大文件传递）
  Future<ui.Codec> _loadFullImage(ImageDecoderCallback decode) async {
    try {
      if (asset.type == AssetType.image) {
        // 图片：如果指定了 targetSize，生成指定尺寸的缩略图；否则读取原文件
        if (targetSize != null) {
          // 统一使用原生解码
          // 原生 API 已经能够高效处理各种格式（包括 RAW 格式）和任意尺寸
          if (_shouldUseNativeDecode()) {
            try {
              checkCancelled();

              // 检测格式类型并记录日志
              final isRaw = await _isRawFormat();
              final formatType = isRaw ? 'RAW' : 'standard';
              final fileName = asset.title ?? asset.id;
              final targetWidth = targetSize!.width.toInt();
              final targetHeight = targetSize!.height.toInt();

              _log.info(
                'Using native decode for $formatType format adapted image: $fileName (${targetWidth}x$targetHeight)',
              );

              final codec = await _thumbnailApiService.requestImageCodec(
                assetId: asset.id,
                width: targetWidth,
                height: targetHeight,
                isVideo: false,
              );

              if (codec == null) {
                throw CancelledException('Image request was cancelled');
              }

              checkCancelled();

              // 原生解码成功，记录成功日志
              _log.info(
                'Native decode succeeded for $formatType format adapted image: $fileName',
              );

              // 原生解码成功，直接返回 Codec
              // 注意：不要在这里测试 getNextFrame()，因为它会消耗第一帧，
              // 导致 MultiImageStreamCompleter 再次调用时失败
              return codec;
            } catch (e) {
              if (e is CancelledException) {
                rethrow;
              }
              // 原生解码失败，降级到 Flutter 层
              final isRaw = await _isRawFormat();
              final formatType = isRaw ? 'RAW' : 'standard';
              final fileName = asset.title ?? asset.id;

              _log.warning(
                'Native decode failed for $formatType format adapted image, falling back to Flutter layer: $e',
              );
              if (isRaw) {
                _log.warning(
                  'RAW format detected but native decode failed for adapted image, using Flutter fallback: $fileName',
                );
              }
            }
          }

          // 使用 Flutter 层生成指定尺寸的缩略图（用于渐进式加载的第二阶段）
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
          // 加载原图（用于渐进式加载的第三阶段）
          // 使用原生解码，传递 width=0, height=0 表示最大尺寸/原图
          // iOS 原生层：width=0, height=0 对应 PHImageManagerMaximumSize
          // Android 原生层：width=0, height=0 时返回原图尺寸
          try {
            checkCancelled();

            // 检测格式类型并记录日志
            final isRaw = await _isRawFormat();
            final formatType = isRaw ? 'RAW' : 'standard';
            final fileName = asset.title ?? asset.id;

            _log.info(
              'Using native decode for $formatType format original image: $fileName',
            );

            final codec = await _thumbnailApiService.requestImageCodec(
              assetId: asset.id,
              width: 0, // 0 表示最大尺寸/原图
              height: 0, // 0 表示最大尺寸/原图
              isVideo: false,
            );

            if (codec == null) {
              throw CancelledException('Image request was cancelled');
            }

            checkCancelled();

            // 原生解码成功，记录成功日志
            _log.info(
              'Native decode succeeded for $formatType format original image: $fileName',
            );

            return codec;
          } catch (e) {
            if (e is CancelledException) {
              rethrow;
            }
            // 原生解码失败，降级到 Flutter 层
            final isRaw = await _isRawFormat();
            final formatType = isRaw ? 'RAW' : 'standard';
            final fileName = asset.title ?? asset.id;

            _log.warning(
              'Native decode failed for $formatType format original image, falling back to Flutter layer: $e',
            );
            if (isRaw) {
              _log.warning(
                'RAW format detected but native decode failed for original image, using Flutter fallback: $fileName',
              );
            }

            // 降级到 Flutter 层：直接读取原文件
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
            } catch (decodeError) {
              throw ImageDecodeException(
                message: 'Failed to decode image file',
                source: file.path,
                originalException: decodeError,
              );
            }
          }
        }
      } else {
        // 视频：生成指定尺寸的缩略图
        final targetSize = this.targetSize ?? const Size(1080, 1920);
        checkCancelled();
        final thumbnail = await asset.thumbnailDataWithSize(
          ThumbnailSize(targetSize.width.toInt(), targetSize.height.toInt()),
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
    return '$userId$localId$checksum$width$height';
  }
}
