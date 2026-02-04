# 设计：圈子 Feed 页顶部栏随滚动隐藏

## Context

- 圈子 Feed 页当前结构：Scaffold + 固定 AppBar + Column（圈子选择器 + Expanded ListView）。用户希望上滑时顶部栏隐藏、仅保留圈子栏，以增加内容可见区域。
- 约束：保留下拉刷新、上拉加载更多、发帖 FAB 显隐、空状态与错误态；不改变数据源与 API。

## Goals / Non-Goals

- **Goals**：上滑时顶部栏滚出视野，圈子栏钉在顶部；下滑时顶部栏重新出现；实现方案可维护、与 Flutter 滚动语义一致。
- **Non-Goals**：不改变 Feed 数据源、帖子卡片、圈子选择器数据与交互逻辑；不在本提案内增加「全部 Feed 发帖」等产品优化。

## Decisions

- **采用 CustomScrollView + Sliver（方案 1）**：
  - 使用 **CustomScrollView** 统一管理「可滚走的顶部栏 + 钉住的圈子栏 + Feed 列表」。
  - **顶部栏**：SliverAppBar 或等价 Sliver，内容为当前标题 + 「我的圈子」「创建」按钮；`pinned: false`、`floating` 按需设置，使上滑时随内容滚出。
  - **圈子栏**：`SliverPersistentHeader(pinned: true)`，delegate 内绘制现有横向 Chip 列表（全部 + 各圈子），高度固定（如 44）。钉住时 SHALL 预留系统顶部安全区（如 SafeArea 或 MediaQuery.padding.top），使圈子栏显示在状态栏/刘海下方、不与之重合。
  - **列表**：`SliverList` / `SliverChildBuilderDelegate`，与现有 `ListView.builder` 的 itemBuilder 逻辑一致；共用同一 `ScrollController`，以便继续做加载更多与 FAB 显隐。
- **备选方案（方案 2）**：保留 Column + ListView，顶部栏改为自定义 Widget，通过监听 ScrollController 的滚动方向与偏移做显隐动画（如 AnimatedSize）。未采用原因：需额外维护显隐阈值与动画状态，易出现抖动；Sliver 方案与 Flutter 滚动模型一致，行为更可预期。

## Risks / Trade-offs

- **NestedScrollView 与内层 Controller**：若将来使用 NestedScrollView，内层 Body 会有独立 controller，加载更多与 FAB 需监听内层滚动。本提案采用单 CustomScrollView + 单 controller，避免此问题。
- **刷新组件**：Material 的 RefreshIndicator 需包在可滚动区域外或使用 Sliver 版刷新；实现时选用一种并保持与现有刷新行为一致。

## Migration Plan

- 仅修改 `GroupFeedPage` 及可能拆出的 Sliver 子组件；无数据迁移、无 API 变更。上线后观察滚动流畅度与 FAB/刷新是否正常即可。

## Open Questions

- 无。
