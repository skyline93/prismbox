# 12. 测试策略

## 12.1 单元测试

- Service 层：使用 mock Repository 和 Storage
- Repository 层：使用测试数据库（SQLite）
- Worker 层：测试任务处理逻辑

## 12.2 集成测试

- 测试完整的 API 流程
- 测试任务队列处理流程
- 测试存储操作

## 12.3 测试工具

- 使用 `testify` 进行断言和 mock
- 使用 `testcontainers` 进行数据库测试（可选）

