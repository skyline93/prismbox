# Changelog 模块

## 概述

`changelog` 是一个**可插拔的**、**零侵入的**、基于变更日志（Change Data Capture）的数据同步引擎。它为移动客户端提供高效的数据同步能力，支持增量同步和全量同步，同时保证数据的最终一致性。

### 核心特性

- **可插拔设计**：通过配置控制启用/禁用，禁用时零开销
- **零侵入**：业务代码无需感知 changelog 的存在
- **通用隔离机制**：支持任意维度的数据隔离（用户、组织、项目等）
- **原子性保证**：业务数据变更和变更日志记录在同一事务中完成
- **自动清理**：后台任务自动清理陈旧的变更日志

## 架构设计

### 核心组件

```
┌─────────────────────────────────────────────────────────┐
│                    Changelog Module                      │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────┐  │
│  │   Engine     │───▶│   Handler    │───▶│  Service │  │
│  │  (入口)      │    │  (HTTP API)  │    │ (业务逻辑)│  │
│  └──────────────┘    └──────────────┘    └──────────┘  │
│         │                    │                  │        │
│         │                    │                  │        │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────┐  │
│  │  Repository  │    │   Cleanup    │    │  Adapter │  │
│  │  (包装器)    │    │  (清理服务)  │    │ (适配层) │  │
│  └──────────────┘    └──────────────┘    └──────────┘  │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

### 数据流

#### 1. 数据写入流程

```
业务代码
  │
  ▼
MediaRepository.Create()
  │
  ▼
ChangelogAwareMediaRepository (适配器)
  │
  ▼
MediaRepositoryAdapter (适配器)
  │
  ▼
changelogRepository (包装器)
  │
  ├─▶ wrapped.Create() ──▶ 业务表写入
  │
  └─▶ createChangelogEntry() ──▶ changelogs 表写入
       (同一事务中)
```

#### 2. 数据同步流程

```
客户端
  │
  ▼
GET /api/v1/sync?last_seq_id=100
  │
  ▼
syncHandler.handleSync()
  │
  ▼
syncService.GetIncrementalChanges()
  │
  ├─▶ 应用隔离条件 (isolation_key, isolation_value)
  │
  └─▶ 查询 changelogs 表
       WHERE sequence_id > 100
       AND isolation_key = 'user_id'
       AND isolation_value = '123'
```

## 核心概念

### 1. 变更日志（Changelog）

`Changelog` 表记录所有数据变更，每个变更都有一个全局唯一的自增 `SequenceID`，作为同步的"游标"。

**关键字段**：
- `SequenceID`: 全局自增ID，作为同步游标
- `TableNameCol`: 业务表名
- `RecordID`: 业务记录ID
- `OperationType`: 操作类型（CREATED/UPDATED/DELETED）
- `Payload`: 完整的业务数据（JSON格式）
- `IsolationKey`: 隔离键（如 "user_id"）
- `IsolationValue`: 隔离值（如用户ID）

### 2. 隔离机制

使用通用的 `IsolationKey` 和 `IsolationValue` 字段实现数据隔离，不硬编码特定字段名。

**优势**：
- 支持任意隔离维度（用户、组织、项目等）
- 查询时可直接使用索引，无需 JOIN
- 灵活扩展，无需修改模块代码

**示例**：
```go
// Media 模型实现
func (m *Media) GetIsolationKey() string {
    return "user_id"  // 可以是任意字段名
}

func (m *Media) GetIsolationValue() string {
    return fmt.Sprintf("%d", m.UserID)
}
```

### 3. 包装器模式

使用装饰器模式包装业务仓储，自动记录变更日志：

```go
// 原始仓储
mediaRepo := repository.NewMediaRepository(db)

// 创建适配器（适配新架构接口）
adapter := changelog.NewMediaRepositoryAdapter(mediaRepo)

// 包装适配器（添加变更日志功能）
wrapped := changelog.WithChangelog(db, adapter, config)

