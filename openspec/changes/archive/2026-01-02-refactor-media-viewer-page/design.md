# Design: 媒体查看器页面重构架构设计

## Context

当前 `media_viewer_page.dart` 文件包含 1087 行代码，违反了项目 UI 重构规范（build 方法不超过 80 行，组件化拆分）。文件承担了过多职责：
- 页面状态管理（12+ 个状态变量）
- 图片查看器构建
- 视频播放器管理（缓存、创建、释放）
- 手势处理（垂直滑动退出）
- 动画控制（退出动画）
- UI 控制栏（顶部 AppBar + 底部控制栏）
- 视频控制器 UI

需要进行组件化拆分，提取可复用的组件和业务逻辑类。

## Goals / Non-Goals

### Goals
- **组件化拆分**：将超大文件拆分为多个职责单一的组件
- **代码行数控制**：主页面文件减少到 200-300 行
- **性能优化**：减少不必要的 Widget 重建，优化状态管理
- **可维护性提升**：提高代码可读性和可测试性
- **遵循项目规范**：符合 UI 重构规范和代码质量要求

### Non-Goals
- 不改变现有功能行为（纯重构）
- 不引入新的依赖或框架
- 不改变用户界面外观
- 不进行大规模架构调整（如引入新的状态管理方案）

## Decisions

### Decision 1: 视频播放器管理器设计

**选择**：创建 `ViewerVideoManager` 类作为纯 Dart 类（非 Widget），封装视频控制器管理逻辑。

**理由**：
- 视频控制器管理是业务逻辑，不是 UI 组件
- 需要独立生命周期管理（创建、缓存、释放）
- 可以通过构造函数注入到页面类中使用
- 便于单元测试

**实现方式**：
```dart
class ViewerVideoManager {
  final Map<String, VideoPlayerController> _controllers = {};
  final Map<String, bool> _mutedStates = {};
  String? _currentVideoAssetId;
  Set<int> _visiblePageIndices = {};
  
  // 管理方法：创建、获取、释放、暂停等
}
```

### Decision 2: 手势处理组件设计

**选择**：创建 `ViewerDismissGesture` 作为 StatefulWidget，封装手势识别和动画逻辑。

**理由**：
- 手势处理是独立的 UI 逻辑，可以独立复用
- 需要维护动画控制器状态（AnimationController）
- 通过 Widget 包装子组件，符合 Flutter 设计模式

**实现方式**：
```dart
class ViewerDismissGesture extends StatefulWidget {
  final Widget child;
  final bool isZoomed;
  final VoidCallback onDismiss;
  // ...
}
```

### Decision 3: 图片/视频页面组件设计

**选择**：分别创建 `ViewerImagePage` 和 `ViewerVideoPage` 作为独立 Widget。

**理由**：
- 图片和视频查看逻辑差异较大，分开更清晰
- 每个组件可以独立优化和维护
- 符合单一职责原则

**实现方式**：
```dart
class ViewerImagePage extends StatelessWidget {
  final BaseAsset asset;
  final String assetId;
  // ...
}

class ViewerVideoPage extends StatefulWidget {
  final BaseAsset asset;
  final String assetId;
  final ViewerVideoManager videoManager;
  // ...
}
```

### Decision 4: 控制栏组件设计

**选择**：创建 `ViewerControlsBar` 作为 StatelessWidget，包含顶部和底部控制栏。

**理由**：
- 控制栏是独立的 UI 组件，可以整体复用
- 使用 StatelessWidget 因为状态由父组件管理
- 通过回调函数处理用户交互

**实现方式**：
```dart
class ViewerControlsBar extends StatelessWidget {
  final bool showControls;
  final VoidCallback onToggleControls;
  // ...
}
```

### Decision 5: 状态管理策略

**选择**：保持现有状态管理方式，不引入新的 Provider。

**理由**：
- 页面级状态（如 `showControls`、`isZoomed`）仍然由页面类管理
- 视频管理器状态由 `ViewerVideoManager` 类内部管理
- 避免过度设计，保持简单

### Decision 6: 目录结构

**选择**：在 `lib/presentation/widgets/viewer/` 目录下创建所有组件。

**理由**：
- 符合项目目录结构规范（widgets 目录存放组件）
- 使用 `viewer` 子目录组织相关组件
- 文件命名使用 `viewer_` 前缀，便于识别

## Alternatives Considered

### Alternative 1: 使用 Provider 管理视频状态
**考虑**：将视频管理器改为 Riverpod Provider。
**放弃原因**：
- 当前视频管理器状态主要是页面内部状态，不需要全局共享
- 引入 Provider 会增加复杂度
- 纯 Dart 类更简单，便于测试

### Alternative 2: 使用 Mixin 处理手势逻辑
**考虑**：使用 Mixin 在页面类中混入手势处理逻辑。
**放弃原因**：
- Mixin 会增加类复杂度
- Widget 封装更符合 Flutter 设计模式
- 独立 Widget 更容易测试和复用

### Alternative 3: 将视频控制器 UI 保留在页面类中
**考虑**：保持 `_VideoPlayerControls` 在页面文件中。
**放弃原因**：
- 虽然已经是独立的 Widget，但放在同一文件会影响可读性
- 移动到独立文件更符合组件化原则
- 便于后续扩展和维护

## Risks / Trade-offs

### Risk 1: 性能影响
**风险**：组件拆分可能引入额外的 Widget 层级，影响性能。
**缓解措施**：
- 使用 `const` 构造函数减少重建
- 使用 `RepaintBoundary` 隔离绘制边界
- 保持现有的 `ValueListenableBuilder` 优化

### Risk 2: 状态传递复杂度
**风险**：组件拆分后需要传递更多参数。
**缓解措施**：
- 通过回调函数传递事件处理
- 保持必要的参数传递，避免过度抽象
- 视频管理器通过构造函数注入

### Risk 3: 重构引入 Bug
**风险**：重构过程中可能引入功能回归。
**缓解措施**：
- 保持纯重构，不改变功能行为
- 分阶段进行，逐步验证
- 充分测试每个组件

## Migration Plan

### Phase 1: 提取视频管理器（低风险）
1. 创建 `ViewerVideoManager` 类
2. 迁移视频控制器管理逻辑
3. 更新页面类使用管理器
4. 验证功能正常

### Phase 2: 提取手势处理（中风险）
1. 创建 `ViewerDismissGesture` Widget
2. 迁移手势和动画逻辑
3. 更新页面类使用手势组件
4. 验证手势和动画正常

### Phase 3: 提取 UI 组件（中风险）
1. 创建控制栏组件
2. 创建图片/视频页面组件
3. 逐步替换页面类中的代码
4. 验证 UI 显示正常

### Phase 4: 清理和优化（低风险）
1. 移动视频控制器 UI 到独立文件
2. 清理冗余代码
3. 添加文档注释
4. 代码质量检查

### Rollback Plan
- 每个阶段独立验证，发现问题立即回滚
- 使用 Git 分支管理，便于回滚
- 保持原有代码逻辑不变，仅改变组织结构

## Open Questions

无。设计方案已明确，可以开始实施。

