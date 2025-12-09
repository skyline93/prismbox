// lib/features/media_loading/providers/local_full_provider.dart

import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/core/cache/thumbnail_cache_manager.dart';
import 'package:prismbox/core/settings/app_setting.dart';
import 'package:prismbox/features/media_loading/exceptions/file_system_image_exception.dart';
import 'package:prismbox/features/media_loading/exceptions/image_decode_exception.dart';
import 'package:prismbox/features/media_loading/requests/local_image_request.dart';

/// 本地原图提供者
/// 用于加载本地资源的原图或适配设备分辨率的图片
/// 支持渐进式加载：先显示缩略图，再显示适配分辨率图片，最后根据设置决定是否加载原图
class LocalFullImageProvider extends ImageProvider<LocalFullImageProvider> {
  /// photo_manager 的 AssetEntity
  final AssetEntity asset;
  
  /// 目标尺寸（可选，如果提供则加载适配分辨率的图片）
  final Size? targetSize;
  
  /// 缓存管理器（可选）
  final ThumbnailImageCacheManager? cacheManager;
  
  /// 用户 ID（可选）
  final String? userId;
  
  /// 文件校验和（可选）
  final String? checksum;

  final Logger _log = Logger('LocalFullImageProvider');

  LocalFullImageProvider({
    required this.asset,
    this.targetSize,
    this.cacheManager,
    this.userId,
    this.checksum,
  });

  @override
  Future<LocalFullImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(this);
  }

  @override
  ImageStreamCompleter loadImage(
    LocalFullImageProvider key,
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
  /// 阶段 3：根据 loadOriginal 设置决定是否加载原图
  Stream<ui.Codec> _loadImage(LocalFullImageProvider key, ImageDecoderCallback decode) async* {
    try {
      final shouldLoadOriginal = AppSetting.get(Setting.loadOriginal);
      final cacheManager = key.cacheManager ?? ThumbnailImageCacheManager();
      
      if (key.asset.type == AssetType.image) {
        // 阶段 1：加载缩略图
        final thumbCodec = await _loadThumbnail(key, decode, cacheManager);
        yield thumbCodec;
        
        // 阶段 2：加载适配设备分辨率的图片
        final adaptedCodec = await _loadAdaptedImage(key, decode);
        yield adaptedCodec;
        
        // 阶段 3：根据设置决定是否加载原图
        if (shouldLoadOriginal) {
          final originalCodec = await _loadOriginalImage(key, decode);
          yield originalCodec;
        }
      } else {
        // 视频：使用 LocalImageRequest 生成指定尺寸的缩略图
        final targetSize = key.targetSize ?? const Size(1080, 1920);
        final request = LocalImageRequest(
          asset: key.asset,
          targetSize: targetSize,
          cacheManager: cacheManager,
          userId: key.userId,
          checksum: key.checksum,
          isThumbnail: false, // 视频使用全图模式，但会生成指定尺寸的缩略图
        );
        
        final codec = await request.load(decode);
        yield codec;
      }
    } on FileSystemImageException {
      rethrow;
    } on ImageDecodeException {
      rethrow;
    } catch (e, stackTrace) {
      _log.severe('Failed to load local full image', e, stackTrace);
      throw FileSystemImageException(
        message: 'Unexpected error while loading image: $e',
        filePath: key.asset.id,
      );
    }
  }
  
  /// 加载缩略图（阶段 1）
  /// 
  /// 使用 LocalImageRequest 处理缩略图加载
  Future<ui.Codec> _loadThumbnail(
    LocalFullImageProvider key,
    ImageDecoderCallback decode,
    ThumbnailImageCacheManager cacheManager,
  ) async {
    final request = LocalImageRequest(
      asset: key.asset,
      targetSize: const Size(200, 200),
      cacheManager: cacheManager,
      userId: key.userId,
      checksum: key.checksum,
      isThumbnail: true,
    );
    
    return await request.load(decode);
  }
  
  /// 加载适配设备分辨率的图片（阶段 2）
  /// 
  /// 使用 LocalImageRequest 处理适配尺寸的图片加载
  Future<ui.Codec> _loadAdaptedImage(
    LocalFullImageProvider key,
    ImageDecoderCallback decode,
  ) async {
    final targetSize = key.targetSize ?? _getDeviceResolution();
    final cacheManager = key.cacheManager ?? ThumbnailImageCacheManager();
    
    // 使用 LocalImageRequest 加载适配尺寸的图片
    // 注意：对于图片类型，LocalImageRequest 会生成指定尺寸的缩略图
    final request = LocalImageRequest(
      asset: key.asset,
      targetSize: targetSize,
      cacheManager: cacheManager,
      userId: key.userId,
      checksum: key.checksum,
      isThumbnail: false, // 不是缩略图，但会生成适配尺寸的图片
    );
    
    return await request.load(decode);
  }
  
  /// 加载原图（阶段 3）
  /// 
  /// 使用 LocalImageRequest 处理原图加载
  /// 对于图片类型，直接读取原文件；对于视频类型，生成高质量缩略图
  Future<ui.Codec> _loadOriginalImage(
    LocalFullImageProvider key,
    ImageDecoderCallback decode,
  ) async {
    final cacheManager = key.cacheManager ?? ThumbnailImageCacheManager();
    
    // 使用 LocalImageRequest 加载原图
    // LocalImageRequest 的 _loadFullImage 会处理图片和视频的不同情况
    final request = LocalImageRequest(
      asset: key.asset,
      targetSize: null, // 原图不需要指定尺寸
      cacheManager: cacheManager,
      userId: key.userId,
      checksum: key.checksum,
      isThumbnail: false,
    );
    
    return await request.load(decode);
  }
  
  /// 获取设备分辨率
  /// 
  /// 使用 Flutter 的 window API 动态获取设备分辨率
  /// 如果获取失败，回退到默认值 1080p
  Size _getDeviceResolution() {
    try {
      // 使用 Flutter 的 window API
      final views = ui.PlatformDispatcher.instance.views;
      if (views.isNotEmpty) {
        final view = views.first;
        final physicalSize = view.physicalSize;
        final devicePixelRatio = view.devicePixelRatio;
        
        // 计算逻辑分辨率（考虑设备像素比）
        return Size(
          physicalSize.width / devicePixelRatio,
          physicalSize.height / devicePixelRatio,
        );
      }
    } catch (e) {
      _log.warning('Failed to get device resolution, using default', e);
    }
    
    // 回退到默认值
    return const Size(1080, 1920);
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalFullImageProvider &&
          runtimeType == other.runtimeType &&
          asset.id == other.asset.id &&
          targetSize == other.targetSize &&
          userId == other.userId &&
          checksum == other.checksum;

  @override
  int get hashCode => Object.hash(asset.id, targetSize, userId, checksum);
}

/// 多图片流完成器
/// 支持渐进式加载：先显示缩略图，再显示适配分辨率图片，最后显示原图
class MultiImageStreamCompleter extends ImageStreamCompleter {
  final Stream<ui.Codec> codec;
  bool _isDisposed = false;

  MultiImageStreamCompleter({
    required this.codec,
    required double scale,
  }) : super() {
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
            reportError(
              exception: e,
              stack: StackTrace.current,
            );
          }
        }
      }
    } catch (e, stackTrace) {
      if (!_isDisposed) {
        reportError(
          exception: e,
          stack: stackTrace,
        );
      }
    }
  }
}

