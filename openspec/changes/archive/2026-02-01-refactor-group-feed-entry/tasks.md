# Tasks: refactor-group-feed-entry

## 1. Implementation

- [x] 1.1 Post 模型：在 `lib/data/models/post/post.dart` 中增加 `String? groupUuid`、`String? groupName`；在 fromJson 中解析 `group_uuid`、`group_name`（可选）；toJson 按需输出，兼容未返回时为 null。
- [x] 1.2 PostApiClient：在 `lib/infrastructure/network/post_api_client.dart` 中新增 `getMyFeed({ int page = 1, int limit = 20 })`，请求 `GET /api/v1/groups/feed`，解析与 getGroupFeed 一致的帖子列表（含 group_uuid/group_name）。
- [x] 1.3 PostService：在 `lib/services/post/post_service.dart` 中新增 `getMyFeed`，委托 apiClient.getMyFeed。
- [x] 1.4 全部 Feed Provider：新建 `lib/providers/post/all_groups_feed_provider.dart`（或等效），无参，内部调用 getMyFeed，实现 load/refresh/loadMore，与 GroupFeedProvider 行为对齐；运行 build_runner 生成 .g.dart。
- [x] 1.5 新建 GroupFeedPage：在 `lib/presentation/pages/groups/` 下新建 `group_feed_page.dart`，包含 AppBar（标题随选择、「我的圈子」「创建圈子」）、圈子选择器（全部 + GroupListProvider 的圈子列表）、Feed 列表（复用现有帖子卡片与下拉刷新/上拉加载）、空状态（无圈子/无帖子）；内部状态 `selectedGroupUuid`，null 时监听 AllGroupsFeedProvider，非空时监听 GroupFeedProvider(selectedGroupUuid)。
- [x] 1.6 路由与 Tab：在 app_router 中新增 GroupFeedRoute（或 CirclesFeedRoute），path 与 Tab 对应（如 `groups`）；将 TabShell 下原 GroupListRoute 换为 GroupFeedRoute；保留 GroupListRoute 为独立路由（path 如 `/groups/list`），供「我的圈子」跳转。
- [x] 1.7 TabShell：在 `tab_shell_page.dart` 的 AutoTabsRouter routes 中，将对应 Tab 的 `GroupListRoute()` 换为 `GroupFeedRoute()`。
- [x] 1.8 Feed 页：实现圈子选择器 UI（横向列表或下拉），绑定 selectedGroupUuid 与 GroupListProvider；标题与选择器联动（「全部动态」/「{圈子名称}」）。
- [x] 1.9 Feed 页：在 AppBar 或顶部增加「我的圈子」入口（导航到 GroupListRoute）、「创建圈子」入口（导航到 CreateGroupRoute）。
- [x] 1.10 帖子卡片：当 `post.groupName != null` 时展示「来自 {groupName}」或标签；点击该区域可切换 Feed 页选中为该圈（selectedGroupUuid = post.groupUuid）或导航到 GroupDetailPage(groupUuid)，按产品选择一种。
- [x] 1.11 空状态：无圈子时显示「还没有加入圈子」+ 按钮「创建圈子」「加入圈子」；有圈子无帖子时显示「暂无帖子」等；单圈无帖子与现有 GroupDetailPage 空状态一致。
- [x] 1.12 发帖 FAB：仅在选中单圈时在 Feed 页显示发帖 FAB（默认当前圈）；选中「全部」时不显示 FAB，后续再做优化。
- [x] 1.13 单元/Widget 测试：为 getMyFeed、AllGroupsFeedProvider、Post 解析 group 字段、GroupFeedPage 关键交互编写测试；运行现有测试确保无回归。
