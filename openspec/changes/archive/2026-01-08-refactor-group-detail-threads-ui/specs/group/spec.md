## MODIFIED Requirements

### Requirement: 圈子详情

系统 SHALL 提供圈子详情页面，展示圈子信息、Feed 流和成员列表入口。页面布局采用 Threads 风格的简洁设计。

#### Scenario: 圈子详情页面展示（Threads 风格）
- **WHEN** 用户进入圈子详情页面
- **THEN** 系统 SHALL 使用 `NestedScrollView` + `SliverAppBar` 架构
- **AND** 系统 SHALL 显示顶部导航栏（左侧菜单图标 `Icons.sort`、中间 logo `Icons.alternate_email`、右侧搜索图标 `Icons.search`，Threads 风格）
- **AND** 系统 SHALL 导航栏为白色背景，无阴影，支持浮动和固定
- **AND** 系统 SHALL 直接显示 Feed 流（帖子列表，无额外的圈子信息卡片）
- **AND** 系统 SHALL 显示创建帖子按钮（使用 `Positioned` 定位的悬浮按钮，底部右侧，白色背景，圆角，带阴影）
- **AND** 系统 SHALL 显示成员列表入口（在导航栏中）

#### Scenario: 圈子详情数据加载
- **WHEN** 加载圈子详情
- **THEN** 系统 SHALL 显示加载状态
- **AND** 系统 SHALL 调用后端 API 获取圈子详情（用于导航栏标题等）
- **AND** 系统 SHALL 更新页面显示

#### Scenario: 点击成员列表入口
- **WHEN** 用户点击导航栏中的成员列表入口
- **THEN** 系统 SHALL 导航到成员管理页面

