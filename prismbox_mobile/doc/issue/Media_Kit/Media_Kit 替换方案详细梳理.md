## Media_Kit 替换方案详细梳理

### 一、架构对比分析

#### 1.1 video_player vs media_kit 核心差异

| 维度 | video_player | media_kit |
|------|-------------|-----------|
| 核心类 | `VideoPlayerController` | `Player` + `VideoController` |
| 状态管理 | `VideoPlayerValue` (ValueNotifier) | `PlayerState` (Stream) |
| 视频渲染 | `VideoPlayer` widget | `Video` widget |
| 初始化 | `controller.initialize()` | `player.open(Media(...))` |
| 状态监听 | `ValueListenableBuilder` | `StreamBuilder` 或 `PlayerStream` |
| 跨平台支持 | Android/iOS/Web | Android/iOS/macOS/Windows/Linux/Web |
| HDR 支持 | 不支持 | 原生支持（基于 FFmpeg/libmpv） |
| 格式支持 | 有限 | 广泛（FFmpeg 支持的所有格式） |

#### 1.2 media_kit 核心组件

```
Player (播放器核心)
  ├── PlayerState (播放状态流)
  ├── PlayerStream (各种状态流)
  └── 控制方法 (play, pause, seek, setVolume 等)

VideoController (视频渲染控制器)
  ├── 管理 Video widget 的渲染
  └── 与 Player 绑定

Video (视频渲染 Widget)
  ├── 渲染视频画面
  └── 支持自定义配置
```

### 二、API 映射关系

#### 2.1 控制器创建与初始化

**video_player 方式：**
```dart
// 创建控制器
final controller = VideoPlayerController.file(File(path));
// 或
final controller = VideoPlayerController.networkUrl(Uri.parse(url));

// 初始化
await controller.initialize();
```

**media_kit 方式：**
```dart
// 创建 Player
final player = Player();

// 打开媒体（自动初始化）
await player.open(Media(path)); // 本地文件
// 或
await player.open(Media(url));  // 网络 URL
```

#### 2.2 状态监听

**video_player 方式：**
```dart
ValueListenableBuilder<VideoPlayerValue>(
  valueListenable: controller,
  builder: (context, value, child) {
    // value.isPlaying, value.position, value.duration 等
  },
)
```

**media_kit 方式：**
```dart
// 方式1：使用 StreamBuilder
StreamBuilder<PlayerState>(
  stream: player.stream.playing,
  builder: (context, snapshot) {
    final isPlaying = snapshot.data ?? false;
  },
)

// 方式2：使用 PlayerStream（推荐，性能更好）
PlayerStream(
  player.stream.playing,
  builder: (context, isPlaying) {
    // 使用 isPlaying
  },
)
```

#### 2.3 播放控制

| 操作 | video_player | media_kit |
|------|-------------|-----------|
| 播放 | `controller.play()` | `player.play()` |
| 暂停 | `controller.pause()` | `player.pause()` |
| 跳转 | `controller.seekTo(position)` | `player.seek(Duration(...))` |
| 音量 | `controller.setVolume(0.0)` | `player.setVolume(0)` |
| 循环 | `controller.setLooping(true)` | `player.setPlaylistMode(PlaylistMode.loop)` |
| 获取位置 | `controller.value.position` | `player.state.position` |
| 获取时长 | `controller.value.duration` | `player.state.duration` |
| 获取宽高比 | `controller.value.aspectRatio` | 需要从 metadata 获取 |

#### 2.4 错误处理

**video_player：**
```dart
if (controller.value.hasError) {
  // 处理错误
}
```

**media_kit：**
```dart
player.stream.error.listen((error) {
  // 处理错误
});
```

### 三、实施架构设计

#### 3.1 依赖结构

```yaml
dependencies:
  # 核心库
  media_kit: ^1.2.0
  media_kit_video: ^1.3.0
  
  # 平台原生库（按需添加）
  media_kit_libs_android_video: any    # Android
  media_kit_libs_ios_video: any        # iOS
  media_kit_libs_macos_video: any      # macOS（如需要）
  media_kit_libs_windows_video: any    # Windows（如需要）
  media_kit_libs_linux: any            # Linux（如需要）
```

#### 3.2 初始化流程

**在 main.dart 中：**
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

#### 3.3 状态管理重构

**当前结构：**
```dart
Map<String, VideoPlayerController> _videoControllers = {};
```

