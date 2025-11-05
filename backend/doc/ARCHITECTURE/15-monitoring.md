# 15. 监控和运维

## 15.1 健康检查

- `/health` 端点检查服务状态
- `/ready` 端点检查就绪状态（数据库连接等）

## 15.2 日志

### 15.2.1 日志系统概述

Album Backend 使用统一的日志模块（`pkg/logger`），提供结构化日志记录能力。所有模块的日志输出统一管理，便于监控和分析。

### 15.2.2 日志特性

- **结构化日志**：支持 JSON 格式输出，便于解析和查询
- **日志级别**：支持 DEBUG、INFO、WARN、ERROR、FATAL 五个级别
- **模块标识**：每个模块的日志自动包含模块名，便于过滤
- **上下文追踪**：支持 request_id、user_id 等上下文信息
- **文件轮转**：自动轮转日志文件，支持保留策略和压缩
- **容器化支持**：支持输出到 stdout，便于容器日志收集

### 15.2.3 日志格式

#### JSON 格式（生产环境）

```json
{
  "time": "2025-01-20T10:00:00.123Z",
  "level": "info",
  "module": "service.media",
  "msg": "Uploading media",
  "user_id": 123,
  "media_uuid": "abc-123",
  "file_size": 1024,
  "caller": "service.go:45"
}
```

#### 控制台格式（开发环境）

```
2025-01-20 10:00:00 [INFO] service.media Uploading media
  user_id=123 media_uuid=abc-123 file_size=1024
  caller=service.go:45
```

### 15.2.4 日志收集和查询

#### 容器化部署

- 日志输出到 `stdout`，由容器运行时自动收集
- 与 Docker/Kubernetes 日志系统集成
- 可通过 `kubectl logs` 或 Docker 日志命令查看

#### 日志收集器集成

- **Fluentd/Filebeat**：收集容器日志，转发到集中式日志系统
- **ELK Stack**：Elasticsearch + Logstash + Kibana，全文搜索和分析
- **Loki**：轻量级日志聚合系统，与 Prometheus 集成
- **Datadog/New Relic**：SaaS 日志管理和分析平台

#### 日志查询示例

```bash
# 查询特定模块的日志
jq 'select(.module == "service.media")' app.log

# 查询错误日志
jq 'select(.level == "error")' app.log

# 查询特定用户的日志
jq 'select(.user_id == 123)' app.log

# 查询特定请求的日志（链路追踪）
jq 'select(.request_id == "req-abc-123")' app.log
```

### 15.2.5 日志告警

- 基于日志级别设置告警规则（如 ERROR 级别日志过多）
- 基于关键字匹配设置告警（如 "disk full"、"connection timeout"）
- 与监控系统集成，实现实时告警

### 15.2.6 日志分析

- **错误率统计**：统计各模块的错误日志数量和比例
- **性能分析**：通过日志中的耗时字段分析性能瓶颈
- **用户行为分析**：通过 user_id 追踪用户操作轨迹
- **请求链路追踪**：通过 request_id 追踪完整请求流程

详细设计请参考 [7.7 日志模块架构设计](./07-core-modules/07-logger.md)。

## 15.3 指标（可选）

- Prometheus 指标暴露
- 请求统计
- 任务队列统计