// 转换回业务接口
changelogAwareRepo := changelog.NewChangelogAwareMediaRepository(wrapped, mediaRepo)
```

**关键点**：
- 如果 `config.Enabled = false`，`WithChangelog` 直接返回原始仓储（零开销）
- 包装后的仓储接口与原始仓储完全相同
- 业务代码无需修改

## 接口设计

### SyncedModel 接口

业务模型需要实现此接口以支持同步：

```go
type SyncedModel interface {
    GetRecordID() string      // 返回记录的唯一标识
    GetTableName() string     // 返回表名
    GetIsolationKey() string  // 返回隔离键（如 "user_id"）
    GetIsolationValue() string // 返回隔离值（如用户ID）
}
```

**实现示例**（Media 模型）：
```go
func (m *Media) GetRecordID() string {
    return m.UUID
}

func (m *Media) GetTableName() string {
    return "medias"
}

func (m *Media) GetIsolationKey() string {
    return "user_id"
}

func (m *Media) GetIsolationValue() string {
    return fmt.Sprintf("%d", m.UserID)
}
```

### WritableRepository 接口

需要同步的业务仓储需要实现此接口：

```go
type WritableRepository[T SyncedModel] interface {
    Create(ctx context.Context, model T) (T, error)
    Update(ctx context.Context, model T) (T, error)
    Delete(ctx context.Context, model T) error
}
```

## 配置

### 配置结构

```go
type Config struct {
    Enabled              bool          // 是否启用（关键：控制可插拔）
    CleanupInterval      time.Duration // 清理周期
    DeviceActiveThreshold time.Duration // 设备活跃阈值
    DefaultSyncPageLimit int           // 默认分页大小
    FullSyncTables       map[string]FullSyncTableConfig // 全量同步表配置
}
```

### 配置示例

```yaml
changelog:
  enabled: true
  cleanup_interval: 24h
  device_active_threshold: 4320h  # 180天
  default_sync_page_limit: 500
  full_sync_tables:
    medias:
      primary_key_column: "uuid"
```

### 禁用模块

设置 `enabled: false` 即可完全禁用，此时：
- 不创建数据库表
- 不注册 API 路由
- 不启动后台任务
- 包装器直接透传（零开销）

## API 接口

### 增量同步

```
GET /api/v1/sync?last_seq_id=100&limit=500

请求头：
  X-Isolation-Key: user_id
  X-Isolation-Value: 123
  X-Device-ID: device-001

响应：
{
  "changes": [...],
  "latest_seq_id": 150,
  "has_more": true
}
```

### 全量同步初始化

```
GET /api/v1/sync/full_init

响应：
{
  "tables_to_sync": ["medias"],
  "snapshot_seq_id": 200
}
```

### 全量同步数据

```
GET /api/v1/sync/full_data?table=medias&page_token=0&limit=500

请求头：
  X-Isolation-Key: user_id
  X-Isolation-Value: 123

响应：
{
  "changes": [...],
  "next_page_token": "500"
}
```

## 集成指南

### 1. 在业务模型中实现接口

```go
// internal/database/models/media.go
func (m *Media) GetRecordID() string { return m.UUID }
func (m *Media) GetTableName() string { return "medias" }
func (m *Media) GetIsolationKey() string { return "user_id" }
func (m *Media) GetIsolationValue() string { return fmt.Sprintf("%d", m.UserID) }
```

### 2. 在 Builder 中初始化

```go
// internal/app/builder.go
func (b *Builder) BuildChangelog() error {
    config := changelog.DefaultConfig()
    config.FullSyncTables["medias"] = changelog.FullSyncTableConfig{
        PrimaryKeyColumn: "uuid",
    }
    
    b.app.ChangelogEngine = changelog.NewEngine(b.app.DB, config)
    b.app.ChangelogFactory = changelog.NewWrapperFactory(b.app.DB, config)
    return nil
}
```

### 3. 包装业务仓储

```go
// internal/app/builder.go
func (b *Builder) BuildRepositories() error {
    originalRepo := repository.NewMediaRepository(b.app.DB)
    
    if b.app.ChangelogFactory != nil && b.app.ChangelogFactory.IsEnabled() {
        adapter := changelog.NewMediaRepositoryAdapter(originalRepo)
        wrapped := changelog.WrapRepository(b.app.ChangelogFactory, adapter)
        b.app.MediaRepo = changelog.NewChangelogAwareMediaRepository(wrapped, originalRepo)
    } else {
        b.app.MediaRepo = originalRepo
    }
    return nil
}
```

### 4. 注册路由

```go
// internal/api/router.go
func (r *Router) setupAPIV1() {
    v1 := r.engine.Group("/api/v1")
    
    if r.app.ChangelogEngine != nil && r.app.ChangelogEngine.IsEnabled() {
        changelog.RegisterRoutes(v1, r.app)
    }
}
```

## 数据库设计

### Changelog 表

```sql
CREATE TABLE changelogs (
    sequence_id BIGSERIAL PRIMARY KEY,
    table_name VARCHAR(255) NOT NULL,
    record_id VARCHAR(255) NOT NULL,
    operation_type VARCHAR(10) NOT NULL,
    payload JSONB,
    timestamp TIMESTAMP NOT NULL,
    isolation_key VARCHAR(100),
    isolation_value VARCHAR(255)
);

