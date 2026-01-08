# Change: 添加帖子功能（含后台处理和媒体上传）

## Why

用户需要在圈子中发布帖子，分享照片和视频，并与其他成员互动。当前系统缺少帖子相关的移动端 UI 和完整的数据同步功能。

**关键需求**：
- **媒体处理优先**：媒体处理任务需要先实现添加帖子的功能
- **后台处理**：添加帖子需要能在后台处理，用户点击发布后，帖子应该在后台处理发布
- **Threads UI 风格**：发布帖子的页面需要参考 Threads 的发布 UI

需要实现的核心功能：
- **创建帖子**：在圈子中发布帖子，包含媒体和文字说明
- **后台发布**：用户点击发布后，帖子在后台处理（媒体上传、创建帖子）
- **媒体上传**：选择本地媒体后自动上传到服务器
- **Feed 流**：查看圈子中的帖子列表，支持分页加载
- **帖子详情**：查看单个帖子的详细信息
- **评论功能**：对帖子进行评论和回复
- **在线访问**：完全依赖后端 API，不存储到本地数据库（预留后续缓存优化）

## What Changes

### 移动端 UI 层
- **创建帖子页面**（参考 Threads UI）：
  - 顶部导航栏：取消按钮、标题"新建串文"、更多选项按钮
  - 用户信息区域：头像、用户名、添加话题入口
  - 文字输入区域：多行文本输入框，占位符"有什么新鲜事吗?"
  - 媒体选择工具栏：图片、GIF、列表、引用、更多选项
  - 底部操作栏：回复选项、表情开关、发布按钮（禁用状态直到有内容）
  - 媒体预览区域：显示选中的媒体缩略图，支持删除
  - 媒体选择抽屉：使用时间线组件在上滑抽屉中显示媒体选择界面（复用 LocalAssetEntity）
- **Feed 流页面**：在圈子主页展示帖子列表，支持下拉刷新和上拉加载
- **帖子详情页面**：查看帖子完整信息、评论列表、添加评论
- **评论组件**：评论列表、评论输入框、回复功能
- **UI 组件**：帖子卡片、评论项、媒体网格等

### 移动端服务层
- **帖子发布服务**：封装帖子创建业务逻辑
- **媒体上传服务**：复用现有上传服务，上传媒体文件（选择的媒体来自 LocalAssetEntity，与照片页面上传时一致）
- **后台任务管理**：
  - 创建帖子任务类型（PostTaskType）
  - 任务状态管理（待上传、上传中、待发布、发布中、已完成、失败）
  - 任务进度跟踪（媒体上传进度、发布进度）
  - 后台任务执行（使用 background_downloader）

### 移动端数据层
- **帖子数据模型**：Post、PostMedia、Comment 等实体（仅用于 API 响应解析）
- **帖子任务模型**：PostTask 实体，存储后台发布任务状态
- **帖子服务**：PostService、CommentService，封装业务逻辑和 API 调用
- **状态管理**：使用 Riverpod Provider 管理页面状态（内存中）

### 移动端网络层
- **API 客户端**：封装帖子相关 API 调用
- **错误处理**：统一的错误处理和重试机制

### 路由配置
- **路由定义**：添加帖子相关路由（创建帖子、帖子详情）

## Impact

- **新增文件**：
  - `mobile/lib/presentation/pages/posts/` - 帖子相关页面
  - `mobile/lib/presentation/widgets/posts/` - 帖子相关组件
  - `mobile/lib/data/models/post/` - 帖子数据模型（仅用于 API 响应）
  - `mobile/lib/data/models/post/post_task.dart` - 帖子任务模型
  - `mobile/lib/data/database/enums/post_task_status.dart` - 帖子任务状态枚举
  - `mobile/lib/services/post/` - 帖子服务
  - `mobile/lib/services/post/post_task_manager.dart` - 帖子任务管理器
  - `mobile/lib/providers/post/` - 帖子 Provider（内存状态管理）
- **受影响文件**：
  - `mobile/lib/presentation/pages/groups/group_detail_page.dart` - 集成 Feed 流
  - `mobile/lib/presentation/routing/app_router.dart` - 添加路由
  - `mobile/lib/infrastructure/network/` - 添加 API 客户端
  - `mobile/lib/services/backup/upload_service.dart` - 复用上传服务
  - `mobile/lib/data/database/app_database.dart` - 添加帖子任务表
- **受影响规范**：
  - `openspec/specs/post/spec.md` - 新增帖子功能规范
- **向后兼容性**：
  - 完全向后兼容，不影响现有功能

