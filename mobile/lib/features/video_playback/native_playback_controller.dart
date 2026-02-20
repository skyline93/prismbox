// lib/features/video_playback/native_playback_controller.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:native_video_player/native_video_player.dart';
import 'package:prismbox/features/video_playback/viewer_playback_controller.dart';

final Logger _log = Logger('NativePlaybackController');

/// 基于 native_video_player 的播放控制器，仅支持本地文件路径。
class NativePlaybackController extends ViewerPlaybackController {
  NativePlaybackController._(this._path);

  final String _path;
  NativeVideoPlayerController? _nativeController;
  final List<VoidCallback> _positionListeners = [];
  final List<VoidCallback> _statusListeners = [];

  static Future<NativePlaybackController> fromFile(String path) async {
    return NativePlaybackController._(path);
  }

  void _onViewReady(NativeVideoPlayerController controller) {
    if (_nativeController != null) return;
    _nativeController = controller;
    _setupListeners();
    unawaited(_loadSource());
  }

  Future<void> _loadSource() async {
    final nc = _nativeController;
    if (nc == null) return;
    try {
      final source = await VideoSource.init(path: _path, type: VideoSourceType.file);
      await nc.loadVideoSource(source);
    } catch (e, st) {
      _log.severe('Failed to load local video source', e, st);
      _notifyStatus();
    }
  }

  void _setupListeners() {
    final nc = _nativeController;
    if (nc == null) return;
    nc.onPlaybackStatusChanged.addListener(_notifyStatus);
    nc.onPlaybackPositionChanged.addListener(_notifyPosition);
    nc.onPlaybackReady.addListener(_notifyStatus);
    nc.onPlaybackEnded.addListener(_notifyStatus);
  }

  void _removeListeners() {
    final nc = _nativeController;
    if (nc == null) return;
    nc.onPlaybackStatusChanged.removeListener(_notifyStatus);
    nc.onPlaybackPositionChanged.removeListener(_notifyPosition);
    nc.onPlaybackReady.removeListener(_notifyStatus);
    nc.onPlaybackEnded.removeListener(_notifyStatus);
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
  Duration get position {
    final info = _nativeController?.playbackInfo;
    if (info == null) return Duration.zero;
    return Duration(milliseconds: info.position);
  }

  @override
  Duration get duration {
    final info = _nativeController?.videoInfo;
    if (info == null) return Duration.zero;
    return Duration(milliseconds: info.duration);
  }

  @override
  bool get isPlaying {
    final info = _nativeController?.playbackInfo;
    return info?.status == PlaybackStatus.playing;
  }

  @override
  bool get isReady {
    final nc = _nativeController;
    if (nc == null) return false;
    return nc.playbackInfo != null && nc.videoInfo != null;
  }

  @override
  Future<void> play() => _nativeController?.play() ?? Future.value();

  @override
  Future<void> pause() => _nativeController?.pause() ?? Future.value();

  @override
  Future<void> seekTo(Duration position) =>
      _nativeController?.seekTo(position.inMilliseconds) ?? Future.value();

  @override
  Future<void> setVolume(double volume) =>
      _nativeController?.setVolume(volume) ?? Future.value();

  @override
  Future<void> setLoop(bool loop) =>
      _nativeController?.setLoop(loop) ?? Future.value();

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
    return NativeVideoPlayerView(
      key: ValueKey('native_$_path'),
      onViewReady: _onViewReady,
    );
  }

  @override
  Future<void> dispose() async {
    _removeListeners();
    _positionListeners.clear();
    _statusListeners.clear();
    _nativeController = null;
  }
}
