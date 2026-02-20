// lib/features/media_loading/video_provider.dart

import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:native_video_player/native_video_player.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/domain/entities/local_asset.dart';
import 'package:prismbox/domain/entities/remote_asset.dart';
import 'package:prismbox/features/local_sync/services/asset_entity_loader.dart';
import 'package:prismbox/infrastructure/api/api_service.dart';

final Logger _log = Logger('VideoProvider');

/// 视频提供者
///
/// 负责根据 BaseAsset 获取视频源（本地文件路径或远程 URL）。
/// 使用 native_video_player 的 VideoSource 类型，支持 HDR 视频格式。
/// 遵循性能规范：
/// - 异步加载，不阻塞主线程
/// - 支持本地和远程视频
/// - 支持自定义请求头（用于远程视频认证）
class VideoProvider {
  /// 获取视频源
  ///
  /// [asset] 资产对象
  /// [serverUrl] 服务器 URL（可选，用于远程视频）
  /// [assetEntityLoader] AssetEntity 加载器（可选，用于延迟加载本地视频）
  /// [videoIdOverride] 视频资产 ID 覆盖（可选；用于 Live Photo 时传 livePhotoVideoId，仅用该 ID 拼远程 URL）
  ///
  /// 返回 native_video_player.VideoSource，如果无法获取则返回 null
  static Future<VideoSource?> getVideoSource(
    BaseAsset asset, {
    String? serverUrl,
    AssetEntityLoader? assetEntityLoader,
    String? videoIdOverride,
  }) async {
    try {
      // 本地 Live Photo motion：asset 为 LocalAsset 且传入了 videoIdOverride 时，从 AssetEntity 取 motion 文件
      if (videoIdOverride != null && asset is LocalAsset) {
        final motionSource = await _getLocalMotionVideoSource(
          asset,
          assetEntityLoader,
        );
        if (motionSource != null) return motionSource;
        // 取不到本地 motion 时 fallback 到远程（若后续支持远程 Live Photo）
        return await _getRemoteLivePhotoVideoSource(
          asset,
          serverUrl,
          videoIdOverride,
        );
      }

      // Live Photo 关联视频（仅远程）：优先预览 URL，不可用时回退到原片
      if (videoIdOverride != null) {
        return await _getRemoteLivePhotoVideoSource(
          asset,
          serverUrl,
          videoIdOverride,
        );
      }

      // 本地视频
      if (asset is LocalAsset) {
        return await _getLocalVideoSource(asset, assetEntityLoader);
      }

      // 远程视频
      if (asset is RemoteAsset) {
        return await _getRemoteVideoSource(asset, serverUrl, null);
      }

      // 合并资产（本地和远程都存在）
      if (asset.storage == AssetState.merged) {
        // 优先使用本地视频
        if (asset is LocalAsset) {
          final localSource = await _getLocalVideoSource(
            asset,
            assetEntityLoader,
          );
          if (localSource != null) {
            return localSource;
          }
        }

        // 如果本地不可用，使用远程视频
        if (asset is RemoteAsset || asset.remoteId != null) {
          return await _getRemoteVideoSource(asset, serverUrl, null);
        }
      }

      // 仅远程资产
      if (asset.storage == AssetState.remote && asset.remoteId != null) {
        return await _getRemoteVideoSource(asset, serverUrl, null);
      }

      _log.warning('Unable to determine video source for asset: ${asset.id}');
      return null;
    } catch (e, stackTrace) {
      _log.severe(
        'Failed to get video source for asset: ${asset.id}',
        e,
        stackTrace,
      );
      return null;
    }
  }

  /// 获取本地 Live Photo motion 视频源
  ///
  /// 当 asset 为 LocalAsset 且为 Live Photo 时，通过 AssetEntity 的 originFileWithSubtype / loadFile(withSubtype: true) 取 motion 文件
  static Future<VideoSource?> _getLocalMotionVideoSource(
    LocalAsset asset,
    AssetEntityLoader? assetEntityLoader,
  ) async {
    try {
      AssetEntity? entity = asset.assetEntity;
      if (entity == null && assetEntityLoader != null) {
        entity = await assetEntityLoader.loadAsync(asset);
      }
      if (entity == null) {
        _log.fine('Local Live Photo: no AssetEntity for asset ${asset.id}');
        return null;
      }
      // 取 motion 子类型文件：iOS originFileWithSubtype / Android loadFile(withSubtype: true)。
      // 注意：photo_manager 的 isLivePhoto 仅 iOS/macOS 有效；Android Motion Photo 形态因厂商而异，若插件未暴露 motion 文件则此处可能为 null。
      File? file = await entity.originFileWithSubtype;
      file ??= await entity.loadFile(withSubtype: true);
      if (file == null) {
        _log.fine('Local Live Photo: no motion file for asset ${asset.id}');
        return null;
      }
      final path = file.path;
      if (path.isEmpty) return null;
      if (!await File(path).exists()) {
        _log.warning('Local Live Photo motion file does not exist: $path');
        return null;
      }
      return await VideoSource.init(path: path, type: VideoSourceType.file);
    } catch (e, stackTrace) {
      _log.warning(
        'Failed to get local motion video source for asset: ${asset.id}',
        e,
        stackTrace,
      );
      return null;
    }
  }

