# Tasks: add-all-groups-feed-api

## 1. Implementation

- [x] 1.1 Repository：在 `GroupPostRepository` 接口中新增 `FindByGroupIDs(ctx, groupIDs []uint, limit, offset int) ([]*models.GroupPost, error)`，并在 `backend/internal/repository/group.go` 中实现（WHERE group_id IN (?), ORDER BY created_at DESC, Preload Creator）。
- [x] 1.2 Service：在 group Service 接口与实现中新增 `GetMyFeed(ctx, userID, page, pageSize) (*GroupFeedResult, error)`；内部调用 `FindByUserID` 取用户加入的圈子，若为空则返回空 Feed，否则调用 `FindByGroupIDs`，组装帖子时为每条填充所属圈子的 uuid、name（与 GetGroupFeed 共享媒体/点赞/评论/Creator 等组装逻辑，可抽公共方法）。
- [x] 1.3 响应结构：在 `GroupPostInfo` 中增加 `GroupUUID`、`GroupName` 字段（json: `group_uuid`, `group_name`）；GetMyFeed 必填，GetGroupFeed 可选填当前圈子信息。
- [x] 1.4 Handler：在 `backend/internal/api/v1/group/handler.go` 中新增 `GetMyFeed` Handler，解析 page/limit（默认 1、20），调用 `GetMyFeed` Service，返回与单圈 Feed 一致的响应格式（如 `response.Success(c, ..., result.Posts)`）。
- [x] 1.5 路由：在 `backend/internal/api/v1/group/routes.go` 的 `groupRoutes` 中，在 `GET("/:uuid", ...)` 之前注册 `GET("/feed", handler.GetMyFeed)`，并添加注释说明路由顺序要求。
- [x] 1.6 单圈 Feed 响应（可选）：在 `GetGroupFeed` 组装 `GroupPostInfo` 时填充当前圈子的 `group_uuid`、`group_name`，便于前端统一 Post 模型。
- [x] 1.7 单元测试：为 `FindByGroupIDs`、`GetMyFeed` 编写单元测试（含空圈子、分页、权限仅限成员圈子）。
