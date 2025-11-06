# 媒体上传功能使用说明

## 功能概述

已实现用户上传媒体到本地存储的基础功能，包括：

- ✅ 媒体文件上传到本地存储（流式处理，不读入内存）
- ✅ 数据库记录创建
- ✅ 任务队列入队（媒体处理任务，目前空跑）
- ✅ Hash去重（秒传功能，相同文件只存储一份）
- ✅ 接口参数与旧架构完全一致
- ✅ 使用客户端传入的Hash，实现流式处理

## 待实现功能（已标注TODO）

### 1. 用户认证
- **位置**: `internal/api/v1/media/handler.go:29`
- **说明**: 目前使用默认userID=1，需要实现JWT认证中间件
- **相关文件**: 
  - `internal/api/v1/media/routes.go` - 需要添加认证中间件
  - `internal/api/middleware/auth.go` - 需要创建认证中间件

### 2. 媒体处理（生成缩略图和预览图）
- **位置**: `internal/worker/media/handler.go`
- **说明**: 任务处理器已注册并空跑，需要实现实际的图片/视频处理逻辑
- **相关文件**:
  - `internal/worker/media/handler.go` - 需要实现 `processImageHandler` 和 `processVideoHandler`
  - `pkg/media-processor` - 需要实现媒体处理模块（参考架构文档7.6）

### 3. 文件类型自动检测
- **位置**: `internal/service/media/service.go:95-96`
- **说明**: 目前硬编码为"image"和"image/jpeg"，需要根据文件内容自动检测

### 4. 其他API接口
- **位置**: `internal/api/v1/media/handler.go`
- **说明**: GetMedia、GetMedias、DeleteMedia 等接口需要实现

## 快速开始

### 1. 配置

确保 `configs/config.yaml` 文件存在，或使用默认配置：

```yaml
server:
  host: "0.0.0.0"
  port: 8080

database:
  type: "sqlite"
  dsn: "data.db"

storage:
  primary:
    type: "local"
    local:
      base_path: "./uploads"
      pools:
        - id: "pool-1"
          path: "./uploads"
          max_size: "1TB"
          priority: 1
          enabled: true
          auto_disable_threshold: 0.9

logger:
  level: "info"
  format: "json"
  output: "stdout"
```

### 2. 启动服务器

```bash
cd backend
go run cmd/server/main.go
```

或者指定配置文件：

```bash
go run cmd/server/main.go configs/config.yaml
```

### 3. 上传媒体文件

**接口参数（与旧架构一致）**：
- `file` (formData file, 必填) - 媒体文件本身
- `hash` (formData string, 必填) - 文件的SHA256哈希值（64个字符的十六进制字符串，客户端计算）
- `item_type` (formData string, 必填) - 媒体类型：`image` 或 `video`
- `cloud_uuid` (formData string, 必填) - 客户端预生成的UUID
- `original_filename` (formData string, 可选) - 文件的原始名称
- `media_taken_at` (formData string, 可选) - 媒体拍摄时间（ISO 8601格式）

**使用curl上传文件**：

```bash
# 先计算文件的SHA256哈希值
HASH=$(sha256sum /path/to/your/image.jpg | cut -d' ' -f1)
UUID=$(uuidgen)

curl -X POST http://localhost:8080/api/v1/media/upload-stream \
  -F "file=@/path/to/your/image.jpg" \
  -F "hash=$HASH" \
  -F "item_type=image" \
  -F "cloud_uuid=$UUID" \
  -F "original_filename=image.jpg"
```

**使用Postman或其他工具**：
- **URL**: `POST http://localhost:8080/api/v1/media/upload-stream`
- **Body**: form-data
- **Key-Value对**:
  - `file`: 选择要上传的文件（类型: File）
  - `hash`: 文件的SHA256哈希值（64个字符的十六进制字符串）
  - `item_type`: `image` 或 `video`
  - `cloud_uuid`: 客户端预生成的UUID
  - `original_filename`: 文件的原始名称（可选）
  - `media_taken_at`: 媒体拍摄时间，ISO 8601格式（可选）

### 4. 响应示例

**新上传成功（201 Created）**：

