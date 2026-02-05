import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:native_video_player/native_video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/features/local_sync/services/asset_entity_loader.dart';
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
  NativeVideoPlayerController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isVideoReady = false;
  double? _aspectRatio;
  bool _shouldPlayOnForeground = true; // 应用恢复时是否继续播放
  bool _isVisible = false; // 用于延迟显示，避免闪烁（参考 Immich）
  bool _isMuted = true; // 静音状态，独立管理（对齐 Immich）
  String? _currentVideoId; // 本地状态跟踪当前视频（参考 Immich）

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
    
    // 初始化静音状态（默认静音，对齐 Immich）
    _isMuted = true;
    
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

      // 静音状态已由本地 _isMuted 管理

      _initializeVideo();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // 参考 Immich 的 useEffect cleanup：移除监听器并停止播放
    final playerController = _controller;
    if (playerController != null) {
      _removeListeners(playerController);
      playerController.stop().catchError((error) {
        _log.fine('dispose: 停止视频时出错: $error');
      });
    }
    // 禁用唤醒锁
    WakelockPlus.disable();
    // 注意：controller 的底层原生实现由 NativeVideoPlayerView 自动管理
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final controller = _controller;
    if (controller == null) return;

    if (state == AppLifecycleState.resumed && _shouldPlayOnForeground) {
      // 应用恢复时继续播放（直接操作本地 controller）
      if (_isControllerValid(controller)) {
        controller.play().catchError((_) {});
      }
    } else if (state == AppLifecycleState.paused) {
      // 应用进入后台时暂停播放（直接操作本地 controller）
      if (_isControllerValid(controller)) {
        controller.isPlaying().then((isPlaying) {
          if (isPlaying) {
            _shouldPlayOnForeground = true;
            controller.pause().catchError((_) {});
          } else {
            _shouldPlayOnForeground = false;
          }
        }).catchError((_) {});
      }
    }
  }

  /// 初始化视频
  Future<void> _initializeVideo() async {
    _log.info('_initializeVideo: 开始初始化, assetId=${widget.assetId}');
    setState(() {
      _isLoading = true;
      _hasError = false;
      _isVideoReady = false;
    });

    // 检查是否在可见范围内
    if (!widget.visiblePageIndices.contains(widget.currentIndex)) {
      _log.warning(
        '_initializeVideo: 不在可见范围内, currentIndex=${widget.currentIndex}, visibleIndices=${widget.visiblePageIndices}',
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // 参考 Immich: 不重用已存在的 controller，每次都让 NativeVideoPlayerView 创建新的 controller
    _log.info('_initializeVideo: 等待 NativeVideoPlayerView 创建控制器');
    // 不设置 _isLoading = false，等待 _onPlaybackReady 来更新状态
    // 但也不阻塞 UI，让 NativeVideoPlayerView 可以显示
    // 注意：这里只预加载视频源，不阻塞 UI 显示
    // NativeVideoPlayerView 会在 onViewReady 回调中加载视频
    try {
      _log.info('_initializeVideo: 开始获取视频源');
      final videoSource = await widget.videoManager.getVideoSource(
        widget.asset,
        widget.assetId,
        serverUrl: widget.serverUrl,
        assetEntityLoader: widget.assetEntityLoader,
        videoIdOverride: widget.livePhotoVideoId,
      );

      if (mounted) {
        if (videoSource == null) {
          _log.severe('_initializeVideo: 视频源获取失败，videoSource 为 null');
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        } else {
          _log.info('_initializeVideo: 视频源获取成功，等待 NativeVideoPlayerView 创建控制器');
          // 视频源获取成功，允许显示 NativeVideoPlayerView
          // 不设置 _isLoading = false，等待 _onPlaybackReady 来更新状态
          // 但也不阻塞 UI，让 NativeVideoPlayerView 可以显示
        }
      } else {
        _log.warning('_initializeVideo: widget 已卸载，跳过状态更新');
      }
    } catch (e, stackTrace) {
      _log.severe('_initializeVideo: 获取视频源时发生错误', e, stackTrace);
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  /// 检查 controller 是否有效（原生实现是否还存在）
  bool _isControllerValid(NativeVideoPlayerController? controller) {
    if (controller == null) return false;
    try {
      final info = controller.playbackInfo;
      return info != null;
    } catch (e) {
      _log.warning('_isControllerValid: controller 无效，原生实现可能已被销毁: $e');
      return false;
    }
  }

  /// 移除监听器（参考 Immich 的 removeListeners）
  void _removeListeners(NativeVideoPlayerController controller) {
    controller.onPlaybackPositionChanged.removeListener(_onPlaybackPositionChanged);
    controller.onPlaybackStatusChanged.removeListener(_onPlaybackStatusChanged);
    controller.onPlaybackReady.removeListener(_onPlaybackReady);
    controller.onPlaybackEnded.removeListener(_onPlaybackEnded);
  }

  /// 设置监听器
  void _setupListeners(NativeVideoPlayerController controller) {
    _log.info('_setupListeners: 添加监听器, assetId=${widget.assetId}');
    // 先移除可能存在的旧监听器，避免重复添加（当重用控制器时）
    _removeListeners(controller);
    // 添加新的监听器
    controller.onPlaybackReady.addListener(_onPlaybackReady);
    controller.onPlaybackStatusChanged.addListener(_onPlaybackStatusChanged);
    controller.onPlaybackPositionChanged.addListener(
      _onPlaybackPositionChanged,
    );
    controller.onPlaybackEnded.addListener(_onPlaybackEnded);
    _log.info('_setupListeners: 监听器添加完成');
  }

  /// 播放就绪回调
  /// 
  /// 参考 Immich 的实现：开头检查 isCurrent，只有当前视频才执行播放逻辑
  void _onPlaybackReady() {
    _log.info('_onPlaybackReady: 播放就绪回调触发, assetId=${widget.assetId}');
    
    // 参考 Immich: 开头检查 isCurrent，如果不是当前视频直接返回
    final currentVideoIdFromProvider = ref.read(currentVideoAssetIdProvider);
    final currentVideoId = currentVideoIdFromProvider ?? 
        widget.videoManager.getCurrentVideoAssetId();
    final isCurrent = widget.assetId == currentVideoId;
    
    if (!isCurrent) {
      _log.info('_onPlaybackReady: 不是当前视频，直接返回');
      return;
    }
    
    if (!mounted) {
      _log.warning('_onPlaybackReady: widget 已卸载，忽略回调');
      return;
    }
    final controller = _controller;
    if (controller == null) {
      _log.warning('_onPlaybackReady: controller 为 null，忽略回调');
      return;
    }

    final playbackInfo = controller.playbackInfo;
    final videoInfo = controller.videoInfo;

    _log.info(
      '_onPlaybackReady: playbackInfo=${playbackInfo != null}, videoInfo=${videoInfo != null}',
    );

    if (playbackInfo != null && videoInfo != null) {
      _log.info(
        '_onPlaybackReady: 视频信息完整, width=${videoInfo.width}, height=${videoInfo.height}, duration=${videoInfo.duration}',
      );
      
      // 重要：videoInfo 返回的是视频文件的原始宽高（未考虑 rotation/orientation）
      // 但 NativeVideoPlayer 会自动应用 rotation，实际显示的尺寸可能不同
      // 因此不应该直接使用 videoInfo 的宽高比，而应该使用 AssetService 返回的宽高比
      // （AssetService 已考虑 orientation，返回的是实际显示尺寸）
      // 
      // 我们仍然需要更新视频就绪状态，但不更新宽高比
      setState(() {
        _isVideoReady = true;
        _isLoading = false;
        // 不更新 _aspectRatio，保持使用 AssetService 返回的宽高比
        // 如果在 _fetchAspectRatioAsync 中已经设置了正确的宽高比，就不需要修改
        // 如果还没有设置（可能 AssetService 还在加载），使用当前值（可能是临时值）
        _log.fine(
          '_onPlaybackReady: 视频就绪，保持当前宽高比: $_aspectRatio',
        );
        // 静音状态已由本地 _isMuted 管理
        // 确保视频可见
        _isVisible = true;
      });

      // 是当前视频，自动播放（直接操作本地 controller，对齐 Immich）
      // 再次检查 controller 是否有效（防止底层实现已被销毁）
      if (!_isControllerValid(controller)) {
        _log.warning('_onPlaybackReady: controller 无效，原生实现可能已被销毁，跳过播放');
        return;
      }
      
      _log.info('_onPlaybackReady: 是当前视频，开始播放');
      controller.play().catchError((error) {
        _log.warning('_onPlaybackReady: 播放失败', error);
      });
    } else {
      _log.warning(
        '_onPlaybackReady: 视频信息不完整, playbackInfo=${playbackInfo != null}, videoInfo=${videoInfo != null}',
      );
    }
  }

  /// 播放状态变化回调
  void _onPlaybackStatusChanged() {
    if (!mounted) return;
    final controller = _controller;
    if (controller == null) return;

    final playbackInfo = controller.playbackInfo;
    if (playbackInfo != null) {
      _log.fine(
        '_onPlaybackStatusChanged: status=${playbackInfo.status}, position=${playbackInfo.position}',
      );
      // 根据播放状态管理唤醒锁
      if (playbackInfo.status == PlaybackStatus.playing) {
        WakelockPlus.enable();
      } else {
        WakelockPlus.disable();
      }
    }
    // 移除空的 setState，避免频繁重建
    // 如果需要更新 UI，应该只在必要时调用 setState
  }

  /// 播放进度变化回调
  void _onPlaybackPositionChanged() {
    if (!mounted) return;
    // 移除空的 setState，避免频繁重建
    // 如果需要更新进度条，应该使用 ValueListenableBuilder 或其他方式
  }

  /// 播放结束回调
  void _onPlaybackEnded() {
    if (!mounted) return;
    if (widget.isLivePhotoVideo) {
      ref.read(isPlayingMotionVideoProvider.notifier).state = false;
    }
  }

  /// 初始化控制器（由 NativeVideoPlayerView 的 onViewReady 调用）
  /// 
  /// 参考 Immich 的实现：
  /// - 只检查本地 _controller 状态，不检查从 ViewerVideoManager 获取的 controller
  /// - 直接调用 nc.loadVideoSource(source)，然后设置本地状态
  Future<void> _initController(NativeVideoPlayerController controller) async {
    _log.info('_initController: 开始初始化控制器, assetId=${widget.assetId}');
    
    // 参考 Immich: if (controller.value != null || !context.mounted) return;
    // 只检查本地 _controller 状态，不检查从 ViewerVideoManager 获取的 controller
    if (_controller != null || !mounted) {
      _log.warning('_initController: controller 已存在或 widget 已卸载，跳过初始化');
      return;
    }

    try {
      // 获取视频源
      _log.info('_initController: 开始获取视频源');
      final videoSource = await widget.videoManager.getVideoSource(
        widget.asset,
        widget.assetId,
        serverUrl: widget.serverUrl,
        assetEntityLoader: widget.assetEntityLoader,
        videoIdOverride: widget.livePhotoVideoId,
      );

      if (!mounted) {
        _log.warning('_initController: widget 已卸载，跳过后续操作');
        return;
      }

      if (videoSource == null) {
        _log.severe('_initController: 视频源为空，设置错误状态');
        if (widget.isLivePhotoVideo) {
          ref.read(isPlayingMotionVideoProvider.notifier).state = false;
        }
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        return;
      }

      // 设置监听器（使用 _setupListeners 确保先移除旧的监听器，避免重复添加）
      _setupListeners(controller);

      // 参考 Immich: 直接调用 nc.loadVideoSource(source)
      _log.info('_initController: 开始加载视频源');
      unawaited(
        controller.loadVideoSource(videoSource).catchError((error) {
          _log.severe('_initController: 加载视频源失败', error);
          if (mounted) {
            if (widget.isLivePhotoVideo) {
              ref.read(isPlayingMotionVideoProvider.notifier).state = false;
            }
            setState(() {
              _hasError = true;
              _isLoading = false;
            });
          }
        }),
      );

      // 参考 Immich: 在 controller 刚创建时设置状态（此时原生实现肯定存在）
      // Live Photo 不循环，播完回图；普通视频默认循环
      final loop = !widget.isLivePhotoVideo;
      unawaited(controller.setLoop(loop).catchError((error) {
        _log.warning('_initController: 设置循环播放失败', error);
      }));
      
      // 设置默认静音（参考 Immich: await videoController.setVolume(0.9)）
      // 注意：在 controller 刚创建时设置，确保原生实现存在
      unawaited(controller.setVolume(0.0).catchError((error) {
        _log.warning('_initController: 设置静音失败', error);
      }));

      // 参考 Immich: controller.value = nc; (设置本地状态)
      _log.info('_initController: 设置本地 controller 状态');
      setState(() {
        _controller = controller;
      });

      // 注意：不再注册 controller 到 ViewerVideoManager，每个 Widget 独立管理（对齐 Immich）
    } catch (e, stackTrace) {
      _log.severe('_initController: 发生异常', e, stackTrace);
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
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
    
    // 监听当前视频状态变化，响应式地处理播放逻辑（参考 Immich 实现）
    ref.listen<String?>(currentVideoAssetIdProvider, (previous, next) {
      final controller = _controller;
      
      // 参考 Immich: 如果该视频不再是当前视频，移除监听器
      if (controller != null && next != widget.assetId && next != previous) {
        _log.info('build: 视频不再是当前视频，移除监听器');
        _removeListeners(controller);
        // 设置为不可见
        if (mounted) {
          setState(() {
            _isVisible = false;
          });
        }
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

    // 如果视频未就绪且没有控制器，显示加载中
    // 但如果 isCurrent=true，即使没有 controller 也要显示 NativeVideoPlayerView（它会创建 controller）
    if (_isLoading && !_isVideoReady && _controller == null && !isCurrent) {
      _log.fine('build: 加载中且无控制器且不是当前视频，显示加载指示器');
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
        if (isCurrent && _isVisible)
          Center(
            child: AspectRatio(
              aspectRatio: _aspectRatio ?? 16 / 9,
              child: NativeVideoPlayerView(
                key: ValueKey(widget.assetId),
                onViewReady: (controller) {
                  _log.info(
                    '_buildVideoPlayerWidget: onViewReady 回调触发, assetId=${widget.assetId}',
                  );
                  _initController(controller);
                },
              ),
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
            bottom: MediaQuery.of(context).padding.bottom + 80, // 底部控制栏高度约 80px
            child: IgnorePointer(
              ignoring: false, // 控制栏按钮需要接收点击事件
              child: VideoPlayerControls(
                controller: controller,
                showControls: widget.showControls,
                isMuted: _isMuted,
                onMuteChanged: (muted) async {
                  // 直接操作本地 controller（对齐 Immich）
                  if (_isControllerValid(controller)) {
                    await controller.setVolume(muted ? 0.0 : 1.0).catchError((error) {
                      _log.warning('onMuteChanged: 设置音量失败', error);
                    });
                  }
                  // 更新本地状态并触发重建，确保 UI 同步
                  if (mounted) {
                    setState(() {
                      _isMuted = muted;
                    });
                  }
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
