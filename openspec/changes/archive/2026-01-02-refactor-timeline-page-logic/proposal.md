# Change: 重构时间线页面业务逻辑提取

## Why

当前 `main_timeline_page.dart` 文件虽然已经完成了 UI 组件化拆分，但页面类仍然承担了过多的业务逻辑职责（863 行），存在以下问题：

- **职责过多**：页面类同时负责事件监听、拖动选择、捏合手势、滚动管理、上传处理等多个业务逻辑
- **状态管理分散**：多个 StreamSubscription、拖动选择状态、捏合手势状态等分散在页面类中
- **可测试性差**：复杂的业务逻辑（如拖动选择算法）耦合在 State 中，难以单独测试
- **可维护性差**：代码行数过多，逻辑复杂，修改一个功能可能影响其他功能
- **可复用性差**：拖动选择、捏合手势等逻辑无法在其他页面复用

通过将业务逻辑提取到独立的控制器类和管理器中，可以：
- 提高代码可维护性和可测试性
- 遵循单一职责原则，每个类只负责一个功能领域
- 便于逻辑复用和独立测试
- 降低页面类复杂度，使其专注于 UI 构建和协调

## What Changes

- **提取事件监听管理器**：创建 `TimelineEventListeners` 类，负责所有 Stream 事件监听
  - 数据源切换监听
  - 上传完成监听
  - 远程同步完成监听
  - Checksum 匹配完成监听
- **提取拖动选择控制器**：创建 `TimelineDragSelectionController` 类，负责拖动选择逻辑
  - 拖动开始、进入、结束处理
  - 矩形/行选择算法（约 150 行复杂逻辑）
  - 拖动滚动处理
- **提取捏合手势处理器**：创建 `TimelinePinchGestureHandler` Mixin，负责捏合手势调整列数
  - 手势开始、更新、结束处理
  - 列数计算逻辑
  - 防抖机制
- **提取滚动位置管理器**：创建 `TimelineScrollPositionManager` 类，负责滚动位置保存和恢复
  - 保存滚动位置（长按进入选择模式时）
  - 恢复滚动位置（使用多个 postFrameCallback 确保布局稳定）
- **提取上传处理器**：创建 `TimelineUploadHandler` 类，负责上传业务逻辑
  - 获取用户信息
  - 启动备份服务
  - 显示成功/错误提示
- **简化页面类**：`MainTimelinePage` 仅保留页面级协调逻辑，代码行数从 863 行减少到约 300-400 行

所有新类将：
- 存放在 `lib/presentation/pages/photos/controllers/` 或 `lib/presentation/pages/photos/listeners/` 目录下
- 使用清晰的命名（如 `timeline_drag_selection_controller.dart`）
- 遵循单一职责原则
- 通过构造函数或方法参数接收必要的依赖（WidgetRef、ScrollController 等）

## Impact

- **受影响文件**：
  - `prismbox_mobile/lib/presentation/pages/photos/main_timeline_page.dart` - 大幅简化（从 863 行减少到约 300-400 行）
  - 新增 5 个业务逻辑类文件：
    - `lib/presentation/pages/photos/listeners/timeline_event_listeners.dart` - 事件监听管理器
    - `lib/presentation/pages/photos/controllers/timeline_drag_selection_controller.dart` - 拖动选择控制器
    - `lib/presentation/pages/photos/mixins/timeline_pinch_gesture_handler.dart` - 捏合手势处理器 Mixin
    - `lib/presentation/pages/photos/controllers/timeline_scroll_position_manager.dart` - 滚动位置管理器
    - `lib/presentation/pages/photos/controllers/timeline_upload_handler.dart` - 上传处理器
- **受影响规范**：
  - 单一职责原则
  - 代码可维护性和可测试性要求
- **向后兼容性**：纯重构，不改变功能行为，保持完全兼容

