# 7.5 媒体处理流程

> **注意**：本文档描述了媒体处理的任务流程和集成方式。详细的架构设计、接口定义、并发安全设计等内容请参考 [7.6 媒体处理模块架构设计](./07-media-processor.md)。

## 7.5.1 任务队列集成

### 任务类型

- **media:process:image**：图片处理（生成缩略图、预览图）
- **media:process:video**：视频处理（生成缩略图、预览视频）
- **storage:backup:upload**：备份上传任务（由备份调度器创建）

### 任务处理流程

```
用户上传媒体 → 保存到本地存储 → 创建数据库记录（backup_status = "pending"） → 
入队处理任务 → Worker 处理（生成缩略图/预览） → 
更新数据库状态 → 返回给用户（立即返回）
```

**注意**：云存储备份由独立的备份调度器处理，不在用户上传流程中。

### 任务处理器注册

```go
// internal/worker/handler.go
func RegisterMediaProcessors(mux *gq.ServeMux, app *app.App) {
    mux.HandleFunc("media:process:image", processImageHandler(app))
    mux.HandleFunc("media:process:video", processVideoHandler(app))
}

func RegisterBackupProcessors(mux *gq.ServeMux, app *app.App) {
    mux.HandleFunc("storage:backup:upload", backupUploadHandler(app))
}
```

## 7.5.2 图片处理流程

### 处理步骤

1. 读取原始图片
2. 提取 EXIF 元数据
3. 生成缩略图（400x400）
4. 生成预览图（1280px 宽度）
5. 更新数据库记录

### 实现示例

```go
func processImageHandler(app *app.App) gq.HandlerFunc {
    return func(ctx context.Context, task *gq.Task) error {
        var payload ImageProcessPayload
        if err := json.Unmarshal(task.Payload, &payload); err != nil {
            return err
        }
        
        // 1. 查询媒体文件
        media, err := app.MediaRepo.FindByUUID(payload.MediaUUID)
        if err != nil {
            return err
        }
        
        // 2. 从本地存储读取原始图片
        reader, err := app.StorageManager.Get(ctx, media.LocalPath)
        if err != nil {
            return err
        }
        defer reader.Close()
        
        // 3. 处理图片（使用 media-processor 包）
        result, err := app.MediaProcessor.ProcessImage(ctx, media.LocalPath, nil)
        if err != nil {
            return err
        }
        
        // 4. 保存生成的缩略图和预览图路径
        // ... 保存 result.GeneratedFiles
        
        // 5. 更新数据库状态和元数据
        updates := map[string]interface{}{
            "processing_status": "completed",
        }
        if result.Metadata != nil {
            // 更新元数据字段
            // ...
        }
        return app.MediaRepo.Update(media.UUID, updates)
    }
}
```

## 7.5.3 视频处理流程

### 处理步骤

1. 读取原始视频
2. 提取元数据
3. 生成缩略图（从第 1 秒提取帧）
4. 生成预览视频（1280px 宽度）
5. 更新数据库记录

### 实现示例

```go
func processVideoHandler(app *app.App) gq.HandlerFunc {
    return func(ctx context.Context, task *gq.Task) error {
        var payload VideoProcessPayload
        if err := json.Unmarshal(task.Payload, &payload); err != nil {
            return err
        }
        
        // 1. 查询媒体文件
        media, err := app.MediaRepo.FindByUUID(payload.MediaUUID)
        if err != nil {
            return err
        }
        
        // 2. 从本地存储读取原始视频
        reader, err := app.StorageManager.Get(ctx, media.LocalPath)
        if err != nil {
            return err
        }
        defer reader.Close()
        
        // 3. 处理视频（使用 media-processor 包）
        result, err := app.MediaProcessor.ProcessVideo(ctx, media.LocalPath, nil)
        if err != nil {
            return err
        }
        
        // 4. 保存生成的缩略图和预览视频路径
        // ... 保存 result.GeneratedFiles
        
        // 5. 更新数据库状态和元数据
        updates := map[string]interface{}{
            "processing_status": "completed",
        }
        if result.Metadata != nil {
            // 更新元数据字段
            // ...
        }
        return app.MediaRepo.Update(media.UUID, updates)
    }
}
```

## 7.5.4 处理流程总结

### 用户上传流程

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
返回给用户（立即返回，不等待处理）
```

### 媒体处理流程

```
Task Queue (取出处理任务)
    ↓
Worker (异步处理：生成缩略图/预览)
    ↓
Repository (更新处理状态)
```

### 备份流程

```
备份调度器（定时扫描）
    ↓
查询待备份文件（backup_status = "pending"）
    ↓
创建备份任务（低优先级）
    ↓
Task Queue (Queue: backup, Priority: 1)
    ↓
Worker (处理备份任务)
    ↓
从本地存储读取文件
    ↓
上传到云存储
    ↓
更新数据库（backup_status = "completed"）
```

## 7.5.5 相关文档

- [7.6 媒体处理模块架构设计](./07-media-processor.md) - 详细的架构设计、接口定义、并发安全设计等

