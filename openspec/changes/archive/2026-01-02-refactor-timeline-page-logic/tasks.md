## 1. 创建事件监听管理器

- [x] 1.1 创建 `lib/presentation/pages/photos/listeners/timeline_event_listeners.dart` 文件
- [x] 1.2 实现 `TimelineEventListeners` 类，包含所有 Stream 订阅管理
- [x] 1.3 实现 `start()` 方法，启动所有监听
- [x] 1.4 实现 `dispose()` 方法，清理所有订阅
- [x] 1.5 迁移数据源切换监听逻辑
- [x] 1.6 迁移上传完成监听逻辑
- [x] 1.7 迁移远程同步完成监听逻辑
- [x] 1.8 迁移 checksum 匹配完成监听逻辑
- [ ] 1.9 编写单元测试

## 2. 创建拖动选择控制器

- [x] 2.1 创建 `lib/presentation/pages/photos/controllers/timeline_drag_selection_controller.dart` 文件
- [x] 2.2 实现 `TimelineDragSelectionController` 类
- [x] 2.3 迁移拖动选择相关状态（_dragAnchorIndex, _isDragging, _draggedAssetIds）
- [x] 2.4 实现 `handleDragStart()` 方法
- [x] 2.5 实现 `handleDragAssetEnter()` 方法（包含矩形/行选择算法）
- [x] 2.6 实现 `handleDragEnd()` 方法
- [x] 2.7 实现 `handleDragScroll()` 方法
- [x] 2.8 提取矩形选择算法到独立方法 `_calculateSelectedAssets()`
- [ ] 2.9 编写单元测试（特别是选择算法）

## 3. 创建捏合手势处理器 Mixin

- [x] 3.1 创建 `lib/presentation/pages/photos/mixins/timeline_pinch_gesture_handler.dart` 文件
- [x] 3.2 实现 `TimelinePinchGestureHandler` Mixin
- [x] 3.3 迁移捏合手势相关状态（_lastColumnCount, _lastUpdateTime）
- [x] 3.4 实现 `onScaleStart()` 方法
- [x] 3.5 实现 `onScaleUpdate()` 方法（包含防抖逻辑）
- [x] 3.6 实现 `onScaleEnd()` 方法
- [x] 3.7 实现 `_calculateTargetColumns()` 方法
- [ ] 3.8 编写单元测试

## 4. 创建滚动位置管理器

- [x] 4.1 创建 `lib/presentation/pages/photos/controllers/timeline_scroll_position_manager.dart` 文件
- [x] 4.2 实现 `TimelineScrollPositionManager` 类
- [x] 4.3 迁移滚动位置相关状态（_savedScrollOffset）
- [x] 4.4 实现 `saveScrollOffset()` 方法
- [x] 4.5 实现 `restoreScrollOffset()` 方法（包含多个 postFrameCallback 逻辑）
- [x] 4.6 实现 `clearSavedOffset()` 方法
- [ ] 4.7 编写单元测试

## 5. 创建上传处理器

- [x] 5.1 创建 `lib/presentation/pages/photos/controllers/timeline_upload_handler.dart` 文件
- [x] 5.2 实现 `TimelineUploadHandler` 类
- [x] 5.3 实现 `handleUpload()` 方法
- [x] 5.4 迁移获取用户信息逻辑
- [x] 5.5 迁移启动备份服务逻辑
- [x] 5.6 迁移显示提示逻辑
- [ ] 5.7 编写单元测试

## 6. 重构主页面类

- [x] 6.1 在 `main_timeline_page.dart` 中创建控制器实例
- [x] 6.2 在 `initState()` 中初始化事件监听管理器
- [x] 6.3 在 `dispose()` 中清理所有控制器
- [x] 6.4 将事件监听逻辑委托给 `TimelineEventListeners`
- [x] 6.5 将拖动选择逻辑委托给 `TimelineDragSelectionController`
- [x] 6.6 将捏合手势逻辑委托给 `TimelinePinchGestureHandler` Mixin
- [x] 6.7 将滚动位置管理委托给 `TimelineScrollPositionManager`
- [x] 6.8 将上传处理委托给 `TimelineUploadHandler`
- [x] 6.9 删除页面类中的旧逻辑和状态变量
- [x] 6.10 简化 `build()` 方法，使其专注于 UI 构建

## 7. 测试和验证

- [ ] 7.1 运行现有测试，确保功能正常
- [ ] 7.2 手动测试事件监听功能（数据源切换、上传完成等）
- [ ] 7.3 手动测试拖动选择功能（矩形选择、行选择）
- [ ] 7.4 手动测试捏合手势功能（调整列数）
- [ ] 7.5 手动测试滚动位置恢复功能
- [ ] 7.6 手动测试上传功能
- [x] 7.7 运行 linter 检查代码质量
- [ ] 7.8 检查代码覆盖率

## 8. 代码审查和文档

- [ ] 8.1 代码审查
- [x] 8.2 更新相关注释和文档
- [x] 8.3 确保所有新类都有适当的文档注释

