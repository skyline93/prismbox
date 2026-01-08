# Change: 重构圈子详情页面为 Threads UI 风格

## Why

当前圈子详情页面的 UI 设计与 Threads 风格不一致，用户体验不佳。主要问题包括：
1. 页面布局不符合 Threads 的简洁风格（有独立的圈子信息卡片，占用空间）
2. 帖子卡片样式与 Threads 不一致（缺少位置信息、话题标签等元素）
3. 向下滑动时会重复显示同样的帖子（分页逻辑存在问题）

需要将圈子详情页面重构为 Threads 风格的 Feed 流布局，提供更一致的用户体验。

## What Changes

- **MODIFIED** 圈子详情页面架构：使用 `NestedScrollView` + `SliverAppBar` 替代 `CustomScrollView`，实现 Threads 风格的浮动导航栏
- **MODIFIED** 圈子详情页面布局：移除独立的圈子信息卡片，改为简洁的顶部导航栏（左侧菜单图标、中间 logo（@ 图标）、右侧搜索图标）
- **MODIFIED** 帖子列表样式：使用 `ListView` + `Divider` 分隔帖子，移除卡片边框，采用简洁的列表样式
- **MODIFIED** 帖子卡片布局：采用左侧头像列 + 右侧内容区的布局结构，匹配 Threads 风格
- **MODIFIED** 帖子卡片样式：包括用户信息（头像、用户名、认证标记、话题标签（`› Threads travel` 格式）、时间、更多按钮）、文字内容、图片（横向滚动显示）、位置信息、互动按钮（点赞、评论、转发、分享图标）、点赞和回复数
- **MODIFIED** Feed 流分页逻辑：修复重复显示帖子的 bug，确保分页正确工作
- **MODIFIED** 帖子媒体显示：使用横向滚动的 `ListView.separated` 显示多张图片（固定高度，每张图片固定宽度），支持左右滑动查看
- **MODIFIED** 底部悬浮按钮：使用 `Positioned` 定位的悬浮按钮替代 `FloatingActionButton`，匹配 Threads 风格

## Impact

- **Affected specs**: 
  - `group` - 圈子详情页面展示需求
  - `post` - Feed 流展示和帖子卡片样式需求
- **Affected code**:
  - `mobile/lib/presentation/pages/groups/group_detail_page.dart` - 页面布局重构
  - `mobile/lib/presentation/widgets/posts/post_card.dart` - 帖子卡片样式调整
  - `mobile/lib/presentation/widgets/posts/post_media_grid.dart` - 媒体显示逻辑调整
  - `mobile/lib/presentation/widgets/groups/group_info_card.dart` - 可能不再需要或简化
  - `mobile/lib/providers/post/group_feed_provider.dart` - 分页逻辑修复

