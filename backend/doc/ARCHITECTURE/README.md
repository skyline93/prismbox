# Album Backend 架构设计文档

本文档描述了 Album Backend 的完整架构设计。

## 目录

- [1. 架构概述](./01-overview.md)
- [2. 目录结构](./02-directory-structure.md)
- [3. 分层架构](./03-layered-architecture.md)
- [4. 依赖注入](./04-dependency-injection.md)
- [5. 版本控制系统](./05-version-control.md)
- [6. 容器部署](./06-container-deployment.md)
- [7. 核心模块设计](./07-core-modules.md)
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
- [核心模块设计](./07-core-modules.md) - 分层存储架构、OpenList/AList 对接、备份调度器等
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

