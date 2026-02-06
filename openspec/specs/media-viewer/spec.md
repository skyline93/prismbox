# media-viewer Specification

## Purpose
TBD - created by archiving change refactor-media-viewer-page. Update Purpose after archive.
## Requirements
### Requirement: 媒体查看器页面 UI 组件结构
媒体查看器页面（MediaViewerPage）的 UI 组件 SHALL 遵循原子组件拆分原则，将大型 UI 逻辑拆分为独立的、可复用的组件和业务逻辑类。

#### Scenario: 页面代码行数符合规范
- **WHEN** 查看 MediaViewerPage 文件
- **THEN** 页面文件代码行数 SHALL 不超过 300 行
- **AND** `build` 方法的代码行数 SHALL 不超过 80 行
- **AND** UI 构建逻辑 SHALL 通过独立的组件实现

#### Scenario: 视频播放器管理器为独立类
- **WHEN** 使用 ViewerVideoManager 类
- **THEN** 该类 SHALL 位于 `lib/presentation/widgets/viewer/viewer_video_manager.dart`
- **AND** 类名 SHALL 为 `ViewerVideoManager`
- **AND** 类 SHALL 封装视频控制器的创建、缓存、释放逻辑
- **AND** 类 SHALL 管理视频播放状态（播放/暂停、静音状态等）
- **AND** 类 SHALL 处理可见页面范围的资源管理
- **AND** 类 SHALL 提供创建、获取、释放、暂停、播放等管理方法

#### Scenario: 手势处理为独立组件
- **WHEN** 使用 ViewerDismissGesture 组件
- **THEN** 该组件 SHALL 位于 `lib/presentation/widgets/viewer/viewer_dismiss_gesture.dart`
- **AND** 组件类名 SHALL 为 `ViewerDismissGesture`
- **AND** 组件 SHALL 使用 `StatefulWidget`（需要动画控制器）
- **AND** 组件 SHALL 封装垂直拖动手势识别
- **AND** 组件 SHALL 处理退出动画（执行和重置）
- **AND** 组件 SHALL 通过回调函数通知父组件退出事件
- **AND** 组件 SHALL 接收 `child`、`isZoomed`、`onDismiss` 参数

#### Scenario: 控制栏为独立组件
- **WHEN** 使用 ViewerControlsBar 组件
- **THEN** 该组件 SHALL 位于 `lib/presentation/widgets/viewer/viewer_controls_bar.dart`
- **AND** 组件类名 SHALL 为 `ViewerControlsBar`
- **AND** 组件 SHALL 使用 `StatelessWidget`
- **AND** 组件 SHALL 提供 `const` 构造函数
- **AND** 组件 SHALL 包含顶部 AppBar（返回按钮、分享按钮、更多操作按钮）
- **AND** 组件 SHALL 包含底部控制栏（收藏、信息、编辑等功能按钮）
- **AND** 组件 SHALL 通过回调函数处理用户交互事件
- **AND** 组件 SHALL 接收 `isFavorite` 参数表示当前资源的收藏状态
- **AND** 收藏按钮图标 SHALL 根据 `isFavorite` 状态显示不同图标（`true` 显示实心图标 `Icons.favorite`，`false` 或 `null` 显示空心图标 `Icons.favorite_border`）

#### Scenario: 图片查看页面为独立组件
- **WHEN** 使用 ViewerImagePage 组件
- **THEN** 该组件 SHALL 位于 `lib/presentation/widgets/viewer/viewer_image_page.dart`
- **AND** 组件类名 SHALL 为 `ViewerImagePage`
- **AND** 组件 SHALL 使用 `StatelessWidget`
- **AND** 组件 SHALL 提供 `const` 构造函数（如果可能）
- **AND** 组件 SHALL 接收 `asset`、`assetId`、`serverUrl`、`assetEntityLoader` 等参数
- **AND** 组件 SHALL 通过回调函数处理 `onTap` 和 `onScaleStateChanged` 事件
- **AND** 组件 SHALL 封装 PhotoView 配置和逻辑
- **AND** 组件 SHALL 处理图片加载和错误状态

