## Media_Kit 替换方案详细梳理（无向后兼容版本）

### 一、架构对比分析

#### 1.1 video_player vs media_kit 核心差异

| 维度 | video_player | media_kit |
|------|-------------|-----------|
| 核心类 | `VideoPlayerController` | `Player` + `VideoController` |
| 状态管理 | `VideoPlayerValue` (ValueNotifier) | `PlayerState` (Stream) |
| 视频渲染 | `VideoPlayer` widget | `Video` widget |
| 初始化 | `controller.initialize()` | `player.open(Media(...))` |
| 状态监听 | `ValueListenableBuilder` | `PlayerStream`（推荐） |
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

### 二、API 映射关系（直接替换）

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

**media_kit 方式（直接替换）：**
```dart
// 创建 Player 和 VideoController
final player = Player();
final videoController = VideoController(player);

// 打开媒体（自动初始化）
await player.open(Media(path)); // 本地文件
// 或
await player.open(Media(url));  // 网络 URL
```

#### 2.2 状态监听（直接使用 PlayerStream）

**video_player 方式：**
```dart
ValueListenableBuilder<VideoPlayerValue>(
  valueListenable: controller,
  builder: (context, value, child) {
    // value.isPlaying, value.position, value.duration 等
  },
)
```

**media_kit 方式（直接替换）：**
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

| 操作 | video_player | media_kit |
|------|-------------|-----------|
| 播放 | `controller.play()` | `player.play()` |
| 暂停 | `controller.pause()` | `player.pause()` |
| 跳转 | `controller.seekTo(position)` | `player.seek(position)` |
| 音量 | `controller.setVolume(0.0)` | `player.setVolume(0)`（范围 0-100） |
| 循环 | `controller.setLooping(true)` | `player.setPlaylistMode(PlaylistMode.loop)` |
| 获取位置 | `controller.value.position` | `player.state.position` |
| 获取时长 | `controller.value.duration` | `player.state.duration` |
| 获取宽高比 | `controller.value.aspectRatio` | 从 `player.stream.track` 获取 |

#### 2.4 错误处理

**video_player：**
```dart
if (controller.value.hasError) {
  // 处理错误
}
```

**media_kit：**
```dart
// 使用 PlayerStream 监听错误
PlayerStream(
  player.stream.error,
  builder: (context, error) {
    if (error != null) {
      // 处理错误
    }
    return const SizedBox.shrink();
  },
)
```

### 三、实施架构设计（简化版）

#### 3.1 依赖结构

```yaml
dependencies:
  # 核心库
  media_kit: ^1.2.0
  media_kit_video: ^1.3.0
  
  # 平台原生库（仅添加需要的平台）
  media_kit_libs_android_video: any    # Android
  media_kit_libs_ios_video: any        # iOS
  # macOS/Windows/Linux 按需添加
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

#### 3.3 状态管理（直接使用，无需封装）

**当前结构：**
```dart
Map<String, VideoPlayerController> _videoControllers = {};
```

**media_kit 结构（直接替换）：**
```dart
// 直接使用 Player 和 VideoController，无需封装层
Map<String, Player> _players = {};
Map<String, VideoController> _videoControllers = {}; // 用于渲染
Map<String, bool> _videoMutedStates = {}; // 静音状态
```

**优势：**
- 代码更简洁，减少抽象层
- 直接使用 media_kit 特性
- 维护成本更低
- 性能更好（无中间层开销）

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
  
  // 直接 dispose Player
  if (player != null) {
    player.dispose();
  }
  // VideoController 不需要单独 dispose，会随 Player 一起释放
  
  // 清理相关状态
  _videoMutedStates.remove(assetId);
  if (_currentVideoAssetId == assetId) {
    _currentVideoAssetId = null;
  }
}
```

### 四、UI 布局保持方案

#### 4.1 视频渲染 Widget 替换

**当前实现：**
```dart
VideoPlayer(videoController)
```

**media_kit 实现（直接替换）：**
```dart
Video(
  controller: videoController, // VideoController 实例
  fill: Colors.black, // 填充颜色
  fit: BoxFit.contain, // 适配方式
  controls: NoVideoControls, // 禁用内置控制器（使用自定义控制器）
)
```

#### 4.2 自定义控制器（直接使用 Player）

**当前控制器结构：**
- `_VideoPlayerControls` Widget
- 接收 `VideoPlayerController`
- 使用 `ValueListenableBuilder` 监听状态

**media_kit 适配（直接替换）：**
```dart
class _VideoPlayerControls extends StatefulWidget {
  final Player player; // 直接接收 Player
  final VideoController? videoController; // 可选，用于获取宽高比
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

// 状态监听直接使用 PlayerStream
PlayerStream(
  player.stream.playing,
  builder: (context, isPlaying) {
    // 构建 UI
  },
)
```

#### 4.3 进度条实现（使用 PlayerStream）

**video_player 方式：**
```dart
final position = controller.value.position;
final duration = controller.value.duration;
```

**media_kit 方式（直接替换）：**
```dart
// 使用 PlayerStream 监听位置和时长
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
        return Slider(
          value: progress.clamp(0.0, 1.0),
          onChanged: (newProgress) {
            final newPosition = Duration(
              milliseconds: (newProgress * duration.inMilliseconds).round(),
            );
            player.seek(newPosition);
          },
        );
      },
    );
  },
)
```

#### 4.4 宽高比获取（监听 track stream）

**video_player：**
```dart
final aspectRatio = controller.value.aspectRatio;
```

**media_kit（直接替换）：**
```dart
// 从 track stream 获取宽高比
PlayerStream(
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
)
```

### 五、HDR 支持实现

