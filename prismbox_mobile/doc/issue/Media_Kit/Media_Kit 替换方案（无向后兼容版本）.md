## Media_Kit 替换方案（无向后兼容版本）

### 一、核心架构简化

#### 1.1 直接使用 media_kit 原生 API

**状态管理结构：**
```dart
// 直接使用 Player 和 VideoController，无需封装
Map<String, Player> _players = {};
Map<String, VideoController> _videoControllers = {}; // 用于渲染
Map<String, bool> _videoMutedStates = {}; // 静音状态
```

**优势：**
- 代码更简洁，减少抽象层
- 直接使用 media_kit 特性
- 维护成本更低

### 二、API 直接替换映射

#### 2.1 控制器创建（直接替换）

**替换前（video_player）：**
```dart
final controller = VideoPlayerController.file(File(path));
await controller.initialize();
```

**替换后（media_kit）：**
```dart
final player = Player();
final videoController = VideoController(player);
await player.open(Media(path));
```

#### 2.2 状态监听（直接使用 PlayerStream）

**替换前：**
```dart
ValueListenableBuilder<VideoPlayerValue>(
  valueListenable: controller,
  builder: (context, value, child) {
    // 使用 value.isPlaying, value.position 等
  },
)
```

**替换后：**
```dart
// 直接使用 PlayerStream，无需封装
PlayerStream(
  player.stream.playing,
  builder: (context, isPlaying) {
    // 使用 isPlaying
  },
)
```

#### 2.3 播放控制（直接调用 Player 方法）

| 操作 | 替换前 | 替换后 |
|------|--------|--------|
| 播放 | `controller.play()` | `player.play()` |
| 暂停 | `controller.pause()` | `player.pause()` |
| 跳转 | `controller.seekTo(position)` | `player.seek(position)` |
| 音量 | `controller.setVolume(0.0)` | `player.setVolume(0)` |
| 循环 | `controller.setLooping(true)` | `player.setPlaylistMode(PlaylistMode.loop)` |
| 获取位置 | `controller.value.position` | `player.state.position` |
| 获取时长 | `controller.value.duration` | `player.state.duration` |

### 三、实施架构（简化版）

#### 3.1 依赖结构

```yaml
dependencies:
  # 核心库
  media_kit: ^1.2.0
  media_kit_video: ^1.3.0
  
  # 平台原生库（仅添加需要的平台）
  media_kit_libs_android_video: any    # Android
  media_kit_libs_ios_video: any        # iOS
  # 其他平台按需添加
```

#### 3.2 初始化（在 main.dart）

```dart
void main() async {
  // 1. 初始化 media_kit（必须在 runApp 之前）
  MediaKit.ensureInitialized();
  
  // 2. 其他初始化...
  await DatabaseConnection.initializeDatabaseIsolate();
  
  // 3. 运行应用
  runApp(...);
}
```

#### 3.3 状态管理（直接使用）

```dart
class _MediaViewerPageState extends ConsumerState<MediaViewerPage> {
  // 直接使用 Player 和 VideoController
  final Map<String, Player> _players = {};
  final Map<String, VideoController> _videoControllers = {};
  final Map<String, bool> _videoMutedStates = {};
  
  // 其他状态保持不变
  int _currentPageIndex = 0;
  Set<int> _visiblePageIndices = {};
  String? _currentVideoAssetId;
}
```

#### 3.4 资源管理（直接 dispose）

```dart
void _disposeVideoController(String assetId) {
  final player = _players.remove(assetId);
  final videoController = _videoControllers.remove(assetId);
  
  // 直接 dispose，无需封装
  player?.dispose();
  // VideoController 会自动释放，无需手动 dispose
  
  _videoMutedStates.remove(assetId);
  if (_currentVideoAssetId == assetId) {
    _currentVideoAssetId = null;
  }
}
```

### 四、UI 布局直接替换

#### 4.1 视频渲染 Widget

**替换前：**
```dart
VideoPlayer(videoController)
```

**替换后：**
```dart
Video(
  controller: videoController, // VideoController 实例
  fill: Colors.black,
  fit: BoxFit.contain,
  controls: NoVideoControls, // 禁用内置控制器
)
```

#### 4.2 自定义控制器（直接使用 Player）

```dart
class _VideoPlayerControls extends StatefulWidget {
  final Player player; // 直接接收 Player
  final VideoController? videoController; // 用于获取宽高比
  final bool showControls;
  final bool isMuted;
  final ValueChanged<bool> onMuteChanged;
  final VoidCallback? onTap;

  const _VideoPlayerControls({
    required this.player,
    this.videoController,
    required this.showControls,
    required this.isMuted,
    required this.onMuteChanged,
    this.onTap,
  });
}
```

#### 4.3 状态监听（使用 PlayerStream）

