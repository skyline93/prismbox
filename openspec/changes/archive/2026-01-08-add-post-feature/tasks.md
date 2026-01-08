## 1. 创建数据模型

- [x] 1.1 创建 `mobile/lib/data/models/post/post.dart` 文件
- [x] 1.2 实现 `Post` 实体类，包含 id、groupId、creatorId、caption、createdAt 等字段（仅用于 API 响应解析）
- [x] 1.3 创建 `mobile/lib/data/models/post/post_media.dart` 文件
- [x] 1.4 实现 `PostMedia` 实体类，包含 postId、mediaUuid 等字段（仅用于 API 响应解析）
- [x] 1.5 创建 `mobile/lib/data/models/post/comment.dart` 文件
- [x] 1.6 实现 `Comment` 实体类，包含 id、postId、userId、content、parentCommentId、createdAt 等字段（仅用于 API 响应解析）

## 2. 创建帖子任务模型和数据库表

- [x] 2.1 创建 `mobile/lib/data/database/enums/post_task_status.dart` 文件
- [x] 2.2 定义帖子任务状态枚举（pending、uploading_media、media_uploaded、creating_post、completed、failed）
- [x] 2.3 创建 `mobile/lib/data/database/tables/post_task_entity.dart` 文件
- [x] 2.4 定义 PostTask 数据库表（taskId、groupId、caption、mediaPaths、mediaUuids、status、progress、errorMessage、createdAt、updatedAt）
- [x] 2.5 在 `app_database.dart` 中添加 PostTask 表定义
- [x] 2.6 创建 `mobile/lib/data/database/daos/post_task_dao.dart` 文件
- [x] 2.7 实现 PostTaskDao，提供 CRUD 操作

## 3. 创建网络层

- [x] 3.1 创建 `mobile/lib/infrastructure/network/post_api_client.dart` 文件
- [x] 3.2 实现帖子相关 API 调用（创建、获取 Feed、获取详情、删除等）
- [x] 3.3 实现评论相关 API 调用（添加评论、获取评论列表、删除评论）
- [x] 3.4 实现错误处理和重试机制

## 4. 创建帖子任务管理器

- [x] 4.1 创建 `mobile/lib/services/post/post_task_manager.dart` 文件
- [x] 4.2 实现 PostTaskManager 类，管理帖子发布任务
- [x] 4.3 实现创建任务方法（保存任务到数据库）
- [x] 4.4 实现任务执行方法（媒体上传 → 创建帖子）
- [x] 4.5 实现媒体上传集成（调用 UploadService）
- [x] 4.6 实现创建帖子 API 调用
- [x] 4.7 实现任务状态更新和进度跟踪
- [x] 4.8 实现任务失败处理和重试机制
- [x] 4.9 实现任务取消功能（基础实现，需要完善）

## 5. 创建服务层

- [x] 5.1 创建 `mobile/lib/services/post/post_service.dart` 文件
- [x] 5.2 实现 `PostService` 类，封装业务逻辑
- [x] 5.3 实现创建帖子方法（调用 PostTaskManager 创建后台任务）
- [x] 5.4 实现获取 Feed 流方法（分页加载、直接调用 API）
- [x] 5.5 实现获取帖子详情方法（直接调用 API）
- [x] 5.6 实现删除帖子方法（直接调用 API）
- [x] 5.7 实现错误处理和重试机制
- [x] 5.8 预留缓存接口（注释说明后续可添加缓存层）
- [x] 5.9 创建 `mobile/lib/services/post/comment_service.dart` 文件
- [x] 5.10 实现 `CommentService` 类，封装评论业务逻辑

## 6. 创建 Provider 层

- [x] 6.1 创建 `mobile/lib/providers/post/group_feed_provider.dart` 文件
- [x] 6.2 实现 `groupFeedProvider`，管理 Feed 流状态（使用 family 参数区分圈子）
- [x] 6.3 实现分页加载逻辑
- [x] 6.4 创建 `mobile/lib/providers/post/post_detail_provider.dart` 文件
- [x] 6.5 实现 `postDetailProvider`，管理帖子详情状态
- [x] 6.6 创建 `mobile/lib/providers/post/comments_provider.dart` 文件
- [x] 6.7 实现 `commentsProvider`，管理评论列表状态
- [x] 6.8 创建 `mobile/lib/providers/post/post_task_provider.dart` 文件
- [x] 6.9 实现 `postTaskProvider`，管理帖子任务状态（监听任务状态变化）

## 7. 实现 Threads 风格的创建帖子页面

- [x] 7.1 更新 `mobile/lib/presentation/pages/posts/create_post_page.dart`
- [x] 7.2 实现顶部导航栏（取消按钮、标题"新建串文"、更多选项）
- [x] 7.3 实现用户信息区域（头像、用户名、添加话题入口）
- [x] 7.4 实现文字输入区域（多行文本输入框，占位符"有什么新鲜事吗?"）
- [x] 7.5 实现媒体选择工具栏（图片、GIF、列表、引用、更多选项）- 基础实现，部分功能待完善
- [x] 7.6 实现底部操作栏（回复选项、表情开关、发布按钮）
- [x] 7.7 实现媒体预览区域（显示选中媒体的缩略图网格，支持删除）
- [x] 7.8 实现发布按钮状态管理（有媒体或文字时启用）
- [x] 7.9 实现媒体选择功能（使用时间线组件在上滑抽屉中显示，复用 LocalAssetEntity）
  - [x] 7.9.1 创建 `PostMediaSelectionBottomSheet` 组件（使用 DraggableScrollableSheet）
  - [x] 7.9.2 在抽屉中集成 `SelectableTimelineSliverListBuilder`
  - [x] 7.9.3 使用 `timelineSectionsProvider` 获取时间线数据
  - [x] 7.9.4 使用 `assetSelectionProvider` 管理选择状态
  - [x] 7.9.5 实现多选功能（最多 9 张）
  - [x] 7.9.6 实现选择确认和关闭抽屉
  - [x] 7.9.7 将选中的 LocalAssetEntity 转换为媒体预览
