## 1. 实现

- [x] 1.1 移除 `GroupFeedPage` 的 `Scaffold.appBar`，将顶部栏内容（标题、我的圈子、创建）迁移到 CustomScrollView 的首个 Sliver（如 SliverAppBar 或 SliverToBoxAdapter + 自定义栏），配置为不 pinned，使上滑时随内容滚出视野。
- [x] 1.2 将圈子选择器改为 `SliverPersistentHeader`（pinned: true），delegate 内绘制现有「全部 + 各圈子」Chip 横向列表，保证上滑后仅圈子栏贴顶。
- [x] 1.3 将 Feed 列表由 `ListView.builder` 改为 `SliverList`（或 `SliverChildBuilderDelegate`），纳入同一 CustomScrollView，共用同一 ScrollController；保留下拉刷新（RefreshIndicator 或 CupertinoSliverRefreshControl 等）、上拉加载更多与 FAB 显隐逻辑。
- [x] 1.4 处理 SafeArea/状态栏：无 Scaffold.appBar 时在首 Sliver 或 SliverAppBar 内预留顶部安全区，避免内容与系统 UI 重叠。
- [x] 1.7 确保钉住的圈子栏预留系统顶部安全区：上滑后圈子栏（SliverPersistentHeader）显示在状态栏/刘海下方，不与之重合（如 CustomScrollView 外包 SafeArea(top: true) 或 delegate 内预留 MediaQuery.padding.top）。
- [x] 1.5 空状态与错误态：在 Sliver 布局下正确展示无圈子/无帖子/加载失败等状态（如 SliverFillRemaining 或条件 Sliver）。
- [x] 1.6 运行 `dart analyze` 与现有测试（如有），确认无回归；按需补充 Widget 或集成测试覆盖「上滑后仅见圈子栏」行为。
