## ADDED Requirements

### Requirement: Feed 数据源 API（后端）

后端 SHALL 提供两种 Feed 数据源接口：全部圈子 Feed 与指定圈子 Feed；全部 Feed 的每条帖子 SHALL 包含所属圈子信息，以便前端统一展示与跳转。

#### Scenario: 全部圈子 Feed 接口
- **WHEN** 客户端请求全部圈子 Feed（如 `GET /api/v1/groups/feed`）
- **THEN** 后端 SHALL 返回当前用户为其成员的所有圈子中的帖子，按 `created_at DESC` 分页
- **AND** 每条帖子 SHALL 包含 `group_uuid`、`group_name`

#### Scenario: 指定圈子 Feed 接口
- **WHEN** 客户端请求指定圈子 Feed（如 `GET /api/v1/groups/:uuid/feed`）
- **THEN** 后端 SHALL 返回该圈子内的帖子（需为成员），按 `created_at DESC` 分页
- **AND** 帖子项 MAY 包含 `group_uuid`、`group_name` 以与全部 Feed 响应结构一致

#### Scenario: Feed 分页语义一致
- **WHEN** 客户端使用 page、limit 请求任一种 Feed
- **THEN** 后端 SHALL 使用与现有单圈 Feed 相同的分页语义（page 从 1 开始，limit 默认 20）
