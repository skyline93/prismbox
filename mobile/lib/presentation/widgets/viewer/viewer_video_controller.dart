import 'dart:async';
import 'package:flutter/material.dart';
import 'package:prismbox/features/video_playback/viewer_playback_controller.dart';

/// 视频播放器控制器 UI 组件
///
/// 封装视频播放控制逻辑（播放/暂停、进度条、静音等）。
/// 仅依赖 ViewerPlaybackController 接口，支持 Native 与 Network 两种引擎。
class VideoPlayerControls extends StatefulWidget {
  final ViewerPlaybackController playbackController;
  final bool showControls;
  final bool isMuted;
  final ValueChanged<bool> onMuteChanged;
  final VoidCallback? onTap;

  const VideoPlayerControls({
    super.key,
    required this.playbackController,
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

  static const double _progressHeight = 4.0;
  static const double _horizontalPadding = 16.0;

  void _onUpdate() {
    if (mounted && !_isDragging) {
      setState(() {
        _position = widget.playbackController.position;
        _duration = widget.playbackController.duration;
        _isPlaying = widget.playbackController.isPlaying;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.isMuted) {
      widget.playbackController.setVolume(0.0);
    }
    widget.playbackController.addPositionListener(_onUpdate);
    widget.playbackController.addStatusListener(_onUpdate);
    _startProgressTimer();
    _onUpdate();
  }

  @override
  void didUpdateWidget(VideoPlayerControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playbackController != widget.playbackController) {
      oldWidget.playbackController.removePositionListener(_onUpdate);
      oldWidget.playbackController.removeStatusListener(_onUpdate);
      widget.playbackController.addPositionListener(_onUpdate);
      widget.playbackController.addStatusListener(_onUpdate);
    }
    if (oldWidget.isMuted != widget.isMuted) {
      widget.playbackController.setVolume(widget.isMuted ? 0.0 : 1.0);
    }
    _onUpdate();
  }

  @override
  void dispose() {
    widget.playbackController.removePositionListener(_onUpdate);
    widget.playbackController.removeStatusListener(_onUpdate);
    _progressUpdateTimer?.cancel();
    super.dispose();
  }

  void _startProgressTimer() {
    _progressUpdateTimer?.cancel();
    _progressUpdateTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted && !_isDragging) _onUpdate();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showControls) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
        decoration: BoxDecoration(
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
            _buildPlayPauseButton(_isPlaying),
            const SizedBox(width: 12),
            Expanded(child: _buildProgressBar()),
            const SizedBox(width: 12),
            _buildMuteButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayPauseButton(bool isPlaying) {
    return IconButton(
      icon: Icon(
        isPlaying ? Icons.pause : Icons.play_arrow,
        color: Colors.white,
        size: 28,
      ),
      onPressed: () async {
        if (isPlaying) {
          await widget.playbackController.pause();
        } else {
          await widget.playbackController.play();
        }
      },
    );
  }

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
        Text(
          '${_formatDuration(position)} / ${_formatDuration(duration)}',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        const SizedBox(height: 4),
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
              await widget.playbackController.seekTo(newPosition);
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

  Widget _buildMuteButton() {
    return IconButton(
      icon: Icon(
        widget.isMuted ? Icons.volume_off : Icons.volume_up,
        color: Colors.white,
        size: 24,
      ),
      onPressed: () async {
        final newMuted = !widget.isMuted;
        await widget.playbackController.setVolume(newMuted ? 0.0 : 1.0);
        widget.onMuteChanged(newMuted);
      },
    );
  }

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