  /// 获取本地视频源
  static Future<VideoSource?> _getLocalVideoSource(
    LocalAsset asset,
    AssetEntityLoader? assetEntityLoader,
  ) async {
    try {
      String? filePath;

      // 如果已有 assetEntity，直接使用
      if (asset.assetEntity != null) {
        final file = await asset.assetEntity!.file;
        if (file != null) {
          filePath = file.path;
        }
      }

      // 如果提供了 assetEntityLoader，尝试异步加载
      if (filePath == null && assetEntityLoader != null) {
        final entity = await assetEntityLoader.loadAsync(asset);
        if (entity != null) {
          final file = await entity.file;
          if (file != null) {
            filePath = file.path;
          }
        }
      }

      if (filePath == null) {
        _log.warning('Local video file not found for asset: ${asset.id}');
        return null;
      }

      if (!await File(filePath).exists()) {
        _log.warning('Local video file does not exist: $filePath');
        return null;
      }

      // 使用 native_video_player 的 VideoSource.init 创建本地视频源
      return await VideoSource.init(path: filePath, type: VideoSourceType.file);
    } catch (e, stackTrace) {
      _log.warning(
        'Failed to get local video source for asset: ${asset.id}',
        e,
        stackTrace,
      );
      return null;
    }
  }

  /// 远程 Live Photo 视频（仅用于预览播放）：优先 preview，不可用时回退 original。
  /// 若需下载/导出原片，应使用 .../download/original（同一 mediaId）。
  static Future<VideoSource?> _getRemoteLivePhotoVideoSource(
    BaseAsset asset,
    String? serverUrl,
    String mediaId,
  ) async {
    final baseUrl = await _resolveBaseUrl(serverUrl);
    if (baseUrl.isEmpty) {
      _log.warning('No server URL available for remote Live video: ${asset.id}');
      return null;
    }
    final headers = await ApiService.getRequestHeaders();
    final previewUrl = '$baseUrl/api/v1/media/$mediaId/download/preview';
    final originalUrl = '$baseUrl/api/v1/media/$mediaId/download/original';
    try {
      final response = await http.head(
        Uri.parse(previewUrl),
        headers: Map<String, String>.from(headers),
      ).timeout(const Duration(seconds: 10));
      final usePreview = response.statusCode == 200;
      final videoUrl = usePreview ? previewUrl : originalUrl;
      _log.fine(
        'Remote Live video: using ${usePreview ? "preview" : "original"} '
        'statusCode=${response.statusCode}',
      );
      return await VideoSource.init(
        path: videoUrl,
        type: VideoSourceType.network,
        headers: headers,
      );
    } catch (e, stackTrace) {
      _log.warning(
        'Preview check failed, using original: ${asset.id}',
        e,
        stackTrace,
      );
      return await _getRemoteVideoSource(
        asset,
        serverUrl,
        mediaId,
      );
    }
  }

  static Future<String> _resolveBaseUrl(String? serverUrl) async {
    if (serverUrl != null && serverUrl.isNotEmpty) return serverUrl;
    try {
      return ApiService().endpoint ?? '';
    } catch (e) {
      _log.warning('Failed to get endpoint from ApiService', e);
      return '';
    }
  }