```json
{
  "code": 0,
  "message": "Media uploaded successfully",
  "data": {
    "uuid": "abc-123-def-456",
    "user_id": 1,
    "hash": "abcd1234efgh5678ijkl9012mnop3456qrst7890uvwx1234yzab5678cdef",
    "item_type": "image",
    "original_filename": "image.jpg",
    "filename": "image.jpg",
    "file_size": 1024000,
    "mime_type": "",
    "processing_status": "PENDING",
    "local_path": "ab/cd/abc-123-def-456.jpg",
    "backup_status": "pending",
    "created_at": "2025-01-20T10:00:00Z"
  }
}
```

**秒传成功（200 OK）**：

```json
{
  "code": 0,
  "message": "File already exists for this user",
  "data": {
    "uuid": "existing-uuid-123",
    "user_id": 1,
    "hash": "abcd1234efgh5678ijkl9012mnop3456qrst7890uvwx1234yzab5678cdef",
    "item_type": "image",
    "original_filename": "image.jpg",
    "filename": "image.jpg",
    "file_size": 1024000,
    "mime_type": "",
    "processing_status": "COMPLETED",
    "local_path": "ab/cd/existing-uuid-123.jpg",
    "backup_status": "completed",
    "created_at": "2025-01-19T10:00:00Z"
  }
}
```

## 目录结构

上传的文件会按照Hash-based路径存储：

```
uploads/
├── files/                    # 文件存储根目录
│   ├── {hash[0:2]}/         # Hash前2位（00-ff）
│   │   ├── {hash[2:4]}/     # Hash 3-4位（00-ff）
│   │   │   ├── {uuid}.jpg   # 原始文件
```

例如：
- Hash: `abcd1234...`
- UUID: `abc-123-def-456`
- 存储路径: `uploads/files/ab/cd/abc-123-def-456.jpg`

## 任务队列

上传成功后，会自动入队媒体处理任务：

- **任务类型**: `media:process:image` 或 `media:process:video`
- **队列**: `default`
- **优先级**: 5
- **状态**: 目前空跑，直接返回成功

任务处理器在后台运行，可以通过日志查看任务执行情况。

## 数据库

使用SQLite数据库（默认文件：`data.db`），包含以下表：

- `medias` - 媒体文件记录
- `gq_tasks` - 任务队列表（由GQ框架自动创建）

## 日志

日志输出到stdout（JSON格式），包含：

- 上传请求日志
- 任务处理日志
- 错误日志

示例日志：

```json
{
  "time": "2025-01-20T10:00:00.123Z",
  "level": "info",
  "module": "api.v1.media",
  "msg": "media uploaded successfully",
  "uuid": "abc-123-def-456",
  "filename": "image.jpg",
  "user_id": 1
}
```

## 注意事项

1. **用户认证**: 目前所有请求使用默认userID=1，生产环境需要实现JWT认证
2. **文件大小**: 没有限制，建议在配置中添加最大文件大小限制
3. **并发处理**: 任务队列支持并发处理，默认并发数为5
4. **存储空间**: 确保存储路径有足够的空间
5. **去重机制**: 相同Hash的文件只存储一份，但会为每个用户创建独立的数据库记录
6. **流式处理**: 文件上传采用流式处理，不会将整个文件读入内存，支持大文件上传
7. **Hash验证**: Hash必须是64个字符的十六进制字符串（SHA256格式）
8. **必填参数**: `hash`、`item_type`、`cloud_uuid` 是必填参数，缺少任何一个都会返回错误

## 核心优化点

### 1. 流式处理
- ✅ 使用客户端传入的Hash，不需要在服务端计算
- ✅ 直接使用 `io.Reader` 流式写入存储，不读入内存
- ✅ 支持大文件上传，内存占用恒定

### 2. 秒传优化
- ✅ 使用客户端Hash在数据库中进行秒传检查
- ✅ 如果文件已存在，直接返回现有记录，不进行文件上传
- ✅ 秒传时返回200状态码，新上传返回201状态码

### 3. 接口一致性
- ✅ 接口参数与旧架构完全一致
- ✅ 响应格式与旧架构完全一致
- ✅ 路由地址与旧架构完全一致

## 下一步开发

1. 实现JWT认证中间件
2. 实现媒体处理逻辑（生成缩略图和预览图）
3. 实现文件类型自动检测（MIME类型）
4. 实现其他API接口（获取、列表、删除等）
5. 添加文件大小限制
6. 添加文件类型验证

