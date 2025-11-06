# 媒体上传功能实现总结

## ✅ 已完成功能

### 核心功能
1. **媒体文件上传到本地存储**（流式处理，不读入内存）
2. **数据库记录创建**（Media模型）
3. **Hash去重机制**（秒传功能，相同文件只存储一份）
4. **任务队列入队**（媒体处理任务，目前空跑）
5. **存储路径解析**（Hash-based路径）
6. **应用依赖注入**（App Builder）
7. **服务器启动入口**

### 接口优化
1. **接口参数与旧架构完全一致**
   - `file` (formData file, 必填) - 媒体文件本身
   - `hash` (formData string, 必填) - 文件的SHA256哈希值（64个字符，客户端计算）
   - `item_type` (formData string, 必填) - 媒体类型：`image` 或 `video`
   - `cloud_uuid` (formData string, 必填) - 客户端预生成的UUID
   - `original_filename` (formData string, 可选) - 文件的原始名称
   - `media_taken_at` (formData string, 可选) - 媒体拍摄时间（ISO 8601格式）

2. **cloud_uuid作为必传字段**（不再生成）

3. **Hash由客户端传入**，服务端不计算，实现流式处理

4. **秒传优化**
   - Handler层先进行秒传检查，如果是秒传，不需要打开文件流
   - Service层提供 `CheckInstantUpload` 方法用于秒传检查
   - 秒传时返回200状态码，新上传返回201状态码

5. **流式处理**
   - 直接使用 `io.Reader` 流式写入存储，不读入内存
   - 支持大文件上传，内存占用恒定
   - 秒传时不需要打开文件流，进一步优化性能

## 🎯 核心优化点

### 1. 流式处理（避免内存问题）
- ✅ 使用客户端传入的Hash，不需要在服务端计算
- ✅ 直接使用 `io.Reader` 流式写入存储，不读入内存
- ✅ 支持大文件上传，内存占用恒定

### 2. 秒传优化（性能提升）
- ✅ Handler层先进行秒传检查，如果是秒传，不需要打开文件流
- ✅ 使用客户端Hash在数据库中进行秒传检查
- ✅ 如果文件已存在，直接返回现有记录，不进行文件上传
- ✅ 秒传时返回200状态码，新上传返回201状态码

### 3. 接口一致性（向后兼容）
- ✅ 接口参数与旧架构完全一致
- ✅ 响应格式与旧架构完全一致
- ✅ 路由地址与旧架构完全一致

### 4. 代码优化（更清晰合理）
- ✅ Handler层负责参数验证和秒传检查
- ✅ Service层负责业务逻辑和文件上传
- ✅ 职责分离清晰，代码更易维护
- ✅ 错误处理更完善

## 📋 代码结构

### Handler层 (`internal/api/v1/media/handler.go`)
- 接收所有表单参数（与旧架构一致）
- 参数验证（hash、cloud_uuid、item_type等）
- 秒传检查（在打开文件流之前）
- 调用Service层上传媒体
- 响应格式化（秒传200，新上传201）

### Service层 (`internal/service/media/service.go`)
- `CheckInstantUpload`: 秒传检查方法
- `UploadMedia`: 上传媒体方法（流式处理）
- 使用客户端传入的Hash构建存储路径
- 流式写入存储，不读入内存
- 创建数据库记录
- 入队处理任务

### Repository层 (`internal/repository/media.go`)
- `FindByHash`: 根据Hash查找媒体（用于秒传检查）
- `Create`: 创建媒体记录
- 其他CRUD方法

## 🔍 关键实现细节

### 1. 流式处理实现
```go
// Service层直接使用io.Reader，不读入内存
if err := s.storageManager.Put(ctx, storageKey, req.Data, req.FileSize, putOpts); err != nil {
    return nil, fmt.Errorf("upload to storage: %w", err)
}
```

### 2. 秒传检查优化
```go
// Handler层先进行秒传检查，如果是秒传，不需要打开文件流
existingMedia, err := h.mediaService.CheckInstantUpload(c.Request.Context(), userID, hash)
if existingMedia != nil {
    // 直接返回，不需要打开文件流
    return
}
```

### 3. Hash验证
```go
// Handler层验证Hash格式（SHA256应该是64个字符）
if len(hash) != 64 {
    apiresponse.Error(c, "Invalid 'hash' format...")
    return
}
```

### 4. 存储路径构建
```go
// 使用客户端传入的Hash构建存储路径
hashPrefix := req.Hash[:2]
hashNext := req.Hash[2:4]
storageKey := fmt.Sprintf("%s/%s/%s%s", hashPrefix, hashNext, req.CloudUUID, ext)
```

## 📝 待实现功能（已标注TODO）

### 1. 用户认证 ⚠️ 重要
- **位置**: `internal/api/v1/media/handler.go:29`
- **说明**: 目前使用默认userID=1，需要实现JWT认证中间件

### 2. 媒体处理逻辑 ⚠️ 重要
- **位置**: `internal/worker/media/handler.go`
- **说明**: 任务处理器已注册并空跑，需要实现实际的图片/视频处理逻辑

### 3. 文件类型自动检测
- **位置**: `internal/service/media/service.go:125`
- **说明**: MimeType需要根据文件内容自动检测（目前为空字符串）

### 4. 其他API接口
- **位置**: `internal/api/v1/media/handler.go`
- **说明**: GetMedia、GetMedias、DeleteMedia等接口需要实现

## 🚀 使用示例

### 启动服务器
```bash
cd backend
go run cmd/server/main.go
```

### 上传文件
```bash
# 计算文件的SHA256哈希值
HASH=$(sha256sum /path/to/your/image.jpg | cut -d' ' -f1)
UUID=$(uuidgen)

curl -X POST http://localhost:8080/api/v1/media/upload-stream \
  -F "file=@/path/to/your/image.jpg" \
  -F "hash=$HASH" \
  -F "item_type=image" \
  -F "cloud_uuid=$UUID" \
  -F "original_filename=image.jpg"
```

## ✨ 优化亮点

1. **性能优化**：流式处理 + 秒传检查优化，避免不必要的文件流打开
2. **内存优化**：不读入内存，支持大文件上传
3. **代码优化**：职责分离清晰，错误处理完善
4. **接口一致性**：与旧架构完全一致，确保向后兼容

## 📊 对比旧架构

### 改进点
- ✅ 流式处理（旧架构也是流式，但新架构更清晰）
- ✅ 秒传检查优化（在打开文件流之前检查）
- ✅ 代码结构更清晰（Handler层和Service层职责分离）
- ✅ 错误处理更完善（使用结构化日志）

### 保持一致
- ✅ 接口参数完全一致
- ✅ 响应格式完全一致
- ✅ 路由地址完全一致
- ✅ 业务逻辑完全一致

