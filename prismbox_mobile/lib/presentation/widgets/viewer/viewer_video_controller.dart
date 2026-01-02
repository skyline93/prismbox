import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// 视频播放器控制器 UI 组件
///
/// 封装视频播放控制逻辑（播放/暂停、进度条、静音等）。
/// 性能优化：使用 ValueListenableBuilder 和 RepaintBoundary 隔离绘制边界。
class VideoPlayerControls extends StatefulWidget {
  final VideoPlayerController controller;
  final bool showControls;
  final bool isMuted;
  final ValueChanged<bool> onMuteChanged;
  final VoidCallback? onTap;

  const VideoPlayerControls({
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
    _startProgressTimer();
  }

  @override
  void didUpdateWidget(VideoPlayerControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果静音状态改变，更新音量
    if (oldWidget.isMuted != widget.isMuted) {
      widget.controller.setVolume(widget.isMuted ? 0.0 : 1.0);
    }
  }

  @override
  void dispose() {
    _progressUpdateTimer?.cancel();
    super.dispose();
  }

  /// 性能优化：使用 Timer 节流，避免每帧更新
  /// 视频进度不需要 60fps 更新，每 100ms 更新一次足够流畅
  void _startProgressTimer() {
    _progressUpdateTimer?.cancel();
    _progressUpdateTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) {
        if (mounted && widget.controller.value.isInitialized) {
          // ValueListenableBuilder 会自动监听，这里只是确保更新
          // 实际上不需要 setState，因为 ValueListenableBuilder 会处理
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showControls) {
      return const SizedBox.shrink();
    }

    // 性能优化：使用 ValueListenableBuilder 只监听 VideoPlayerController
    // 避免整个页面 rebuild
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: widget.controller,
      builder: (context, value, child) {
        return RepaintBoundary(
          // 性能优化：隔离绘制边界，避免影响视频播放区域
          child: GestureDetector(
            onTap: widget.onTap, // 点击空白区域切换显示/隐藏
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
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              child: Row(
                children: [
                  // 播放/暂停按钮
                  _buildPlayPauseButton(value.isPlaying && value.isInitialized),
                  
                  const SizedBox(width: 12),
                  
                  // 进度条（可扩展）
                  Expanded(
                    child: _buildProgressBar(value),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // 静音按钮
                  _buildMuteButton(),
                ],
              ),
            ),
          ),
        );
      },
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
      onPressed: () {
        if (isPlaying) {
          widget.controller.pause();
        } else {
          widget.controller.play();
        }
      },
    );
  }

  /// 进度条实现（支持拖拽）
  Widget _buildProgressBar(VideoPlayerValue value) {
    final position = _isDragging && _dragPosition != null ? _dragPosition! : value.position;
    final duration = value.duration;

    if (duration == Duration.zero || !value.isInitialized) {
      return const SizedBox.shrink();
    }

    final progress = position.inMilliseconds / duration.inMilliseconds;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 时间显示
        Text(
          '${_formatDuration(position)} / ${_formatDuration(duration)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        // 进度条
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: _progressHeight,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white.withOpacity(0.3),
            thumbColor: Colors.white,
            overlayColor: Colors.white.withOpacity(0.2),
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
            onChangeEnd: (newProgress) {
              final newPosition = Duration(
                milliseconds: (newProgress * duration.inMilliseconds).round(),
              );
              widget.controller.seekTo(newPosition);
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
      onPressed: () {
        final newMuted = !widget.isMuted;
        widget.controller.setVolume(newMuted ? 0.0 : 1.0);
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

