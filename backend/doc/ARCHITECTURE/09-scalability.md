# 9. 扩展性考虑

## 9.1 存储扩展

新增存储类型只需：
1. 实现 `storage.Storage` 接口
2. 在 `storage/factory.go` 中注册
3. 在配置文件中添加对应配置

## 9.2 任务类型扩展

新增任务类型只需：
1. 定义任务类型常量
2. 实现任务处理器函数
3. 在 `worker/handler.go` 中注册

## 9.3 服务扩展

新增业务服务只需：
1. 在 `internal/service` 下创建新包
2. 定义服务接口和实现
3. 在 `app/builder.go` 中构建和注入

## 9.4 数据库扩展

- 支持多种数据库（PostgreSQL、MySQL、SQLite）
- 通过 GORM 的 Dialector 切换
- 数据库迁移通过 GORM AutoMigrate 或独立迁移工具

## 9.5 水平扩展

- **无状态服务**：所有服务都是无状态的，可以水平扩展
- **任务队列**：多个 Server 实例可以共享同一个数据库，通过 `FOR UPDATE SKIP LOCKED` 实现分布式锁
- **负载均衡**：在多个 Server 实例前放置负载均衡器

