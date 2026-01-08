## MODIFIED Requirements

### Requirement: Feed 流

系统 SHALL 提供 Feed 流功能，在圈子主页展示帖子列表。Feed 流采用 Threads 风格的布局和样式。

#### Scenario: Feed 流展示（Threads 风格）
- **WHEN** 用户进入圈子主页
- **THEN** 系统 SHALL 显示 Feed 流区域（从页面顶部开始，无额外的信息卡片）
- **AND** 系统 SHALL 使用 `ListView` 显示帖子列表
- **AND** 系统 SHALL 帖子之间使用 `Divider` 分隔（高度 1px，颜色 `Color(0xFFEEEEEE)`）
- **AND** 系统 SHALL 显示加载状态
- **AND** 系统 SHALL 调用后端 API 获取帖子列表（第一页）
- **AND** 系统 SHALL 显示每个帖子的卡片（Threads 风格：左侧头像列 + 右侧内容区，用户信息、文字、媒体、位置、互动按钮）

#### Scenario: Feed 流分页加载
- **WHEN** 用户滚动到 Feed 流底部
- **THEN** 系统 SHALL 自动加载下一页数据
- **AND** 系统 SHALL 显示加载指示器
- **AND** 系统 SHALL 追加新帖子到列表
- **AND** 系统 SHALL 确保不会重复显示已加载的帖子（数据去重）

#### Scenario: Feed 流下拉刷新
- **WHEN** 用户下拉刷新 Feed 流
- **THEN** 系统 SHALL 调用后端 API 获取最新数据（重置分页）
- **AND** 系统 SHALL 刷新列表显示
- **AND** 系统 SHALL 确保刷新后不会重复显示帖子

#### Scenario: Feed 流空状态
- **WHEN** 圈子中没有帖子
- **THEN** 系统 SHALL 显示空状态提示
- **AND** 系统 SHALL 显示"发布第一个帖子"提示

#### Scenario: 点击帖子卡片
- **WHEN** 用户点击帖子卡片
- **THEN** 系统 SHALL 导航到帖子详情页面

### Requirement: 帖子卡片样式（Threads 风格）

系统 SHALL 提供 Threads 风格的帖子卡片，展示帖子信息。

#### Scenario: 帖子卡片展示（Threads 风格）
- **WHEN** 显示帖子卡片
- **THEN** 系统 SHALL 使用 `Row` 布局（左侧头像列，右侧内容区）
- **AND** 系统 SHALL 左侧显示头像（`CircleAvatar`，radius: 20），支持头像上的加号图标
- **AND** 系统 SHALL 右侧内容区顶部显示用户信息（用户名、认证标记（蓝色 `Icons.verified`，如果有）、话题标签（`› Threads travel` 格式，如果有）、时间、更多按钮 `Icons.more_horiz`）
- **AND** 系统 SHALL 显示文字内容（`fontSize: 15`，`height: 1.3`，如果有）
- **AND** 系统 SHALL 显示媒体内容（横向滚动的 `ListView.separated`，固定高度 300px，每张图片固定宽度 220px）
- **AND** 系统 SHALL 显示位置信息（灰色文字，`fontSize: 13`，如果有）
- **AND** 系统 SHALL 显示互动按钮行（点赞 `Icons.favorite_border`、评论 `Icons.chat_bubble_outline`、转发 `Icons.autorenew`、分享 `Icons.send`，图标 size: 22，间距 16px）
- **AND** 系统 SHALL 显示点赞和回复数（灰色文字，`fontSize: 13`，格式：`$likes likes`，`$replies reply`）
- **AND** 系统 SHALL 使用简洁的样式（无卡片边框，使用 `Padding`，匹配 Threads 风格）

### Requirement: 媒体显示

系统 SHALL 使用横向滚动的列表显示帖子中的媒体，支持左右滑动查看多张图片（Threads 风格）。

#### Scenario: 媒体横向滚动显示（Threads 风格）
- **WHEN** 帖子有媒体内容
- **THEN** 系统 SHALL 使用横向滚动的 `ListView.separated`（`scrollDirection: Axis.horizontal`）
- **AND** 系统 SHALL 固定高度为 300px
- **AND** 系统 SHALL 每张图片固定宽度为 220px
- **AND** 系统 SHALL 图片间距为 8px
- **AND** 系统 SHALL 图片圆角为 12px
- **AND** 系统 SHALL 支持左右滑动查看多张图片
- **AND** 系统 SHALL 显示加载状态（加载中显示占位符）
- **AND** 系统 SHALL 使用项目封装的图片组件（如 `ExtendedImage`），而非直接使用 `Image.network`

#### Scenario: 点击媒体查看大图
- **WHEN** 用户点击帖子中的媒体
- **THEN** 系统 SHALL 打开媒体查看器
- **AND** 系统 SHALL 支持左右滑动查看多张图片

