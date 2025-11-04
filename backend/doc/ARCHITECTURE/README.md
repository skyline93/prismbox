# Album Backend 架构设计文档

本文档描述了 Album Backend 的完整架构设计。

## 目录

- [1. 架构概述](./01-overview.md)
- [2. 目录结构](./02-directory-structure.md)
- [3. 分层架构](./03-layered-architecture.md)
- [4. 依赖注入](./04-dependency-injection.md)
- [5. 版本控制系统](./05-version-control.md)
- [6. 容器部署](./06-container-deployment.md)
- [7. 核心模块设计](./07-core-modules/README.md)
  - [7.1 分层存储架构](./07-core-modules/07-storage-architecture.md)
  - [7.2 主存储设计（本地存储）](./07-core-modules/07-storage-primary.md)
  - [7.3 OpenList/AList 云存储对接](./07-core-modules/07-storage-openlist.md)
  - [7.4 备份调度器模块](./07-core-modules/07-backup-scheduler.md)
  - [7.5 媒体处理流程](./07-core-modules/07-media-processing.md)
- [8. 数据流设计](./08-data-flow.md)
- [9. 扩展性考虑](./09-scalability.md)
- [10. 配置管理](./10-configuration.md)
- [11. 错误处理](./11-error-handling.md)
- [12. 测试策略](./12-testing.md)
- [13. 性能优化](./13-performance.md)
- [14. 安全考虑](./14-security.md)
- [15. 监控和运维](./15-monitoring.md)
- [16. 部署流程](./16-deployment.md)
- [17. 总结](./17-summary.md)

## 快速导航

### 核心概念
- [架构概述](./01-overview.md) - 设计原则和技术栈
- [分层架构](./03-layered-architecture.md) - API、Service、Repository、Worker 层
- [依赖注入](./04-dependency-injection.md) - 应用组装和依赖注入方式

### 模块设计
- [核心模块设计](./07-core-modules/README.md) - 核心模块设计索引
  - [分层存储架构](./07-core-modules/07-storage-architecture.md) - 存储架构概述和接口设计
  - [主存储设计](./07-core-modules/07-storage-primary.md) - 本地存储的详细设计
  - [OpenList 对接](./07-core-modules/07-storage-openlist.md) - OpenList/AList 对接模块
  - [备份调度器](./07-core-modules/07-backup-scheduler.md) - 备份调度器设计
  - [媒体处理流程](./07-core-modules/07-media-processing.md) - 媒体处理任务和流程
- [数据流设计](./08-data-flow.md) - 媒体上传流程（完全解耦）、云存储备份流程（独立调度）

### 运维相关
- [配置管理](./10-configuration.md) - 配置文件结构和环境变量支持
- [容器部署](./06-container-deployment.md) - Dockerfile 和 docker-compose 配置
- [版本控制系统](./05-version-control.md) - 版本注入和查询方式
- [部署流程](./16-deployment.md) - 本地开发、构建和部署步骤

### 质量保证
- [测试策略](./12-testing.md) - 单元测试、集成测试
- [错误处理](./11-error-handling.md) - 错误分类和响应格式
- [性能优化](./13-performance.md) - 数据库、存储、任务队列优化
- [安全考虑](./14-security.md) - 认证授权、数据安全、文件安全

### 扩展和维护
- [扩展性考虑](./09-scalability.md) - 存储、任务、服务、数据库扩展
- [监控和运维](./15-monitoring.md) - 健康检查、日志、指标

## 相关文档

- [GQ 任务队列框架文档](../../pkg/gq/README.md) - 任务队列框架详细文档

