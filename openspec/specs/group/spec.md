# group Specification

## Purpose
TBD - created by archiving change add-group-feature. Update Purpose after archive.
## Requirements
### Requirement: 创建圈子

系统 SHALL 提供创建圈子的功能，允许用户创建新圈子并设置基本信息。

#### Scenario: 创建圈子页面展示
- **WHEN** 用户进入创建圈子页面
- **THEN** 系统 SHALL 显示圈子名称输入框（必填）
- **AND** 系统 SHALL 显示圈子描述输入框（可选）
- **AND** 系统 SHALL 显示封面图选择区域（可选）
- **AND** 系统 SHALL 显示创建按钮（名称未填写时禁用）

#### Scenario: 创建圈子输入验证
- **WHEN** 用户输入圈子名称
- **THEN** 系统 SHALL 实时验证名称长度（1-100 字符）
- **AND** 系统 SHALL 显示字符数提示
- **AND** 系统 SHALL 在名称有效时启用创建按钮

#### Scenario: 创建圈子成功
- **WHEN** 用户填写圈子名称并点击创建按钮
- **THEN** 系统 SHALL 调用后端 API 创建圈子
- **AND** 系统 SHALL 显示加载状态
- **AND** 系统 SHALL 跳转到新创建的圈子主页
- **AND** 系统 SHALL 显示成功提示

#### Scenario: 创建圈子失败
- **WHEN** 创建圈子 API 调用失败
- **THEN** 系统 SHALL 显示错误提示
- **AND** 系统 SHALL 保持输入内容
- **AND** 系统 SHALL 允许用户重试

### Requirement: 圈子列表

系统 SHALL 提供圈子列表页面，展示用户创建和加入的所有圈子。

#### Scenario: 圈子列表页面展示
- **WHEN** 用户进入圈子列表页面
- **THEN** 系统 SHALL 显示导航栏（标题"我的圈子"，创建按钮）
- **AND** 系统 SHALL 显示加载状态
- **AND** 系统 SHALL 调用后端 API 获取圈子列表
- **AND** 系统 SHALL 显示每个圈子的卡片（封面、名称、成员数）

#### Scenario: 圈子列表空状态
- **WHEN** 用户没有加入任何圈子
- **THEN** 系统 SHALL 显示空状态提示
- **AND** 系统 SHALL 显示"创建第一个圈子"按钮

#### Scenario: 圈子列表刷新
- **WHEN** 用户下拉刷新圈子列表
- **THEN** 系统 SHALL 调用后端 API 获取最新数据
- **AND** 系统 SHALL 刷新列表显示

#### Scenario: 点击圈子卡片
- **WHEN** 用户点击圈子卡片
- **THEN** 系统 SHALL 导航到圈子详情页面

### Requirement: 圈子详情

系统 SHALL 提供圈子详情页面，展示圈子信息、Feed 流和成员列表入口。

#### Scenario: 圈子详情页面展示
- **WHEN** 用户进入圈子详情页面
- **THEN** 系统 SHALL 显示圈子信息卡片（封面、名称、描述、成员数、帖子数）
- **AND** 系统 SHALL 显示 Feed 流（帖子列表，在帖子提案中实现）
- **AND** 系统 SHALL 显示创建帖子按钮（FAB）
- **AND** 系统 SHALL 显示成员列表入口

#### Scenario: 圈子详情数据加载
- **WHEN** 加载圈子详情
- **THEN** 系统 SHALL 显示加载状态
- **AND** 系统 SHALL 调用后端 API 获取圈子详情
- **AND** 系统 SHALL 更新页面显示

#### Scenario: 点击成员列表入口
- **WHEN** 用户点击成员列表入口
- **THEN** 系统 SHALL 导航到成员管理页面

### Requirement: 成员管理

系统 SHALL 提供成员管理功能，允许查看成员列表、邀请成员、移除成员。

#### Scenario: 成员列表展示
- **WHEN** 用户进入成员管理页面
- **THEN** 系统 SHALL 显示成员列表（头像、用户名、角色）
- **AND** 系统 SHALL 区分所有者、管理员、普通成员
- **AND** 系统 SHALL 显示邀请按钮（管理员/所有者可见）

#### Scenario: 创建邀请码
- **WHEN** 管理员或所有者点击创建邀请码
- **THEN** 系统 SHALL 调用后端 API 创建邀请码
- **AND** 系统 SHALL 显示邀请码
- **AND** 系统 SHALL 提供分享功能（复制到剪贴板）

#### Scenario: 移除成员
- **WHEN** 管理员或所有者长按成员项
- **THEN** 系统 SHALL 显示移除选项
- **AND** 系统 SHALL 显示确认对话框
- **AND** 系统 SHALL 调用后端 API 移除成员
- **AND** 系统 SHALL 刷新成员列表（重新调用 API）

### Requirement: 加入圈子

系统 SHALL 提供加入圈子的功能，允许用户通过邀请码加入圈子。

