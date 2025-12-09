// lib/features/media_loading/loaders/image_loader.dart

import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/features/media_loading/exceptions/image_decode_exception.dart';
import 'package:prismbox/features/media_loading/exceptions/network_image_exception.dart';
import 'package:prismbox/features/media_loading/mixins/cancellable_image_provider_mixin.dart';
import 'package:prismbox/features/media_loading/utils/retry_helper.dart';

/// 图片加载器
/// 统一图片加载接口，集成缓存管理器和进度事件
class ImageLoader {
  static final Logger _log = Logger('ImageLoader');
  
  /// 从缓存加载图片
  /// 
  /// [url] 图片 URL 或缓存键
  /// [cacheManager] 缓存管理器
  /// [decode] 图片解码回调
  /// 
  /// 返回解码后的 Codec，如果缓存不存在则返回 null
  static Future<ui.Codec?> loadImageFromCache(
    String url,
    CacheManager cacheManager,
    ImageDecoderCallback decode,
  ) async {
    try {
      final cachedFile = await cacheManager.getFileFromCache(url);
      if (cachedFile != null) {
        _log.fine('Image cache hit: $url');
        try {
          final buffer = await ui.ImmutableBuffer.fromFilePath(cachedFile.file.path);
          return await decode(buffer);
        } catch (e) {
          // 解码错误，清理损坏的缓存
          _log.warning('Failed to decode cached image, removing cache: $url', e);
          try {
            await cacheManager.removeFile(url);
          } catch (_) {
            // 忽略清理失败
          }
          throw ImageDecodeException(
            message: 'Failed to decode cached image',
            source: cachedFile.file.path,
            originalException: e,
          );
        }
      }
      return null;
    } catch (e) {
      _log.warning('Failed to load image from cache: $url', e);
      return null;
    }
  }
  
  /// 从网络加载图片（带重试和进度报告）
  /// 
  /// [url] 图片 URL
  /// [cacheManager] 缓存管理器
  /// [decode] 图片解码回调
  /// [onProgress] 进度回调（可选）
  /// [onCancel] 取消检查函数（可选）
  /// [onSubscription] 订阅设置回调（可选，用于管理订阅）
  /// 
  /// 返回解码后的 Codec
  static Future<ui.Codec> loadImageFromNetwork(
    String url,
    CacheManager cacheManager,
    ImageDecoderCallback decode, {
    void Function(int downloaded, int? total)? onProgress,
    bool Function()? onCancel,
    void Function(StreamSubscription?)? onSubscription,
  }) async {
    return await RetryHelper.executeWithRetry<ui.Codec>(
      operation: () async {
        _log.fine('Downloading image: $url');
        
        final stream = cacheManager.getFileStream(
          url,
          withProgress: true,
        );
        
        await for (final response in stream) {
          // 检查取消
          if (onCancel?.call() ?? false) {
            throw CancelledException('Image loading was cancelled');
          }
          
          if (response is DownloadProgress) {
            onProgress?.call(response.downloaded, response.totalSize);
          } else if (response is FileInfo) {
            try {
              final buffer = await ui.ImmutableBuffer.fromFilePath(response.file.path);
              return await decode(buffer);
            } catch (e) {
              // 解码错误，清理损坏的缓存
              _log.warning('Failed to decode downloaded image, removing cache: $url', e);
              try {
                await cacheManager.removeFile(url);
              } catch (_) {
                // 忽略清理失败
              }
              throw ImageDecodeException(
                message: 'Failed to decode downloaded image',
                source: response.file.path,
                originalException: e,
              );
            }
          }
        }
        
        throw NetworkImageException(
          message: 'Download stream ended without file',
          url: url,
        );
      },
      shouldRetry: (error) {
        if (error is CancelledException) return false;
        if (error is NetworkImageException) {
          return error.isRetryable && error.isNetworkError;
        }
        return false;
      },
      onRetry: (attempt, error) {
        _log.info('Retrying image download (attempt $attempt): $url');
      },
    );
  }
  
  /// 加载图片（自动选择缓存或网络）
  /// 
  /// [url] 图片 URL
  /// [cacheManager] 缓存管理器
  /// [decode] 图片解码回调
  /// [onProgress] 进度回调（可选）
  /// [onCancel] 取消检查函数（可选）
  /// [onSubscription] 订阅设置回调（可选）
  /// [fallbackToExpiredCache] 网络失败时是否回退到过期缓存
  /// 
  /// 返回解码后的 Codec
  static Future<ui.Codec> loadImage(
    String url,
    CacheManager cacheManager,
    ImageDecoderCallback decode, {
    void Function(int downloaded, int? total)? onProgress,
    bool Function()? onCancel,
    void Function(StreamSubscription?)? onSubscription,
    bool fallbackToExpiredCache = true,
  }) async {
    // 先尝试从缓存加载
    final cachedCodec = await loadImageFromCache(url, cacheManager, decode);
    if (cachedCodec != null) {
      return cachedCodec;
    }
    
    // 从网络加载
    try {
      return await loadImageFromNetwork(
        url,
        cacheManager,
        decode,
        onProgress: onProgress,
        onCancel: onCancel,
        onSubscription: onSubscription,
      );
    } on NetworkImageException catch (e) {
      // 网络错误，尝试回退到过期缓存
      if (fallbackToExpiredCache) {
        try {
          final cachedFile = await cacheManager.getFileFromCache(url);
          if (cachedFile != null) {
            _log.info('Network error, using expired cache: $url');
            // 检查取消
            if (onCancel?.call() ?? false) {
              throw CancelledException('Image loading was cancelled');
            }
            try {
              final buffer = await ui.ImmutableBuffer.fromFilePath(cachedFile.file.path);
              return await decode(buffer);
            } catch (decodeError) {
              _log.warning('Failed to decode expired cache', decodeError);
              throw e;
            }
          }
        } catch (_) {
          // 忽略缓存回退失败
        }
      }
      rethrow;
    }
  }
  
  /// 清理损坏的缓存文件
  /// 
  /// [url] 图片 URL 或缓存键
  /// [cacheManager] 缓存管理器
  static Future<void> removeCorruptedCache(
    String url,
    CacheManager cacheManager,
  ) async {
    try {
      await cacheManager.removeFile(url);
      _log.fine('Removed corrupted cache: $url');
    } catch (e) {
      _log.warning('Failed to remove corrupted cache: $url', e);
    }
  }
}