#### 5.1 HDR 自动检测

**media_kit 特性：**
- 基于 FFmpeg/libmpv，自动识别 HDR 格式
- 在支持的设备上自动启用 HDR 渲染
- 无需额外配置，开箱即用

**检测 HDR 信息（可选，用于显示 HDR 标识等）：**
```dart
// 获取视频轨道信息
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

#### 5.2 HDR 渲染配置

**Video widget 配置：**
```dart
Video(
  controller: videoController,
  // HDR 会自动处理，无需特殊配置
  // 但可以配置渲染选项
  fill: Colors.black,
  fit: BoxFit.contain,
  controls: NoVideoControls,
)
```

### 六、性能优化策略

#### 6.1 状态监听优化

**使用 PlayerStream（推荐）：**
```dart
// PlayerStream 性能优于 StreamBuilder
PlayerStream(
  player.stream.playing,
  builder: (context, isPlaying) {
    // 只重建必要的部分
  },
)
```

**减少嵌套：**
- 尽量将多个 PlayerStream 放在同一层级
- 避免深层嵌套，影响性能

#### 6.2 进度更新节流

**media_kit 特性：**
- `player.stream.position` 本身有节流机制
- 通常不需要额外节流
- 如果确实需要，可以使用 RxDart 的 `throttleTime`

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

#### 7.2 平台检测（如需要）

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
1. 替换所有 `ValueListenableBuilder` → `PlayerStream`
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

### 九、潜在问题与解决方案

#### 9.1 宽高比获取延迟

**问题：** media_kit 的宽高比需要从 metadata 获取，可能有延迟

**解决：**
- 使用默认宽高比（16:9）作为初始值
- 监听 `player.stream.track` 获取实际宽高比
- 使用 `setState` 更新宽高比

#### 9.2 状态同步

**问题：** `PlayerState` 是 Stream，与 `ValueNotifier` 不同

**解决：**
- 直接使用 `PlayerStream` 替代 `ValueListenableBuilder`
- 避免使用 `StreamBuilder`（性能较差）
- 减少嵌套，优化性能

#### 9.3 初始化时机

**问题：** `player.open()` 是异步的，需要等待

**解决：**
- 使用 `FutureBuilder` 或状态管理
- 显示加载指示器
- 处理初始化错误

#### 9.4 音量范围差异

**问题：** media_kit 的音量范围是 0-100，不是 0.0-1.0

**解决：**
- 直接使用 0-100 范围
- 静音：`player.setVolume(0)`
- 最大音量：`player.setVolume(100)`

#### 9.5 循环播放方式

**问题：** media_kit 使用 `setPlaylistMode` 而不是 `setLooping`

**解决：**
- 使用 `player.setPlaylistMode(PlaylistMode.loop)`
- 或使用 `player.setPlaylistMode(PlaylistMode.single)` 配合播放完成事件

### 十、关键改动点总结

#### 10.1 必须修改的地方

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
   final player = Player();
   final videoController = VideoController(player);
   await player.open(Media(path));
   ```

4. **状态监听**
   ```dart
   // 替换所有 ValueListenableBuilder
   // 为 PlayerStream
   PlayerStream(
     player.stream.playing,
     builder: (context, isPlaying) { ... },
   )
   ```

5. **播放控制**
   ```dart
   // 替换所有 controller.xxx()
   // 为 player.xxx()
   player.play();
   player.pause();
   player.seek(position);
   player.setVolume(0);
   ```

6. **视频渲染**
   ```dart
   // 替换
   VideoPlayer(controller)
   
   // 为
   Video(
     controller: videoController,
     fill: Colors.black,
     fit: BoxFit.contain,
     controls: NoVideoControls,
   )
   ```

#### 10.2 保持不变的部分

- UI 布局结构（Stack、Positioned 等）
- 资源释放机制（可见页面范围管理）
- 控制栏显示/隐藏逻辑
- 页面切换处理逻辑
- 性能优化策略（RepaintBoundary 等）

### 十一、注意事项

1. **初始化顺序**：`MediaKit.ensureInitialized()` 必须在 `runApp()` 之前调用
2. **宽高比获取**：需要监听 `player.stream.track`，可能有延迟，使用默认值作为初始值
3. **错误处理**：使用 `PlayerStream` 监听 `player.stream.error`
4. **音量范围**：media_kit 的音量范围是 0-100，不是 0.0-1.0
5. **循环播放**：使用 `player.setPlaylistMode(PlaylistMode.loop)` 而不是 `setLooping()`
6. **资源释放**：只 dispose Player，VideoController 会自动释放

### 十二、总结

**优势：**
- ✅ 原生 HDR 支持，开箱即用
- ✅ 跨平台兼容性好（Android/iOS/macOS/Windows/Linux/Web）
- ✅ 格式支持广泛（FFmpeg 支持的所有格式）
- ✅ 性能优秀，基于 libmpv
- ✅ 代码简洁，直接使用原生 API，无中间层

**挑战：**
- ⚠️ API 差异较大，需要完整重构
- ⚠️ 状态管理方式不同（Stream vs ValueNotifier）
- ⚠️ 学习成本（需要了解 media_kit API）

**实施建议：**
- ✅ 一次性完整替换，无需考虑向后兼容
- ✅ 充分测试各平台功能
- ✅ 关注性能指标，确保流畅度
- ✅ 利用 media_kit 的丰富功能（如字幕、多音轨等）

**关键原则：**
- 直接使用 media_kit 原生 API，不创建封装层
- 使用 `PlayerStream` 进行状态监听，避免 `StreamBuilder`
- 保持现有 UI 布局和资源管理机制
- 充分利用 media_kit 的 HDR 和跨平台优势
