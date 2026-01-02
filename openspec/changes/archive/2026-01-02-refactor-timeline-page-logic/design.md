# Design: 时间线页面业务逻辑提取架构设计

## Context

当前 `main_timeline_page.dart` 文件虽然已经完成了 UI 组件化拆分，但页面类仍然承担了过多的业务逻辑职责。页面类需要处理：
- 4 个不同的 Stream 事件监听（数据源切换、上传完成、远程同步完成、checksum 匹配完成）
- 复杂的拖动选择算法（矩形/行选择，约 150 行代码）
- 捏合手势处理（调整网格列数）
- 滚动位置管理（长按进入选择模式时的位置保存和恢复）
- 上传业务逻辑处理

这些逻辑耦合在页面 State 中，导致：
- 代码难以测试（特别是拖动选择算法）
- 代码难以维护（修改一个功能可能影响其他功能）
- 逻辑无法复用（其他页面无法使用拖动选择功能）

## Goals / Non-Goals

### Goals
- 将业务逻辑从页面类中提取到独立的控制器类和管理器中
- 每个类只负责一个功能领域，遵循单一职责原则
- 提高代码可测试性，特别是拖动选择算法
- 提高代码可维护性，降低修改成本
- 保持功能行为完全不变（纯重构）

### Non-Goals
- 不改变现有的 UI 组件结构（已在之前的重构中完成）
- 不改变现有的状态管理方式（仍使用 Riverpod）
- 不改变现有的数据流（仍使用相同的 Provider）
- 不优化性能（本次重构专注于代码结构）

## Decisions

### Decision 1: 使用独立的控制器类而非 Mixin

**选择**：为拖动选择、滚动位置管理、上传处理创建独立的控制器类

**理由**：
- 控制器类可以独立测试，不依赖 Widget 生命周期
- 可以更好地管理状态和资源（如 StreamSubscription）
- 符合单一职责原则，每个类只负责一个功能领域
- 便于在其他页面复用（如拖动选择可以在相册页面复用）

**替代方案**：使用 Mixin
- 缺点：Mixin 仍然耦合在 State 中，难以独立测试
- 缺点：Mixin 无法管理资源（如 StreamSubscription）

### Decision 2: 使用 Mixin 处理捏合手势

**选择**：为捏合手势创建 `TimelinePinchGestureHandler` Mixin

**理由**：
- 捏合手势处理逻辑相对简单，主要是状态管理和计算
- Mixin 可以方便地在页面类中使用，减少样板代码
- 手势处理通常需要访问 Widget 的 State，Mixin 更合适

**替代方案**：使用独立的控制器类
- 缺点：手势处理需要访问 WidgetRef 和 State，控制器类会增加复杂度

### Decision 3: 事件监听使用独立的监听器类

**选择**：创建 `TimelineEventListeners` 类管理所有 Stream 监听

**理由**：
- 4 个不同的 Stream 监听逻辑相似，可以统一管理
- 便于资源管理（统一 dispose）
- 便于测试和调试

**替代方案**：分散在页面类中
- 缺点：代码分散，难以管理
- 缺点：资源管理容易遗漏

### Decision 4: 文件组织方式

**选择**：按功能类型组织文件
```
lib/presentation/pages/photos/
  ├── main_timeline_page.dart (主页面，简化后)
  ├── controllers/
  │   ├── timeline_drag_selection_controller.dart
  │   ├── timeline_scroll_position_manager.dart
  │   └── timeline_upload_handler.dart
  ├── listeners/
  │   └── timeline_event_listeners.dart
  └── mixins/
      └── timeline_pinch_gesture_handler.dart
```

**理由**：
- 清晰的目录结构，便于查找和维护
- 按功能类型分组，符合项目规范
- 与 UI 组件目录（`widgets/timeline/`）分离，职责清晰

**替代方案**：所有文件放在同一目录
- 缺点：文件过多时难以管理
- 缺点：职责不清晰

## Risks / Trade-offs

### Risk 1: 过度抽象导致代码复杂度增加

**风险**：提取过多的类可能导致代码跳转增加，理解成本提高

**缓解措施**：
- 只提取真正独立的业务逻辑（如拖动选择算法）
- 保持类的职责清晰，每个类只负责一个功能领域
- 使用清晰的命名，便于理解

### Risk 2: 状态管理复杂化

**风险**：控制器类需要访问 WidgetRef，可能导致状态管理复杂化

**缓解措施**：
- 通过构造函数传递 WidgetRef，保持依赖关系清晰
- 控制器类只读取必要的 Provider，不持有状态
- 状态仍然由 Riverpod Provider 管理，控制器只负责逻辑处理

### Risk 3: 测试覆盖不足

**风险**：提取的类可能没有足够的测试覆盖

**缓解措施**：
- 为每个控制器类编写单元测试
- 特别是拖动选择算法，需要详细的测试用例
- 保持测试覆盖率达到项目要求

## Migration Plan

### Phase 1: 创建新的控制器类（保持原有代码）
1. 创建 `TimelineEventListeners` 类，实现事件监听逻辑
2. 创建 `TimelineDragSelectionController` 类，实现拖动选择逻辑
3. 创建 `TimelinePinchGestureHandler` Mixin，实现捏合手势逻辑
4. 创建 `TimelineScrollPositionManager` 类，实现滚动位置管理
5. 创建 `TimelineUploadHandler` 类，实现上传处理逻辑

### Phase 2: 逐步迁移功能
1. 在页面类中创建控制器实例
2. 逐步将方法调用委托给控制器
3. 验证功能正常（每个功能迁移后都进行验证）

### Phase 3: 清理旧代码
1. 删除页面类中的旧逻辑
2. 清理不再使用的状态变量
3. 运行测试确保功能正常

### Phase 4: 测试和文档
1. 为每个控制器类编写单元测试
2. 更新相关文档
3. 代码审查

## Open Questions

- 是否需要为控制器类创建接口，以便于测试和替换？
  - **决定**：暂时不需要，保持简单。如果未来需要替换实现，再考虑引入接口。
- 拖动选择算法是否应该支持跨分组选择？
  - **决定**：当前实现只支持同一分组内的选择，跨分组选择作为未来增强功能。
- 是否应该将拖动选择算法提取为更通用的组件？
  - **决定**：当前先提取为控制器类，如果其他页面需要，再考虑进一步抽象。