#### Scenario: 视频查看页面为独立组件
- **WHEN** 使用 ViewerVideoPage 组件
- **THEN** 该组件 SHALL 位于 `lib/presentation/widgets/viewer/viewer_video_page.dart`
- **AND** 组件类名 SHALL 为 `ViewerVideoPage`
- **AND** 组件 SHALL 使用 `StatefulWidget`（需要处理视频加载状态）
- **AND** 组件 SHALL 接收 `asset`、`assetId`、`videoManager`、`serverUrl`、`assetEntityLoader` 等参数
- **AND** 组件 SHALL 通过回调函数处理 `showControls`、`onToggleControls`、`onMuteChanged` 事件
- **AND** 组件 SHALL 使用 `ViewerVideoManager` 管理视频控制器
- **AND** 组件 SHALL 封装 VideoPlayer 相关逻辑
- **AND** 组件 SHALL 处理视频加载和错误状态
- **AND** 组件 SHALL 集成视频控制器 UI

#### Scenario: 视频控制器 UI 为独立组件
- **WHEN** 使用视频控制器 UI 组件
- **THEN** 该组件 SHALL 位于 `lib/presentation/widgets/viewer/viewer_video_controller.dart`
- **AND** 组件类名 SHALL 为 `_VideoPlayerControls`（私有类，保持现有命名）
- **AND** 组件 SHALL 使用 `StatefulWidget`
- **AND** 组件 SHALL 封装视频播放控制逻辑（播放/暂停、进度条、静音等）
- **AND** 组件 SHALL 使用 `ValueListenableBuilder` 优化性能
- **AND** 组件 SHALL 使用 `RepaintBoundary` 隔离绘制边界

#### Scenario: 组件命名和目录规范
- **WHEN** 创建新的媒体查看器相关组件
- **THEN** 组件文件 SHALL 存放在 `lib/presentation/widgets/viewer/` 目录下
- **AND** 文件名 SHALL 使用 `viewer_` 前缀，使用 snake_case 命名（如 `viewer_image_page.dart`）
- **AND** 类名 SHALL 与文件名对应，使用 PascalCase 命名（如 `ViewerImagePage`）

#### Scenario: 组件性能优化要求
- **WHEN** 实现新的 UI 组件
- **THEN** 无状态组件 SHALL 优先使用 `StatelessWidget`
- **AND** 需要状态管理时 SHALL 使用 `StatefulWidget`
- **AND** 所有组件 SHALL 提供 `const` 构造函数（如果可能）
- **AND** 组件调用时 SHALL 使用 `const` 关键字（如果可能）
- **AND** 保持现有的性能优化措施（如 `ValueListenableBuilder`、`RepaintBoundary`）

#### Scenario: 状态管理规范
- **WHEN** 组件需要访问状态或数据
- **THEN** 页面级状态（如 `showControls`、`isZoomed`）SHALL 由页面类管理
- **AND** 视频管理器状态 SHALL 由 `ViewerVideoManager` 类内部管理
- **AND** 组件 SHALL 通过构造函数参数接收必要的数据
- **AND** 组件 SHALL 通过回调函数通知父组件用户交互事件
- **AND** 避免过度抽象，保持参数传递的简洁性

#### Scenario: 收藏功能集成
- **WHEN** 在 MediaViewerPage 中显示媒体资源
- **THEN** 页面 SHALL 从 `timelineAssetsProvider` 获取当前资源的收藏状态（从 Prismbox 数据库读取）
- **AND** 页面 SHALL 使用 `Consumer` 包装 `ViewerControlsBar`，直接响应 `timelineAssetsProvider` 的更新
- **AND** 页面 SHALL 实现收藏切换逻辑，调用 `AssetFavoriteService.toggleFavorite` 方法（仅更新数据库）
- **AND** 收藏操作成功后 SHALL 刷新 `timelineAssetsProvider` 或更新本地状态
- **AND** 收藏操作失败时 SHALL 显示错误提示并回滚 UI 状态

