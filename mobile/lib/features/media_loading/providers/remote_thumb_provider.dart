// lib/features/media_loading/providers/remote_thumb_provider.dart

import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/core/cache/thumbnail_cache_manager.dart';
import 'package:prismbox/features/media_loading/mixins/cancellable_image_provider_mixin.dart';
import 'package:prismbox/features/media_loading/providers/remote_full_provider.dart';
import 'package:prismbox/infrastructure/api/api_service.dart';

/// 远程缩略图提供者
/// 用于加载远程资源的缩略图
class RemoteThumbProvider extends ImageProvider<RemoteThumbProvider>
    with CancellableImageProviderMixin {
  /// 资产 ID
  final String assetId;

  /// 目标尺寸
  final Size size;

  /// 服务器 URL（可选）
  final String? serverUrl;

  /// 缓存管理器（可选）
  final CacheManager? cacheManager;

  /// API 服务（用于构建 URL）
  final ApiService? apiService;

  final Logger _log = Logger('RemoteThumbProvider');

  RemoteThumbProvider({
    required this.assetId,
    required this.size,
    this.serverUrl,
    this.cacheManager,
    this.apiService,
  });

  @override
  Future<RemoteThumbProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(this);
  }

  @override
  ImageStreamCompleter loadImage(
    RemoteThumbProvider key,
    ImageDecoderCallback decode,
  ) {
    // 重置取消状态
    reset();

    final chunkEvents = StreamController<ImageChunkEvent>();
    return MultiImageStreamCompleter(
      codec: _loadThumbnailStream(key, decode, chunkEvents),
      scale: 1.0,
      chunkEvents: chunkEvents.stream,
    );
  }

  /// 加载缩略图流
  /// 使用 Stream<ui.Codec> 支持自动更新：当缓存过期时，getFileStream 会自动重新下载
  Stream<ui.Codec> _loadThumbnailStream(
    RemoteThumbProvider key,
    ImageDecoderCallback decode,
    StreamController<ImageChunkEvent> chunkEvents,
  ) async* {
    checkCancelled();

    try {
      // 构建 URL
      final url = _buildUrl(key);

      // 使用缓存管理器加载
      final cacheManager = key.cacheManager ?? ThumbnailImageCacheManager();

      // 获取认证头
      final headers = await ApiService.getRequestHeaders();

      // 循环处理，支持占位符自动刷新
      while (!isCancelled) {
        // 直接使用 getFileStream，让它自动处理缓存过期
        // 当缓存过期时（占位符30秒后），会自动重新下载
        final stream = cacheManager.getFileStream(
          url,
          withProgress: true,
          headers: headers,
        );

        bool isPlaceholder = false;
        int? cacheAgeSeconds;

        await for (final response in stream) {
          checkCancelled();

          if (response is DownloadProgress) {
            chunkEvents.add(
              ImageChunkEvent(
                cumulativeBytesLoaded: response.downloaded,
                expectedTotalBytes: response.totalSize,
              ),
            );
          } else if (response is FileInfo) {
            try {
              final buffer = await ui.ImmutableBuffer.fromFilePath(response.file.path);
              checkCancelled();
              final codec = await decode(buffer);
              yield codec; // 每次新的 FileInfo 到达时，yield 新的 Codec

              // 检查缓存时间，判断是否是占位符
              final now = DateTime.now();
              final validTill = response.validTill;
              final ageSeconds = validTill.difference(now).inSeconds;
              cacheAgeSeconds = ageSeconds;

              // 如果缓存时间很短（< 60秒），可能是占位符
              if (ageSeconds > 0 && ageSeconds < 60) {
                isPlaceholder = true;
                _log.fine(
                  'Detected placeholder (short cache: ${ageSeconds}s), will retry after cache expires: $url',
                );
              } else {
                _log.fine('Detected actual thumbnail (long cache: ${ageSeconds}s): $url');
              }
            } catch (e) {
              _log.warning('Failed to decode image: $url', e);
              // 继续处理下一个响应
            }
          }
        }

        // 如果检测到占位符，等待缓存过期后重新请求
        final ageSeconds = cacheAgeSeconds;
        if (isPlaceholder && ageSeconds != null && ageSeconds > 0) {
          _log.fine('Waiting for placeholder cache to expire (${ageSeconds}s): $url');
          await Future.delayed(Duration(seconds: ageSeconds + 1));
          
          if (!isCancelled) {
            _log.fine('Placeholder cache expired, removing to trigger re-download: $url');
            // 清除缓存，触发重新下载
            try {
              await cacheManager.removeFile(url);
            } catch (e) {
              _log.warning('Failed to remove expired cache: $url', e);
            }
            // 继续循环，重新获取流
            continue;
          }
        }

        // 如果不是占位符，或者没有成功加载，退出循环
        break;
      }
    } on CancelledException {
      _log.fine('Thumbnail loading cancelled: ${_buildUrl(key)}');
      rethrow;
    } catch (e, stackTrace) {
      _log.severe('Failed to load remote thumbnail stream', e, stackTrace);
      rethrow;
    }
  }

  /// 构建缩略图 URL
  String _buildUrl(RemoteThumbProvider key) {
    // 优先使用传入的 serverUrl，否则从 ApiService 获取
    String baseUrl = key.serverUrl ?? '';
    if (baseUrl.isEmpty) {
      // 如果 serverUrl 为空，尝试从 ApiService 获取 endpoint
      try {
        final apiService = key.apiService ?? ApiService();
        baseUrl = apiService.endpoint ?? '';
      } catch (e) {
        _log.warning('Failed to get endpoint from ApiService', e);
        baseUrl = '';
      }
    }

    // 如果仍然为空，记录警告
    if (baseUrl.isEmpty) {
      _log.warning(
        'No server URL available for remote thumbnail: ${key.assetId}',
      );
    }

    final size = '${key.size.width.toInt()}x${key.size.height.toInt()}';
    // 使用后端路由：/api/v1/assets/:uuid/thumbnail
    return '$baseUrl/api/v1/assets/${key.assetId}/thumbnail?size=$size';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RemoteThumbProvider &&
          runtimeType == other.runtimeType &&
          assetId == other.assetId &&
          size == other.size &&
          serverUrl == other.serverUrl;

  @override
  int get hashCode => Object.hash(assetId, size, serverUrl);
}
