# 圈子 Feed 入口重构设计文档

## 目录

1. [方案概述](#1-方案概述)
2. [当前状态分析](#2-当前状态分析)
3. [目标设计（以刷内容为主线）](#3-目标设计以刷内容为主线)
4. [后端改造](#4-后端改造)
5. [前端改造](#5-前端改造)
6. [数据模型与 API 约定](#6-数据模型与-api-约定)
7. [交互与边界情况](#7-交互与边界情况)
8. [实施步骤与任务拆分](#8-实施步骤与任务拆分)
9. [与 OpenSpec 的对应](#9-与-openspec-的对应)

---

## 1. 方案概述

### 1.1 重构目标

将圈子模块从「列表优先」改为「内容优先」：用户点击底部栏的圈子 Tab 时，直接进入 Feed 流页面，默认按时间展示所有圈子的帖子；当用户指定某个圈子时，再展示该圈子的帖子 Feed。去掉「先看圈子列表、再点进某个圈子看 Feed」的中间步骤。

### 1.2 核心功能

1. **默认全部 Feed**：点击圈子 Tab 后直接展示「我加入的所有圈子的帖子」按时间混排的 Feed。
2. **指定圈子 Feed**：用户通过圈子选择器选择某一圈子后，仅展示该圈子的帖子 Feed。
3. **圈子选择器**：在 Feed 页顶部（或合适位置）提供「全部」与各圈子的切换入口。
4. **保留列表与创建**：「我的圈子」列表与「创建圈子」入口从 Tab 首屏移至 Feed 页的次级入口（如 AppBar 菜单或按钮）。

### 1.3 设计原则

1. **内容优先**：主路径是「看帖子」，减少一次点击即可开始刷内容。
2. **与常见产品一致**：主 Tab 进入即 Feed、默认综合流、可筛选到单圈，符合常见社交/社区产品心智。
3. **渐进式改造**：在现有单圈 Feed API 与前端 Provider 基础上扩展，不破坏已有圈子详情、发帖、评论等能力。
4. **前后端职责清晰**：后端提供「全部圈子 Feed」与「单圈 Feed」两种数据源；前端统一 Feed 容器，按当前选择切换数据源。

---

## 2. 当前状态分析

### 2.1 后端现状

| 项目 | 现状 | 说明 |
|------|------|------|
| Feed API | 仅 `GET /api/v1/groups/:uuid/feed` | 路径中必须带 `groupUUID`，仅支持单圈 Feed |
| Service | `GetGroupFeed(ctx, groupUUID, userID, page, pageSize)` | 入参为单圈 UUID |
| Repository | `FindByGroupID(ctx, groupID, limit, offset)` | 按单圈 ID 查帖子，按 `created_at DESC` |
| 帖子响应 | `GroupPostInfo` 不含 `group_uuid` / `group_name` | 单圈场景下前端已知当前圈，未带圈子信息 |

**相关文件**：

- `backend/internal/api/v1/group/handler.go`：`GetGroupFeed`、路由 `GET /:uuid/feed`
- `backend/internal/api/v1/group/routes.go`：`groupRoutes.GET("/:uuid/feed", handler.GetGroupFeed)`
- `backend/internal/service/group/service.go`：`GetGroupFeed`、`GroupFeedResult`、`GroupPostInfo`
- `backend/internal/repository/group.go`：`FindByGroupID`
- `backend/internal/repository/interfaces.go`：`GroupPostRepository.FindByGroupID`

### 2.2 前端现状

| 项目 | 现状 | 说明 |
|------|------|------|
| Tab 与路由 | 圈子 Tab 对应 `GroupListRoute` → `GroupListPage` | 点击 Tab 先进入圈子列表 |
| Feed 数据 | `GroupFeedProvider(groupUuid)`，必传 `groupUuid` | 无「不指定圈子」的 Feed 数据源 |
| API 客户端 | `PostApiClient.getGroupFeed(groupUuid, page, limit)` | 仅调用 `/groups/$groupUuid/feed` |
| 帖子模型 | `Post` 无 `groupUuid` / `groupName` | 无法在全部 Feed 中展示来源圈子或跳转 |
| 创建/列表入口 | 在 `GroupListPage` 导航栏与空状态 | 列表作为首屏时用户可直接看到 |

**相关文件**：

- `mobile/lib/presentation/pages/tab_shell/tab_shell_page.dart`：`AutoTabsRouter` 的 `routes` 含 `GroupListRoute`
- `mobile/lib/presentation/routing/app_router.dart`：TabShell 下 `GroupListRoute.page`，path `groups`
- `mobile/lib/providers/post/group_feed_provider.dart`：`GroupFeedProvider(groupUuid)`
- `mobile/lib/infrastructure/network/post_api_client.dart`：`getGroupFeed(groupUuid, ...)`
- `mobile/lib/data/models/post/post.dart`：`Post` 无圈子字段
- `mobile/lib/presentation/pages/groups/group_list_page.dart`：圈子列表、加入圈子弹窗、创建入口
- `mobile/lib/presentation/pages/groups/group_detail_page.dart`：单圈详情 + Feed，依赖 `groupUuid`

### 2.3 存在的问题

1. **多一步才能看到内容**：用户想「刷圈子动态」时，需先看列表再点进某圈，多一次点击。
2. **没有「全部圈子」Feed**：后端与前端都只支持「单圈 Feed」，无法实现默认的「所有圈子按时间混排」。
3. **全部 Feed 下帖子缺少圈子信息**：若将来有全部 Feed，帖子需带 `group_uuid`/`group_name` 才能展示来源并支持「点进该圈」。
4. **列表作为首屏的必要性不足**：多数场景下用户目的是看帖子，列表可退为次级入口。

---

## 3. 目标设计（以刷内容为主线）

### 3.1 用户路径

- **主路径**：底部栏点击「圈子」→ 直接进入 **Feed 页** → 默认展示「全部圈子」帖子（按时间）→ 可下拉刷新、上拉加载更多。
- **切换圈子**：在 Feed 页通过「圈子选择器」选择某一圈子 → 仅展示该圈子的帖子 Feed；选择「全部」恢复为全部 Feed。
- **次级路径**：在 Feed 页通过「我的圈子」进入圈子列表；通过「创建圈子」进入创建页；从帖子卡片或选择器进入某圈详情（可选，与现有 `GroupDetailPage` 一致）。

### 3.2 信息架构

```
底部 Tab「圈子」
  └── Feed 页（新首屏）
        ├── 圈子选择器（全部 | 圈子 A | 圈子 B | …）
        ├── Feed 流（根据选择：全部 or 单圈）
        ├── AppBar：标题、我的圈子、创建圈子（或 FAB/菜单）
        └── 空状态：无圈子时引导创建/加入；无帖子时提示暂无帖子
```

### 3.3 与现有页面的关系

- **GroupListPage**：不再作为 Tab 默认页，保留路由；从 Feed 页「我的圈子」等入口进入。
- **GroupDetailPage**：保留；从帖子卡片「进入该圈」或从列表点击某圈进入，仍使用 `GroupFeedProvider(groupUuid)` 与单圈 Feed API。
- **CreateGroupPage**：保留；入口改为 Feed 页的「创建圈子」。
- **CreatePostPage / PostDetailPage**：不变；发帖、看帖、评论逻辑不变，仅 Feed 数据源增加「全部 Feed」一种。

---

## 4. 后端改造

### 4.1 新增「全部圈子 Feed」API

**接口约定**：

- **路径**：`GET /api/v1/feed` 或 `GET /api/v1/groups/feed`（不包含 `:uuid`，避免与 `GET /groups/:uuid` 冲突）。
- **鉴权**：需登录；仅返回当前用户作为成员的圈子中的帖子。
- **查询参数**：`page`（默认 1）、`limit`（默认 20），与现有单圈 Feed 一致。
- **响应**：与单圈 Feed 相同的帖子列表结构，但每条帖子需带所属圈子信息（见 4.3）。

**路由注册**（建议在 `group/routes.go`）：

- 在 `groupRoutes` 上增加：`groupRoutes.GET("/feed", handler.GetMyFeed)`（若采用 `GET /api/v1/groups/feed`，需保证该路由在 `GET /:uuid` 之前注册，或使用独立前缀如 `/api/v1/feed`）。

### 4.2 Service 层

**新增方法**：

- `GetMyFeed(ctx context.Context, userID uint, page, pageSize int) (*GroupFeedResult, error)`

**逻辑概要**：

1. 查询当前用户加入的圈子 ID 列表（可复用 `groupRepo` 的「用户加入的圈子」查询，或通过现有 GetMyGroups 所用逻辑）。
2. 若圈子列表为空，直接返回空列表（与单圈无帖子一致）。
3. 调用 Repository 层按「多个 groupID」分页查询帖子，按 `created_at DESC` 排序（见 4.3）。
4. 组装帖子列表时，为每条帖子附带其所属圈子的 `uuid`、`name`（用于全部 Feed 展示与跳转）。
5. 其余逻辑（媒体、点赞数、评论数、Creator 等）与现有 `GetGroupFeed` 保持一致，可抽公共方法减少重复。

### 4.3 Repository 层

**可选方案**：

- **方案 A**：在 `GroupPostRepository` 增加方法：  
  `FindByGroupIDs(ctx context.Context, groupIDs []uint, limit, offset int) ([]*models.GroupPost, error)`  
  - 实现：`WHERE group_id IN (?) ORDER BY created_at DESC LIMIT ? OFFSET ?`，Preload Creator 等与现有一致。
- **方案 B**：不新增接口，在 Service 中先查用户加入的 group IDs，再在现有单表上写一条「IN + ORDER BY created_at」查询（可放在 group 相关 repo 或新方法中，避免 N+1）。

**要求**：排序必须按帖子 `created_at` 降序，分页语义与单圈 Feed 一致。

### 4.4 响应结构中帖子的「所属圈子」信息

- **单圈 Feed**（`GET /groups/:uuid/feed`）：可保持不变；若为统一前端模型，也可在 `GroupPostInfo` 中增加可选字段，单圈时一并返回当前圈子信息。
- **全部 Feed**（`GET /feed` 或 `GET /groups/feed`）：每条帖子**必须**带所属圈子信息，便于前端展示「来自 XX 圈子」并跳转。

**建议**：在 `GroupPostInfo` 中增加可选字段（或单独定义 `FeedPostInfo` 内嵌 `GroupPostInfo` 并增加）：

- `group_uuid`（string）
- `group_name`（string）

单圈 Feed 时由后端填当前圈子；全部 Feed 时填每条帖子所属圈子。前端 `Post` 模型相应增加可选字段（见 5.5）。

---

## 5. 前端改造

### 5.1 路由与 Tab 默认页

**修改**：

- TabShell 下第三个 Tab 的默认页由 **GroupListPage** 改为 **Feed 页**（新建页面，见下）。
- 新建路由与页面组件，例如：
  - 路由名：`GroupFeedRoute` 或 `CirclesFeedRoute`（与现有命名风格一致）。
  - 路径：如 `groups` 保持不变，仅将对应 Page 从 `GroupListPage` 换为新的 Feed 页组件。

**涉及文件**：

- `lib/presentation/routing/app_router.dart`：TabShell 的 children 中，将 `GroupListRoute` 换为 `GroupFeedRoute`（或新命名）；并保留 `GroupListRoute` 为独立路由（供「我的圈子」跳转）。
- `lib/presentation/pages/tab_shell/tab_shell_page.dart`：`AutoTabsRouter` 的 `routes` 中对应项改为新 Feed 页 Route。
- 新建：`lib/presentation/pages/groups/group_feed_page.dart`（或 `circles_feed_page.dart`）作为圈子 Tab 的默认页。

### 5.2 Feed 页组件职责

- 顶部：AppBar（标题随当前选择变化：「全部动态」/「{圈子名称}」）、「我的圈子」入口、「创建圈子」入口。
- 圈子选择器：横向列表或下拉，选项为「全部」+ 用户加入的圈子列表（数据来自 `GroupListProvider` 或等价来源）；选中项驱动下方 Feed 数据源。
- 中部：Feed 列表（复用现有帖子卡片与滚动、下拉刷新、上拉加载更多逻辑）。
- 空状态：无圈子时提示「还没有加入圈子」+ 按钮「创建圈子」「加入圈子」；有圈子无帖子时提示「暂无帖子」等。
- 发帖 FAB：可选；若保留，发帖时需根据当前选择决定默认圈子（单圈时默认该圈，全部时需用户选择圈子或进入创建帖子页再选）。

### 5.3 数据层：全部 Feed 与单圈 Feed

**API 客户端**（`PostApiClient`）：

- 新增方法：`getMyFeed({ int page = 1, int limit = 20 })`，请求 `GET /api/v1/feed`（或你们最终确定的「全部 Feed」URL），解析返回的帖子列表（与现有 `getGroupFeed` 返回结构一致，且含 `group_uuid`/`group_name`）。

**Provider**（二选一或组合）：

- **方案 A**：  
  - 新增 `AllGroupsFeedProvider`（无参）：内部调用 `getMyFeed`，实现与 `GroupFeedProvider` 类似的 `load`、`refresh`、`loadMore`。  
  - 保留 `GroupFeedProvider(groupUuid)` 用于单圈。  
  - Feed 页根据「当前选中的是全部还是某圈」选择监听 `AllGroupsFeedProvider` 或 `GroupFeedProvider(selectedGroupUuid)`。
- **方案 B**：  
  - 统一为「Feed 源」Provider：参数为 `String?`，`null` 表示全部，非空表示 `groupUuid`。  
  - 内部根据参数调用 `getMyFeed` 或 `getGroupFeed(groupUuid)`，对外暴露统一的 `load`/`refresh`/`loadMore` 与 `AsyncValue<List<Post>>`。

**推荐**：方案 A 实现简单、与现有 `GroupFeedProvider` 并存清晰；若希望少一个 Provider 类型，可采用方案 B。

### 5.4 圈子选择器与「当前选中圈子」状态

- Feed 页内部状态：`String? selectedGroupUuid`，`null` 表示「全部」。
- 选择器数据源：`GroupListProvider`（或等价）提供的用户加入的圈子列表。
- 选择「全部」：`selectedGroupUuid = null`，使用全部 Feed Provider。
- 选择某圈：`selectedGroupUuid = group.uuid`，使用 `GroupFeedProvider(group.uuid)`。
- 标题/AppBar 随 `selectedGroupUuid` 更新：「全部动态」或「{圈子名称}」。

### 5.5 帖子模型与帖子卡片

- **Post 模型**（`lib/data/models/post/post.dart`）：增加可选字段，例如 `String? groupUuid`、`String? groupName`，在 `fromJson` 中解析（兼容单圈 Feed 不返回时的 null）。
- **帖子卡片**（如 `PostCard`）：当 `post.groupName != null` 时，展示「来自 {groupName}」或小标签；点击可跳转到该圈子 Feed（将 `selectedGroupUuid` 设为该 `groupUuid` 或导航到 `GroupDetailPage(groupUuid)`，视产品选择）。

### 5.6 「我的圈子」与「创建圈子」入口

- 在 Feed 页 AppBar 或顶部区域增加：
  - 「我的圈子」：导航到现有 `GroupListPage`（保留 `GroupListRoute`，从 Feed 页 push 或替换到该路由）。
  - 「创建圈子」：导航到现有 `CreateGroupPage`。
- 加入圈子（邀请码）可保留在 `GroupListPage` 的弹窗或入口，或按需在 Feed 页提供快捷入口。

### 5.7 空状态与无圈子用户

- 当「全部 Feed」无数据且用户圈子列表为空：显示空状态「还没有加入圈子」，按钮「创建圈子」「加入圈子」（跳转逻辑与现有一致）。
- 当「全部 Feed」无数据但用户有圈子：显示「暂无帖子」或「去发第一条帖子」等。
- 当选择单圈且该圈无帖子：与现有 `GroupDetailPage` 空状态一致。

---

## 6. 数据模型与 API 约定

### 6.1 全部 Feed 请求/响应（建议）

**请求**：

- `GET /api/v1/feed?page=1&limit=20`  
- Header：鉴权（如 Bearer Token）。

**响应**（与单圈 Feed 对齐，仅帖子项增加圈子信息）：

-  body 为数组或包装对象，元素与现有单圈 Feed 的帖子结构一致，每条增加：
  - `group_uuid`（string，可选）
  - `group_name`（string，可选）

### 6.2 单圈 Feed 扩展（可选）

- 为保持前端模型统一，单圈 Feed 的帖子也可在响应中带上 `group_uuid`、`group_name`（即当前圈子），前端解析后与全部 Feed 使用同一 `Post` 模型。

### 6.3 前端 Post 模型扩展

- 在 `Post` 中增加：`final String? groupUuid;`、`final String? groupName;`。
- `fromJson`：`groupUuid = json['group_uuid'] as String?;`，`groupName = json['group_name'] as String?;`。
- `toJson`、拷贝构造等按需补充，保证向后兼容（旧接口不返回时为 null）。

---

## 7. 交互与边界情况

### 7.1 下拉刷新与加载更多

- 与现有单圈 Feed 一致：下拉刷新重置为第一页；滚动到底部触发加载更多（下一页）。
- 全部 Feed 与单圈 Feed 使用相同分页参数（page/limit），后端保证排序稳定（按 `created_at DESC`）。

### 7.2 切换圈子时的 Feed 切换

- 从「全部」切换到某圈：展示该圈的 Feed，若该圈 Feed 未加载过，则触发 `GroupFeedProvider(groupUuid)` 的加载。
- 从某圈切换到「全部」：展示全部 Feed，若未加载过则触发全部 Feed Provider 的加载。
- 可选：切换时保留上一数据源的最后列表位置（如使用 PageStorageKey 或记录 scrollOffset），以提升返回时的体验。

### 7.3 发帖与评论

- 发帖、评论接口与权限不变；发帖时若在单圈视图下可默认选中当前圈，在全部视图下需在创建帖子页选择圈子（与现有 create post 流程一致）。
- 帖子详情、评论列表仍使用现有接口；帖子所属圈子由帖子数据中的 `group_uuid` 提供，用于返回 Feed 或进入该圈详情。

### 7.4 无圈子用户

- 首次进入 Feed 页且用户无任何圈子：不请求全部 Feed API（或请求后为空），结合圈子列表为空，显示「还没有加入圈子」空状态，引导创建或加入圈子。
- 创建或加入第一个圈子后，再进入 Feed 页即显示全部 Feed（一条或零条帖子）。

### 7.5 权限与安全

- 全部 Feed 仅返回当前用户为其成员的圈子中的帖子；后端在 `GetMyFeed` 中严格按「用户加入的 group IDs」过滤，不暴露非成员圈子的帖子。

---

## 8. 实施步骤与任务拆分

### 8.1 后端

| 序号 | 任务 | 说明 |
|------|------|------|
| B1 | 新增 `GET /api/v1/feed`（或 `/api/v1/groups/feed`）路由与 Handler | 解析 page/limit，调用 Service |
| B2 | Service：实现 `GetMyFeed(ctx, userID, page, pageSize)` | 查用户加入的圈子 ID，再查帖子、组装结果 |
| B3 | Repository：实现按多 groupID 分页查帖子（如 `FindByGroupIDs`） | 按 created_at DESC，limit/offset |
| B4 | 响应中帖子增加 `group_uuid`、`group_name` | 全部 Feed 必带；单圈 Feed 可选带 |
| B5 | 单圈 Feed 响应结构（可选） | 在 `GroupPostInfo` 中增加 group 字段，便于前端统一模型 |

### 8.2 前端

| 序号 | 任务 | 说明 |
|------|------|------|
| F1 | 新增 `GroupFeedPage`（或 `CirclesFeedPage`） | 包含选择器、Feed 列表、AppBar、空状态 |
| F2 | 路由：Tab 默认页改为 Feed 页，保留 `GroupListRoute` | 修改 app_router、tab_shell_page |
| F3 | PostApiClient：新增 `getMyFeed(page, limit)` | 请求全部 Feed API，解析列表 |
| F4 | 新增全部 Feed Provider（或统一 Feed 源 Provider） | load/refresh/loadMore，与现有 GroupFeedProvider 对齐 |
| F5 | Post 模型：增加 `groupUuid`、`groupName`（可选） | fromJson/toJson 兼容 |
| F6 | Feed 页：圈子选择器 + 当前选中状态 | 绑定 AllGroupsFeedProvider / GroupFeedProvider |
| F7 | Feed 页：AppBar「我的圈子」「创建圈子」入口 | 跳转到 GroupListPage、CreateGroupPage |
| F8 | 帖子卡片：展示「来自 XX 圈子」及跳转 | 当 groupName 非空时显示，点击切到该圈 Feed 或详情 |
| F9 | 空状态：无圈子 / 无帖子 | 与 5.7、7.4 一致 |
| F10 | 发帖 FAB 或入口（可选） | 单圈时默认当前圈，全部时在创建页选圈 |

### 8.3 建议顺序

1. 后端 B3 → B2 → B1 → B4（B5 可选）。
2. 前端 F3、F5 → F4 → F1、F2、F6 → F7、F8、F9 → F10（可选）。
3. 联调：全部 Feed 接口与 Feed 页、选择器、空状态；再验证单圈 Feed 与现有详情页、发帖、评论无回归。

---

## 9. 与 OpenSpec 的对应

### 9.1 涉及的 Spec

- **group**（`openspec/specs/group/spec.md`）：当前有「圈子列表」「圈子详情」等需求；本重构相当于**修改**「圈子列表」在主流程中的角色（不再作为 Tab 首屏），并**新增**「全部圈子 Feed」与「Feed 页作为圈子 Tab 默认」等行为。
- **post**（`openspec/specs/post/spec.md`）：Feed 流需求扩展为「支持全部圈子 Feed」与「支持按圈子筛选」，帖子展示需支持「所属圈子」信息。

### 9.2 建议的变更提案（Change Proposal）

- **Change-ID**：如 `update-group-feed-entry`。
- **Spec 变更**：
  - **group**：MODIFIED「圈子列表」：从「用户进入圈子列表页面」作为 Tab 默认改为「用户进入圈子 Feed 页面（默认全部 Feed）」；ADDED「全部圈子 Feed」：当用户进入圈子 Feed 且未选择圈子时，系统展示所有加入圈子的帖子按时间排序的 Feed；ADDED「圈子选择器」：在 Feed 页提供全部/单圈切换。
  - **post**：MODIFIED「Feed 流」：扩展为支持「全部圈子 Feed」与「指定圈子 Feed」；帖子展示可包含所属圈子信息（用于全部 Feed）。
- **Migration**：保留圈子列表页面与路由，仅入口从 Tab 改为 Feed 页内「我的圈子」；现有单圈详情、发帖、评论 API 与流程不变。

### 9.3 文档与实现一致性

- 实现完成后，将本设计文档中的「实施步骤」与 `tasks.md` 对齐，并在 OpenSpec 变更归档时更新 `specs/group/spec.md` 与 `specs/post/spec.md`，使文档与代码一致。

---

## 附录：相关文件索引

### 后端

- `backend/internal/api/v1/group/handler.go` — GetGroupFeed、需新增 GetMyFeed
- `backend/internal/api/v1/group/routes.go` — 注册新 Feed 路由
- `backend/internal/service/group/service.go` — GetGroupFeed、GroupPostInfo、需新增 GetMyFeed
- `backend/internal/repository/group.go` — FindByGroupID、需新增 FindByGroupIDs 或等价
- `backend/internal/repository/interfaces.go` — GroupPostRepository 接口

### 前端（Mobile）

- `mobile/lib/presentation/routing/app_router.dart` — TabShell children、GroupListRoute
- `mobile/lib/presentation/pages/tab_shell/tab_shell_page.dart` — Tab 路由列表
- `mobile/lib/presentation/pages/groups/group_list_page.dart` — 保留，入口改为 Feed 页
- `mobile/lib/presentation/pages/groups/group_detail_page.dart` — 保留，单圈详情与 Feed
- `mobile/lib/providers/post/group_feed_provider.dart` — GroupFeedProvider
- `mobile/lib/providers/group/group_list_provider.dart` — 圈子列表，供选择器使用
- `mobile/lib/infrastructure/network/post_api_client.dart` — getGroupFeed、需新增 getMyFeed
- `mobile/lib/data/models/post/post.dart` — Post 模型，需增加 groupUuid/groupName

---

*文档版本：1.0 | 与「以刷内容为主线的圈子 Feed 入口」设计一致*
