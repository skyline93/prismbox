# Project Context

## Purpose

PrismBox 是一个高性能相册应用，提供完整的照片和视频管理解决方案。项目包含：

- **后端服务**（`backend/`）：基于 Go 语言开发的照片和视频管理后端服务，提供用户认证、媒体管理、相册管理、圈子分享等功能
- **移动端应用**（`prismbox_mobile/`）：基于 Flutter 开发的高性能移动端应用，支持自动备份、媒体浏览、远程同步等功能

核心目标：
- 高性能、高效率且体验良好的备份上传和下载
- 高性能的媒体资源展示（流畅的图片/视频浏览体验）
- 智能缓存策略，优化内存和存储使用
- 渐进式加载，提供即时视觉反馈

## Tech Stack

### 后端（`backend/`）
- **语言**：Go 1.24+
- **Web 框架**：Gin
- **ORM**：GORM
- **任务队列**：自研 GQ (Go-Gorm-Queue)，基于 GORM 和关系型数据库的分布式任务队列框架
- **数据库**：PostgreSQL / SQLite（支持多数据库）
- **日志系统**：自研日志包（结构化日志，支持 JSON/Console 格式）
- **容器化**：Docker, docker-compose
- **命令行工具**：github.com/urfave/cli/v2
- **配置管理**：Viper
- **媒体处理**：ImageMagick (imagick.v3), ThumbHash，Ffmpeg

### 移动端（`prismbox_mobile/`）
- **框架**：Flutter 3.x+ (Dart SDK ^3.10.4)
- **状态管理**：Riverpod 2.x（使用代码生成）
- **路由**：AutoRoute 8.x（代码生成）
- **数据库**：Drift (SQLite) 2.x
- **网络**：Dio 5.x, background_downloader 9.x
- **本地资源**：photo_manager 3.x
- **缓存**：flutter_cache_manager 3.x
- **跨平台通信**：Pigeon（类型安全的跨平台通信）
- **图片处理**：image 4.x（ThumbHash 解码）

## Project Conventions

### Code Style

#### 后端（Go）
- **命名规范**：
  - 包名：小写，简短，有意义
  - 接口名：通常以 `er` 结尾（如 `Repository`, `Storage`）
  - 结构体：大驼峰命名
  - 函数/方法：大驼峰命名（公开），小驼峰命名（私有）
- **代码组织**：
  - 严格遵循分层架构（API → Service → Repository → Database）
  - 使用接口抽象核心组件（存储、仓储等）
  - 依赖注入：手动依赖注入，不使用框架
  - 模块化设计：按功能模块组织代码
- **错误处理**：
  - 统一错误响应格式：`ApiResponse{code, message, data}`
  - 使用结构化日志记录错误
  - 错误分类：网络错误、认证错误、服务器错误、本地错误

#### 移动端（Dart/Flutter）
- **命名规范**：
  - 文件：snake_case（如 `backup_service.dart`）
  - 类：大驼峰命名（如 `BackupService`）
  - 变量/函数：小驼峰命名
  - 常量：小写+下划线（如 `max_concurrent_tasks`）
- **代码组织**：
  - 严格遵循分层架构（UI 层、服务层、仓库层、数据层、网络层）
  - 使用绝对路径导入（从 `lib/` 目录开始）：`import 'package:prismbox/...'`
  - 模块化设计：功能模块独立，低耦合高内聚
- **类型安全**：
  - 充分利用 Dart 的强类型系统，避免使用 `dynamic`
  - 使用 Drift、Riverpod、AutoRoute 的类型安全特性
  - 使用 `freezed` 创建不可变数据类（如需要）
- **性能优化**：
  - 使用 `const` 构造函数减少重建
  - 使用 `ListView.builder` 等虚拟滚动组件
  - 及时释放资源（Stream、Controller、Timer 等）
  - 使用 `isolate` 处理耗时操作

### Architecture Patterns

#### 后端架构
- **分层架构**：
  - API 层：接收 HTTP 请求，参数验证，调用 Service 层
  - Service 层：实现核心业务逻辑，协调 Repository 和 Storage
  - Repository 层：封装数据库操作，提供数据访问接口
  - Worker 层：处理异步任务（媒体处理、云端上传等）
- **依赖注入**：手动依赖注入，不使用框架，提高代码清晰度和可测试性
- **接口抽象**：存储、仓储等核心组件通过接口抽象，便于替换和扩展
- **异步处理**：媒体处理、云端上传等耗时操作通过任务队列异步处理
- **结构化日志**：统一的日志系统，支持结构化输出、文件轮转和监控集成

