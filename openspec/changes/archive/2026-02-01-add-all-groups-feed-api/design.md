# Design: 全部圈子 Feed API 后端实现

## Context

- 设计依据：`mobile/doc/modules/圈子 Feed 入口重构设计文档.md`，后端改造章节（§4）。
- 现有能力：单圈 Feed 已实现（`GET /groups/:uuid/feed`、`GetGroupFeed`、`FindByGroupID`），帖子响应 `GroupPostInfo` 不含圈子信息。
- 约束：仅返回当前用户为其成员的圈子中的帖子；分页、排序与单圈 Feed 一致（page/limit，created_at DESC）。

## Goals / Non-Goals

- **Goals**：提供「全部圈子 Feed」API；帖子响应可带所属圈子信息；与单圈 Feed 共用响应结构与分页语义。
- **Non-Goals**：不改变单圈 Feed 的 URL 或语义；不涉及前端路由、Tab、选择器实现；不改变发帖、评论、圈子列表等现有 API。

## Decisions

### 1. 全部 Feed 路径

- **决策**：采用 `GET /api/v1/groups/feed`，与现有 `GET /api/v1/groups/:uuid/feed` 同属 group 路由组，语义一致。
- **替代**：`GET /api/v1/feed` 需在顶层注册、易与其它 feed 混淆，故不采用。
- **路由顺序**：在 `groupRoutes` 中必须将 `GET("/feed", handler.GetMyFeed)` 注册在 `GET("/:uuid", ...)` 之前，否则 "feed" 会被当作 uuid 匹配。

### 2. Repository 层：多圈帖子查询

- **决策**：在 `GroupPostRepository` 新增 `FindByGroupIDs(ctx, groupIDs []uint, limit, offset int) ([]*models.GroupPost, error)`。
- **实现要点**：`WHERE group_id IN (?) ORDER BY created_at DESC LIMIT ? OFFSET ?`，Preload Creator 与现有 `FindByGroupID` 一致；groupIDs 为空时返回空列表，由 Service 层保证不传空切片（先查用户加入的圈子）。
- **替代**：在 Service 内循环调用 `FindByGroupID` 再合并排序会导致 N 次查询与排序逻辑重复，故不采用。

### 3. 帖子响应中的圈子信息

- **决策**：在 `GroupPostInfo` 中增加可选字段 `GroupUUID string`、`GroupName string`（json: `group_uuid`, `group_name`）。全部 Feed 必填；单圈 Feed 为保持前端统一模型可选填当前圈子信息。
- **兼容**：未填时前端解析为 null/空，旧客户端忽略该字段，无破坏性。

### 4. Service 层 GetMyFeed 逻辑概要

1. 使用现有 `groupRepo.FindByUserID(ctx, userID)` 获取用户加入的圈子列表。
2. 若列表为空，直接返回空 Feed（与单圈无帖子一致）。
3. 提取 `groupIDs`，调用 `groupPostRepo.FindByGroupIDs(ctx, groupIDs, pageSize, offset)`。
4. 组装帖子时需为每条帖子附带所属圈子的 uuid、name：可从 `FindByUserID` 返回的 `[]*models.Group` 建 map[id]*Group，按 post.GroupID 查找；或由 Repository 返回时带 Group 信息，选一种避免 N+1。
5. 媒体、点赞数、评论数、Creator 等与 `GetGroupFeed` 一致，可抽公共方法减少重复。

## Risks / Trade-offs

- **路由顺序**：若漏将 `/feed` 放在 `/:uuid` 前，会导致 404 或错误匹配。→ 在 routes 中明确注释并单测或手工验证。
- **性能**：全部 Feed 的 groupIDs 可能较多，IN 查询与结果集需合理；当前以「用户加入圈子数」为规模，暂不引入缓存。

## Migration Plan

- 无数据迁移。仅新增接口与可选响应字段，现有单圈 Feed 调用方不受影响。
- 回滚：移除新路由与 `GetMyFeed`、`FindByGroupIDs`，去掉 `GroupPostInfo` 的 group 字段即可。

## Open Questions

- 无。路径与字段名与设计文档一致，可与前端联调时再确认响应 body 是否包一层（如 `{ data: [...] }`）与现有单圈 Feed 是否完全一致。