**media_kit 结构：**
```dart
// 方案1：直接使用 Player（推荐）
Map<String, Player> _players = {};
Map<String, VideoController> _videoControllers = {}; // 用于渲染

// 方案2：封装为统一接口（更复杂但更灵活）
class MediaKitPlayerWrapper {
  final Player player;
  final VideoController videoController;
  // 封装常用方法，提供类似 video_player 的接口
}
```

#### 3.4 资源管理策略

**保持现有机制：**
- 可见页面范围管理（`_visiblePageIndices`）
- 即时释放不可见资源
- 页面切换时暂停并释放

**media_kit 特定处理：**
```dart
void _disposeVideoController(String assetId) {
  final player = _players.remove(assetId);
  final videoController = _videoControllers.remove(assetId);
  
  if (player != null) {
    player.dispose(); // 释放 Player
  }
  // VideoController 不需要单独 dispose，会随 Player 一起释放
}
```

### 四、UI 布局保持方案

#### 4.1 视频渲染 Widget 替换

**当前实现：**
```dart
VideoPlayer(videoController)
```

**media_kit 实现：**
```dart
Video(
  controller: videoController, // VideoController 实例
  // 可选配置
  fill: Colors.black, // 填充颜色
  fit: BoxFit.contain, // 适配方式
  // 禁用内置控制器（使用自定义控制器）
  controls: NoVideoControls,
)
```

#### 4.2 自定义控制器适配

**当前控制器结构：**
- `_VideoPlayerControls` Widget
- 接收 `VideoPlayerController`
- 使用 `ValueListenableBuilder` 监听状态

**media_kit 适配：**
```dart
class _VideoPlayerControls extends StatefulWidget {
  final Player player; // 改为接收 Player
  final VideoController? videoController; // 可选，用于获取宽高比
  // ... 其他参数保持不变
}

// 状态监听改为使用 PlayerStream
PlayerStream(
  player.stream.playing,
  builder: (context, isPlaying) {
    // 构建 UI
  },
)
```

#### 4.3 进度条实现

**video_player 方式：**
```dart
final position = controller.value.position;
final duration = controller.value.duration;
```

**media_kit 方式：**
```dart
// 使用 PlayerStream 监听位置和时长
Column(
  children: [
    PlayerStream(
      player.stream.position,
      builder: (context, position) {
        return PlayerStream(
          player.stream.duration,
          builder: (context, duration) {
            // 构建进度条
            final progress = duration > Duration.zero
                ? position.inMilliseconds / duration.inMilliseconds
                : 0.0;
            return Slider(...);
          },
        );
      },
    ),
  ],
)
```

#### 4.4 宽高比获取

**video_player：**
```dart
final aspectRatio = controller.value.aspectRatio;
```

**media_kit：**
```dart
// 方式1：从 metadata 获取（需要监听）
PlayerStream(
  player.stream.track,
  builder: (context, track) {
    if (track != null && track.video != null) {
      final video = track.video!;
      final aspectRatio = video.w / video.h;
      return AspectRatio(aspectRatio: aspectRatio, ...);
    }
    return AspectRatio(aspectRatio: 16/9, ...); // 默认值
  },
)

// 方式2：使用 VideoController 的配置（如果可用）
```

### 五、HDR 支持实现

#### 5.1 HDR 自动检测

**media_kit 特性：**
- 基于 FFmpeg/libmpv，自动识别 HDR 格式
- 在支持的设备上自动启用 HDR 渲染
- 无需额外配置

**检测 HDR 信息（可选）：**
```dart
// 获取视频轨道信息
PlayerStream(
  player.stream.track,
  builder: (context, track) {
    if (track?.video != null) {
      final video = track!.video!;
      // 检查是否为 HDR（通过色彩空间等信息）
      final isHdr = video.hdr != null; // 如果可用
      // 或通过其他 metadata 判断
    }
  },
)
```

#### 5.2 HDR 渲染配置

**Video widget 配置：**
```dart
Video(
  controller: videoController,
  // HDR 会自动处理，无需特殊配置
  // 但可以配置渲染选项
  fill: Colors.black,
  fit: BoxFit.contain,
)
```

### 六、性能优化策略

#### 6.1 状态监听优化

**问题：**
- `StreamBuilder` 可能触发频繁重建
- 多个 `PlayerStream` 嵌套可能影响性能

**解决方案：**
```dart
// 方案1：使用 PlayerStream（推荐，性能更好）
PlayerStream(
  player.stream.playing,
  builder: (context, isPlaying) {
    // 只重建必要的部分
  },
)

// 方案2：合并多个流（减少嵌套）
// 使用 RxDart 的 combineLatest 或自定义 Stream
```

#### 6.2 进度更新节流

