# 7.9 数据库层架构设计

## 7.9.1 概述

数据库层是 Album Backend 的数据持久化层，负责所有业务数据的存储和管理。该层采用 GORM ORM 框架，统一继承 `gorm.Model`，支持 SQLite 和 PostgreSQL 两种数据库，并提供了完善的迁移机制。

## 7.9.2 设计原则

### 核心设计理念

1. **统一模型基类**：所有模型统一继承 `gorm.Model`，保持代码一致性
2. **向后兼容**：保留旧架构的所有表和字段，确保业务功能不变
3. **数据库兼容**：使用 GORM 的数据库无关特性，同时支持 SQLite 和 PostgreSQL
4. **简洁维护**：设计简洁，不过度设计，便于后续维护
5. **迁移支持**：提供完善的数据库迁移机制，支持表结构升级

## 7.9.3 目录结构

```
backend/internal/
├── database/
│   ├── connection.go          # 数据库连接管理（支持 SQLite 和 PostgreSQL）
│   ├── migrations/            # 数据库迁移文件
│   │   ├── migrations.go     # 迁移注册和版本管理
│   │   └── v1_initial.go      # 初始版本迁移
│   └── models/                # 数据模型定义（统一继承 gorm.Model）
│       ├── base.go            # 基础模型（可选扩展）
│       ├── user.go            # 用户相关模型
│       ├── media.go           # 媒体相关模型
│       ├── album.go           # 相册相关模型
│       ├── share.go           # 分享相关模型
│       ├── group.go           # 圈子相关模型
│       ├── sync.go            # 同步相关模型（Changelog, ClientSyncStatus）
│       └── upload.go           # 上传任务模型
│
└── repository/                # 数据访问层（已存在）
    ├── interfaces.go          # 仓储接口定义
    ├── user.go
    ├── media.go
    ├── album.go
    ├── group.go
    └── share.go
```

## 7.9.4 核心设计

### 统一模型基类

所有模型统一继承 `gorm.Model`，包含以下字段：
- `ID`：主键（uint）
- `CreatedAt`：创建时间
- `UpdatedAt`：更新时间
- `DeletedAt`：软删除时间（可选，使用索引）

特殊场景（如 UploadTask）使用自定义主键，但保留时间字段。

### 数据库兼容性

- **SQLite 与 PostgreSQL**：使用 GORM 的数据库无关特性，统一模型定义
- **字段类型**：使用 GORM 推荐类型（如 `string` 而非 `varchar`），GORM 自动适配
- **JSON 字段**：使用 `datatypes.JSON`，PostgreSQL 使用 JSONB，SQLite 使用 JSON
- **索引兼容**：使用 GORM 的索引标签，自动适配两种数据库

### 索引设计

- **复合唯一索引**：使用 `uniqueIndex:idx_name,priority:N` 格式
- **普通索引**：使用 `index` 标签
- **软删除索引**：`DeletedAt` 字段统一使用 `gorm:"index"` 标记

### 外键关系

- 使用 GORM 的 `foreignKey` 标签定义关系
- 多对多关系使用中间表（如 `album_items`, `group_members`）
- 关联关系保持与旧架构一致

## 7.9.5 模型设计

### 7.9.5.1 用户相关模型

#### User（用户表）
继承 `gorm.Model`

**字段**：
- `Username`: `string`, 唯一索引，允许 NULL（可选）
- `Email`: `string`, 唯一索引，必须（关键锚点）
- `Password`: `string`, 允许 NULL（可选）
- `Avatar`: `string`

**关联**：
- `AuthProviders []AuthProvider`
- `RefreshTokens []RefreshToken`

#### AuthProvider（第三方认证提供商）
继承 `gorm.Model`

**字段**：
- `UserID`: `uint`, 外键关联 User
- `ProviderName`: `string` (如 "apple", "google")
- `ProviderUserID`: `string` (text)

**索引**：
- 复合唯一索引：`(ProviderName, UserID)`

#### RefreshToken（刷新令牌）
继承 `gorm.Model`

**字段**：
- `UserID`: `uint`, 外键关联 User，索引
- `Token`: `string`, 唯一索引
- `ExpiresAt`: `time.Time`
- `IsRevoked`: `bool`, 默认 false

