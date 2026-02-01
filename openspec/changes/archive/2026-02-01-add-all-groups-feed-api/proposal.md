# Change: 圈子重构后端改造 — 全部圈子 Feed API

## Why

圈子 Feed 入口重构（以刷内容为主线）需要后端支持「全部圈子 Feed」：用户进入圈子 Tab 时默认展示其加入的所有圈子的帖子按时间混排，而不仅限单圈 Feed。当前后端仅提供 `GET /groups/:uuid/feed`，无法支撑默认首屏的「全部 Feed」能力。

## What Changes

- 新增「全部圈子 Feed」接口：`GET /api/v1/feed` 或 `GET /api/v1/groups/feed`，需登录，返回当前用户作为成员的所有圈子中的帖子，按 `created_at DESC` 分页。
- Service 层新增 `GetMyFeed(ctx, userID, page, pageSize)`，复用用户加入圈子查询与帖子组装逻辑，仅数据源改为多圈帖子。
- Repository 层新增按多 `groupID` 分页查询帖子方法（如 `FindByGroupIDs`），按 `created_at DESC`、limit/offset。
- 帖子响应结构扩展：在 `GroupPostInfo` 中增加可选字段 `group_uuid`、`group_name`；全部 Feed 必带，单圈 Feed 可选带，便于前端统一模型并展示「来自 XX 圈子」。
- 路由注册：在 group 路由中注册新 Feed 路由，并保证与 `GET /:uuid` 无冲突（如 `/feed` 在 `/:uuid` 之前或使用独立前缀）。

## Impact

- Affected specs: `group`, `post`
- Affected code:
  - `backend/internal/api/v1/group/handler.go` — 新增 GetMyFeed Handler
  - `backend/internal/api/v1/group/routes.go` — 注册新 Feed 路由
  - `backend/internal/service/group/service.go` — 新增 GetMyFeed、GroupPostInfo 增加 group 字段
  - `backend/internal/repository/group.go` — 新增 FindByGroupIDs（或等价）
  - `backend/internal/repository/interfaces.go` — GroupPostRepository 接口扩展