```dart
@override
Widget build(BuildContext context) {
  if (!widget.showControls) {
    return const SizedBox.shrink();
  }

  return RepaintBoundary(
    child: GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
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
            _buildPlayPauseButton(),
            
            const SizedBox(width: 12),
            
            // 进度条
            Expanded(child: _buildProgressBar()),
            
            const SizedBox(width: 12),
            
            // 静音按钮
            _buildMuteButton(),
          ],
        ),
      ),
    ),
  );
}

// 播放/暂停按钮
Widget _buildPlayPauseButton() {
  return PlayerStream(
    widget.player.stream.playing,
    builder: (context, isPlaying) {
      return IconButton(
        icon: Icon(
          isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: 28,
        ),
        onPressed: () {
          if (isPlaying) {
            widget.player.pause();
          } else {
            widget.player.play();
          }
        },
      );
    },
  );
}

// 进度条
Widget _buildProgressBar() {
  return PlayerStream(
    widget.player.stream.position,
    builder: (context, position) {
      return PlayerStream(
        widget.player.stream.duration,
        builder: (context, duration) {
          final progress = duration > Duration.zero
              ? position.inMilliseconds / duration.inMilliseconds
              : 0.0;
          
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
                  trackHeight: 4.0,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                ),
                child: Slider(
                  value: progress.clamp(0.0, 1.0),
                  onChanged: (newProgress) {
                    final newPosition = Duration(
                      milliseconds: (newProgress * duration.inMilliseconds).round(),
                    );
                    widget.player.seek(newPosition);
                  },
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

// 静音按钮
Widget _buildMuteButton() {
  return IconButton(
    icon: Icon(
      widget.isMuted ? Icons.volume_off : Icons.volume_up,
      color: Colors.white,
      size: 24,
    ),
    onPressed: () {
      final newMuted = !widget.isMuted;
      widget.player.setVolume(newMuted ? 0 : 100);
      widget.onMuteChanged(newMuted);
    },
  );
}
```

#### 4.4 宽高比获取（监听 track stream）

```dart
Widget _buildVideoPlayerWidget(String assetId) {
  final player = _players[assetId];
  final videoController = _videoControllers[assetId];
  
  if (player == null || videoController == null) {
    return const Center(
      child: CircularProgressIndicator(color: Colors.white),
    );
  }

  return GestureDetector(
    onTap: _toggleControls,
    child: Stack(
      fit: StackFit.expand,
      children: [
        // 视频播放区域（使用 PlayerStream 获取宽高比）
        Center(
          child: PlayerStream(
            player.stream.track,
            builder: (context, track) {
              final aspectRatio = (track?.video != null)
                  ? track!.video!.w / track.video!.h
                  : 16 / 9; // 默认值
              
              return AspectRatio(
                aspectRatio: aspectRatio,
                child: Video(
                  controller: videoController,
                  fill: Colors.black,
                  fit: BoxFit.contain,
                  controls: NoVideoControls,
                ),
              );
            },
          ),
        ),

        // 错误处理
        PlayerStream(
          player.stream.error,
          builder: (context, error) {
            if (error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      '播放失败: ${error.toString()}',
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),

        // 自定义控制器
        Positioned(
          bottom: _getBottomBarHeight() + 16,
          left: 0,
          right: 0,
          child: _VideoPlayerControls(
            player: player,
            videoController: videoController,
            showControls: _showControls,
            isMuted: _videoMutedStates[assetId] ?? true,
            onMuteChanged: (muted) {
              setState(() {
                _videoMutedStates[assetId] = muted;
              });
            },
            onTap: _toggleControls,
          ),
        ),
      ],
    ),
  );
}
```

### 五、视频创建逻辑（直接替换）

```dart
Widget _createVideoPlayer(VideoSource videoSource, String assetId) {
  // 如果已有播放器，直接使用
  if (_players.containsKey(assetId)) {
    return _buildVideoPlayerWidget(assetId);
  }

  // 创建新的 Player 和 VideoController
  final player = Player();
  final videoController = VideoController(player);

  _players[assetId] = player;
  _videoControllers[assetId] = videoController;
  _videoMutedStates[assetId] = true; // 默认静音

  // 打开媒体（自动初始化）
  final media = videoSource.type == VideoSourceType.file
      ? Media(videoSource.source)
      : Media(videoSource.source);

  player.open(media).then((_) {
    if (mounted) {
      // 设置默认静音
      player.setVolume(0);

      // 如果是当前视频，自动播放
      if (assetId == _currentVideoAssetId) {
        player.play();
      }

      // 设置循环播放
      player.setPlaylistMode(PlaylistMode.loop);

      // 触发重建
      setState(() {});
    }
  }).catchError((error) {
    // 错误处理
    if (mounted) {
      setState(() {});
    }
  });

  // 返回加载中的 Widget
  return _buildVideoPlayerWidget(assetId);
}
```

### 六、播放控制方法（直接替换）

