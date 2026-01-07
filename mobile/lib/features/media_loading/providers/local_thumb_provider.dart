// lib/features/media_loading/providers/local_thumb_provider.dart

import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:prismbox/core/cache/thumbnail_cache_manager.dart';
import 'package:prismbox/features/media_loading/requests/local_image_request.dart';

/// 包装 MultiFrameImageStreamCompleter，添加详细的错误日志和错误处理
class WrappedMultiFrameImageStreamCompleter extends ImageStreamCompleter {
  final Future<ui.Codec> codecFuture;
  final String assetId;
  final Logger log;
  bool _isDisposed = false;
  ui.Codec? _codec;

  WrappedMultiFrameImageStreamCompleter({
    required this.codecFuture,
    required this.assetId,
    required this.log,
    required double scale,
  }) : super() {
    _loadCodec();
  }

  void _loadCodec() async {
    try {
      log.fine('Loading codec: assetId=$assetId');
      _codec = await codecFuture;
      
      if (_isDisposed) {
        _codec?.dispose();
        return;
      }

      log.fine('Codec loaded, getting next frame: assetId=$assetId');
      
      try {
        final frame = await _codec!.getNextFrame();
        
        if (_isDisposed) {
          frame.image.dispose();
          return;
        }

        log.fine('Frame obtained successfully: assetId=$assetId, size=${frame.image.width}x${frame.image.height}');
        setImage(ImageInfo(image: frame.image, scale: 1.0));
      } catch (e, stackTrace) {
        log.severe(
          'Failed to get next frame: assetId=$assetId, error=$e',
          e,
          stackTrace,
        );
        if (!_isDisposed) {
          reportError(
            exception: e,
            stack: stackTrace,
          );
        }
      }
    } catch (e, stackTrace) {
      log.severe(
        'Failed to load codec: assetId=$assetId, error=$e',
        e,
        stackTrace,
      );
      if (!_isDisposed) {
        reportError(
          exception: e,
          stack: stackTrace,
        );
      }
    }
  }

  @override
  void onDisposed() {
    _isDisposed = true;
    _codec?.dispose();
    super.onDisposed();
  }
}

/// 本地缩略图提供者
/// 用于加载本地资源的缩略图
class LocalThumbProvider extends ImageProvider<LocalThumbProvider> {
  static final _log = Logger('LocalThumbProvider');

  /// photo_manager 的 AssetEntity
  final AssetEntity asset;
  
  /// 目标尺寸
  final Size size;
  
  /// 缓存管理器（可选）
  final ThumbnailImageCacheManager? cacheManager;
  
  /// 用户 ID（可选，用于多用户场景）
  final String? userId;
  
  /// 文件校验和（可选，用于检测文件变更）
  final String? checksum;

  LocalThumbProvider({
    required this.asset,
    required this.size,
    this.cacheManager,
    this.userId,
    this.checksum,
  });

  @override
  Future<LocalThumbProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(this);
  }

  @override
  ImageStreamCompleter loadImage(
    LocalThumbProvider key,
    ImageDecoderCallback decode,
  ) {
    final completer = WrappedMultiFrameImageStreamCompleter(
      codecFuture: _loadThumbnail(key, decode),
      assetId: key.asset.id,
      log: _log,
      scale: 1.0,
    );
    
    // 添加错误监听，记录详细的错误信息
    completer.addListener(
      ImageStreamListener(
        (ImageInfo image, bool synchronousCall) {
          _log.fine(
            'Image loaded successfully: assetId=${key.asset.id}, synchronous=$synchronousCall',
          );
        },
        onError: (Object exception, StackTrace? stackTrace) {
          _log.severe(
            'ImageStream error: assetId=${key.asset.id}, error=$exception',
            exception,
            stackTrace,
          );
        },
      ),
    );
    
    return completer;
  }

  /// 加载缩略图
  /// 
  /// 使用 LocalImageRequest 处理加载逻辑，减少代码耦合
  Future<ui.Codec> _loadThumbnail(LocalThumbProvider key, ImageDecoderCallback decode) async {
    try {
      _log.fine('Loading thumbnail: assetId=${key.asset.id}, size=${key.size}');
      
      final request = LocalImageRequest(
        asset: key.asset,
        targetSize: key.size,
        cacheManager: key.cacheManager,
        userId: key.userId,
        checksum: key.checksum,
        isThumbnail: true,
      );
      
      final codec = await request.load(decode);
      
      _log.fine('Thumbnail codec loaded successfully: assetId=${key.asset.id}');
      
      return codec;
    } catch (e, stackTrace) {
      _log.severe(
        'Failed to load thumbnail codec: assetId=${key.asset.id}, error=$e',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalThumbProvider &&
          runtimeType == other.runtimeType &&
          asset.id == other.asset.id &&
          size == other.size &&
          userId == other.userId &&
          checksum == other.checksum;

  @override
  int get hashCode => Object.hash(asset.id, size, userId, checksum);
}