**当前实现：**
```dart
Timer.periodic(Duration(milliseconds: 100), ...)
```

**media_kit 适配：**
```dart
// media_kit 的 position stream 本身有节流
// 但可以进一步优化
player.stream.position
  .throttleTime(Duration(milliseconds: 100)) // 如果使用 RxDart
  .listen((position) {
    // 更新 UI
  });
```

#### 6.3 RepaintBoundary 保持

```dart
RepaintBoundary(
  child: Video(
    controller: videoController,
    // ...
  ),
)
```

### 七、跨平台兼容性

#### 7.1 平台特定配置

**Android：**
- 需要 `media_kit_libs_android_video`
- 可能需要配置 `minSdkVersion`（建议 21+）

**iOS：**
- 需要 `media_kit_libs_ios_video`
- 可能需要配置权限（如果访问网络视频）

**Web：**
- 需要 `media_kit_libs_web_video`
- 可能需要 CORS 配置

#### 7.2 平台检测与降级

```dart
// 检测平台并选择合适配置
if (Platform.isAndroid) {
  // Android 特定配置
} else if (Platform.isIOS) {
  // iOS 特定配置
} else if (kIsWeb) {
  // Web 特定配置
}
```

### 八、实施步骤

#### 阶段1：依赖与初始化
1. 更新 `pubspec.yaml`，添加 media_kit 依赖
2. 在 `main.dart` 中初始化 `MediaKit.ensureInitialized()`
3. 移除 `video_player` 依赖

#### 阶段2：核心替换
1. 创建 `MediaKitPlayerWrapper`（可选，用于封装）
2. 替换 `VideoPlayerController` 为 `Player`
3. 替换 `VideoPlayer` 为 `Video`
4. 更新状态管理（`ValueListenableBuilder` → `PlayerStream`）

#### 阶段3：控制器适配
1. 更新 `_VideoPlayerControls` 接收 `Player`
2. 重构状态监听逻辑
3. 更新进度条实现
4. 更新播放/暂停/静音逻辑

#### 阶段4：资源管理
1. 更新 `_disposeVideoController` 方法
2. 更新 `_pauseAndReleaseVideo` 方法
3. 测试资源释放机制

#### 阶段5：测试与优化
1. 测试本地视频播放
2. 测试网络视频播放
3. 测试 HDR 视频播放（如有设备）
4. 测试页面切换资源释放
5. 性能测试与优化

### 九、潜在问题与解决方案

#### 9.1 宽高比获取延迟

**问题：** media_kit 的宽高比需要从 metadata 获取，可能有延迟

**解决：**
- 使用默认宽高比（16:9）作为初始值
- 监听 `player.stream.track` 获取实际宽高比
- 使用 `VideoController` 的配置（如果可用）

#### 9.2 状态同步

**问题：** `PlayerState` 是 Stream，与 `ValueNotifier` 不同

**解决：**
- 使用 `PlayerStream` 替代 `ValueListenableBuilder`
- 合并多个流以减少嵌套
- 使用状态管理库（如 Riverpod）缓存状态

#### 9.3 初始化时机

**问题：** `player.open()` 是异步的，需要等待

**解决：**
- 使用 `FutureBuilder` 或状态管理
- 显示加载指示器
- 处理初始化错误

### 十、代码结构建议

#### 10.1 封装层设计（可选但推荐）

```dart
// lib/features/media_loading/media_kit_player_wrapper.dart
class MediaKitPlayerWrapper {
  final Player player;
  final VideoController videoController;
  final String assetId;
  
  // 封装常用方法
  Future<void> initialize();
  void play();
  void pause();
  void seek(Duration position);
  void setVolume(double volume);
  void setLooping(bool looping);
  
  // 状态流
  Stream<bool> get playingStream;
  Stream<Duration> get positionStream;
  Stream<Duration> get durationStream;
}
```

#### 10.2 状态管理优化

```dart
// 使用 Riverpod 管理 Player 状态
final videoPlayerProvider = StateNotifierProvider.family<
  VideoPlayerNotifier,
  VideoPlayerState,
  String
>((ref, assetId) {
  return VideoPlayerNotifier(assetId);
});
```

### 十一、总结

**优势：**
- 原生 HDR 支持
- 跨平台兼容性好
- 格式支持广泛
- 性能较好

**挑战：**
- API 差异较大，需要重构
- 状态管理方式不同
- 学习成本较高

**建议：**
- 先实现封装层，统一接口
- 逐步迁移，保持向后兼容
- 充分测试各平台
- 关注性能指标
