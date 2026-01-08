# post Specification

## Purpose
TBD - created by archiving change add-post-feature. Update Purpose after archive.
## Requirements
### Requirement: 创建帖子（Threads UI 风格）

系统 SHALL 提供创建帖子的功能，允许用户在圈子中发布包含媒体和文字说明的帖子。UI 设计参考 Threads 的发布页面。

#### Scenario: 创建帖子页面展示（Threads 风格）
- **WHEN** 用户进入创建帖子页面
- **THEN** 系统 SHALL 显示顶部导航栏（取消按钮、标题"新建串文"、更多选项）
- **AND** 系统 SHALL 显示用户信息区域（头像、用户名、添加话题入口）
- **AND** 系统 SHALL 显示文字输入框（占位符"有什么新鲜事吗?"）
- **AND** 系统 SHALL 显示媒体选择工具栏（图片、GIF、列表、引用、更多选项）
- **AND** 系统 SHALL 显示底部操作栏（回复选项、表情开关、发布按钮）
- **AND** 系统 SHALL 发布按钮初始为禁用状态（灰色）

#### Scenario: 选择媒体（时间线抽屉）
- **WHEN** 用户点击媒体选择工具栏中的图片图标
- **THEN** 系统 SHALL 显示上滑抽屉（DraggableScrollableSheet）
- **AND** 系统 SHALL 在抽屉中使用时间线组件显示媒体（复用 LocalAssetEntity）
- **AND** 系统 SHALL 显示时间线分组视图（按日期分组）
- **AND** 系统 SHALL 支持多选模式（最多 9 张）
- **AND** 系统 SHALL 显示已选择数量
- **AND** 系统 SHALL 提供"确定"按钮确认选择
- **AND** 系统 SHALL 关闭抽屉后显示选中的媒体预览（缩略图网格）
- **AND** 系统 SHALL 允许删除已选中的媒体
- **AND** 系统 SHALL 更新发布按钮状态（有媒体或文字时启用）

#### Scenario: 输入文字说明
- **WHEN** 用户在文字输入框中输入内容
- **THEN** 系统 SHALL 更新发布按钮状态（有内容时启用）
- **AND** 系统 SHALL 支持多行文本输入
- **AND** 系统 SHALL 支持换行

#### Scenario: 发布帖子（后台处理）
- **WHEN** 用户选择媒体和/或输入文字说明，并点击发布按钮
- **THEN** 系统 SHALL 创建后台发布任务
- **AND** 系统 SHALL 显示任务创建成功提示
- **AND** 系统 SHALL 允许用户关闭页面（任务在后台继续）
- **AND** 系统 SHALL 开始媒体上传阶段（如果选择了媒体）
- **AND** 系统 SHALL 显示上传进度（如果用户仍在页面）
- **AND** 系统 SHALL 所有媒体上传完成后，自动进入创建帖子阶段
- **AND** 系统 SHALL 调用后端 API 创建帖子
- **AND** 系统 SHALL 任务完成后，刷新 Feed 流
- **AND** 系统 SHALL 显示发布成功通知

#### Scenario: 媒体上传进度显示
- **WHEN** 后台任务正在上传媒体
- **THEN** 系统 SHALL 显示整体上传进度（0-100%）
- **AND** 系统 SHALL 显示当前上传的媒体文件名
- **AND** 系统 SHALL 显示已上传/总媒体数量
- **AND** 系统 SHALL 如果用户关闭页面，任务在后台继续

#### Scenario: 发布帖子失败
- **WHEN** 发布帖子失败（媒体上传失败或创建帖子失败）
- **THEN** 系统 SHALL 将任务状态标记为失败
- **AND** 系统 SHALL 显示错误通知
- **AND** 系统 SHALL 保存任务信息（媒体列表、文字说明）
- **AND** 系统 SHALL 允许用户查看失败任务
- **AND** 系统 SHALL 提供重试按钮

#### Scenario: 任务状态查询
- **WHEN** 用户查看任务列表或进入创建帖子页面
- **THEN** 系统 SHALL 显示未完成的发布任务
- **AND** 系统 SHALL 显示任务状态（上传中、发布中、失败）
- **AND** 系统 SHALL 显示任务进度
- **AND** 系统 SHALL 允许用户取消任务

### Requirement: 媒体上传集成

系统 SHALL 集成现有上传服务，用于上传帖子中的媒体文件。

#### Scenario: 媒体上传流程
- **WHEN** 后台任务进入媒体上传阶段
- **THEN** 系统 SHALL 调用现有上传服务（UploadService）
- **AND** 系统 SHALL 为每个媒体文件创建上传任务
- **AND** 系统 SHALL 使用 background_downloader 执行上传
- **AND** 系统 SHALL 跟踪每个媒体的上传进度
- **AND** 系统 SHALL 上传完成后保存 media_uuid
- **AND** 系统 SHALL 所有媒体上传完成后，进入创建帖子阶段