  /// 获取远程视频源
  ///
  /// [videoIdOverride] 若不为 null（如 Live Photo 的 livePhotoVideoId），用其替代 asset.remoteId/id 拼 URL
  static Future<VideoSource?> _getRemoteVideoSource(
    BaseAsset asset,
    String? serverUrl, [
    String? videoIdOverride,
  ]) async {
    try {
      final baseUrl = await _resolveBaseUrl(serverUrl);
      if (baseUrl.isEmpty) {
        _log.warning('No server URL available for remote video: ${asset.id}');
        return null;
      }

      final mediaId = videoIdOverride ?? asset.remoteId ?? asset.id;
      final videoUrl =
          '$baseUrl/api/v1/media/$mediaId/download/original';

      final headers = await ApiService.getRequestHeaders();

      return await VideoSource.init(
        path: videoUrl,
        type: VideoSourceType.network,
        headers: headers,
      );
    } catch (e, stackTrace) {
      _log.severe(
        'Failed to get remote video source for asset: ${asset.id}',
        e,
        stackTrace,
      );
      return null;
    }
  }

  /// 解析本地可播放文件路径（供 PlaybackBackendFactory 使用）
  ///
  /// 返回本地文件路径；若无本地文件则返回 null（工厂将尝试远程）。
  static Future<String?> getLocalFilePath(
    BaseAsset asset, {
    AssetEntityLoader? assetEntityLoader,
    String? videoIdOverride,
  }) async {
    try {
      if (videoIdOverride != null && asset is LocalAsset) {
        final path = await _getLocalMotionFilePath(asset, assetEntityLoader);
        if (path != null) return path;
      }
      if (asset is LocalAsset) {
        return await _getLocalVideoFilePath(asset, assetEntityLoader);
      }
      if (asset.storage == AssetState.merged && asset is LocalAsset) {
        final path = await _getLocalVideoFilePath(asset, assetEntityLoader);
        if (path != null) return path;
      }
      return null;
    } catch (e, stackTrace) {
      _log.warning(
        'Failed to get local file path for asset: ${asset.id}',
        e,
        stackTrace,
      );
      return null;
    }
  }

  static Future<String?> _getLocalMotionFilePath(
    LocalAsset asset,
    AssetEntityLoader? assetEntityLoader,
  ) async {
    AssetEntity? entity = asset.assetEntity;
    if (entity == null && assetEntityLoader != null) {
      entity = await assetEntityLoader.loadAsync(asset);
    }
    if (entity == null) return null;
    File? file = await entity.originFileWithSubtype;
    file ??= await entity.loadFile(withSubtype: true);
    if (file == null) return null;
    final path = file.path;
    if (path.isEmpty) return null;
    if (!await File(path).exists()) return null;
    return path;
  }

  static Future<String?> _getLocalVideoFilePath(
    LocalAsset asset,
    AssetEntityLoader? assetEntityLoader,
  ) async {
    String? filePath;
    if (asset.assetEntity != null) {
      final file = await asset.assetEntity!.file;
      if (file != null) filePath = file.path;
    }
    if (filePath == null && assetEntityLoader != null) {
      final entity = await assetEntityLoader.loadAsync(asset);
      if (entity != null) {
        final file = await entity.file;
        if (file != null) filePath = file.path;
      }
    }
    if (filePath == null) return null;
    if (!await File(filePath).exists()) return null;
    return filePath;
  }

  /// 解析远程视频 URL 与请求头（供 PlaybackBackendFactory 使用）
  ///
  /// 若无远程源或 serverUrl 不可用则返回 null。
  static Future<({String url, Map<String, String> headers})?> getRemoteUrlAndHeaders(
    BaseAsset asset, {
    String? serverUrl,
    String? videoIdOverride,
  }) async {
    try {
      if (asset.storage == AssetState.local && videoIdOverride == null) return null;
      final baseUrl = await _resolveBaseUrl(serverUrl);
      if (baseUrl.isEmpty) return null;
      final headers = await ApiService.getRequestHeaders();
      final mediaId = videoIdOverride ?? asset.remoteId ?? asset.id;

      if (videoIdOverride != null) {
        final previewUrl = '$baseUrl/api/v1/media/$mediaId/download/preview';
        final originalUrl = '$baseUrl/api/v1/media/$mediaId/download/original';
        try {
          final response = await http.head(
            Uri.parse(previewUrl),
            headers: Map<String, String>.from(headers),
          ).timeout(const Duration(seconds: 10));
          final url = response.statusCode == 200 ? previewUrl : originalUrl;
          return (url: url, headers: headers);
        } catch (_) {
          return (url: originalUrl, headers: headers);
        }
      }

      final url = '$baseUrl/api/v1/media/$mediaId/download/original';
      return (url: url, headers: headers);
    } catch (e, stackTrace) {
      _log.warning(
        'Failed to get remote url for asset: ${asset.id}',
        e,
        stackTrace,
      );
      return null;
    }
  }
}
