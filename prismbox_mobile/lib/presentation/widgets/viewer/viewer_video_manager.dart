import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/features/media_loading/video_provider.dart';
import 'package:prismbox/features/local_sync/services/asset_entity_loader.dart';

/// 视频播放器管理器
///
/// 负责视频控制器的创建、缓存、释放和状态管理。
/// 封装视频控制器缓存逻辑，管理视频播放状态（播放/暂停、静音状态等），
/// 处理可见页面范围的资源管理。
class ViewerVideoManager {
  /// 视频播放器控制器缓存（按 assetId）
  final Map<String, VideoPlayerController> _controllers = {};

  /// 当前播放的视频 assetId
  String? _currentVideoAssetId;

  /// 可见页面范围（当前页 ± 1，即最多保留 3 页）
  static const int _visiblePageRange = 1;

  /// 需要保留资源的页面索引集合
  Set<int> _visiblePageIndices = {};

  /// 视频静音状态（默认静音）
  final Map<String, bool> _mutedStates = {};

  /// 创建视频控制器
  ///
  /// [asset] 资产对象
  /// [assetId] 资产 ID
  /// [serverUrl] 服务器 URL（可选）
  /// [assetEntityLoader] AssetEntity 加载器（可选）
  ///
  /// 返回 Future<VideoPlayerController?>，如果创建失败则返回 null
  Future<VideoPlayerController?> createController(
    BaseAsset asset,
    String assetId, {
    String? serverUrl,
    AssetEntityLoader? assetEntityLoader,
  }) async {
    // 如果已有控制器，直接返回
    if (_controllers.containsKey(assetId)) {
      return _controllers[assetId];
    }

    // 获取视频源
    final videoSource = await VideoProvider.getVideoSource(
      asset,
      serverUrl: serverUrl,
      assetEntityLoader: assetEntityLoader,
    );

    if (videoSource == null) {
      return null;
    }

    // 创建新的 VideoPlayerController
    final controller = videoSource.type == VideoSourceType.file
        ? VideoPlayerController.file(File(videoSource.source))
        : VideoPlayerController.networkUrl(Uri.parse(videoSource.source));

    _controllers[assetId] = controller;
    _mutedStates[assetId] = true; // 默认静音

    // 初始化
    try {
      await controller.initialize();
      // 设置默认静音
      controller.setVolume(0.0);
      // 设置循环播放
      controller.setLooping(true);
      return controller;
    } catch (e) {
      // 初始化失败，清理
      _controllers.remove(assetId);
      _mutedStates.remove(assetId);
      controller.dispose();
      return null;
    }
  }

  /// 获取已存在的控制器
  ///
  /// [assetId] 资产 ID
  ///
  /// 返回 VideoPlayerController?，如果不存在则返回 null
  VideoPlayerController? getController(String assetId) {
    return _controllers[assetId];
  }

  /// 释放单个控制器
  ///
  /// [assetId] 资产 ID
  void disposeController(String assetId) {
    final controller = _controllers.remove(assetId);
    if (controller != null) {
      // 确保先暂停
      if (controller.value.isPlaying) {
        controller.pause();
      }
      // 释放资源
      controller.dispose();
    }

    // 清理相关状态
    _mutedStates.remove(assetId);

    // 如果这是当前视频，清除标记
    if (_currentVideoAssetId == assetId) {
      _currentVideoAssetId = null;
    }
  }

  /// 释放所有控制器
  void disposeAllControllers() {
    // 暂停所有正在播放的视频
    for (final controller in _controllers.values) {
      if (controller.value.isPlaying) {
        controller.pause();
      }
    }

    // 释放所有控制器
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _mutedStates.clear();
    _visiblePageIndices.clear();
    _currentVideoAssetId = null;
  }

  /// 暂停控制器播放
  ///
  /// [assetId] 资产 ID
  void pauseController(String assetId) {
    final controller = _controllers[assetId];
    if (controller != null && controller.value.isPlaying) {
      controller.pause();
    }
  }

  /// 播放控制器
  ///
  /// [assetId] 资产 ID
  void playController(String assetId) {
    final controller = _controllers[assetId];
    if (controller != null &&
        controller.value.isInitialized &&
        !controller.value.isPlaying) {
      controller.play();
    }
  }

  /// 设置静音状态
  ///
  /// [assetId] 资产 ID
  /// [muted] 是否静音
  void setMuted(String assetId, bool muted) {
    _mutedStates[assetId] = muted;
    final controller = _controllers[assetId];
    if (controller != null) {
      controller.setVolume(muted ? 0.0 : 1.0);
    }
  }

  /// 获取静音状态
  ///
  /// [assetId] 资产 ID
  ///
  /// 返回 bool，默认为 true（静音）
  bool isMuted(String assetId) {
    return _mutedStates[assetId] ?? true;
  }

  /// 更新可见页面索引并释放不可见资源
  ///
  /// [visibleIndices] 可见页面索引集合
  /// [assetIds] 所有资产 ID 列表
  /// [assetMap] 资产 ID 到 BaseAsset 的映射
  void updateVisibleIndices(
    Set<int> visibleIndices,
    List<String> assetIds,
    Map<String, BaseAsset>? assetMap,
  ) {
    // 更新可见页面集合
    final toRelease = _visiblePageIndices.difference(visibleIndices);
    _visiblePageIndices = visibleIndices;

    // 释放不可见页面的视频控制器
    for (final index in toRelease) {
      if (index < assetIds.length) {
        final assetId = assetIds[index];
        final asset = assetMap?[assetId];

        if (asset != null && asset.isVideo) {
          disposeController(assetId);
        }
      }
    }
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

  /// 暂停并释放视频（根据是否可见决定是否完全释放）
  ///
  /// [assetId] 资产 ID
  /// [keepIfVisible] 如果视频在可见范围内，是否保留控制器
  void pauseAndReleaseVideo(String assetId, {required bool keepIfVisible}) {
    final controller = _controllers[assetId];
    if (controller == null) {
      return;
    }

    // 暂停播放
    if (controller.value.isPlaying) {
      controller.pause();
    }

    // 如果不在可见范围内，完全释放
    if (!keepIfVisible) {
      disposeController(assetId);
    }
  }
}

