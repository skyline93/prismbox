// lib/features/media_loading/video_provider.dart

import 'dart:io';

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
        return await _getRemoteVideoSource(asset, serverUrl, videoIdOverride);
      }

      // Live Photo 关联视频（仅远程）：用 videoIdOverride 拼远程 URL
      if (videoIdOverride != null) {
        return await _getRemoteVideoSource(asset, serverUrl, videoIdOverride);
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

  /// 获取远程视频源
  ///
  /// [videoIdOverride] 若不为 null（如 Live Photo 的 livePhotoVideoId），用其替代 asset.remoteId/id 拼 URL
  static Future<VideoSource?> _getRemoteVideoSource(
    BaseAsset asset,
    String? serverUrl, [
    String? videoIdOverride,
  ]) async {
    try {
      // 获取服务器 URL
      String baseUrl = serverUrl ?? '';
      if (baseUrl.isEmpty) {
        try {
          final apiService = ApiService();
          baseUrl = apiService.endpoint ?? '';
        } catch (e) {
          _log.warning('Failed to get endpoint from ApiService', e);
        }
      }

      if (baseUrl.isEmpty) {
        _log.warning('No server URL available for remote video: ${asset.id}');
        return null;
      }

      // 构建视频下载 URL；Live Photo 时使用 videoIdOverride（livePhotoVideoId）
      final mediaId = videoIdOverride ?? asset.remoteId ?? asset.id;
      final videoUrl =
          '$baseUrl/api/v1/media/$mediaId/download/original';

      // 获取请求头（用于认证）
      final headers = await ApiService.getRequestHeaders();

      // 使用 native_video_player 的 VideoSource.init 创建远程视频源
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
}