#### 移动端架构
- **分层架构**：
  - UI 层（Presentation Layer）：用户界面展示和交互
  - 服务层（Service Layer）：业务逻辑封装和编排
  - 仓库层（Repository Layer）：数据访问抽象
  - 数据层（Data Layer）：数据库和缓存管理
  - 网络层（Network Layer）：HTTP/HTTPS 请求处理
- **模块化设计**：
  - 功能模块独立（备份上传下载、本地媒体同步、媒体资源展示等）
  - 低耦合高内聚
  - 使用 Riverpod 进行依赖注入和状态管理
- **渐进式加载**：占位符 → 缩略图 → 预览图 → 原图
- **智能资源选择**：根据本地/远程资源可用性和用户偏好自动选择最优资源
- **多级缓存体系**：内存缓存（三级缓存池）+ 磁盘缓存（分离管理）

### Testing Strategy

#### 后端测试
- **单元测试**：
  - Service 层：使用 mock Repository 和 Storage
  - Repository 层：使用测试数据库（SQLite）
  - Worker 层：测试任务处理逻辑
- **集成测试**：
  - 测试完整的 API 流程
  - 测试任务队列处理流程
  - 测试存储操作
- **测试工具**：
  - 使用 `testify` 进行断言和 mock
  - 使用 `testcontainers` 进行数据库测试（可选）

#### 移动端测试
- **单元测试**：测试服务层、仓库层逻辑
- **Widget 测试**：测试 UI 组件
- **集成测试**：测试完整业务流程
- **性能测试**：测试媒体加载、上传下载性能

### Git Workflow

- **版本管理**：
  - 使用 Git 标签管理版本（如 `v1.0.0`）
  - 构建时自动注入版本信息（Version, BuildTime, GitCommit, GitBranch）
  - 版本信息可通过 CLI 和 API 查询
- **分支策略**：
  - 主分支：`main` 或 `master`
  - 功能分支：`feature/*`
  - 修复分支：`fix/*`
- **提交规范**：
  - 使用有意义的提交信息
  - 建议使用约定式提交（Conventional Commits）格式

## Domain Context

### 核心业务概念

- **资产（Asset）**：照片或视频文件，包含本地资产和远程资产
- **相册（Album）**：资产的集合，支持本地相册和远程相册
- **备份（Backup）**：将本地资产上传到服务器的过程
  - **手动备份**：用户主动选择资源，立即执行，高优先级
  - **自动备份**：系统根据配置自动触发，检查网络条件，正常优先级
- **同步（Sync）**：
  - **本地同步**：扫描设备媒体库，更新本地数据库
  - **远程同步**：从服务器获取已上传资产列表，更新本地数据库
- **媒体处理**：缩略图生成、ThumbHash 生成、视频转码等

### 多用户支持

- 所有接口方法必须包含 `userId` 参数
- 使用 `BackupQueryBuilder` 强制 userId 过滤，确保多用户数据隔离
- 每个用户拥有独立的备份配置和状态

### 存储架构

- **主存储**：本地文件系统存储
- **云存储**：支持 S3、OSS、COS 等对象存储
- **OpenList/AList 对接**：支持 OpenList/AList 云存储对接

## Important Constraints

### 技术约束
- **性能优先**：所有设计决策优先考虑性能影响，确保流畅的用户体验
- **类型安全**：使用类型安全的技术栈（Go 强类型、Dart 强类型、Drift、Riverpod、AutoRoute、Pigeon）
- **并发安全**：多 goroutine/Isolate 环境下安全操作，无竞争条件
- **资源管理**：及时释放资源，避免内存泄漏

### 业务约束
- **数据隔离**：多用户数据必须严格隔离
- **备份策略**：支持 WiFi 优先上传、断点续传、智能重试
- **缓存策略**：大图小图分离缓存，避免相互干扰
- **网络优化**：连接复用、智能重试、网络状态检测

### 平台约束
- **移动端**：支持 Android 和 iOS 平台
- **后端**：支持 Linux（amd64/arm64）平台
- **容器化**：支持 Docker 和 docker-compose 部署

## External Dependencies

### 后端依赖
- **数据库**：PostgreSQL / SQLite
- **云存储**：S3、OSS、COS 等对象存储服务
- **OpenList/AList**：云存储对接服务
- **ImageMagick**：媒体处理（缩略图生成等）

### 移动端依赖
- **平台服务**：
  - Android：WorkManager（后台任务）、PhotoManager（本地媒体库访问）、Keystore（Token 存储）
  - iOS：BGTaskScheduler（后台任务）、PHPhotoLibrary（本地媒体库访问）、Keychain（Token 存储）
- **网络服务**：后端 API 服务
- **云存储**：通过后端服务间接访问

### 开发工具
- **后端**：Go 1.24+, Docker, docker-compose, Make
- **移动端**：Flutter 3.x+, Dart SDK ^3.10.4, build_runner（代码生成）