```dart
/// 播放视频
void _playVideo(String assetId) {
  final player = _players[assetId];
  if (player != null) {
    player.play();
  }
}

/// 暂停视频
void _pauseVideo(String assetId) {
  final player = _players[assetId];
  if (player != null) {
    player.pause();
  }
}

/// 暂停并释放视频
void _pauseAndReleaseVideo(String assetId, {required bool keepIfVisible}) {
  final player = _players[assetId];
  if (player == null) {
    return;
  }

  // 暂停播放
  player.pause();

  // 如果不在可见范围内，完全释放
  if (!keepIfVisible) {
    _disposeVideoController(assetId);
  }
}
```

### 七、HDR 支持（自动处理）

**media_kit 自动支持 HDR：**
- 基于 FFmpeg/libmpv，自动识别 HDR 格式
- 在支持的设备上自动启用 HDR 渲染
- 无需额外配置，直接使用即可

**可选：检测 HDR 信息**
```dart
PlayerStream(
  player.stream.track,
  builder: (context, track) {
    if (track?.video != null) {
      final video = track!.video!;
      // 可以检查视频信息（如果需要显示 HDR 标识等）
      // HDR 会自动渲染，无需手动处理
    }
    return Container();
  },
)
```

### 八、实施步骤（简化版）

#### 阶段1：依赖与初始化
1. 更新 `pubspec.yaml`，移除 `video_player`，添加 `media_kit` 相关依赖
2. 在 `main.dart` 中添加 `MediaKit.ensureInitialized()`
3. 运行 `flutter pub get`

#### 阶段2：核心替换
1. 替换导入：`video_player` → `media_kit` + `media_kit_video`
2. 替换状态管理：`Map<String, VideoPlayerController>` → `Map<String, Player>` + `Map<String, VideoController>`
3. 替换视频创建逻辑：`VideoPlayerController` → `Player` + `VideoController`
4. 替换视频渲染：`VideoPlayer` → `Video`

#### 阶段3：状态监听替换
1. 替换 `ValueListenableBuilder` → `PlayerStream`
2. 更新控制器 Widget：接收 `Player` 而非 `VideoPlayerController`
3. 更新进度条：使用 `PlayerStream` 监听 `position` 和 `duration`
4. 更新播放控制：直接调用 `Player` 方法

#### 阶段4：资源管理更新
1. 更新 `_disposeVideoController`：直接 `player.dispose()`
2. 更新 `_pauseAndReleaseVideo`：使用 `player.pause()`
3. 测试资源释放机制

#### 阶段5：测试与优化
1. 测试本地视频播放
2. 测试网络视频播放
3. 测试 HDR 视频播放（如有设备）
4. 测试页面切换资源释放
5. 性能测试与优化

### 九、关键改动点总结

#### 9.1 必须修改的地方

1. **导入语句**
   ```dart
   // 移除
   import 'package:video_player/video_player.dart';
   
   // 添加
   import 'package:media_kit/media_kit.dart';
   import 'package:media_kit_video/media_kit_video.dart';
   ```

2. **状态管理**
   ```dart
   // 替换
   final Map<String, VideoPlayerController> _videoControllers = {};
   
   // 为
   final Map<String, Player> _players = {};
   final Map<String, VideoController> _videoControllers = {};
   ```

3. **视频创建**
   ```dart
   // 替换 VideoPlayerController 创建逻辑
   // 为 Player + VideoController 创建逻辑
   ```

4. **状态监听**
   ```dart
   // 替换所有 ValueListenableBuilder
   // 为 PlayerStream
   ```

5. **播放控制**
   ```dart
   // 替换所有 controller.xxx()
   // 为 player.xxx()
   ```

#### 9.2 保持不变的部分

- UI 布局结构（Stack、Positioned 等）
- 资源释放机制（可见页面范围管理）
- 控制栏显示/隐藏逻辑
- 页面切换处理逻辑
- 性能优化策略（RepaintBoundary 等）

### 十、注意事项

1. **初始化顺序**：`MediaKit.ensureInitialized()` 必须在 `runApp()` 之前调用
2. **宽高比获取**：需要监听 `player.stream.track`，可能有延迟，使用默认值作为初始值
3. **错误处理**：使用 `PlayerStream` 监听 `player.stream.error`
4. **音量范围**：media_kit 的音量范围是 0-100，不是 0.0-1.0
5. **循环播放**：使用 `player.setPlaylistMode(PlaylistMode.loop)` 而不是 `setLooping()`

### 十一、优势总结

**简化后的优势：**
- 代码更简洁，无额外抽象层
- 直接使用 media_kit 特性，性能更好
- 维护成本更低，减少中间层
- 更容易利用 media_kit 的高级功能
- HDR 支持开箱即用

**实施建议：**
- 一次性完整替换，无需分阶段兼容
- 充分测试各平台功能
- 关注性能指标，确保流畅度
- 利用 media_kit 的丰富功能（如字幕、多音轨等）

该方案已移除所有向后兼容性考虑，直接使用 media_kit 原生 API，实施更直接。需要我开始实施代码吗？