#### Scenario: 媒体上传失败处理
- **WHEN** 媒体上传失败
- **THEN** 系统 SHALL 根据上传服务的重试策略自动重试
- **AND** 系统 SHALL 如果达到最大重试次数仍失败，标记任务为失败
- **AND** 系统 SHALL 保存已成功上传的媒体 UUID（部分成功的情况）
- **AND** 系统 SHALL 允许用户选择重试失败的媒体或取消任务

### Requirement: Feed 流

系统 SHALL 提供 Feed 流功能，在圈子主页展示帖子列表。

#### Scenario: Feed 流展示
- **WHEN** 用户进入圈子主页
- **THEN** 系统 SHALL 显示 Feed 流区域
- **AND** 系统 SHALL 显示加载状态
- **AND** 系统 SHALL 调用后端 API 获取帖子列表（第一页）
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
- **WHEN** 圈子中没有帖子
- **THEN** 系统 SHALL 显示空状态提示
- **AND** 系统 SHALL 显示"发布第一个帖子"提示

#### Scenario: 点击帖子卡片
- **WHEN** 用户点击帖子卡片
- **THEN** 系统 SHALL 导航到帖子详情页面

### Requirement: 帖子详情

系统 SHALL 提供帖子详情页面，展示帖子的完整信息和评论列表。

#### Scenario: 帖子详情页面展示
- **WHEN** 用户进入帖子详情页面
- **THEN** 系统 SHALL 显示帖子完整信息（用户信息、文字、媒体）
- **AND** 系统 SHALL 显示评论列表
- **AND** 系统 SHALL 显示评论输入框
- **AND** 系统 SHALL 显示互动按钮（点赞、评论、分享）

#### Scenario: 帖子详情数据加载
- **WHEN** 加载帖子详情
- **THEN** 系统 SHALL 显示加载状态
- **AND** 系统 SHALL 调用后端 API 获取帖子详情
- **AND** 系统 SHALL 更新页面显示

### Requirement: 评论功能

系统 SHALL 提供评论功能，允许用户对帖子进行评论和回复。

#### Scenario: 添加评论
- **WHEN** 用户在帖子详情页面输入评论并提交
- **THEN** 系统 SHALL 调用后端 API 添加评论
- **AND** 系统 SHALL 刷新评论列表（重新调用 API）
- **AND** 系统 SHALL 清空输入框

#### Scenario: 回复评论
- **WHEN** 用户点击评论的回复按钮
- **THEN** 系统 SHALL 在输入框中显示"回复 @用户名"
- **AND** 系统 SHALL 用户输入回复内容并提交
- **AND** 系统 SHALL 调用后端 API 添加回复（设置 parentCommentId）
- **AND** 系统 SHALL 刷新评论列表（重新调用 API）

#### Scenario: 评论列表展示
- **WHEN** 显示评论列表
- **THEN** 系统 SHALL 显示所有评论（包括回复）
- **AND** 系统 SHALL 主评论完整显示
- **AND** 系统 SHALL 回复缩进显示，标注"回复 @用户名"
- **AND** 系统 SHALL 显示评论时间（相对时间）

#### Scenario: 删除评论
- **WHEN** 评论作者或管理员长按评论
- **THEN** 系统 SHALL 显示删除选项
- **AND** 系统 SHALL 显示确认对话框
- **AND** 系统 SHALL 调用后端 API 删除评论
- **AND** 系统 SHALL 刷新评论列表（重新调用 API）

### Requirement: 媒体显示

系统 SHALL 根据帖子中的媒体数量使用不同的布局显示。

#### Scenario: 单图显示
- **WHEN** 帖子只有一张图片
- **THEN** 系统 SHALL 显示大图（全宽或按比例）

#### Scenario: 多图网格显示
- **WHEN** 帖子有多张图片（2-4 张）
- **THEN** 系统 SHALL 使用 2x2 网格布局
- **AND** 系统 SHALL 图片等比例显示

#### Scenario: 多图网格显示（5-9 张）
- **WHEN** 帖子有 5-9 张图片
- **THEN** 系统 SHALL 使用 3x3 网格布局
- **AND** 系统 SHALL 显示前 9 张图片
- **AND** 系统 SHALL 如果超过 9 张，显示"+N"提示

#### Scenario: 点击媒体查看大图
- **WHEN** 用户点击帖子中的媒体
- **THEN** 系统 SHALL 打开媒体查看器
- **AND** 系统 SHALL 支持左右滑动查看多张图片

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

### Requirement: 性能优化

系统 SHALL 优化 Feed 流和媒体显示的性能。

#### Scenario: 虚拟滚动
- **WHEN** Feed 流包含大量帖子
- **THEN** 系统 SHALL 使用 ListView.builder 实现虚拟滚动
- **AND** 系统 SHALL 仅渲染可见区域的帖子

#### Scenario: 图片懒加载
- **WHEN** 显示帖子中的图片
- **THEN** 系统 SHALL 使用懒加载策略
- **AND** 系统 SHALL 优先加载可见区域的图片
- **AND** 系统 SHALL 使用缩略图快速显示

#### Scenario: 图片缓存
- **WHEN** 加载帖子中的图片
- **THEN** 系统 SHALL 使用图片缓存
- **AND** 系统 SHALL 避免重复下载相同图片

