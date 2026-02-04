# Change: 圈子 Feed 页上滑隐藏顶部栏、仅保留圈子栏

## Why

用户在圈子 Feed 页浏览帖子时，希望更多屏幕空间用于内容；上滑阅读时顶部 AppBar（标题 + 我的圈子/创建）占用空间且非刚需，而圈子选择器（全部/各圈子 Tab）需要常驻以便切换。通过「上滑隐藏顶部栏、仅保留圈子栏」可提升阅读体验并符合常见 Feed 产品模式。

## What Changes

- **布局重构**：圈子 Feed 页由「Scaffold.appBar + Column(圈子选择器 + Expanded ListView)」改为 **CustomScrollView + Sliver**：顶部栏作为可滚出视野的 Sliver（如 SliverAppBar 或自定义 Sliver），圈子选择器使用 **SliverPersistentHeader（pinned: true）** 钉在顶部，Feed 列表为 SliverList。
- **交互**：用户**上滑**时顶部栏随内容滚出屏幕，仅剩圈子栏贴顶；**下滑**或回到顶部时顶部栏重新出现。
- **顶部安全区**：上滑钉住时，圈子栏 SHALL 预留系统顶部安全区（状态栏/刘海区域），使圈子栏显示在系统顶部栏下方、不与之重合。
- **保持**：下拉刷新、上拉加载更多、发帖 FAB 显隐逻辑、空状态与现有行为一致；「我的圈子」「创建」等入口仍位于顶部栏（未滚出时可见），必要时可在圈子栏或其它位置提供快捷入口（本提案不强制）。

## Impact

- Affected specs: `group`
- Affected code: `mobile/lib/presentation/pages/groups/group_feed_page.dart`（以及若拆出 Sliver 相关子组件则 `mobile/lib/presentation/widgets/` 下新增或修改的组件）
