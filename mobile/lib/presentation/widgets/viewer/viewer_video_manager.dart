import 'package:native_video_player/native_video_player.dart';
import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/features/media_loading/video_provider.dart';
import 'package:prismbox/features/local_sync/services/asset_entity_loader.dart';

/// 视频播放器管理器
///
/// 负责视频源缓存和可见页面范围管理。
/// 注意：不再缓存 controller，每个 ViewerVideoPage Widget 独立管理自己的 controller（对齐 Immich 架构）。
class ViewerVideoManager {
  /// 视频源缓存（按 assetId）
  final Map<String, Future<VideoSource?>> _videoSources = {};

  /// 当前播放的视频 assetId（用于兜底，主要使用 Provider）
  String? _currentVideoAssetId;

  /// 可见页面范围（当前页 ± 1，即最多保留 3 页）
  static const int _visiblePageRange = 1;

  /// 获取视频源（用于创建控制器）
  ///
  /// [asset] 资产对象
  /// [assetId] 资产 ID
  /// [serverUrl] 服务器 URL（可选）
  /// [assetEntityLoader] AssetEntity 加载器（可选）
  ///
  /// 返回 Future&lt;VideoSource?&gt;，如果无法获取则返回 null
  Future<VideoSource?> getVideoSource(
    BaseAsset asset,
    String assetId, {
    String? serverUrl,
    AssetEntityLoader? assetEntityLoader,
  }) async {
    // 如果已有缓存的视频源，直接返回
    if (_videoSources.containsKey(assetId)) {
      return await _videoSources[assetId];
    }

    // 获取视频源并缓存
    final videoSourceFuture = VideoProvider.getVideoSource(
      asset,
      serverUrl: serverUrl,
      assetEntityLoader: assetEntityLoader,
    );
    _videoSources[assetId] = videoSourceFuture;

    return await videoSourceFuture;
  }


  /// 更新可见页面索引
  ///
  /// 注意：不再释放 controller，因为每个 Widget 独立管理自己的 controller
  ///
  /// [visibleIndices] 可见页面索引集合
  void updateVisibleIndices(Set<int> visibleIndices) {
    // 更新可见页面集合（目前仅用于记录，将来可用于优化）
  }

  /// 计算可见页面索引范围
  ///
  /// [currentIndex] 当前页面索引
  /// [totalCount] 总页面数
  ///
  /// 返回可见页面索引集合
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
  ///
  /// [assetId] 资产 ID
  void setCurrentVideoAssetId(String? assetId) {
    _currentVideoAssetId = assetId;
  }

  /// 获取当前视频 assetId
  ///
  /// 返回 String?，如果没有当前视频则返回 null
  String? getCurrentVideoAssetId() {
    return _currentVideoAssetId;
  }

}
