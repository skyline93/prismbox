# 7.4 备份调度器模块

## 7.4.1 概述

备份调度器模块负责在系统空闲时批量处理待备份文件，将本地存储的文件上传到云存储。该模块与用户上传流程完全解耦，通过后台调度器统一处理。

## 7.4.2 设计原则

- **完全解耦**：用户上传流程与云存储备份流程完全独立
- **延迟调度**：不在用户上传时触发备份，而是在系统空闲时批量处理
- **批量处理**：在系统空闲时批量处理多个文件，提高效率
- **状态管理**：通过数据库记录文件的备份状态

## 7.4.3 数据库模型设计

备份调度器使用的 Media 模型字段扩展如下：

```go
// 媒体文件模型（扩展）
type Media struct {
    gorm.Model
    
    UUID        string
    Hash        string
    UserID      uint
    FileSize    int64
    
    // 存储信息
    LocalPath   string  // 本地存储路径
    CloudPath   string  // 云存储路径（备份完成后）
    
    // 备份状态
    BackupStatus    string  // pending, processing, completed, failed
    BackupStartedAt *time.Time
    BackupCompletedAt *time.Time
    BackupError     string
    
    // 其他字段...
}
```

**完整的数据库模型设计请参考 [7.9 数据库层架构设计](./07-database-design.md)**。

## 7.4.4 架构设计

### 备份调度器

```go
// 备份调度器：独立的后台服务
type BackupScheduler struct {
    db          *gorm.DB
    cloudStorage SecondaryStorage
    taskQueue   *gq.Client
    
    // 调度配置
    scanInterval    time.Duration  // 扫描间隔
    batchSize       int            // 批量处理大小
    idleThreshold   float64        // 系统空闲阈值
    maxConcurrency  int            // 最大并发数
    
    // 系统监控
    systemMonitor   *SystemMonitor
}

// 调度器运行
func (bs *BackupScheduler) Run(ctx context.Context) {
    ticker := time.NewTicker(bs.scanInterval)
    defer ticker.Stop()
    
    for {
        select {
        case <-ctx.Done():
            return
        case <-ticker.C:
            // 检查系统是否空闲
            if bs.isSystemIdle() {
                // 系统空闲时，批量处理待备份文件
                bs.processBatch(ctx)
            }
        }
    }
}

// 批量处理待备份文件
func (bs *BackupScheduler) processBatch(ctx context.Context) error {
    // 1. 查询待备份的文件（按优先级、时间排序）
    var medias []Media
    err := bs.db.WithContext(ctx).
        Where("backup_status = ?", "pending").
        Order("created_at ASC").  // 优先处理旧文件
        Limit(bs.batchSize).
        Find(&medias).Error
    
    if err != nil {
        return err
    }
    
    if len(medias) == 0 {
        return nil  // 没有待备份文件
    }
    
    // 2. 批量创建备份任务（低优先级）
    for _, media := range medias {
        // 更新状态为 processing
        bs.db.Model(&media).Update("backup_status", "processing")
        
        // 创建备份任务
        task := &gq.Task{
            Type: "storage:backup:upload",
            Payload: marshalBackupPayload(&media),
        }
        
        // 低优先级，延迟执行
        bs.taskQueue.Enqueue(ctx, task,
            gq.Queue("backup"),
            gq.Priority(1),  // 低优先级
            gq.ProcessAt(time.Now().Add(5*time.Minute)),  // 延迟5分钟执行
        )
    }
    
    return nil
}
```

### 系统空闲检测

```go
// 系统监控器
type SystemMonitor struct {
    cpuUsage    float64
    memoryUsage float64
    diskIO      float64
    networkIO   float64
}

// 判断系统是否空闲
func (bs *BackupScheduler) isSystemIdle() bool {
    monitor := bs.systemMonitor
    
    // 检查系统资源使用率
    return monitor.CPUUsage < bs.idleThreshold &&
           monitor.MemoryUsage < bs.idleThreshold &&
           monitor.DiskIO < bs.idleThreshold &&
           monitor.NetworkIO < bs.idleThreshold
}

// 定时收集系统指标
func (sm *SystemMonitor) CollectMetrics(ctx context.Context) {
    ticker := time.NewTicker(10 * time.Second)
    defer ticker.Stop()
    
    for {
        select {
        case <-ctx.Done():
            return
        case <-ticker.C:
            sm.cpuUsage = getCPUUsage()
            sm.memoryUsage = getMemoryUsage()
            sm.diskIO = getDiskIO()
            sm.networkIO = getNetworkIO()
        }
    }
}
```

### 备份任务处理器

```go
// 备份任务处理器
func BackupUploadHandler(ctx context.Context, task *gq.Task) error {
    var payload BackupTaskPayload
    if err := json.Unmarshal(task.Payload, &payload); err != nil {
        return err
    }
    
    // 1. 查询媒体文件信息
    var media Media
    if err := db.First(&media, "uuid = ?", payload.MediaUUID).Error; err != nil {
        return err
    }
    
    // 2. 从本地存储读取文件
    localStorage := getLocalStorage()
    reader, err := localStorage.Get(ctx, media.LocalPath)
    if err != nil {
        return fmt.Errorf("failed to read from local storage: %w", err)
    }
    defer reader.Close()
    
    // 3. 上传到云存储
    cloudStorage := getCloudStorage()
    cloudPath := adaptPath(media.LocalPath)
    
    if err := cloudStorage.Upload(ctx, cloudPath, reader, media.FileSize, nil); err != nil {
        // 更新状态为 failed
        db.Model(&media).Updates(map[string]interface{}{
            "backup_status": "failed",
            "backup_error":  err.Error(),
        })
        return err
    }
    
    // 4. 更新状态为 completed
    now := time.Now()
    db.Model(&media).Updates(map[string]interface{}{
        "backup_status":      "completed",
        "cloud_path":          cloudPath,
        "backup_completed_at": &now,
    })
    
    return nil
}
```

## 7.4.5 配置设计

```yaml
storage:
  backup:
    enabled: true
    scheduler:
      scan_interval: "5m"        # 扫描间隔：5分钟
      batch_size: 100            # 批量处理大小：100个文件
      idle_threshold: 0.3        # 系统空闲阈值：30%
      max_concurrency: 5         # 最大并发数：5
      delay_execution: "5m"      # 延迟执行：5分钟
    
    # 备份策略
    strategy:
      priority: 1                # 低优先级
      retry_times: 3             # 重试次数
      retry_interval: "10m"      # 重试间隔：10分钟
      max_age: "24h"              # 最大等待时间：24小时
```

## 7.4.6 监控和日志

### 监控指标

```go
// 监控指标
type BackupMetrics struct {
    PendingCount    prometheus.Gauge    // 待备份文件数
    ProcessingCount prometheus.Gauge    // 处理中文件数
    CompletedCount  prometheus.Counter  // 已完成文件数
    FailedCount     prometheus.Counter  // 失败文件数
    UploadDuration  prometheus.Histogram // 上传耗时
    UploadSize      prometheus.Histogram // 上传大小
}
```

### 日志记录

```go
logger.Info("backup scheduler started",
    "scan_interval", bs.scanInterval,
    "batch_size", bs.batchSize,
    "idle_threshold", bs.idleThreshold,
)

logger.Info("backup batch processed",
    "count", len(medias),
    "duration", duration,
)
```