#### Scenario: 使用邀请码加入
- **WHEN** 用户输入邀请码并提交
- **THEN** 系统 SHALL 调用后端 API 验证邀请码
- **AND** 系统 SHALL 如果邀请码有效，将用户添加到圈子
- **AND** 系统 SHALL 跳转到圈子详情页面
- **AND** 系统 SHALL 显示成功提示

#### Scenario: 邀请码无效
- **WHEN** 用户输入无效或过期的邀请码
- **THEN** 系统 SHALL 显示错误提示
- **AND** 系统 SHALL 允许用户重新输入

### Requirement: 退出圈子

系统 SHALL 提供退出圈子的功能，允许普通成员退出圈子。

#### Scenario: 退出圈子
- **WHEN** 普通成员点击退出圈子
- **THEN** 系统 SHALL 显示确认对话框
- **AND** 系统 SHALL 调用后端 API 退出圈子
- **AND** 系统 SHALL 返回圈子列表页面（重新加载列表）
- **AND** 系统 SHALL 显示成功提示

#### Scenario: 所有者不能退出
- **WHEN** 所有者尝试退出圈子
- **THEN** 系统 SHALL 显示提示（需要先转移所有权或删除圈子）

### Requirement: 网络错误处理

系统 SHALL 提供网络错误处理功能，确保在网络异常时提供良好的用户体验。

#### Scenario: 网络错误提示
- **WHEN** API 调用失败（网络错误、服务器错误等）
- **THEN** 系统 SHALL 显示友好的错误提示
- **AND** 系统 SHALL 提供重试按钮
- **AND** 系统 SHALL 允许用户手动重试

#### Scenario: 加载状态显示
- **WHEN** 调用 API 获取数据
- **THEN** 系统 SHALL 显示加载指示器
- **AND** 系统 SHALL 在数据加载完成后隐藏加载指示器

#### Scenario: 离线状态提示
- **WHEN** 设备处于离线状态
- **THEN** 系统 SHALL 显示网络错误提示
- **AND** 系统 SHALL 提示用户检查网络连接
- **AND** 系统 SHALL 提供重试按钮（网络恢复后）

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

### Requirement: 圈子 Tab 默认页为 Feed 页

用户点击底部栏圈子 Tab 时，系统 SHALL 默认进入圈子 Feed 页（展示全部圈子或当前选中的单圈 Feed），而非圈子列表页；圈子列表仍可通过 Feed 页内「我的圈子」等入口进入。

#### Scenario: 点击圈子 Tab 进入 Feed 页
- **WHEN** 用户点击底部栏圈子 Tab
- **THEN** 系统 SHALL 进入圈子 Feed 页（首屏）
- **AND** 系统 SHALL 默认展示「全部圈子」帖子 Feed（或空状态）

#### Scenario: 从 Feed 页进入圈子列表
- **WHEN** 用户在 Feed 页点击「我的圈子」入口
- **THEN** 系统 SHALL 导航到圈子列表页面（GroupListPage）
- **AND** 系统 SHALL 显示用户创建和加入的所有圈子

### Requirement: 圈子选择器

在圈子 Feed 页，系统 SHALL 提供圈子选择器，用于在「全部」与各圈子之间切换 Feed 数据源。

#### Scenario: 选择全部展示全部 Feed
- **WHEN** 用户在圈子选择器中选择「全部」
- **THEN** 系统 SHALL 展示全部圈子帖子 Feed（调用全部 Feed 数据源）
- **AND** 系统 SHALL 将 AppBar 标题显示为「全部动态」或等价文案

#### Scenario: 选择某圈展示该圈 Feed
- **WHEN** 用户在圈子选择器中选择某一圈子
- **THEN** 系统 SHALL 展示该圈子的帖子 Feed（调用单圈 Feed 数据源）
- **AND** 系统 SHALL 将 AppBar 标题显示为该圈子名称

#### Scenario: 选择器数据源
- **WHEN** 显示圈子选择器
- **THEN** 系统 SHALL 显示「全部」与用户加入的圈子列表（数据来自圈子列表 API 或等价 Provider）
- **AND** 系统 SHALL 随当前选中项更新 Feed 列表与标题

### Requirement: 发帖 FAB 显示规则

在圈子 Feed 页，系统 SHALL 仅在单圈视图显示发帖 FAB，在全部 Feed 视图不显示；后续可再优化。

#### Scenario: 单圈 Feed 页显示发帖 FAB
- **WHEN** 用户在圈子选择器中选中某一圈子（非「全部」）
- **THEN** 系统 SHALL 在 Feed 页显示发帖 FAB
- **AND** 用户点击 FAB 后发帖 SHALL 默认选中当前圈子

#### Scenario: 全部 Feed 页不显示发帖 FAB
- **WHEN** 用户在圈子选择器中选中「全部」
- **THEN** 系统 SHALL 在 Feed 页不显示发帖 FAB
- **AND** 用户可通过其他入口（如圈子详情、创建帖子页）发帖，后续再做优化