### 7.9.5.2 媒体相关模型

#### Media（媒体文件）
继承 `gorm.Model`

**核心字段**：
- `UUID`: `string`, 唯一索引
- `UserID`: `uint`, 索引
- `Hash`: `string`, 与 UserID 复合唯一索引
- `ItemType`: `string` (MediaType 枚举值: "image", "video")
- `OriginalFilename`: `string`
- `Filename`: `string`
- `FileSize`: `int64`
- `MimeType`: `string`

**媒体元数据**：
- `Width`: `int`
- `Height`: `int`
- `Duration`: `float64`
- `MediaTakenAt`: `*time.Time` (指针，允许 NULL)
- `CameraMake`: `*string`
- `CameraModel`: `*string`
- `Aperture`: `*string`
- `ShutterSpeed`: `*string`
- `ISO`: `*int`
- `Latitude`: `*float64`
- `Longitude`: `*float64`

**处理状态**：
- `ProcessingStatus`: `string` (ProcessingStatus 枚举值: "PENDING", "COMPLETED", "FAILED")
- `Deleted`: `bool`, 默认 false（业务软删除标志，与 DeletedAt 区分）

**存储路径与存储池**（新增，用于 7.2 主存储设计）：
- `LocalPath`: `string` (本地存储路径，hash-based key)
- `CloudPath`: `string` (云存储路径，备份完成后)
- `LocalPoolUUID`: `string` (本地存储池 UUID，用于定位实际磁盘/挂载点)
- `CloudPoolUUID`: `string` (云存储池 UUID，用于备份多云策略)

**备份状态**（新增，用于 7.4 备份调度器）：
- `BackupStatus`: `string` (BackupStatus 枚举值: "pending", "processing", "completed", "failed")
- `BackupStartedAt`: `*time.Time`
- `BackupCompletedAt`: `*time.Time`
- `BackupError`: `string`

**索引**：
- `UUID` 唯一索引
- `UserID` 索引
- 复合唯一索引：`(UserID, Hash)`

### 7.9.5.3 相册相关模型

#### Album（相册）
继承 `gorm.Model`

**字段**：
- `UUID`: `string`, 唯一索引
- `Name`: `string`
- `Description`: `string`
- `UserID`: `uint`, 索引，外键关联 User
- `CoverMediaUUID`: `*string` (指针，允许 NULL)

**关联**：
- `Items []Media` (多对多，通过 `album_items` 中间表)

**索引**：
- `UUID` 唯一索引
- `UserID` 索引

#### album_items（中间表）
GORM 自动创建，包含 `album_id` 和 `media_id` 字段。

### 7.9.5.4 分享相关模型

#### Share（分享）
**注意**：Share 不使用软删除（无 DeletedAt 字段），或手动排除 `DeletedAt`。

继承 `gorm.Model`，但使用 `gorm:"-"` 忽略 `DeletedAt` 字段，或自定义结构体。

**字段**：
- `ShareToken`: `string`, 唯一索引
- `OwnerID`: `uint`, 外键关联 User
- `TargetUserID`: `*uint`, 索引，外键关联 User（可选，NULL 表示公开分享）
- `MediaID`: `uint`, 外键关联 Media
- `ExpiresAt`: `time.Time`
- `IsRevoked`: `bool`, 默认 false

**索引**：
- `ShareToken` 唯一索引
- `TargetUserID` 索引

### 7.9.5.5 圈子相关模型

#### Group（圈子）
继承 `gorm.Model`

**字段**：
- `UUID`: `string`, 唯一索引
- `Name`: `string`
- `Description`: `string`
- `CoverMediaUUID`: `string`
- `OwnerID`: `uint`, 外键关联 User

**关联**：
- `Members []User` (多对多，通过 `group_members` 表)

**索引**：
- `UUID` 唯一索引

#### GroupMember（圈子成员）
继承 `gorm.Model`

**字段**：
- `GroupID`: `uint`, 外键关联 Group
- `UserID`: `uint`, 外键关联 User
- `Role`: `string` (GroupRole 枚举值: "owner", "admin", "member")
- `JoinedAt`: `time.Time`, 自动创建时间

