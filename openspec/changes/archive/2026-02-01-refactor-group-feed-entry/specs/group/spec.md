## ADDED Requirements

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
