// lib/features/media_loading/video_provider.dart

import 'dart:io';

import 'package:logging/logging.dart';
import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/domain/entities/local_asset.dart';
import 'package:prismbox/domain/entities/remote_asset.dart';
import 'package:prismbox/features/local_sync/services/asset_entity_loader.dart';
import 'package:prismbox/infrastructure/api/api_service.dart';

final Logger _log = Logger('VideoProvider');

/// 视频源类型
enum VideoSourceType {
  /// 本地文件路径
  file,

  /// 网络 URL
  network,
}

/// 视频源
class VideoSource {
  /// 源类型
  final VideoSourceType type;

  /// 文件路径或 URL
  final String source;

  const VideoSource({required this.type, required this.source});
}

/// 视频提供者
///
/// 负责根据 BaseAsset 获取视频源（本地文件路径或远程 URL）
/// 遵循性能规范：
/// - 异步加载，不阻塞主线程
/// - 支持本地和远程视频
class VideoProvider {
  /// 获取视频源
  ///
  /// [asset] 资产对象
  /// [serverUrl] 服务器 URL（可选，用于远程视频）
  /// [assetEntityLoader] AssetEntity 加载器（可选，用于延迟加载本地视频）
  ///
  /// 返回 VideoSource，如果无法获取则返回 null
  static Future<VideoSource?> getVideoSource(
    BaseAsset asset, {
    String? serverUrl,
    AssetEntityLoader? assetEntityLoader,
  }) async {
    try {
      // 本地视频
      if (asset is LocalAsset) {
        return await _getLocalVideoSource(asset, assetEntityLoader);
      }

      // 远程视频
      if (asset is RemoteAsset) {
        return _getRemoteVideoSource(asset, serverUrl);
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
          return _getRemoteVideoSource(asset, serverUrl);
        }
      }

      // 仅远程资产
      if (asset.storage == AssetState.remote && asset.remoteId != null) {
        return _getRemoteVideoSource(asset, serverUrl);
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

  /// 获取本地视频源
  static Future<VideoSource?> _getLocalVideoSource(
    LocalAsset asset,
    AssetEntityLoader? assetEntityLoader,
  ) async {
    try {
      // 如果已有 assetEntity，直接使用
      if (asset.assetEntity != null) {
        final file = await asset.assetEntity!.file;
        if (file != null) {
          final filePath = file.path;
          if (await File(filePath).exists()) {
            return VideoSource(type: VideoSourceType.file, source: filePath);
          }
        }
      }

      // 如果提供了 assetEntityLoader，尝试异步加载
      if (assetEntityLoader != null) {
        final entity = await assetEntityLoader.loadAsync(asset);
        if (entity != null) {
          final file = await entity.file;
          if (file != null) {
            final filePath = file.path;
            if (await File(filePath).exists()) {
              return VideoSource(type: VideoSourceType.file, source: filePath);
            }
          }
        }
      }

      _log.warning('Local video file not found for asset: ${asset.id}');
      return null;
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
  static VideoSource? _getRemoteVideoSource(
    BaseAsset asset,
    String? serverUrl,
  ) {
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

      // 构建视频下载 URL
      // 使用后端路由：/api/v1/media/:uuid/download/original
      final videoUrl =
          '$baseUrl/api/v1/media/${asset.remoteId ?? asset.id}/download/original';

      return VideoSource(type: VideoSourceType.network, source: videoUrl);
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
