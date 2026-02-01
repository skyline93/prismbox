## MODIFIED Requirements

### Requirement: Feed 流

系统 SHALL 提供 Feed 流功能，支持「全部圈子 Feed」与「指定圈子 Feed」两种数据源；在圈子 Feed 页（Tab 默认）或圈子详情页展示帖子列表；帖子卡片可展示所属圈子信息（当有 groupName 时），并支持跳转至该圈 Feed 或详情。

#### Scenario: Feed 流展示
- **WHEN** 用户进入圈子主页（Feed 页或圈子详情页）
- **THEN** 系统 SHALL 显示 Feed 流区域
- **AND** 系统 SHALL 显示加载状态
- **AND** 系统 SHALL 调用后端 API 获取帖子列表（第一页；全部 Feed 或单圈 Feed 依当前选择）
- **AND** 系统 SHALL 显示每个帖子的卡片（用户信息、文字、媒体、互动按钮）

#### Scenario: Feed 流分页加载
- **WHEN** 用户滚动到 Feed 流底部
- **THEN** 系统 SHALL 自动加载下一页数据
- **AND** 系统 SHALL 显示加载指示器
- **AND** 系统 SHALL 追加新帖子到列表

#### Scenario: Feed 流下拉刷新
- **WHEN** 用户下拉刷新 Feed 流
- **THEN** 系统 SHALL 调用后端 API 获取最新数据（重置分页）
- **AND** 系统 SHALL 刷新列表显示

#### Scenario: Feed 流空状态
- **WHEN** 圈子中没有帖子（或全部 Feed 无帖子且用户有圈子）
- **THEN** 系统 SHALL 显示空状态提示
- **AND** 系统 SHALL 显示「发布第一个帖子」或「暂无帖子」等等价文案

#### Scenario: 点击帖子卡片
- **WHEN** 用户点击帖子卡片
- **THEN** 系统 SHALL 导航到帖子详情页面

#### Scenario: 全部圈子 Feed 展示
- **WHEN** 用户在圈子 Feed 页且选择「全部」
- **THEN** 系统 SHALL 调用全部圈子 Feed API（如 GET /api/v1/groups/feed）获取帖子
- **AND** 系统 SHALL 按时间倒序展示所有加入圈子的帖子
- **AND** 帖子项可包含 group_uuid、group_name（由后端返回，用于展示来源圈子）

#### Scenario: 切换圈子切换 Feed 数据源
- **WHEN** 用户在圈子选择器从「全部」切换到某圈或从某圈切换到「全部」
- **THEN** 系统 SHALL 切换 Feed 数据源（全部 Feed Provider 或单圈 Feed Provider）
- **AND** 系统 SHALL 展示对应数据（若未加载过则触发加载）

#### Scenario: 帖子卡片展示所属圈子与跳转
- **WHEN** 帖子数据包含 groupName（非空）
- **THEN** 系统 SHALL 在帖子卡片上展示「来自 {groupName}」或等价标签
- **AND** 系统 SHALL 支持用户点击该区域跳转到该圈子 Feed 或圈子详情页（视产品选择）
