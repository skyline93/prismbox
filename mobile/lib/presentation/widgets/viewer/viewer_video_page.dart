import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/features/local_sync/services/asset_entity_loader.dart';
import 'package:prismbox/features/video_playback/viewer_playback_controller.dart';
import 'package:prismbox/presentation/widgets/viewer/viewer_video_manager.dart';
import 'package:prismbox/presentation/widgets/viewer/viewer_video_state_provider.dart';
import 'package:prismbox/presentation/widgets/viewer/viewer_video_controller.dart';
import 'package:prismbox/providers/infrastructure/asset_providers.dart';

final Logger _log = Logger('ViewerVideoPage');

/// 视频查看页面组件
///
/// 封装 NativeVideoPlayer 相关逻辑，集成视频控制器 UI，处理视频加载和错误状态。
class ViewerVideoPage extends ConsumerStatefulWidget {
  /// 资产对象
  final BaseAsset asset;

  /// 资产 ID
  final String assetId;

  /// 视频管理器
  final ViewerVideoManager videoManager;

  /// 服务器 URL（可选）
  final String? serverUrl;

  /// AssetEntity 加载器（可选）
  final AssetEntityLoader? assetEntityLoader;

  /// 是否显示控制栏
  final bool showControls;

  /// 切换控制栏显示/隐藏回调
  final VoidCallback? onToggleControls;

  /// 静音状态改变回调
  final ValueChanged<bool>? onMuteChanged;

  /// 当前页面索引（用于判断是否在可见范围内）
  final int currentIndex;

  /// 可见页面索引集合
  final Set<int> visiblePageIndices;

  /// Live Photo 关联视频资产 ID（非 null 时使用该 ID 获取视频源，不循环，播完回图）
  final String? livePhotoVideoId;

  /// 是否为 Live Photo 关联短视频（用于不循环、播完重置 isPlayingMotionVideoProvider）
  final bool isLivePhotoVideo;

  const ViewerVideoPage({
    super.key,
    required this.asset,
    required this.assetId,
    required this.videoManager,
    this.serverUrl,
    this.assetEntityLoader,
    required this.showControls,
    this.onToggleControls,
    this.onMuteChanged,
    required this.currentIndex,
    required this.visiblePageIndices,
    this.livePhotoVideoId,
    this.isLivePhotoVideo = false,
  });

  @override
  ConsumerState<ViewerVideoPage> createState() => _ViewerVideoPageState();
}

