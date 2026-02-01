## ADDED Requirements

### Requirement: 全部圈子 Feed API

后端 SHALL 提供「全部圈子 Feed」接口，供已登录用户获取其加入的所有圈子中的帖子，按发布时间倒序分页返回。

#### Scenario: 全部 Feed 请求成功
- **WHEN** 已认证用户请求 `GET /api/v1/groups/feed`（或约定的全部 Feed 路径）并携带有效鉴权
- **THEN** 系统 SHALL 返回当前用户作为成员的所有圈子中的帖子列表
- **AND** 帖子 SHALL 按 `created_at DESC` 排序
- **AND** 支持 `page`、`limit` 分页参数（默认与单圈 Feed 一致，如 page=1、limit=20）
- **AND** 每条帖子 SHALL 包含所属圈子的 `group_uuid`、`group_name`

#### Scenario: 全部 Feed 无圈子
- **WHEN** 用户未加入任何圈子时请求全部 Feed
- **THEN** 系统 SHALL 返回空列表（与单圈无帖子一致）

#### Scenario: 全部 Feed 鉴权
- **WHEN** 未认证或无效鉴权请求全部 Feed
- **THEN** 系统 SHALL 返回 401 未认证

#### Scenario: 全部 Feed 仅限成员圈子
- **WHEN** 组装全部 Feed 结果
- **THEN** 系统 SHALL 仅包含当前用户为其成员的圈子中的帖子，不暴露非成员圈子内容

### Requirement: Feed 帖子响应包含所属圈子信息

Feed 接口返回的帖子项 SHALL 可包含所属圈子信息，以便前端在「全部 Feed」中展示来源圈子并支持跳转。

#### Scenario: 全部 Feed 帖子带圈子信息
- **WHEN** 客户端请求全部圈子 Feed
- **THEN** 每条帖子项 SHALL 包含 `group_uuid`、`group_name`（所属圈子）

#### Scenario: 单圈 Feed 帖子可选带圈子信息
- **WHEN** 客户端请求单圈 Feed（`GET /groups/:uuid/feed`）
- **THEN** 帖子项 MAY 包含当前圈子的 `group_uuid`、`group_name`，便于前端与全部 Feed 使用同一 Post 模型
