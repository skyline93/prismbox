// lib/features/video_playback/viewer_playback_controller.dart

import 'package:flutter/material.dart';

/// 视频播放控制器抽象
///
/// 供媒体查看器与控制栏使用，不依赖具体播放引擎（native_video_player / video_player）。
/// 实现类：NativePlaybackController（本地文件）、NetworkPlaybackController（远程 URL+headers）。
abstract class ViewerPlaybackController {
  /// 当前播放位置
  Duration get position;

  /// 总时长（未就绪时为 Duration.zero）
  Duration get duration;

  /// 是否正在播放
  bool get isPlaying;

  /// 是否已就绪（可 seek、可读 duration）
  bool get isReady;

  /// 播放
  Future<void> play();

  /// 暂停
  Future<void> pause();

  /// 跳转到指定位置
  Future<void> seekTo(Duration position);

  /// 设置音量 0.0 ~ 1.0
  Future<void> setVolume(double volume);

  /// 设置是否循环（如 Live Photo 不循环）
  Future<void> setLoop(bool loop);

  /// 进度变化时通知
  void addPositionListener(VoidCallback listener);
  void removePositionListener(VoidCallback listener);

  /// 状态变化时通知（播放/暂停、就绪等）
  void addStatusListener(VoidCallback listener);
  void removeStatusListener(VoidCallback listener);

  /// 构建视频画面 Widget（由各实现返回自己的 View）
  Widget buildVideoView();

  /// 释放资源
  Future<void> dispose();
}