#### Scenario: 状态响应式更新
- **WHEN** `timelineAssetsProvider` 数据更新（如收藏状态改变后刷新）
- **THEN** `_assetMap` SHALL 每次 `allAssets` 更新时都重新构建，不使用 `??=` 操作符
- **AND** `ViewerControlsBar` 的 `isFavorite` 参数 SHALL 直接从 `timelineAssetsProvider` 获取最新状态
- **AND** 预览页面收藏按钮状态 SHALL 与照片页面缩略图收藏图标状态保持一致
- **AND** 预览页面收藏按钮状态 SHALL 与数据库中的收藏状态保持一致

#### Scenario: 功能保持完整
- **WHEN** 重构完成后
- **THEN** 所有原有功能 SHALL 保持不变
- **AND** 图片查看功能 SHALL 正常工作（缩放、平移、加载等）
- **AND** 视频播放功能 SHALL 正常工作（播放、暂停、进度控制、静音等）
- **AND** 手势退出功能 SHALL 正常工作（下滑退出、动画等）
- **AND** 控制栏功能 SHALL 正常工作（显示/隐藏、操作按钮等）
- **AND** 页面切换功能 SHALL 正常工作（左右滑动切换媒体）
- **AND** 收藏功能 SHALL 正常工作（状态显示、切换操作、数据库更新）

### Requirement: Live Photo 检测与播放入口

媒体查看器 SHALL 在当前资产为 Live Photo（`asset.isMotionPhoto == true`）时提供「播放 Live 视频」入口，并在用户未触发播放时仅显示静态主图；SHALL 根据「当前是否在播 Live 视频」的单一状态在静态主图视图与 Live 短视频视图之间切换。

#### Scenario: 当前为 Live Photo 时显示播放按钮

- **WHEN** 媒体查看器当前页对应的资产满足 `asset.isMotionPhoto == true` 且认为有可播放的 Live 视频（如 `livePhotoVideoId != null`，或后续可加可用性检查）
- **THEN** 顶部或控制栏 SHALL 显示「播放 Live 视频」按钮（或等价入口）
- **AND** 默认展示 SHALL 为静态主图（ViewerImagePage），不在此阶段加载 Live 视频

#### Scenario: 当前非 Live Photo 或无视频时不显示播放按钮

- **WHEN** 当前资产满足 `asset.isMotionPhoto == false` 或已知 Live 视频不可用（如 404、未下载且离线）
- **THEN** 不显示播放 Live 按钮或 SHALL 显示为不可用（灰显并可提示）
- **AND** 仅展示主图，无播放入口

#### Scenario: 点击播放后切换为 Live 视频视图

- **WHEN** 用户点击「播放 Live 视频」按钮或通过长按主图触发同一动作
- **THEN** 系统 SHALL 将「当前是否在播 Live 视频」状态置为 true
- **AND** 当前页 SHALL 切换为使用 ViewerVideoPage（或同等能力），视频源由 `livePhotoVideoId` 解析（本地文件路径或远程 URL）
- **AND** Live 视频 SHALL 不循环，播完后自动切回静态主图并将播放状态置为 false

#### Scenario: 页面切换时释放 Live 播放状态

- **WHEN** 用户左右滑动离开当前页（或进入相邻页）
- **THEN** 若当前页为 Live Photo 且正在播放 Live 视频，SHALL 停止播放并释放播放器
- **AND** 「当前是否在播 Live 视频」状态 SHALL 重置为 false（或按页作用域重置）
- **AND** 滑回该页时 SHALL 默认显示静态主图，不自动续播

#### Scenario: 播放状态由单一 Provider 驱动

