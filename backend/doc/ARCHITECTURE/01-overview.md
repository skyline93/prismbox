# 1. 架构概述

## 1.1 设计原则

- **分层架构**：清晰的层次分离（API → Service → Repository → Database）
- **依赖注入**：使用传统的手动依赖注入，提高代码清晰度和可测试性
- **接口抽象**：存储、仓储等核心组件通过接口抽象，便于替换和扩展
- **异步处理**：媒体处理、云端上传等耗时操作通过任务队列异步处理
- **容器化部署**：支持 Docker 和 docker-compose 部署
- **版本管理**：每次构建自动注入版本信息，支持 CLI 和 API 查询

## 1.2 技术栈

- **语言**：Go 1.24+
- **Web 框架**：Gin
- **ORM**：GORM
- **任务队列**：自研 GQ (Go-Gorm-Queue)
- **数据库**：PostgreSQL / SQLite
- **容器化**：Docker, docker-compose
- **命令行工具**：github.com/urfave/cli/v2
