# Album Backend 文档索引

本文档是 Album Backend 项目的文档中心，提供所有文档的入口和导航。

## 🏗️ 架构设计

- **[架构设计文档](./ARCHITECTURE/README.md)** - 完整的架构设计文档
  - [架构概述](./ARCHITECTURE/01-overview.md)
  - [目录结构](./ARCHITECTURE/02-directory-structure.md)
  - [分层架构](./ARCHITECTURE/03-layered-architecture.md)
  - [依赖注入](./ARCHITECTURE/04-dependency-injection.md)
  - [数据流设计](./ARCHITECTURE/08-data-flow.md)

### 核心模块

- [核心模块设计](./ARCHITECTURE/07-core-modules/README.md)
  - [分层存储架构](./ARCHITECTURE/07-core-modules/07-storage-architecture.md)
  - [主存储设计](./ARCHITECTURE/07-core-modules/07-storage-primary.md)
  - [OpenList 对接](./ARCHITECTURE/07-core-modules/07-storage-openlist.md)
  - [备份调度器](./ARCHITECTURE/07-core-modules/07-backup-scheduler.md)
  - [媒体处理流程](./ARCHITECTURE/07-core-modules/07-media-processing.md)
  - [媒体处理模块架构](./ARCHITECTURE/07-core-modules/07-media-processor.md)
  - [认证模块架构](./ARCHITECTURE/07-core-modules/07-auth-architecture.md)
  - [日志模块架构](./ARCHITECTURE/07-core-modules/07-logger.md)

## 📦 框架和库

- **[GQ 任务队列框架](../pkg/gq/README.md)** - Go-Gorm-Queue 任务队列框架
- **[Logger 日志模块](../pkg/logger/README.md)** - 结构化日志库

## 🔧 模块文档

- **[本地存储模块](../internal/storage/primary/local/README.md)** - 本地存储实现
- **[本地存储性能优化](../internal/storage/primary/local/PERFORMANCE.md)** - 性能优化文档

## 📖 开发指南

- [配置管理](./ARCHITECTURE/10-configuration.md)
- [错误处理](./ARCHITECTURE/11-error-handling.md)
- [测试策略](./ARCHITECTURE/12-testing.md)
- [版本控制](./ARCHITECTURE/05-version-control.md)

## 🚀 运维部署

- [容器部署](./ARCHITECTURE/06-container-deployment.md)
- [部署流程](./ARCHITECTURE/16-deployment.md)
- [监控和运维](./ARCHITECTURE/15-monitoring.md)

## ⚡ 性能优化

- [性能优化](./ARCHITECTURE/13-performance.md)
- [本地存储性能优化](../internal/storage/primary/local/PERFORMANCE.md)

## 🔒 安全与扩展

- [安全考虑](./ARCHITECTURE/14-security.md)
- [扩展性考虑](./ARCHITECTURE/09-scalability.md)

