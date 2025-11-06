# TODO 功能清单

## ✅ 已完成功能

### 核心功能
- ✅ 媒体文件上传到本地存储（流式处理，不读入内存）
- ✅ 数据库记录创建（Media模型）
- ✅ Hash去重机制（秒传功能，相同文件只存储一份）
- ✅ 任务队列入队（媒体处理任务）
- ✅ 任务队列处理器注册（空跑）
- ✅ 存储路径解析（Hash-based路径）
- ✅ 应用依赖注入（App Builder）
- ✅ 服务器启动入口
- ✅ 配置文件加载

### 接口优化
- ✅ 接口参数与旧架构完全一致（hash、item_type、cloud_uuid、original_filename、media_taken_at）
- ✅ cloud_uuid作为必传字段（不再生成）
- ✅ Hash由客户端传入，服务端不计算
- ✅ 流式处理，不读入内存
- ✅ 秒传检查优化（使用客户端Hash）
- ✅ 秒传时返回200，新上传返回201

### 代码结构
- ✅ 数据库模型（Media）
- ✅ Repository层（MediaRepository）
- ✅ Service层（MediaService）
- ✅ API Handler层（MediaHandler）
- ✅ 路由注册
- ✅ 统一响应格式
- ✅ 日志集成

## 📝 待实现功能（已标注TODO）

### 1. 用户认证 ⚠️ 重要
**位置**: 
- `internal/api/v1/media/handler.go:29` - 获取userID
- `internal/api/v1/media/routes.go:13` - 添加认证中间件

**说明**: 
- 目前使用默认userID=1
- 需要实现JWT认证中间件
- 需要从JWT token中提取userID

**相关文件**:
- `internal/api/middleware/auth.go` - 需要创建认证中间件

### 2. 媒体处理逻辑 ⚠️ 重要
**位置**: 
- `internal/worker/media/handler.go:30-40` - 图片处理
- `internal/worker/media/handler.go:50-60` - 视频处理
- `internal/service/media/service.go:103` - 任务类型选择

**说明**: 
- 任务处理器已注册并空跑
- 需要实现实际的图片/视频处理逻辑：
  - 生成缩略图（400x400）
  - 生成预览图（1280px宽度）
  - 提取EXIF元数据
  - 更新数据库记录

**相关文件**:
- `pkg/media-processor` - 需要实现媒体处理模块（参考架构文档7.6）

### 3. 文件类型自动检测
**位置**: 
- `internal/service/media/service.go:125` - MimeType

**说明**: 
- ItemType已由客户端传入，不需要检测
- MimeType需要根据文件内容自动检测（目前为空字符串）

### 4. 其他API接口
**位置**: 
- `internal/api/v1/media/handler.go:94` - GetMedia
- `internal/api/v1/media/handler.go:100` - GetMedias
- `internal/api/v1/media/handler.go:106` - DeleteMedia

**说明**: 
- 接口已定义，但未实现
- 需要实现获取、列表、删除等功能

### 5. 中间件
**位置**: 
- `internal/api/router.go:30-35` - 全局中间件

**说明**: 
- 需要添加日志中间件（使用pkg/logger）
- 需要添加恢复中间件
- 需要添加CORS中间件

**相关文件**:
- `internal/api/middleware/logger.go` - 需要创建
- `internal/api/middleware/recovery.go` - 需要创建
- `internal/api/middleware/cors.go` - 需要创建

### 6. 数据库连接
**位置**: 
- `internal/database/connection.go:17` - PostgreSQL
- `internal/database/connection.go:20` - MySQL

**说明**: 
- 目前只支持SQLite
- 需要实现PostgreSQL和MySQL连接

### 7. 存储功能
**位置**: 
- `internal/storage/primary/local/storage.go:359` - ContentType推断
- `internal/storage/primary/local/processor/pipeline.go` - 压缩/加密/元数据提取

**说明**: 
- 需要根据文件扩展名推断ContentType
- 需要实现压缩、加密、元数据提取等处理逻辑

### 8. 次存储（云存储备份）
**位置**: 
- `internal/storage/factory.go:32-45` - 次存储实现

**说明**: 
- 次存储接口已定义，但未实现
- 需要实现OpenList、S3、OSS、COS等云存储对接

## 🎯 优先级建议

### 高优先级（核心功能）
1. **用户认证** - 必须实现，否则无法区分用户
2. **媒体处理逻辑** - 核心功能，生成缩略图和预览图
3. **文件类型自动检测** - 基础功能，需要准确识别文件类型

### 中优先级（完善功能）
4. **其他API接口** - 完善CRUD功能
5. **中间件** - 完善日志、错误处理、CORS支持

### 低优先级（扩展功能）
6. **数据库连接** - 支持更多数据库类型
7. **存储处理** - 压缩、加密等高级功能
8. **次存储** - 云存储备份功能

## 📋 实现建议

### 1. 用户认证实现步骤
1. 创建 `internal/api/middleware/auth.go`
2. 实现JWT验证逻辑
3. 从token中提取userID并注入到context
4. 在 `routes.go` 中添加认证中间件
5. 在 `handler.go` 中从context获取userID

### 2. 媒体处理实现步骤
1. 创建 `pkg/media-processor` 包
2. 实现图片处理逻辑（ImageMagick）
3. 实现视频处理逻辑（FFmpeg）
4. 在 `worker/media/handler.go` 中调用处理逻辑
5. 更新数据库记录（处理状态、元数据等）

### 3. 文件类型检测实现步骤
1. 使用 `mime` 包检测MIME类型
2. 根据MIME类型判断是图片还是视频
3. 更新 `ItemType` 和 `MimeType` 字段

## 🔍 代码检查清单

- [x] 所有TODO都已标注
- [x] 编译通过
- [x] 基础功能可以运行
- [x] 日志记录正常
- [x] 错误处理完善
- [ ] 单元测试（待添加）
- [ ] 集成测试（待添加）

