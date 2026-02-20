// lib/features/video_playback/playback_backend_factory.dart

import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/features/local_sync/services/asset_entity_loader.dart';
import 'package:prismbox/features/media_loading/video_provider.dart';
import 'package:prismbox/features/video_playback/native_playback_controller.dart';
import 'package:prismbox/features/video_playback/network_playback_controller.dart';
import 'package:prismbox/features/video_playback/viewer_playback_controller.dart';

/// 根据资产与上下文选择播放引擎并创建 ViewerPlaybackController。
class PlaybackBackendFactory {
  /// 创建播放控制器：优先本地文件（Native），否则远程 URL+headers（Network）。
  static Future<ViewerPlaybackController?> create({
    required BaseAsset asset,
    required String assetId,
    String? serverUrl,
    AssetEntityLoader? assetEntityLoader,
    String? videoIdOverride,
  }) async {
    final localPath = await VideoProvider.getLocalFilePath(
      asset,
      assetEntityLoader: assetEntityLoader,
      videoIdOverride: videoIdOverride,
    );
    if (localPath != null) {
      return NativePlaybackController.fromFile(localPath);
    }

    final remote = await VideoProvider.getRemoteUrlAndHeaders(
      asset,
      serverUrl: serverUrl,
      videoIdOverride: videoIdOverride,
    );
    if (remote != null) {
      return NetworkPlaybackController.fromNetwork(
        url: remote.url,
        headers: remote.headers,
      );
    }

    return null;
  }
}
