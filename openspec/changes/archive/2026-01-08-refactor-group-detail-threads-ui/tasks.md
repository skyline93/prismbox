## 1. 修复分页逻辑
- [x] 1.1 检查 `group_feed_provider.dart` 中的 `loadMore()` 方法，确保分页计算正确
- [x] 1.2 修复重复显示帖子的 bug（可能是分页索引计算错误或数据去重问题）
- [x] 1.3 添加数据去重逻辑，确保同一帖子不会重复显示
- [x] 1.4 测试分页加载，确保不会重复显示帖子

## 2. 重构圈子详情页面布局
- [x] 2.1 移除或简化 `GroupInfoCard` 组件（不再在页面中显示独立的信息卡片）
- [x] 2.2 将 `GroupDetailPage` 的页面架构改为 `NestedScrollView` + `SliverAppBar`
- [x] 2.3 调整 `SliverAppBar` 为 Threads 风格：
  - 左侧菜单图标（`Icons.sort`，黑色，28px）
  - 中间 logo（`Icons.alternate_email`，黑色，32px）
  - 右侧搜索图标（`Icons.search`，黑色，28px）
  - 白色背景，无阴影，`pinned: true`，`floating: true`
- [x] 2.4 移除页面中的"动态"标题，直接显示 Feed 流
- [x] 2.5 调整页面布局，使 Feed 流从顶部开始（无额外的信息卡片）
- [x] 2.6 保持下拉刷新和上拉加载更多功能

## 3. 重构帖子卡片样式（Threads 风格）
- [x] 3.1 调整 `PostCard` 的整体布局结构：
  - 使用 `Row` 布局，左侧头像列，右侧内容区
  - 左侧头像：`CircleAvatar`（radius: 20），支持头像上的加号图标（`hasAddIcon`）
  - 右侧内容区：`Expanded` + `Column`
- [x] 3.2 调整用户信息区域（顶部一行）：
  - 用户名（`FontWeight.w600`，`fontSize: 15`）
  - 认证标记（蓝色 `Icons.verified`，size: 14，如果有）- 已预留，待后端支持
  - 话题标签（`› Threads travel` 格式，灰色，`fontSize: 14`，如果有）- 已预留，待后端支持
  - `Spacer()` 填充
  - 时间（灰色，`fontSize: 14`）
  - 更多按钮（`Icons.more_horiz`，黑色，size: 20）
- [x] 3.3 调整文字内容显示样式：
  - `fontSize: 15`，`height: 1.3`
  - 上下间距：`top: 4.0`，`bottom: 8.0`
- [x] 3.4 调整媒体显示逻辑：
  - 使用横向滚动的 `ListView.separated`（`scrollDirection: Axis.horizontal`）
  - 固定高度：300px
  - 每张图片固定宽度：220px
  - 图片间距：8px
  - 圆角：12px
  - 支持加载状态显示
- [x] 3.5 添加位置信息显示（如果有）：
  - 灰色文字，`fontSize: 13`
  - 上下间距：`top: 8.0`
  - 已预留，待后端支持 location 字段
- [x] 3.6 调整互动按钮样式和布局：
  - 底部操作栏：`Row` 布局，图标间距 16px
  - 点赞图标：`Icons.favorite_border`，size: 22
  - 评论图标：`Icons.chat_bubble_outline`，size: 22
  - 转发图标：`Icons.autorenew`，size: 22
  - 分享图标：`Icons.send`，size: 22
  - 上下间距：`top: 12.0`，`bottom: 4.0`
- [x] 3.7 添加点赞和回复数显示：
  - 灰色文字，`fontSize: 13`
  - 格式：`$likes likes`，`$replies reply`（如果有）
- [x] 3.8 调整帖子整体样式：
  - 移除卡片边框和背景
  - 使用 `Padding`（`horizontal: 16.0`，`vertical: 12.0`）
  - 帖子之间使用 `Divider`（`height: 1`，`color: Color(0xFFEEEEEE)`）分隔

## 4. 调整媒体网格组件
- [x] 4.1 修改 `PostMediaGrid` 组件，改为横向滚动显示：
  - 使用 `ListView.separated`（`scrollDirection: Axis.horizontal`）
  - 固定高度：300px
  - 每张图片固定宽度：220px
  - 图片间距：8px
  - 圆角：12px
  - 支持加载状态和错误处理
- [x] 4.2 确保图片加载使用项目封装的图片组件（如 `ExtendedImage`），而非直接使用 `Image.network`
  - 已添加 TODO 注释，当前使用 `Image.network`，后续需要替换为项目封装的图片组件

## 5. 调整底部悬浮按钮
- [x] 5.1 将 `FloatingActionButton` 改为使用 `Positioned` 定位的悬浮按钮
- [x] 5.2 按钮样式：
  - 位置：`bottom: 20`，`right: 20`
  - 尺寸：56x56
  - 白色背景，圆角 16px
  - 边框：`Border.all(color: Colors.grey.shade200)`
  - 阴影：`BoxShadow`（`color: Colors.black.withOpacity(0.1)`，`blurRadius: 10`，`offset: Offset(0, 4)`）
  - 图标：`Icons.add`，黑色，size: 32

## 6. 代码质量
- [x] 6.1 运行 linter 检查，修复代码风格问题
- [x] 6.2 确保所有组件遵循 UI 拆分规范（超过 80 行的 build 方法需要拆分）
  - `PostCard` 的 build 方法已拆分为多个私有方法
- [x] 6.3 确保使用 const 构造函数和 const 关键字
  - `PostCard` 和 `PostMediaGrid` 都使用了 const 构造函数
- [x] 6.4 确保使用 `ListView.builder` 或 `ListView.separated` 而非 map 生成列表
  - 页面使用 `ListView.separated`，媒体组件使用 `ListView.separated`

