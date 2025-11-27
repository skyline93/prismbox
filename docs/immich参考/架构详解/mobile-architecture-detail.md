# Immich Mobile 架构详解

> 目的：汇总移动端整体架构设计要点，并按功能服务模块梳理核心单元，方便后续逐一深入。

## 1. 总览

- **技术栈**：Flutter + Dart，状态管理使用 Riverpod，数据库采用 Isar + Drift 双轨方案。
- **架构模式**：分层（Domain / Infrastructure / Presentation）+ Provider 依赖注入 + 响应式更新。
- **核心原则**：领域层不依赖基础设施，Repository 暴露接口不泄漏底层实现，UI 通过 Provider 获取服务。

## 2. 启动与初始化

| 步骤 | 说明 | 关键文件 |
| --- | --- | --- |
| WidgetsBinding & 锁 | 初始化自定义绑定、获取后台锁 | `mobile/lib/main.dart` |
| 数据库初始化 | `Bootstrap.initDB()` 打开 Isar/Drift/日志库 | `mobile/lib/utils/bootstrap.dart` |
| 领域初始化 | `Bootstrap.initDomain()` 选择 Store Repository、初始化 StoreService/LogService | 同上 |
| Isolate 预热 | `workerManagerPatch.init()` 预热 Isolate 池 | `mobile/lib/main.dart` |
| 数据迁移 | `migrateDatabaseIfNeeded` 处理版本迁移 | `mobile/lib/utils/migration.dart` |
| ProviderScope 覆盖 | 注入数据库实例供 Provider 使用 | `mobile/lib/main.dart` |

## 3. 数据与状态层

### 3.1 Domain Layer

- `domain/models/`：业务模型（UserDto、BaseAsset、Timeline 等）
- `domain/services/`：业务逻辑（TimelineService、StoreService、SyncStreamService 等）
- `domain/interfaces/`：Repository 接口
- `domain/utils/`：通用工具（事件流、锁等）

### 3.2 Infrastructure Layer

- `infrastructure/entities/`：Drift 表定义
- `infrastructure/repositories/`：Isar/Drift 实现、API Repository
- `infrastructure/utils/`：数据库工具、转换器

### 3.3 Provider 与状态管理

- Provider 层负责依赖注入与状态聚合：
  - 基础：`providers/infrastructure/*.dart` 注入数据库/API/Repository/Service
  - 业务：`providers/auth.provider.dart`、`providers/timeline.provider.dart` 等
  - UI：`providers/asset_viewer/` 等管理组件状态
- 生命周期：`@Riverpod(keepAlive: true)` 控制缓存，`ref.onDispose` 负责清理。

## 4. 路由与导航

- 使用 AutoRoute 配置 (`routing/router.dart`)，生成代码 `router.gr.dart`。
- 守卫：`AuthGuard`、`GalleryGuard`、`BackupPermissionGuard`、`LockedGuard`。
- 深度链接：`services/deep_link.service.dart` 解析 `immich://` 与 `my.immich.app`。
- 导航观察：`routing/app_navigation_observer.dart`。

## 5. 后台与同步

| 模块 | 说明 | 关键实现 |
| --- | --- | --- |
| 背景上传服务 | Android/iOS 后台上传、通知、锁管理 | `services/background.service.dart`、`domain/services/background_worker.service.dart` |
| 上传任务 | `UploadService` 管理队列、进度、回调 | `services/upload.service.dart` |
| 本地同步 | 读取设备媒体库、增量/全量同步 | `domain/services/local_sync.service.dart` |
| 远程同步 | WebSocket 流式同步、事件处理 | `domain/services/sync_stream.service.dart` |
| 下载 | 后台下载、进度通知、任务分组 | `services/download.service.dart` |

## 6. 主题、国际化与工具

- 主题：`theme/dynamic_theme.dart` + `providers/theme.provider.dart`。
- 国际化：`easy_localization`，`generated/codegen_loader.g.dart`。
- 工具：`utils/*`（哈希、调试输出、HTTP SSL 设置等）。

---

# 功能服务模块拆解

为便于按业务模块逐一分析，以下按功能服务划分核心单元，并列出关键依赖。

## 模块 1：认证与用户管理

- **职责**：登录、OAuth、生物识别、用户信息、会话。
- **关键组件**：
  - Domain：`domain/services/user.service.dart`
  - Repositories：`infrastructure/repositories/user.repository.dart`、`user_api.repository.dart`
  - Services：`services/auth.service.dart`、`oauth.service.dart`、`local_auth.service.dart`、`secure_storage.service.dart`
  - Providers：`providers/auth.provider.dart`、`user.provider.dart`
  - UI：`pages/login/`、`pages/onboarding/`

## 模块 2：资源管理

- **职责**：Asset CRUD、元数据、查看器、堆叠、操作。
- **关键组件**：
  - Domain：`domain/services/asset.service.dart`
  - Repositories：`remote_asset.repository.dart`、`local_asset.repository.dart`、`asset_api.repository.dart`
  - Services：`services/asset.service.dart`、`stack.service.dart`、`trash.service.dart`、`exif.service.dart`
  - Providers：`providers/asset.provider.dart`、`providers/asset_viewer/*`
  - UI：`widgets/asset_viewer/`、`widgets/asset_grid/`、`pages/photos/`

## 模块 3：相册管理

- **职责**：本地/远程相册、共享、资源关联。
- **关键组件**：
  - Domain：`domain/services/local_album.service.dart`、`remote_album.service.dart`、`sync_linked_album.service.dart`
  - Repositories：`local_album.repository.dart`、`remote_album.repository.dart`、`album_api.repository.dart`
  - Service：`services/album.service.dart`
  - Providers：`providers/album/*`
  - UI：`pages/album/`、`pages/albums/`、`widgets/album/`