**索引**：
- 复合唯一索引：`(GroupID, UserID)`

#### GroupPost（圈子帖子）
继承 `gorm.Model`

**字段**：
- `GroupID`: `uint`, 索引，外键关联 Group
- `CreatorID`: `uint`, 外键关联 User
- `Caption`: `string`

**关联**：
- `Media []GroupMedia`
- `Comments []Comment`
- `Likes []Like`

**索引**：
- `GroupID` 索引

#### GroupMedia（圈子媒体）
继承 `gorm.Model`

**字段**：
- `GroupID`: `uint`, 索引（保留，便于快速按圈子过滤）
- `PostID`: `uint`, 索引，外键关联 GroupPost
- `MediaUUID`: `string`, 索引（引用 Media.UUID，非外键）

**索引**：
- `GroupID` 索引
- `PostID` 索引
- `MediaUUID` 索引

#### Comment（评论）
继承 `gorm.Model`

**字段**：
- `PostID`: `uint`, 索引，外键关联 GroupPost
- `UserID`: `uint`, 外键关联 User
- `Content`: `string` (text)
- `ParentCommentID`: `*uint`, 索引（支持嵌套评论）

**关联**：
- `User`, `Post`, `Replies []Comment`, `Likes []CommentLike`

**索引**：
- `PostID` 索引
- `ParentCommentID` 索引

#### CommentLike（评论点赞）
继承 `gorm.Model`

**字段**：
- `CommentID`: `uint`, 外键关联 Comment
- `UserID`: `uint`, 外键关联 User

**索引**：
- 复合唯一索引：`(CommentID, UserID)`

#### Like（帖子点赞）
继承 `gorm.Model`

**字段**：
- `PostID`: `uint`, 外键关联 GroupPost
- `UserID`: `uint`, 外键关联 User

**索引**：
- 复合唯一索引：`(PostID, UserID)`

#### GroupInvite（圈子邀请）
继承 `gorm.Model`

**字段**：
- `GroupID`: `uint`, 外键关联 Group
- `CreatedByID`: `uint`, 外键关联 User
- `Code`: `string`, 唯一索引
- `ExpiresAt`: `time.Time`
- `UsageLimit`: `int` (0 表示无限制)

**索引**：
- `Code` 唯一索引

### 7.9.5.6 上传任务模型

#### UploadTask（上传任务）
**注意**：使用自定义主键，不继承 `gorm.Model`。

**字段**：
- `ID`: `string` (主键，UUID)
- `CreatedAt`: `time.Time`
- `UserID`: `uint`, 索引
- `FileHash`: `string`, 索引
- `TotalSize`: `int64`
- `ChunkSize`: `int`
- `NumChunks`: `int`
- `Status`: `string` ("INITIATED", "COMPLETED", "FAILED")
- `ExpiresAt`: `time.Time`, 索引

**索引**：
- `UserID` 索引
- `FileHash` 索引
- `ExpiresAt` 索引

### 7.9.5.7 同步相关模型

#### Changelog（变更日志）
用于数据同步功能（changelog 模块）。

**注意**：不继承 `gorm.Model`，使用自定义主键。

**字段**：
- `SequenceID`: `int64` (主键，自增) - 全局唯一自增ID，作为同步游标
- `TableNameCol`: `string` (列名: `table_name`), 索引 - 业务表名
- `RecordID`: `string`, 索引 - 业务记录ID
- `OperationType`: `string` ("CREATED", "UPDATED", "DELETED") - 操作类型
- `Payload`: `JSON` (JSONB for PostgreSQL, JSON for SQLite) - 完整的业务数据
- `Timestamp`: `time.Time`, 索引 - 变更时间
- `IsolationKey`: `string`, 索引 - 隔离键（如 "user_id", "organization_id"）
- `IsolationValue`: `string`, 索引 - 隔离值（如用户ID、组织ID）

**索引**：
- `idx_changelog_table`: `table_name`
- `idx_changelog_record`: `record_id`
- `idx_changelog_timestamp`: `timestamp`
- `idx_changelog_isolation`: `(isolation_key, isolation_value)`
- `idx_changelog_isolation_seq`: `(isolation_key, isolation_value, sequence_id)` - 复合索引，优化隔离查询

