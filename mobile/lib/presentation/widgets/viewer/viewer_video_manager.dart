import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/features/local_sync/services/asset_entity_loader.dart';
import 'package:prismbox/features/video_playback/playback_backend_factory.dart';
import 'package:prismbox/features/video_playback/viewer_playback_controller.dart';

/// 视频播放器管理器
///
/// 负责播放控制器缓存和可见页面范围管理。
/// 通过 PlaybackBackendFactory 按源类型（本地/远程）选择引擎并返回 ViewerPlaybackController。
class ViewerVideoManager {
  /// 播放控制器缓存（按 assetId）
  final Map<String, Future<ViewerPlaybackController?>> _controllers = {};

  /// 当前播放的视频 assetId（用于兜底，主要使用 Provider）
  String? _currentVideoAssetId;

  /// 可见页面范围（当前页 ± 1，即最多保留 3 页）
  static const int _visiblePageRange = 1;

  /// 获取播放控制器
  ///
  /// [asset] 资产对象
  /// [assetId] 资产 ID
  /// [serverUrl] 服务器 URL（可选）
  /// [assetEntityLoader] AssetEntity 加载器（可选）
  /// [videoIdOverride] 视频 ID 覆盖（可选；Live Photo 时传 livePhotoVideoId）
  ///
  /// 返回 Future&lt;ViewerPlaybackController?&gt;，如果无法获取则返回 null
  Future<ViewerPlaybackController?> getPlaybackController(
    BaseAsset asset,
    String assetId, {
    String? serverUrl,
    AssetEntityLoader? assetEntityLoader,
    String? videoIdOverride,
  }) async {
    final cacheKey =
        videoIdOverride != null ? 'live_$videoIdOverride' : assetId;
    if (_controllers.containsKey(cacheKey)) {
      return await _controllers[cacheKey];
    }

    final future = PlaybackBackendFactory.create(
      asset: asset,
      assetId: assetId,
      serverUrl: serverUrl,
      assetEntityLoader: assetEntityLoader,
      videoIdOverride: videoIdOverride,
    );
    _controllers[cacheKey] = future;

    return await future;
  }

  /// 移除已缓存的播放控制器（如 Live Photo 播完切回照片后，controller 会被 dispose，需清缓存以便再次长按时创建新 controller）
  ///
  /// [assetId] 资产 ID（与 getPlaybackController 的 assetId 对应）
  /// [videoIdOverride] 视频 ID 覆盖（Live Photo 时传 livePhotoVideoId）
  void removeCachedController({String? assetId, String? videoIdOverride}) {
    final cacheKey =
        videoIdOverride != null ? 'live_$videoIdOverride' : assetId;
    if (cacheKey != null) {
      _controllers.remove(cacheKey);
    }
  }

  /// 更新可见页面索引
  void updateVisibleIndices(Set<int> visibleIndices) {}

  /// 计算可见页面索引范围
  Set<int> calculateVisibleIndices(int currentIndex, int totalCount) {
    final indices = <int>{};
    for (int i = -_visiblePageRange; i <= _visiblePageRange; i++) {
      final index = currentIndex + i;
      if (index >= 0 && index < totalCount) {
        indices.add(index);
      }
    }
    return indices;
  }

  /// 设置当前视频 assetId
  void setCurrentVideoAssetId(String? assetId) {
    _currentVideoAssetId = assetId;
  }

  /// 获取当前视频 assetId
  String? getCurrentVideoAssetId() => _currentVideoAssetId;
}