## 模块 4：备份与上传

- **职责**：自动/手动备份、上传队列、后台服务、验证。
- **关键组件**：
  - Domain：`domain/services/background_worker.service.dart`
  - Repositories：`backup.repository.dart`、`upload.repository.dart`
  - Services：`services/backup.service.dart`、`upload.service.dart`、`background.service.dart`、`backup_album.service.dart`
  - Providers：`providers/backup/*`
  - UI：`pages/backup/`、`widgets/backup/`

## 模块 5：下载与同步

- **职责**：资源下载、远程同步、本地同步、冲突处理。
- **关键组件**：
  - Domain：`domain/services/sync_stream.service.dart`、`local_sync.service.dart`、`store.service.dart`
  - Repositories：`sync_stream.repository.dart`、`sync_api.repository.dart`、`download.repository.dart`
  - Services：`services/download.service.dart`、`sync.service.dart`、`etag.service.dart`
  - Providers：`providers/infrastructure/sync.provider.dart`、`sync_status.provider.dart`

## 模块 6：时间线

- **职责**：时间线构建、分组、筛选、多用户。
- **关键组件**：
  - Domain：`domain/services/timeline.service.dart`
  - Repository：`timeline.repository.dart`
  - Service：`services/timeline.service.dart`
  - Providers：`providers/timeline.provider.dart`
  - UI：`pages/photos/`、`presentation/pages/`、`widgets/timeline/`

## 模块 7：搜索

- **职责**：全文搜索、智能推荐、筛选。
- **关键组件**：
  - Domain：`domain/services/search.service.dart`
  - Repository：`search_api.repository.dart`
  - Service：`services/search.service.dart`
  - Providers：`providers/search/*`
  - UI：`pages/search/`、`widgets/search/`

## 模块 8：地图与位置

- **职责**：地图展示、位置标记、聚类。
- **关键组件**：
  - Domain：`domain/services/map.service.dart`
  - Repository：`map.repository.dart`
  - Service：`services/map.service.dart`
  - Providers：`providers/map/*`
  - UI：`widgets/map/`

## 模块 9：回忆

- **职责**：回忆生成、展示、管理。
- **关键组件**：
  - Domain：`domain/services/memory.service.dart`
  - Repository：`memory.repository.dart`
  - Service：`services/memory.service.dart`
  - Providers：`providers/memory.provider.dart`
  - UI：`widgets/memories/`

## 模块 10：人物识别

- **职责**：人脸识别、人物管理、聚类。
- **关键组件**：
  - Domain：`domain/services/people.service.dart`
  - Repositories：`people.repository.dart`、`person_api.repository.dart`
  - Service：`services/person.service.dart`
  - Providers：`providers/infrastructure/people.provider.dart`
  - UI：`widgets/` & `pages/` 中的人员视图

## 模块 11：共享链接

- **职责**：链接创建、管理、权限控制。
- **关键组件**：
  - Repository：`shared_link.repository.dart`
  - Services：`services/shared_link.service.dart`、`share.service.dart`
  - Providers：`providers/shared_link.provider.dart`
  - UI：`widgets/shared_link/`、`pages/`

## 模块 12：活动

- **职责**：活动记录、统计、展示。
- **关键组件**：
  - Repository：`activity_api.repository.dart`
  - Services：`services/activity.service.dart`、`action.service.dart`
  - Providers：`providers/activity*.dart`
  - UI：`widgets/activities/`

## 模块 13：设置与配置

- **职责**：应用设置、服务器信息、主题、本地化。
- **关键组件**：
  - Domain：`domain/services/setting.service.dart`、`store.service.dart`
  - Services：`services/app_settings.service.dart`、`server_info.service.dart`、`localization.service.dart`
  - Providers：`providers/app_settings.provider.dart`、`theme.provider.dart`、`locale_provider.dart`
  - UI：`pages/settings/`、`widgets/settings/`

## 模块 14：基础服务

- **职责**：API 客户端、网络、日志、通知、设备。
- **关键组件**：
  - Services：`api.service.dart`、`network.service.dart`、`immich_logger.service.dart`、`device.service.dart`、`local_notification.service.dart`、`deep_link.service.dart`
  - Domain：`domain/services/log.service.dart`、`store.service.dart`、`hash.service.dart`
  - Repositories：`store.repository.dart`、`log.repository.dart`
  - Providers：`providers/api.provider.dart`、`network.provider.dart`、`infrastructure/store.provider.dart`

## 模块 15：路由与导航

- **职责**：路由配置、守卫、深链。
- **关键组件**：
  - Routing：`routing/router.dart`、`router.gr.dart`
  - Guards：`routing/auth_guard.dart` 等
  - Services：`deep_link.service.dart`
  - Providers：`providers/routes.provider.dart`

## 模块 16：图片加载与缓存

- **职责**：图片加载、缩略图、缓存管理。
- **关键组件**：
  - Providers：`providers/image/*`
  - 缓存管理：`providers/image/cache/*`
  - UI：依赖于上述 Provider 的各类组件

---

## 后续分析建议

1. **按模块分阶段深入**：先基础（模块 14 → 1 → 15），再核心（2 → 3 → 6），最后高级与辅助。
2. **逐模块关注要点**：数据流、状态管理、错误处理、性能优化、测试策略。
3. **结合代码示例**：阅读对应 Provider + Service + Repository + UI 的调用链，建立完整心智模型。

整理完毕，可据此逐模块展开深入分析。若需要某模块的详细解剖，请告知。

