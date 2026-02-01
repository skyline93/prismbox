# Change: 圈子重构移动端改造 — Feed 入口与全部 Feed

## Why

圈子 Feed 入口重构（以刷内容为主线）需要移动端配合：用户点击底部栏圈子 Tab 时直接进入 Feed 流页面、默认展示「全部圈子」帖子，减少「先看列表再点进某圈」的一步。后端已通过 `add-all-groups-feed-api` 提供全部 Feed API；移动端需新增 Feed 首屏、全部/单圈数据源与圈子选择器，并与后端 API 对齐。

## What Changes

- **Tab 默认页**：圈子 Tab 的默认页由 `GroupListPage` 改为新建的 **Feed 页**（`GroupFeedPage` 或 `CirclesFeedPage`）；路径 `groups` 保持不变，仅对应 Page 更换。保留 `GroupListRoute` 为独立路由，供 Feed 页「我的圈子」进入。
- **Feed 页**：新建页面，包含圈子选择器（全部 + 用户加入的圈子）、Feed 列表（复用现有帖子卡片与下拉刷新/上拉加载更多）、AppBar（标题随选择变化、「我的圈子」「创建圈子」入口）、空状态（无圈子/无帖子）。
- **数据层**：PostApiClient 新增 `getMyFeed(page, limit)` 请求全部 Feed API（与后端 `add-all-groups-feed-api` 约定一致，如 `GET /api/v1/groups/feed`）；新增全部 Feed Provider（如 `AllGroupsFeedProvider`）或统一 Feed 源 Provider，与现有 `GroupFeedProvider(groupUuid)` 并存或统一。Feed 页根据当前选中（全部 vs 某圈）切换数据源。
- **Post 模型**：增加可选字段 `groupUuid`、`groupName`，fromJson/toJson 兼容后端 `group_uuid`、`group_name`（全部 Feed 必带，单圈可选）。
- **帖子卡片**：当 `post.groupName != null` 时展示「来自 {groupName}」或标签，点击可跳转该圈 Feed 或圈子详情。
- **空状态**：无圈子时「还没有加入圈子」+「创建圈子」「加入圈子」；有圈子无帖子时「暂无帖子」等。
- **发帖 FAB**：仅在单圈 Feed 页（选中某圈时）显示发帖 FAB；在全部圈子 Feed 页（选中「全部」时）不显示，后续再做优化。

## Impact

- Affected specs: `group`, `post`
- Affected code:
  - `mobile/lib/presentation/routing/app_router.dart` — TabShell 下 groups 对应 Route 改为 Feed 页
  - `mobile/lib/presentation/pages/tab_shell/tab_shell_page.dart` — AutoTabsRouter routes 中对应项改为 GroupFeedRoute（或新命名）
  - 新建 `mobile/lib/presentation/pages/groups/group_feed_page.dart`（或 circles_feed_page.dart）
  - `mobile/lib/infrastructure/network/post_api_client.dart` — 新增 getMyFeed
  - `mobile/lib/services/post/post_service.dart` — 新增 getMyFeed 并委托 apiClient
  - 新建或扩展 `mobile/lib/providers/post/` — 全部 Feed Provider
  - `mobile/lib/data/models/post/post.dart` — 增加 groupUuid、groupName
  - 帖子卡片组件 — 展示所属圈子与跳转
  - `GroupListPage` 保留，入口改为 Feed 页内「我的圈子」