class _ViewerVideoPageState extends ConsumerState<ViewerVideoPage>
    with WidgetsBindingObserver {
  ViewerPlaybackController? _controller;
  VoidCallback? _statusListener;
  VoidCallback? _livePhotoPositionListener;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isVideoReady = false;
  double? _aspectRatio;
  bool _shouldPlayOnForeground = true;
  bool _isVisible = false;
  String? _currentVideoId;
  /// Live Photo 播完一次后已重置 provider 的标记，下次开始播放时清空
  bool _livePhotoEndHandled = false;

  @override
  void initState() {
    super.initState();
    _log.info(
      'initState: assetId=${widget.assetId}, currentIndex=${widget.currentIndex}',
    );
    WidgetsBinding.instance.addObserver(this);
    
    // 使用 asset.aspectRatio 作为初始宽高比（已经考虑了 orientation）
    // 但为了确保准确性，即使不为 null，也异步调用 AssetService.getAspectRatio 验证
    // 因为 AssetService 会从数据库重新获取 width/height/orientation 并计算，确保准确性
    // 在获取完成前，使用临时宽高比（16/9）来显示 NativeVideoPlayerView
    // 这样 NativeVideoPlayerView 就能被创建，onViewReady 会被调用
    // 注意：不使用 videoInfo 的宽高比，因为它是原始尺寸（未考虑 rotation/orientation）
    // AssetService 返回的宽高比已经考虑了 orientation，这才是实际显示的尺寸
    _aspectRatio = widget.asset.aspectRatio;
    if (_aspectRatio == null) {
      _aspectRatio = 16 / 9; // 临时宽高比，等待异步获取或 videoInfo 准备好
      _log.info('initState: asset.aspectRatio 为 null，使用临时宽高比: $_aspectRatio');
    } else {
      _log.info(
        'initState: 从 asset.aspectRatio 获取宽高比: $_aspectRatio (已考虑 orientation)，将异步验证',
      );
    }

    // 始终异步获取宽高比进行验证（即使 asset.aspectRatio 不为 null）
    // 因为 AssetService 会从数据库重新获取并计算，确保准确性
    // 这样可以修正可能的计算错误（如 iOS 上数据库存储的 width/height 与 orientation 不匹配）
    _fetchAspectRatioAsync();
    
    // 静音状态由 viewerMutedProvider 统一管理，滑动切换视频时保持用户选择
    
    // 初始化本地状态跟踪当前视频（参考 Immich）
    _currentVideoId = ref.read(currentVideoAssetIdProvider);
    
    _initializeVideo();
    
    // 延迟显示视频，避免闪烁（参考 Immich 的实现）
    // 如果是当前视频，立即显示；否则延迟 300ms
    final isCurrent = widget.assetId == _currentVideoId;
    if (isCurrent) {
      _isVisible = true;
    } else {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _isVisible = true;
          });
        }
      });
    }
  }

  /// 异步获取宽高比
  /// 从数据库获取 width/height/orientation 后计算，确保准确性
  /// 即使 asset.aspectRatio 不为 null，也会进行验证和修正
  Future<void> _fetchAspectRatioAsync() async {
    try {
      final assetServiceAsync = ref.read(assetServiceProvider);
      final aspectRatio = await assetServiceAsync.when(
        data: (assetService) => assetService.getAspectRatio(widget.asset),
        loading: () async {
          _log.fine('_fetchAspectRatioAsync: AssetService 加载中，等待...');
          // 等待 Provider 完成加载
          final service = await ref.read(assetServiceProvider.future);
          return service.getAspectRatio(widget.asset);
        },
        error: (error, stackTrace) {
          _log.warning(
            '_fetchAspectRatioAsync: AssetService 加载失败',
            error,
            stackTrace,
          );
          throw error;
        },
      );

      if (mounted) {
        final oldAspectRatio = _aspectRatio;
        setState(() {
          _aspectRatio = aspectRatio;
        });

        if (oldAspectRatio != null && oldAspectRatio != aspectRatio) {
          _log.info(
            '_fetchAspectRatioAsync: 宽高比已修正: $oldAspectRatio -> $aspectRatio, assetId=${widget.assetId}',
          );
        } else {
          _log.fine(
            '_fetchAspectRatioAsync: 异步获取宽高比成功: $aspectRatio, assetId=${widget.assetId}',
          );
        }
      }
    } catch (e, stackTrace) {
      _log.warning(
        '_fetchAspectRatioAsync: 异步获取宽高比失败, assetId=${widget.assetId}, 保持当前宽高比',
        e,
        stackTrace,
      );
      // 如果获取失败，保持当前宽高比（可能是 asset.aspectRatio 或临时宽高比）
      // 注意：不使用 videoInfo 的宽高比，因为它是原始尺寸（未考虑 rotation/orientation）
    }
  }

  @override
  void didUpdateWidget(ViewerVideoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果 assetId 改变，重新初始化视频
    if (oldWidget.assetId != widget.assetId) {
      _log.info(
        'didUpdateWidget: assetId 改变, 从 ${oldWidget.assetId} 到 ${widget.assetId}',
      );
      // 重置可见性状态
      final isCurrent =
          widget.assetId == widget.videoManager.getCurrentVideoAssetId();
      _isVisible = isCurrent; // 如果是当前视频，立即显示；否则延迟显示

      // 重新获取宽高比
      _aspectRatio = widget.asset.aspectRatio ?? (16 / 9); // 临时宽高比

      // 始终异步获取宽高比进行验证
      _fetchAspectRatioAsync();

      // 静音状态由 viewerMutedProvider 管理

      _initializeVideo();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final controller = _controller;
    final listener = _statusListener;
    final positionListener = _livePhotoPositionListener;
    if (controller != null) {
      if (listener != null) controller.removeStatusListener(listener);
      if (positionListener != null) controller.removePositionListener(positionListener);
      controller.pause().catchError((e) => _log.fine('dispose: pause 失败: $e'));
      controller.dispose().catchError((e) => _log.fine('dispose: dispose 失败: $e'));
    }
    WakelockPlus.disable();
    super.dispose();
  }

  static bool _isAtEnd(ViewerPlaybackController c) {
    return c.duration > Duration.zero &&
        c.position >= c.duration - const Duration(milliseconds: 100);
  }

  /// Live Photo 播完：下一帧重置 provider 以切回照片显示，暂停并 seek 到 0；并清除 manager 缓存，以便再次长按时创建新 controller
  void _applyLivePhotoEndReturnToPhoto(ViewerPlaybackController controller) {
    if (!_livePhotoEndHandled && mounted) {
      _livePhotoEndHandled = true;
      widget.videoManager.removeCachedController(
        videoIdOverride: widget.livePhotoVideoId,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(isPlayingMotionVideoProvider.notifier).state = false;
      });
      unawaited(controller.pause().catchError((e) {
        _log.fine('Live Photo 播完 pause 失败', e);
      }));
      unawaited(controller.seekTo(Duration.zero).catchError((e) {
        _log.warning('Live Photo 播完 seekTo(0) 失败', e);
      }));
    }
  }

  /// 由 position 监听调用，用于可靠检测 Live Photo 播完并切回照片
  /// 片尾时即视为结束（不要求 isPlaying 已为 false），避免时序导致漏检
  void _checkLivePhotoEndAndReturnToPhoto() {
    if (!mounted || !widget.isLivePhotoVideo) return;
    final controller = _controller;
    if (controller == null || !controller.isReady) return;
    final isCurrent = ref.read(currentVideoAssetIdProvider) == widget.assetId ||
        widget.videoManager.getCurrentVideoAssetId() == widget.assetId;
    if (!isCurrent) return;
    if (_isAtEnd(controller)) {
      _applyLivePhotoEndReturnToPhoto(controller);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final controller = _controller;
    if (controller == null) return;

    if (state == AppLifecycleState.resumed && _shouldPlayOnForeground) {
      if (_isControllerValid(controller)) {
        controller.play().catchError((_) {});
      }
    } else if (state == AppLifecycleState.paused) {
      if (_isControllerValid(controller)) {
        if (controller.isPlaying) {
          _shouldPlayOnForeground = true;
          controller.pause().catchError((_) {});
        } else {
          _shouldPlayOnForeground = false;
        }
      }
    }
  }

  /// 初始化视频：通过工厂获取 ViewerPlaybackController，设置 loop/volume 与状态监听
  Future<void> _initializeVideo() async {
    _log.info('_initializeVideo: 开始初始化, assetId=${widget.assetId}');
    setState(() {
      _isLoading = true;
      _hasError = false;
      _isVideoReady = false;
    });

    if (!widget.visiblePageIndices.contains(widget.currentIndex)) {
      _log.warning(
        '_initializeVideo: 不在可见范围内, currentIndex=${widget.currentIndex}, visibleIndices=${widget.visiblePageIndices}',
      );
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      _log.info('_initializeVideo: 获取播放控制器');
      final controller = await widget.videoManager.getPlaybackController(
        widget.asset,
        widget.assetId,
        serverUrl: widget.serverUrl,
        assetEntityLoader: widget.assetEntityLoader,
        videoIdOverride: widget.livePhotoVideoId,
      );

      if (!mounted) return;
      if (controller == null) {
        _log.severe('_initializeVideo: 获取播放控制器失败');
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        return;
      }

      _statusListener = () => _onPlaybackStatusMaybeReady();
      controller.addStatusListener(_statusListener!);
      if (widget.isLivePhotoVideo) {
        _livePhotoPositionListener = () => _checkLivePhotoEndAndReturnToPhoto();
        controller.addPositionListener(_livePhotoPositionListener!);
      }
      // Live Photo 必须在起播前完成 setLoop(false)，避免平台未应用导致继续循环
      await controller.setLoop(!widget.isLivePhotoVideo).catchError((e) {
        _log.warning('_initializeVideo: setLoop 失败', e);
      });
      final muted = ref.read(viewerMutedProvider);
      unawaited(controller.setVolume(muted ? 0.0 : 1.0).catchError((e) {
        _log.warning('_initializeVideo: setVolume 失败', e);
      }));

      if (!mounted) return;
      setState(() => _controller = controller);
      _onPlaybackStatusMaybeReady();
    } catch (e, stackTrace) {
      _log.severe('_initializeVideo: 发生错误', e, stackTrace);
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  void _onPlaybackStatusMaybeReady() {
    if (!mounted) return;
    final controller = _controller;
    if (controller == null) return;
    if (controller.isPlaying) {
      WakelockPlus.enable();
      _livePhotoEndHandled = false;
    } else {
      WakelockPlus.disable();
    }
    if (!controller.isReady) return;
    final currentVideoId = ref.read(currentVideoAssetIdProvider) ??
        widget.videoManager.getCurrentVideoAssetId();
    final isCurrent = widget.assetId == currentVideoId;
    setState(() {
      _isVideoReady = true;
      _isLoading = false;
      _isVisible = true;
    });
    // Live Photo 播完：回到静态图并 seek 到 0，便于下次再播；不再自动播放
    final atEnd = _isAtEnd(controller);
    if (widget.isLivePhotoVideo &&
        isCurrent &&
        !controller.isPlaying &&
        atEnd &&
        !_livePhotoEndHandled) {
      _applyLivePhotoEndReturnToPhoto(controller);
    } else if (isCurrent &&
        !(widget.isLivePhotoVideo && atEnd)) {
      // Live Photo 已到片尾时一律不再调用起播，避免时序导致误触发 seek(0)+play() 形成循环
      _log.info('_onPlaybackStatusMaybeReady: 是当前视频，开始播放');
      _playFromStartIfNeeded(controller);
    }
  }

  bool _isControllerValid(ViewerPlaybackController? controller) {
    return controller != null && controller.isReady;
  }

  void _onPlaybackReady() {
    if (!mounted) return;
    final controller = _controller;
    if (controller == null || !controller.isReady) return;
    final currentVideoId = ref.read(currentVideoAssetIdProvider) ??
        widget.videoManager.getCurrentVideoAssetId();
    if (widget.assetId != currentVideoId) return;
    // Live Photo 已到片尾时不自动起播，避免循环
    if (widget.isLivePhotoVideo && _isAtEnd(controller)) return;
    _playFromStartIfNeeded(controller);
  }

  /// 若为 Live Photo 且当前在片尾，先 seek 到 0 再播放，避免复用控制器时无法再次播放
  void _playFromStartIfNeeded(ViewerPlaybackController controller) {
    final duration = controller.duration;
    final position = controller.position;
    if (widget.isLivePhotoVideo &&
        duration > Duration.zero &&
        position >= duration - const Duration(milliseconds: 100)) {
      unawaited(controller.seekTo(Duration.zero).then((_) {
        if (mounted) {
          controller.play().catchError((e) => _log.warning('播放失败', e));
        }
      // ignore: invalid_return_type_for_catch_error
      }).catchError((e) => _log.warning('seekTo(0) 失败', e)));
    } else {
      controller.play().catchError((e) => _log.warning('播放失败', e));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 优先使用 Provider 状态，如果没有则使用 ViewerVideoManager 作为兜底
    final currentVideoIdFromProvider = ref.read(currentVideoAssetIdProvider);
    final currentVideoId = currentVideoIdFromProvider ?? 
        widget.videoManager.getCurrentVideoAssetId();
    final isCurrent = widget.assetId == currentVideoId;
    _log.fine(
      'build: assetId=${widget.assetId}, isCurrent=$isCurrent, _isLoading=$_isLoading, _isVideoReady=$_isVideoReady, _hasError=$_hasError, _controller=${_controller != null}',
    );
    
    // 监听会话级静音状态变化，同步到当前 controller（例如从其他入口更新时）
    ref.listen<bool>(viewerMutedProvider, (previous, next) {
      final controller = _controller;
      if (controller != null && isCurrent && mounted) {
        controller.setVolume(next ? 0.0 : 1.0).catchError((e) {
          _log.warning('viewerMutedProvider: setVolume 失败', e);
        });
      }
    });

    ref.listen<String?>(currentVideoAssetIdProvider, (previous, next) {
      final controller = _controller;
      if (controller != null && next != widget.assetId && next != previous) {
        _log.info('build: 视频不再是当前视频，暂停');
        controller.pause().catchError((e) => _log.fine('build: 暂停出错: $e'));
        if (mounted) setState(() => _isVisible = false);
      }

      // 参考 Immich: 使用本地状态跟踪当前视频
      final curVideoId = _currentVideoId;
      if (curVideoId == widget.assetId) {
        // 已经是当前视频，直接返回
        return;
      }

      // 参考 Immich: 延迟更新，确保切换动画完成
      // 使用 200ms 延迟（参考 Immich 的默认值，可以根据平台调整）
      Timer(const Duration(milliseconds: 200), () {
        if (!mounted) {
          return;
        }

        // 更新本地状态
        _currentVideoId = next;
        
        // 检查是否变成了当前视频
        if (_currentVideoId == widget.assetId) {
          _log.info('build: 视频变成当前视频，调用 onPlaybackReady');
          // 设置为可见
          if (mounted) {
            setState(() {
              _isVisible = true;
            });
          }
          // 调用 onPlaybackReady（它会检查 isCurrent 并自动播放）
          _onPlaybackReady();
        }
      });
    });
    
    // 检查是否在可见范围内
    if (!widget.visiblePageIndices.contains(widget.currentIndex)) {
      _log.fine('build: 不在可见范围内，显示加载中');
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    // 如果有错误，显示错误信息
    if (_hasError) {
      _log.warning('build: 有错误，显示错误信息');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text('视频加载失败', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    if (_isLoading && !_isVideoReady && _controller == null && !isCurrent) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    _log.fine('build: 显示视频播放器, isCurrent=$isCurrent');
    // 显示视频播放器（即使还在加载中，也允许显示 NativeVideoPlayerView）
    return _buildVideoPlayerWidget();
  }

  /// 构建视频播放器 Widget
  Widget _buildVideoPlayerWidget() {
    final controller = _controller;
    // 优先使用 Provider 状态，如果没有则使用 ViewerVideoManager 作为兜底
    final currentVideoIdFromProvider = ref.read(currentVideoAssetIdProvider);
    final currentVideoId = currentVideoIdFromProvider ?? 
        widget.videoManager.getCurrentVideoAssetId();
    final isCurrent = widget.assetId == currentVideoId;

    _log.fine(
      '_buildVideoPlayerWidget: isCurrent=$isCurrent, aspectRatio=$_aspectRatio, controller=${controller != null}, _isVisible=$_isVisible',
    );

    // 添加透明覆盖层来捕获点击事件，因为 NativeVideoPlayerView 可能拦截点击事件
    return Stack(
      fit: StackFit.expand,
      children: [
        // 视频播放区域
        // 使用 aspectRatio（如果为 null 则使用临时值 16/9）
        // 这样 NativeVideoPlayerView 就能被创建，onViewReady 会被调用
        if (isCurrent && _isVisible && controller != null)
          Center(
            child: AspectRatio(
              aspectRatio: _aspectRatio ?? 16 / 9,
              child: controller.buildVideoView(),
            ),
          ),

        // 透明覆盖层：用于捕获点击事件以切换控制栏显示/隐藏
        // 只覆盖控制栏区域外的区域，避免阻挡控制栏按钮
        Positioned.fill(
          bottom: controller != null && widget.showControls
              ? MediaQuery.of(context).padding.bottom + 80 + 72 // 控制栏高度 + 偏移
              : 0,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onToggleControls,
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),

        // 自定义控制器（底部对齐，但要在底部控制栏上方）
        // 底部控制栏高度：padding (16*2) + IconButton (48) + 安全区域底部 ≈ 80-100px
        // 放在覆盖层之后，确保控制栏在最上层
        // 只有当前视频才显示控制栏，避免重叠（参考 Immich）
        if (controller != null && isCurrent)
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 80,
            child: IgnorePointer(
              ignoring: false,
              child: VideoPlayerControls(
                playbackController: controller,
                showControls: widget.showControls,
                isMuted: ref.watch(viewerMutedProvider),
                onMuteChanged: (muted) async {
                  ref.read(viewerMutedProvider.notifier).state = muted;
                  await controller.setVolume(muted ? 0.0 : 1.0).catchError((e) {
                    _log.warning('onMuteChanged: setVolume 失败', e);
                  });
                  widget.onMuteChanged?.call(muted);
                },
                onTap: widget.onToggleControls,
              ),
            ),
          ),
      ],
    );
  }
}
