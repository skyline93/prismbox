// lib/features/media_loading/requests/remote_image_request.dart

import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/features/media_loading/exceptions/network_image_exception.dart';
import 'package:prismbox/features/media_loading/exceptions/image_decode_exception.dart';
import 'package:prismbox/features/media_loading/requests/image_request.dart';
import 'package:prismbox/features/media_loading/utils/retry_helper.dart';

/// 远程图片请求
/// 用于加载远程资源的图片，支持流式下载和进度报告
class RemoteImageRequest extends ImageRequest {
  final Logger _log = Logger('RemoteImageRequest');
  
  /// 请求的 URL
  final String url;
  
  /// 缓存管理器
  final CacheManager cacheManager;
  
  /// 进度事件流控制器（可选）
  final StreamController<ImageChunkEvent>? chunkEvents;
  
  /// 流订阅（用于取消）
  StreamSubscription? _subscription;

  RemoteImageRequest({
    required this.url,
    required this.cacheManager,
    this.chunkEvents,
  });

  @override
  void onCancel() {
    _subscription?.cancel();
    _subscription = null;
    chunkEvents?.close();
  }

  @override
  Future<ui.Codec> load(ImageDecoderCallback decode) async {
    checkCancelled();
    
    // 检查磁盘缓存
    final cachedFile = await cacheManager.getFileFromCache(url);
    if (cachedFile != null) {
      // 检查缓存是否已过期
      final now = DateTime.now();
      if (cachedFile.validTill.isBefore(now)) {
        _log.fine('Cached image expired, will re-download: $url (expired at ${cachedFile.validTill})');
        // 删除过期缓存，返回 null 触发重新下载
        try {
          await cacheManager.removeFile(url);
        } catch (_) {
          // 忽略删除失败
        }
      } else {
        checkCancelled();
        _log.fine('Image cache hit: $url (valid till ${cachedFile.validTill})');
        try {
          final buffer = await ui.ImmutableBuffer.fromFilePath(cachedFile.file.path);
          checkCancelled();
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
    }

    // 从网络下载（带重试）
    return await RetryHelper.executeWithRetry<ui.Codec>(
      operation: () async {
        checkCancelled();
        _log.fine('Downloading image: $url');
        
        final stream = cacheManager.getFileStream(
          url,
          withProgress: true,
        );
        
        try {
          _subscription = stream.listen(
            (response) {
              if (response is DownloadProgress) {
                checkCancelled();
                chunkEvents?.add(ImageChunkEvent(
                  cumulativeBytesLoaded: response.downloaded,
                  expectedTotalBytes: response.totalSize,
                ));
              } else if (response is FileInfo) {
                // 文件下载完成，在 decode 中处理
              }
            },
            onError: (error) {
              chunkEvents?.close();
              throw NetworkImageException(
                message: 'Failed to download image: $error',
                url: url,
              );
            },
          );
          
          await for (final response in stream) {
            checkCancelled();
            if (response is FileInfo) {
              try {
                final buffer = await ui.ImmutableBuffer.fromFilePath(response.file.path);
                checkCancelled();
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
        } finally {
          _subscription?.cancel();
          _subscription = null;
        }
      },
      shouldRetry: (error) {
        if (error is NetworkImageException) {
          return error.isRetryable && error.isNetworkError;
        }
        return false;
      },
      onRetry: (attempt, error) {
        _log.info('Retrying image download (attempt $attempt): $url');
      },
    ).catchError((error) {
      // 如果是网络错误，尝试回退到缓存（即使过期）
      if (error is NetworkImageException) {
        return _fallbackToCache(decode, error);
      }
      throw error;
    });
  }
  
  /// 回退到缓存（即使过期）
  Future<ui.Codec> _fallbackToCache(
    ImageDecoderCallback decode,
    NetworkImageException originalError,
  ) async {
    try {
      final cachedFile = await cacheManager.getFileFromCache(url);
      if (cachedFile != null) {
        _log.info('Network error, using expired cache: $url');
        checkCancelled();
        try {
          final buffer = await ui.ImmutableBuffer.fromFilePath(cachedFile.file.path);
          checkCancelled();
          return await decode(buffer);
        } catch (decodeError) {
          _log.warning('Failed to decode expired cache', decodeError);
          throw originalError;
        }
      }
    } catch (e) {
      // 忽略缓存回退失败
    }
    throw originalError;
  }
}