**设计说明**：
- `IsolationKey` 和 `IsolationValue` 是冗余字段，从 `Payload` 中提取，用于快速过滤和查询
- 支持任意隔离维度，不硬编码特定字段名
- 复合索引 `idx_changelog_isolation_seq` 优化了按隔离条件查询增量变更的性能

#### ClientSyncStatus（客户端同步状态）
用于追踪每个设备的同步进度。

**注意**：使用自定义主键，不继承 `gorm.Model`。

**字段**：
- `DeviceID`: `string` (主键) - 设备唯一标识
- `UserID`: `string`, 索引 - 用户ID（用于查询用户的所有设备）
- `LastSyncedSequenceID`: `int64` - 最后同步到的序列ID
- `LastSeenTimestamp`: `time.Time` - 最后活跃时间

**索引**：
- `idx_client_sync_user`: `user_id`

**设计说明**：
- 用于清理任务判断设备是否活跃
- 支持多设备同步，每个设备独立追踪同步进度

### 7.9.5.8 存储池模型

#### StoragePool（存储池）
继承 `gorm.Model`

**字段**：
- `UUID`: `string`, 唯一索引，对外暴露的存储池 ID
- `Name`: `string`
- `Description`: `string`
- `StorageType`: `string` (`"local"`, `"openlist"`, `"s3"`, `"oss"`, `"cos"`)
- `LocalPath`: `string`（仅 `local` 类型使用）
- `CloudConfig`: `datatypes.JSON`（S3/OSS/COS/OpenList 连接配置）
- `MaxSize`: `int64`
- `CurrentSize`: `int64`
- `Priority`: `int`
- `Enabled`: `bool`
- `AutoDisableThreshold`: `float64`
- `Status`: `string` (`"active"`, `"disabled"`, `"maintenance"`)
- `LastCheckedAt`: `*time.Time`
- `ErrorMessage`: `string`

**索引**：
- `uuid` 唯一索引
- `storage_type` 普通索引
- `(enabled, status)` 组合索引，PoolManager 只扫描启用且 active 的存储池

**设计说明**：
- 存储池配置完全数据库化，替代 YAML 中的 `pools`。
- `StoragePoolRepository` 负责查询/更新，`PoolManager` 通过它加载缓存、原子更新 `current_size`、刷新状态。
- 支持本地与多云统一建模，为未来的故障转移、迁移、权限管理等功能预留字段。

## 7.9.6 枚举类型设计

### 枚举定义位置
在 `internal/constant/` 或 `internal/models/types.go` 中定义。

### 枚举类型

#### MediaType（媒体类型）
- `"image"`
- `"video"`

#### ProcessingStatus（处理状态）
- `"PENDING"` - 待处理
- `"COMPLETED"` - 已完成
- `"FAILED"` - 失败

#### BackupStatus（备份状态）（新增）
- `"pending"` - 待备份
- `"processing"` - 处理中
- `"completed"` - 已完成
- `"failed"` - 失败

#### GroupRole（圈子角色）
- `"owner"` - 所有者
- `"admin"` - 管理员
- `"member"` - 成员

### 枚举使用
- 模型中使用 `string` 类型存储枚举值
- 通过验证函数确保枚举值合法性
- 在 Service 层进行枚举值验证

## 7.9.7 数据库迁移设计

### 7.9.7.1 迁移策略

#### 基础迁移
- 使用 GORM 的 `AutoMigrate` 进行基础表结构迁移
- 自动创建表、索引、外键关系

#### 版本化迁移
- 复杂迁移（如数据迁移、索引调整）使用版本化迁移文件
- 迁移文件按版本命名：`v1_initial.go`, `v2_add_backup_fields.go` 等

#### 迁移注册
- 在 `migrations/migrations.go` 中注册所有迁移版本
- 支持迁移回滚（可选）
- 记录迁移历史到数据库（可选）

### 7.9.7.2 兼容性处理

#### SQLite vs PostgreSQL
- **JSON 字段**：使用 `datatypes.JSON`，PostgreSQL 使用 JSONB，SQLite 使用 JSON
- **字符串长度**：SQLite 无限制，PostgreSQL 使用 `varchar`，GORM 自动处理
- **索引名称**：确保索引名称在两个数据库中唯一