- [x] 7.10 实现发布功能（调用 PostService 创建后台任务）
- [x] 7.11 实现任务进度显示（如果用户仍在页面）- 使用轮询方式
- [x] 7.12 实现任务状态监听（使用 postTaskProvider）

## 8. 创建 UI 组件

- [x] 8.1 创建 `mobile/lib/presentation/widgets/posts/post_card.dart` 文件
- [x] 8.2 实现 `PostCard` 组件，展示帖子卡片（用户信息、文字、媒体、互动按钮）
- [x] 8.3 创建 `mobile/lib/presentation/widgets/posts/post_media_grid.dart` 文件
- [x] 8.4 实现 `PostMediaGrid` 组件，展示帖子媒体（支持单图、多图网格）
- [x] 8.5 创建 `mobile/lib/presentation/widgets/posts/comment_item.dart` 文件
- [x] 8.6 实现 `CommentItem` 组件，展示评论项（头像、用户名、内容、回复）
- [x] 8.7 创建 `mobile/lib/presentation/widgets/posts/comment_input.dart` 文件
- [x] 8.8 实现 `CommentInput` 组件，评论输入框（支持回复）

## 9. 创建页面

- [x] 9.1 创建 `mobile/lib/presentation/pages/posts/create_post_page.dart` 文件（基础框架已存在，需要完善）
- [x] 9.2 实现 `CreatePostPage`，包含媒体选择、文字输入、发布功能（需要更新为 Threads 风格）
- [x] 9.3 创建 `mobile/lib/presentation/pages/posts/post_detail_page.dart` 文件
- [x] 9.4 实现 `PostDetailPage`，展示帖子详情、评论列表、添加评论
- [x] 9.5 修改 `GroupDetailPage`，集成 Feed 流组件

## 10. 集成 Feed 流到圈子主页

- [x] 10.1 在 `GroupDetailPage` 中添加 Feed 流区域
- [x] 10.2 实现下拉刷新功能
- [x] 10.3 实现上拉加载更多功能
- [x] 10.4 实现点击帖子卡片跳转到详情页

## 11. 配置路由

- [x] 11.1 在 `app_router.dart` 中添加 `CreatePostRoute`
- [x] 11.2 在 `app_router.dart` 中添加 `PostDetailRoute`

## 12. 实现媒体处理和上传

- [x] 12.1 实现媒体选择功能（使用时间线组件在上滑抽屉中显示，复用 LocalAssetEntity）
  - [x] 12.1.1 创建媒体选择抽屉组件
  - [x] 12.1.2 集成时间线组件显示媒体
  - [x] 12.1.3 实现多选功能
  - [x] 12.1.4 从 LocalAssetEntity 获取选中的媒体信息
- [x] 12.2 实现媒体预览功能（显示选中媒体的缩略图）
- [x] 12.3 实现媒体上传功能（集成 UploadService，使用 background_downloader）
  - [x] 12.3.1 修改 PostTaskManager._uploadMedia，使用 LocalAssetEntity 的 assetId
  - [x] 12.3.2 确保选中的媒体在 LocalAssetEntity 中存在
  - [x] 12.3.3 使用真实的 assetId 创建上传任务（而不是临时 ID）
- [x] 12.4 实现媒体上传进度跟踪 - 在 PostTaskManager 中实现
- [x] 12.5 实现媒体显示优化（缩略图、懒加载）

## 13. 实现后台任务处理

- [x] 13.1 实现任务创建（用户点击发布后创建后台任务）- 在 CreatePostPage 中实现
- [x] 13.2 实现媒体上传阶段（调用 UploadService 上传所有媒体）- 在 PostTaskManager 中实现
- [x] 13.3 实现创建帖子阶段（所有媒体上传完成后调用创建帖子 API）- 在 PostTaskManager 中实现
- [x] 13.4 实现任务状态更新（pending → uploading_media → media_uploaded → creating_post → completed）- 在 PostTaskManager 中实现
- [x] 13.5 实现任务进度跟踪（整体进度、当前阶段）- 在 PostTaskManager 中实现
- [x] 13.6 实现任务失败处理（保存错误信息、允许重试）- 在 PostTaskManager 中实现
- [x] 13.7 实现任务取消功能 - 基础实现，需要完善
- [x] 13.8 实现应用启动时检查未完成的任务

## 14. 测试和验证

- [ ] 14.1 编写单元测试（服务层）
- [ ] 14.2 编写 Widget 测试（UI 组件）
- [ ] 14.3 测试创建帖子流程（媒体选择 → 上传 → 发布）
- [ ] 14.4 测试后台任务处理（任务创建、状态更新、进度跟踪）
- [ ] 14.5 测试 Feed 流加载和分页
- [ ] 14.6 测试评论功能
- [ ] 14.7 测试网络错误处理
- [ ] 14.8 测试加载状态和错误提示
- [ ] 14.9 测试任务失败重试
- [ ] 14.10 测试应用重启后任务恢复

