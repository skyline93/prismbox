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

  /// 占位符与失败重试共享的总时长上限（2 分钟）
  static const int _retryMaxDurationSeconds = 120;

  /// 渐进式重试间隔（秒）：先短后长，避免频繁请求
  static const List<int> _retryDelays = [2, 2, 5, 5, 10, 10, 15, 15, 20, 20, 30];

  /// 加载缩略图流
  /// 占位符与加载失败分开计数重试，共享 2 分钟总预算，渐进式间隔，直至成功或超时
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

      // 重试预算：首次进入重试（占位符或失败）时记录，两者共享总时长
      DateTime? retryStartTime;
      // 占位符重试：单独计数与渐进间隔
      int placeholderRetryIndex = 0;
      // 失败重试：单独计数与渐进间隔
      int failureRetryIndex = 0;

      // 循环处理，支持占位符刷新与失败自动重试
      while (!isCancelled) {
        try {
          // 直接使用 getFileStream，让它自动处理缓存过期
          final stream = cacheManager.getFileStream(
            url,
            withProgress: true,
            headers: headers,
          );

          bool isPlaceholder = false;

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
                final buffer =
                    await ui.ImmutableBuffer.fromFilePath(response.file.path);
                checkCancelled();
                final codec = await decode(buffer);
                yield codec; // 每次新的 FileInfo 到达时，yield 新的 Codec

                // 检查缓存时间，判断是否是占位符
                final now = DateTime.now();
                final validTill = response.validTill;
                final ageSeconds = validTill.difference(now).inSeconds;

                // 如果缓存时间很短（< 60秒），可能是占位符
                if (ageSeconds > 0 && ageSeconds < 60) {
                  isPlaceholder = true;
                  retryStartTime ??= now;
                  _log.fine(
                    'Detected placeholder (short cache: ${ageSeconds}s), will retry with progressive delay: $url',
                  );
                } else {
                  _log.fine(
                    'Detected actual thumbnail (long cache: ${ageSeconds}s): $url',
                  );
                }
              } catch (e) {
                _log.warning('Failed to decode image: $url', e);
                // 解码失败抛出，由外层 catch 按失败重试
                rethrow;
              }
            }
          }

          // 占位符路径：按渐进式间隔等待后清除缓存并重新请求
          if (isPlaceholder && retryStartTime != null) {
            final elapsedSeconds =
                DateTime.now().difference(retryStartTime).inSeconds;
            final remainingBudget =
                _retryMaxDurationSeconds - elapsedSeconds;

            if (remainingBudget <= 0) {
              _log.fine(
                'Placeholder retry budget exhausted (${elapsedSeconds}s), stopping: $url',
              );
              break;
            }

            final nextDelayIndex = placeholderRetryIndex.clamp(
              0,
              _retryDelays.length - 1,
            );
            final nextDelaySeconds = _retryDelays[nextDelayIndex];
            final delaySeconds = nextDelaySeconds.clamp(1, remainingBudget);

            _log.fine(
              'Placeholder: waiting ${delaySeconds}s before next retry (#$placeholderRetryIndex, ${remainingBudget}s budget left): $url',
            );
            await Future.delayed(Duration(seconds: delaySeconds));
            placeholderRetryIndex += 1;

            if (!isCancelled) {
              _log.fine(
                'Removing placeholder cache to trigger re-download: $url',
              );
              try {
                await cacheManager.removeFile(url);
              } catch (e) {
                _log.warning('Failed to remove cache: $url', e);
              }
              continue;
            }
          }

          // 本轮成功拿到非占位符，或未检测到占位符，退出循环
          break;
        } on CancelledException {
          rethrow;
        } catch (e, stackTrace) {
          // 失败重试：网络/解码等异常，单独计数与渐进间隔，共享总时长
          retryStartTime ??= DateTime.now();
          final elapsedSeconds =
              DateTime.now().difference(retryStartTime).inSeconds;
          final remainingBudget = _retryMaxDurationSeconds - elapsedSeconds;

          if (remainingBudget <= 0) {
            _log.severe(
              'Failure retry budget exhausted (${elapsedSeconds}s), giving up: $url',
              e,
              stackTrace,
            );
            rethrow;
          }

          final nextDelayIndex =
              failureRetryIndex.clamp(0, _retryDelays.length - 1);
          final nextDelaySeconds = _retryDelays[nextDelayIndex];
          final delaySeconds = nextDelaySeconds.clamp(1, remainingBudget);

          _log.warning(
            'Thumbnail load failed (retry #$failureRetryIndex in ${delaySeconds}s, ${remainingBudget}s budget left): $url',
            e,
          );
          await Future.delayed(Duration(seconds: delaySeconds));
          failureRetryIndex += 1;

          if (!isCancelled) {
            try {
              await cacheManager.removeFile(url);
            } catch (_) {}
            continue;
          }
          rethrow;
        }
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

    // 仅使用档位参数，与 Immich 对齐；key.size 保留用于布局/解码，不参与 URL
    const sizeTier = 'thumbnail';
    return '$baseUrl/api/v1/assets/${key.assetId}/thumbnail?size=$sizeTier';
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
