# Design: 圈子 Feed 入口移动端改造

## Context

- 设计依据：`mobile/doc/modules/圈子 Feed 入口重构设计文档.md` §5 前端改造、§8.2 前端任务。
- 后端依赖：变更 `add-all-groups-feed-api` 提供 `GET /api/v1/groups/feed` 及帖子项 `group_uuid`、`group_name`；移动端改造与后端提案对应，联调时使用同一 API 约定。
- 现有实现：圈子 Tab 对应 `GroupListRoute` → `GroupListPage`；Feed 仅通过 `GroupFeedProvider(groupUuid)` 在圈子详情页使用；Post 模型无圈子字段。

## Goals / Non-Goals

- **Goals**：圈子 Tab 默认进入 Feed 页；支持全部 Feed 与单圈 Feed 切换；帖子卡片可展示所属圈子并跳转；保留圈子列表与创建入口为次级路径。
- **Non-Goals**：不改变发帖、评论、帖子详情、圈子详情页核心逻辑；不删除 `GroupListPage` 或 `GroupDetailPage`。

## Decisions

### 1. 路由与 Tab

- **决策**：TabShell 下 `path: 'groups'` 对应页面由 `GroupListPage` 改为新建的 `GroupFeedPage`；Route 名可为 `GroupFeedRoute` 或 `CirclesFeedRoute`，与现有命名风格一致。`GroupListRoute` 保留为独立路由（与 Tab 同级或子路由），从 Feed 页「我的圈子」push 进入。
- **实现要点**：`app_router.dart` 中 TabShell children 将 `GroupListRoute.page` 换为 `GroupFeedRoute.page`；`tab_shell_page.dart` 的 `routes` 中对应项改为 `GroupFeedRoute()`。独立路由中仍保留 `GroupListRoute`（path 如 `/groups/list` 或复用 `/groups` 通过 push 时指定），避免从详情/设置返回列表时失效。

### 2. 全部 Feed 与单圈 Feed 数据源

- **决策**：采用设计文档推荐方案 A — 新增无参 `AllGroupsFeedProvider`，内部调用 `getMyFeed`，实现 load/refresh/loadMore，与 `GroupFeedProvider(groupUuid)` 并存。Feed 页根据 `selectedGroupUuid == null` 监听 `allGroupsFeedProvider`，否则监听 `groupFeedProvider(selectedGroupUuid)`。
- **替代**：方案 B 统一 Feed 源 Provider（参数 `String?`）可减少 Provider 类型数量，但需改造成本；方案 A 实现简单、与现有 `GroupFeedProvider` 并存清晰。

### 3. API 客户端与后端路径

- **决策**：PostApiClient 新增 `getMyFeed({ int page = 1, int limit = 20 })`，请求 `GET /api/v1/groups/feed`（与后端 `add-all-groups-feed-api` 设计一致），解析与 `getGroupFeed` 相同的帖子列表结构（含 `group_uuid`、`group_name`）。PostService 对应新增 `getMyFeed` 并委托 apiClient。

### 4. Post 模型扩展

- **决策**：在 `Post` 中增加 `final String? groupUuid;`、`final String? groupName;`。fromJson 解析 `group_uuid`、`group_name` 为可选（兼容单圈 Feed 不返回时为 null）；toJson 按需输出，保证向后兼容。

### 5. 圈子选择器与选中状态

- **决策**：Feed 页内部状态 `String? selectedGroupUuid`，`null` 表示「全部」。选择器数据源来自现有 `GroupListProvider`（或等价）提供的用户加入的圈子列表。选择「全部」或某圈时更新 `selectedGroupUuid`，驱动下方使用全部 Feed Provider 或 `GroupFeedProvider(selectedGroupUuid)`；AppBar 标题随选择显示「全部动态」或「{圈子名称}」。

### 6. 空状态

- **决策**：无圈子时（全部 Feed 无数据且圈子列表为空）显示「还没有加入圈子」，按钮「创建圈子」「加入圈子」；有圈子无帖子时显示「暂无帖子」或「去发第一条帖子」。单圈 Feed 无帖子时与现有 `GroupDetailPage` 空状态一致。

### 7. 发帖 FAB 显示规则

- **决策**：发帖 FAB 在**单圈 Feed 页**（用户在选择器中选中某一圈子时）保留显示，点击后发帖默认当前圈；在**全部圈子 Feed 页**（选中「全部」时）不显示 FAB，避免「发到哪一圈」歧义，后续再视产品做优化（如全部视图下 FAB 跳转创建页选圈等）。

## Risks / Trade-offs

- **路由冲突**：若 Tab 仍用 path `groups` 且独立路由也有 `/groups`，需确保 push 到列表用明确 path（如 `/groups/list`）或 name，避免与 Feed 页冲突。→ 在 app_router 中为 GroupListRoute 使用独立 path。
- **Provider 缓存**：切换圈子时各 `GroupFeedProvider(groupUuid)` 会按 family 缓存，首次选某圈会加载，再次选同圈复用；全部 Feed 单例，无额外缓存问题。

## Migration Plan

- 无数据迁移。保留 `GroupListPage` 与 `GroupListRoute`，仅入口从 Tab 改为 Feed 页内「我的圈子」；现有圈子详情、发帖、评论流程不变。用户升级后点击圈子 Tab 即见新 Feed 首屏。

## Open Questions

- 无。发帖 FAB 显示规则已定：单圈 Feed 页保留，全部 Feed 页不显示；后续优化可单独迭代。
