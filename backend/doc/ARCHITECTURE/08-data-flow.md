# 8. 数据流设计

## 8.1 媒体上传流程（完全解耦）

### 8.1.1 用户上传流程（主存储）

```
客户端请求
    ↓
API Handler (接收请求、验证参数)
    ↓
Media Service (业务逻辑)
    ↓
StorageManager.Put() (只写入本地存储)
    ↓
PrimaryStorage.Put() (本地存储，同步)
    ↓
Repository (创建数据库记录，backup_status = "pending")
    ↓
Task Queue (入队处理任务)
    ↓
Worker (异步处理：生成缩略图、预览)
    ↓
Repository (更新处理状态)
    ↓
返回给用户（立即返回，不等待云存储）
```

**关键点**：
- 用户上传流程只写入本地存储，立即返回
- 创建数据库记录时，`backup_status` 设置为 `"pending"`
- 不触发云存储备份任务，完全解耦

### 8.1.2 云存储备份流程（独立调度）

```
备份调度器（定时扫描，每5分钟）
    ↓
检查系统是否空闲（CPU/内存/磁盘IO/网络IO < 30%）
    ↓
查询待备份文件（backup_status = "pending"，按创建时间排序）
    ↓
批量处理（每次最多100个文件）
    ↓
更新状态为 "processing"
    ↓
创建备份任务（低优先级，延迟5分钟执行）
    ↓
任务队列（Queue: backup, Priority: 1）
    ↓
Worker 处理备份任务（系统空闲时）
    ↓
从本地存储读取文件
    ↓
上传到云存储（SecondaryStorage.Upload()）
    ↓
更新数据库（backup_status = "completed"，记录 cloud_path）
    ↓
（失败时）更新数据库（backup_status = "failed"，记录错误信息）
```

**关键点**：
- 备份调度器独立运行，不依赖用户上传流程
- 系统空闲时批量处理，不占用高峰资源
- 低优先级队列，不影响业务任务
- 失败时记录错误信息，支持重试

## 8.2 任务处理流程

```
调度器轮询数据库
    ↓
查找待处理任务 (pending/retrying)
    ↓
锁定任务 (FOR UPDATE SKIP LOCKED)
    ↓
更新状态为 active
    ↓
分发到 Worker Channel
    ↓
Worker 处理任务
    ↓
成功 → 更新为 archived
失败 → 重试或标记为 failed
```

## 8.3 数据同步流程

```
客户端请求增量同步
    ↓
Changelog Service (查询变更日志)
  │
  ├─▶ 应用隔离条件 (isolation_key, isolation_value)
  │
  └─▶ 查询 changelogs 表
       WHERE sequence_id > last_seq_id
       AND isolation_key = 'user_id'
       AND isolation_value = '123'
    ↓
Repository (查询数据库变更)
    ↓
返回变更列表
    ↓
客户端应用变更
```

