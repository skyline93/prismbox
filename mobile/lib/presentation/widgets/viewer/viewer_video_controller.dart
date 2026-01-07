import 'dart:async';
import 'package:flutter/material.dart';
import 'package:native_video_player/native_video_player.dart';

/// 视频播放器控制器 UI 组件
///
/// 封装视频播放控制逻辑（播放/暂停、进度条、静音等）。
/// 使用 native_video_player 的 NativeVideoPlayerController，支持 HDR 视频播放。
/// 性能优化：使用监听器和 RepaintBoundary 隔离绘制边界。
class VideoPlayerControls extends StatefulWidget {
  final NativeVideoPlayerController controller;
  final bool showControls;
  final bool isMuted;
  final ValueChanged<bool> onMuteChanged;
  final VoidCallback? onTap;

  const VideoPlayerControls({
    super.key,
    required this.controller,
    required this.showControls,
    required this.isMuted,
    required this.onMuteChanged,
    this.onTap,
  });

  @override
  State<VideoPlayerControls> createState() => _VideoPlayerControlsState();
}

class _VideoPlayerControlsState extends State<VideoPlayerControls> {
  bool _isDragging = false;
  Duration? _dragPosition;
  Timer? _progressUpdateTimer;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // 性能优化：提取样式对象为静态常量
  static const double _progressHeight = 4.0;
  static const double _horizontalPadding = 16.0;

  @override
  void initState() {
    super.initState();
    // 初始化时设置静音
    if (widget.isMuted) {
      widget.controller.setVolume(0.0);
    }
    // 添加监听器
    widget.controller.onPlaybackStatusChanged.addListener(
      _onPlaybackStatusChanged,
    );
    widget.controller.onPlaybackPositionChanged.addListener(
      _onPlaybackPositionChanged,
    );
    _startProgressTimer();
    _updatePlaybackState();
  }

  @override
  void didUpdateWidget(VideoPlayerControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果控制器改变，更新监听器
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.onPlaybackStatusChanged.removeListener(
        _onPlaybackStatusChanged,
      );
      oldWidget.controller.onPlaybackPositionChanged.removeListener(
        _onPlaybackPositionChanged,
      );
      widget.controller.onPlaybackStatusChanged.addListener(
        _onPlaybackStatusChanged,
      );
      widget.controller.onPlaybackPositionChanged.addListener(
        _onPlaybackPositionChanged,
      );
    }
    // 如果静音状态改变，更新音量
    if (oldWidget.isMuted != widget.isMuted) {
      widget.controller.setVolume(widget.isMuted ? 0.0 : 1.0);
    }
    _updatePlaybackState();
  }

  @override
  void dispose() {
    widget.controller.onPlaybackStatusChanged.removeListener(
      _onPlaybackStatusChanged,
    );
    widget.controller.onPlaybackPositionChanged.removeListener(
      _onPlaybackPositionChanged,
    );
    _progressUpdateTimer?.cancel();
    super.dispose();
  }

  /// 更新播放状态
  void _updatePlaybackState() {
    final playbackInfo = widget.controller.playbackInfo;
    final videoInfo = widget.controller.videoInfo;
    if (playbackInfo != null && videoInfo != null) {
      setState(() {
        _position = Duration(milliseconds: playbackInfo.position);
        _duration = Duration(milliseconds: videoInfo.duration);
        _isPlaying = playbackInfo.status == PlaybackStatus.playing;
      });
    }
  }

  /// 播放状态变化回调
  void _onPlaybackStatusChanged() {
    if (mounted) {
      _updatePlaybackState();
    }
  }

  /// 播放进度变化回调
  void _onPlaybackPositionChanged() {
    if (mounted && !_isDragging) {
      _updatePlaybackState();
    }
  }

  /// 性能优化：使用 Timer 节流，避免每帧更新
  /// 视频进度不需要 60fps 更新，每 100ms 更新一次足够流畅
  void _startProgressTimer() {
    _progressUpdateTimer?.cancel();
    _progressUpdateTimer = Timer.periodic(const Duration(milliseconds: 100), (
      _,
    ) {
      if (mounted && !_isDragging) {
        _updatePlaybackState();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showControls) {
      return const SizedBox.shrink();
    }

    // 性能优化：使用 RepaintBoundary 隔离绘制边界
    return RepaintBoundary(
      // 性能优化：隔离绘制边界，避免影响视频播放区域
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
        decoration: BoxDecoration(
          // 性能优化：使用渐变而非复杂效果
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: Row(
          children: [
            // 播放/暂停按钮
            _buildPlayPauseButton(_isPlaying),

            const SizedBox(width: 12),

            // 进度条（可扩展）
            Expanded(child: _buildProgressBar()),

            const SizedBox(width: 12),

            // 静音按钮
            _buildMuteButton(),
          ],
        ),
      ),
    );
  }

  /// 播放/暂停按钮
  Widget _buildPlayPauseButton(bool isPlaying) {
    return IconButton(
      icon: Icon(
        isPlaying ? Icons.pause : Icons.play_arrow,
        color: Colors.white,
        size: 28,
      ),
      onPressed: () async {
        if (isPlaying) {
          await widget.controller.pause();
        } else {
          await widget.controller.play();
        }
      },
    );
  }

  /// 进度条实现（支持拖拽）
  Widget _buildProgressBar() {
    final position = _isDragging && _dragPosition != null
        ? _dragPosition!
        : _position;
    final duration = _duration;

    if (duration == Duration.zero) {
      return const SizedBox.shrink();
    }

    final progress = position.inMilliseconds / duration.inMilliseconds;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 时间显示
        Text(
          '${_formatDuration(position)} / ${_formatDuration(duration)}',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        const SizedBox(height: 4),
        // 进度条
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: _progressHeight,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
            thumbColor: Colors.white,
            overlayColor: Colors.white.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: progress.clamp(0.0, 1.0),
            onChanged: (newProgress) {
              // 拖拽时实时更新
              setState(() {
                _isDragging = true;
                _dragPosition = Duration(
                  milliseconds: (newProgress * duration.inMilliseconds).round(),
                );
              });
            },
            onChangeEnd: (newProgress) async {
              final newPosition = Duration(
                milliseconds: (newProgress * duration.inMilliseconds).round(),
              );
              await widget.controller.seekTo(newPosition.inMilliseconds);
              setState(() {
                _isDragging = false;
                _dragPosition = null;
              });
            },
          ),
        ),
      ],
    );
  }

  /// 静音按钮
  Widget _buildMuteButton() {
    return IconButton(
      icon: Icon(
        widget.isMuted ? Icons.volume_off : Icons.volume_up,
        color: Colors.white,
        size: 24,
      ),
      onPressed: () async {
        final newMuted = !widget.isMuted;
        await widget.controller.setVolume(newMuted ? 0.0 : 1.0);
        widget.onMuteChanged(newMuted);
      },
    );
  }

  /// 格式化时长
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}
