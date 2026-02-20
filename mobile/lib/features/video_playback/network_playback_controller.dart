// lib/features/video_playback/network_playback_controller.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:video_player/video_player.dart';
import 'package:prismbox/features/video_playback/viewer_playback_controller.dart';

final Logger _log = Logger('NetworkPlaybackController');

/// 基于 video_player 的网络播放控制器，支持自定义 HTTP 头（认证）。
class NetworkPlaybackController extends ViewerPlaybackController {
  NetworkPlaybackController._({
    required String url,
    required Map<String, String> headers,
  }) {
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      httpHeaders: headers,
    );
    _controller!.addListener(_onControllerUpdate);
    unawaited(_controller!.initialize().then((_) {
      _notifyStatus();
    }).catchError((e, st) {
      _log.severe('Failed to initialize network video', e, st);
      _notifyStatus();
    }));
  }

  VideoPlayerController? _controller;
  final List<VoidCallback> _positionListeners = [];
  final List<VoidCallback> _statusListeners = [];

  static Future<NetworkPlaybackController> fromNetwork({
    required String url,
    required Map<String, String> headers,
  }) async {
    return NetworkPlaybackController._(url: url, headers: headers);
  }

  void _onControllerUpdate() {
    _notifyPosition();
    _notifyStatus();
  }

  void _notifyPosition() {
    for (final l in List<VoidCallback>.from(_positionListeners)) {
      l();
    }
  }

  void _notifyStatus() {
    for (final l in List<VoidCallback>.from(_statusListeners)) {
      l();
    }
  }

  @override
  Duration get position => _controller?.value.position ?? Duration.zero;

  @override
  Duration get duration => _controller?.value.duration ?? Duration.zero;

  @override
  bool get isPlaying => _controller?.value.isPlaying ?? false;

  @override
  bool get isReady => _controller?.value.isInitialized ?? false;

  @override
  Future<void> play() => _controller?.play() ?? Future.value();

  @override
  Future<void> pause() => _controller?.pause() ?? Future.value();

  @override
  Future<void> seekTo(Duration position) =>
      _controller?.seekTo(position) ?? Future.value();

  @override
  Future<void> setVolume(double volume) =>
      _controller?.setVolume(volume.clamp(0.0, 1.0)) ?? Future.value();

  @override
  Future<void> setLoop(bool loop) =>
      _controller?.setLooping(loop) ?? Future.value();

  @override
  void addPositionListener(VoidCallback listener) {
    _positionListeners.add(listener);
  }

  @override
  void removePositionListener(VoidCallback listener) {
    _positionListeners.remove(listener);
  }

  @override
  void addStatusListener(VoidCallback listener) {
    _statusListeners.add(listener);
  }

  @override
  void removeStatusListener(VoidCallback listener) {
    _statusListeners.remove(listener);
  }

  @override
  Widget buildVideoView() {
    final c = _controller;
    if (c == null) return const SizedBox.expand(child: Center(child: CircularProgressIndicator(color: Colors.white)));
    return VideoPlayer(c);
  }

  @override
  Future<void> dispose() async {
    final c = _controller;
    if (c != null) {
      c.removeListener(_onControllerUpdate);
      await c.dispose();
    }
    _controller = null;
    _positionListeners.clear();
    _statusListeners.clear();
  }
}