- **WHEN** 实现播放入口与图/视频切换
- **THEN** 系统 SHALL 使用单一状态源（如 `isPlayingMotionVideoProvider`）驱动播放按钮的显示/隐藏与图标切换、以及当前页是展示 ViewerImagePage 还是 ViewerVideoPage（Live 视频源）
- **AND** 视频播放器 SHALL 复用现有 ViewerVideoPage/ViewerVideoManager，仅传入 Live 视频源与不循环、播完回图等参数差异

#### Scenario: Live 视频源解析

- **WHEN** 需要播放 Live 视频
- **THEN** 视频源 SHALL 优先使用本地已下载的 Live 视频文件路径（若存在）
- **AND** 否则 SHALL 使用与普通视频一致的远程 URL 规则（如 `$serverUrl/assets/{livePhotoVideoId}/video/playback` 或 original），与现有播放与鉴权逻辑兼容

#### Scenario: 播放失败降级

- **WHEN** 用户点击播放后视频加载或解码失败
- **THEN** 系统 SHALL 提示失败原因并保持或切回静态主图视图
- **AND** 播放状态 SHALL 置为 false，不阻塞主图浏览

### Requirement: 本地 Live Photo 视频源解析

当媒体查看器播放「本地 Live Photo」关联的 motion 视频时，系统 SHALL 从本地 AssetEntity 获取 motion 视频文件并作为视频源，而非使用远程 URL。仅当 asset 为 LocalAsset 且存在 videoIdOverride（livePhotoVideoId）时走此分支。

#### Scenario: 本地 Live Photo 使用本地 motion 文件

- **WHEN** VideoProvider.getVideoSource 被调用且 `videoIdOverride != null` 且 `asset is LocalAsset`
- **THEN** 系统 SHALL 不调用远程视频源逻辑（_getRemoteVideoSource）
- **AND** 系统 SHALL 通过 AssetEntity 获取 motion 视频文件（优先使用 asset.assetEntity，若为空则通过 assetEntityLoader.loadAsync(asset) 获取）
- **AND** 系统 SHALL 使用平台约定 API（iOS：如 originFileWithSubtype；Android：如 loadFile(withSubtype: true)）取得 motion 文件路径
- **AND** 系统 SHALL 使用该路径构造并返回 VideoSource.init(path: path, type: VideoSourceType.file)

#### Scenario: 无 AssetEntity 或 motion 文件不可用时降级

- **WHEN** asset 为 LocalAsset 且 videoIdOverride != null，但无法获取 AssetEntity 或 motion 文件获取失败/超时
- **THEN** 系统 SHALL 返回 null（表示视频源不可用）
- **AND** 查看器侧已有逻辑将播放失败时切回静态主图并重置 isPlayingMotionVideoProvider，不阻塞用户浏览

### Requirement: 远程 Live Photo 视频预览与下载

当媒体查看器播放或下载「仅云端 Live Photo」关联的 Live 视频时，系统 SHALL 使用 `live_photo_video_id` 构造请求：预览播放时优先使用预览视频 URL，不可用时回退到原片 URL；下载时使用原片 URL。

#### Scenario: 远程 Live 预览优先预览回退原片

- **WHEN** 需要播放远程 Live Photo 的 Live 视频（即 asset 为远程且 `livePhotoVideoId` 非空）
- **THEN** 系统 SHALL 优先使用该 ID 请求预览 URL（例如 `.../media/{id}/download/preview`）
- **AND** 若预览返回 4xx 或加载/解码失败，系统 SHALL 回退到原片 URL（例如 `.../media/{id}/download/original`）
- **AND** 系统 SHALL 不在预览不可用时阻塞播放，仅切换为原片继续播放

#### Scenario: 下载 Live Photo 时使用原片

- **WHEN** 用户对远程 Live Photo 执行下载或导出原片
- **THEN** 系统 SHALL 使用 `live_photo_video_id` 请求原片 URL（例如 `.../media/{id}/download/original`）获取 Live 视频文件
- **AND** 系统 SHALL 不在此场景使用预览 URL