-- 索引
CREATE INDEX idx_changelog_table ON changelogs(table_name);
CREATE INDEX idx_changelog_record ON changelogs(record_id);
CREATE INDEX idx_changelog_timestamp ON changelogs(timestamp);
CREATE INDEX idx_changelog_isolation ON changelogs(isolation_key, isolation_value);
CREATE INDEX idx_changelog_isolation_seq ON changelogs(isolation_key, isolation_value, sequence_id);
```

### ClientSyncStatus 表

```sql
CREATE TABLE client_sync_statuses (
    device_id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    last_synced_sequence_id BIGINT NOT NULL,
    last_seen_timestamp TIMESTAMP NOT NULL
);

CREATE INDEX idx_client_sync_user ON client_sync_statuses(user_id);
```

## 清理机制

后台清理服务定期运行，删除不再需要的变更日志：

**清理策略**：
1. 查找所有活跃设备（`last_seen_timestamp > 阈值`）
2. 找到这些设备中最小的 `last_synced_sequence_id`
3. 删除所有 `sequence_id < 最小值` 的变更日志

**配置**：
- `CleanupInterval`: 清理任务运行周期（默认 24 小时）
- `DeviceActiveThreshold`: 设备活跃阈值（默认 180 天）

## 性能优化

### 索引优化

- `idx_changelog_isolation_seq`: 复合索引，优化隔离查询
- `idx_changelog_timestamp`: 优化清理任务查询

### 查询优化

- 使用 `sequence_id` 作为游标，避免时间戳查询
- 隔离字段冗余存储，避免 JOIN 操作
- 分页查询，避免一次性加载大量数据

## 扩展性

### 添加新的隔离维度

如果未来需要支持组织隔离：

```go
// 在业务模型中
func (m *Media) GetIsolationKey() string {
    if m.OrganizationID > 0 {
        return "organization_id"
    }
    return "user_id"
}

func (m *Media) GetIsolationValue() string {
    if m.OrganizationID > 0 {
        return fmt.Sprintf("%d", m.OrganizationID)
    }
    return fmt.Sprintf("%d", m.UserID)
}
```

### 支持多维度隔离

可以扩展 `IsolationKey` 和 `IsolationValue` 为 JSON 字段，支持多维度组合隔离。

## 注意事项

1. **事务一致性**：变更日志记录与业务数据写入在同一事务中，保证原子性
2. **序列ID连续性**：`SequenceID` 必须连续，不能有间隙（由数据库自增保证）
3. **隔离字段提取**：必须在业务数据写入后提取，确保数据完整
4. **清理策略**：清理任务要保守，避免删除仍被使用的变更日志
5. **禁用时的行为**：禁用时所有包装器直接透传，业务代码无需修改

## 故障排查

### 变更日志未记录

1. 检查 `config.Enabled` 是否为 `true`
2. 检查业务模型是否实现了 `SyncedModel` 接口
3. 检查是否使用了包装后的仓储

### 同步查询无数据

1. 检查隔离字段是否正确设置
2. 检查 `last_seq_id` 是否正确
3. 检查数据库索引是否创建

### 清理任务异常

1. 检查 `DeviceActiveThreshold` 配置是否合理
2. 检查是否有长时间未同步的设备
3. 检查数据库连接是否正常

## 相关文档

- [数据库设计文档](../../doc/ARCHITECTURE/07-core-modules/07-database-design.md)
- [API 架构文档](../../doc/ARCHITECTURE/07-core-modules/07-api-architecture.md)
- [配置文档](../../doc/ARCHITECTURE/10-configuration.md)