#### 迁移执行顺序
1. 创建基础表结构（GORM AutoMigrate）
2. 执行版本化迁移（按版本顺序）
3. 验证迁移结果（检查表、索引、外键）

## 7.9.8 Repository 层设计

### 7.9.8.1 接口设计
- 保持与旧架构的 Repository 接口一致
- 所有 Repository 实现放在 `internal/repository/` 目录
- 通过接口定义，便于测试和替换

### 7.9.8.2 Repository 实现

#### 上下文支持
- 使用 GORM 的 `WithContext` 支持上下文传递
- 支持请求超时和取消

#### 软删除处理
- 软删除使用 GORM 的 `DeletedAt` 自动处理
- 业务软删除（如 Media.Deleted）需要手动过滤
- 使用 `Unscoped()` 查询已删除的记录

#### 事务处理
- 使用 GORM 的 `Transaction` 方法
- 支持嵌套事务（PostgreSQL 支持，SQLite 不支持）
- 事务失败时自动回滚

## 7.9.9 特殊设计考虑

### 7.9.9.1 Share 模型无软删除
- Share 不使用软删除（无 `DeletedAt` 字段）
- 使用 `gorm:"-"` 忽略 `DeletedAt` 字段，或自定义结构体
- 硬删除使用 `Unscoped().Delete()`

### 7.9.9.2 备份相关字段
- Media 表新增备份相关字段（LocalPath, CloudPath, BackupStatus 等）
- 这些字段用于 7.4 备份调度器模块
- 初始迁移时这些字段可以为空（允许 NULL）

### 7.9.9.3 同步模型接口
- Media 模型需要实现 `SyncedModel` 接口（如果保留同步功能）
- `GetRecordID()` 返回 UUID
- `GetTableName()` 返回 "media"

详细设计请参考 [旧架构的 Replicator 实现](../../../../server/replicator/)。

## 7.9.10 与旧架构的对比

### 保持一致的特性
- ✅ 所有表名和字段名保持完全一致
- ✅ 所有索引设计保持完全一致
- ✅ 所有外键关系保持完全一致
- ✅ 所有业务功能保持完全一致

### 新增特性
- ✅ Media 表新增备份相关字段（LocalPath, CloudPath, BackupStatus 等）
- ✅ 所有模型统一继承 `gorm.Model`
- ✅ 使用版本化迁移文件管理数据库升级

### 改进特性
- ✅ 统一模型基类，代码更简洁
- ✅ 数据库兼容性处理更完善
- ✅ 迁移机制更清晰

## 7.9.11 设计要点总结

### 统一性和简洁性
- ✅ **统一继承 gorm.Model**：所有模型统一继承，保持代码一致性
- ✅ **设计简洁**：不过度设计，便于维护
- ✅ **向后兼容**：保留旧架构的所有字段和索引

### 数据库兼容性
- ✅ **SQLite 和 PostgreSQL**：使用 GORM 的数据库无关特性，统一模型定义
- ✅ **字段类型兼容**：使用 GORM 推荐类型，自动适配
- ✅ **索引兼容**：使用 GORM 的索引标签，自动适配

### 扩展性
- ✅ **迁移支持**：完善的迁移机制，便于后续升级
- ✅ **新字段支持**：新增备份相关字段，支持新架构的备份调度器
- ✅ **枚举类型**：清晰的枚举定义，便于扩展

### 维护性
- ✅ **代码组织**：清晰的目录结构，便于维护
- ✅ **文档完善**：详细的模型和字段说明
- ✅ **测试友好**：通过接口定义，便于 mock 和测试

## 7.9.12 相关文档

- [3. 分层架构](../03-layered-architecture.md) - Repository 层设计
- [4. 依赖注入](../04-dependency-injection.md) - 数据库依赖注入
- [7.2 主存储设计](./07-storage-primary.md) - 本地存储路径设计
- [7.4 备份调度器模块](./07-backup-scheduler.md) - 备份状态管理
- [10. 配置管理](../10-configuration.md) - 数据库配置

