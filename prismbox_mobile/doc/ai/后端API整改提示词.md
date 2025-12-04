# PrismBox 后端 API 整改 AI 提示词

## 背景

PrismBox 移动端需要对接后端 API，但当前后端实现缺少一些关键功能。需要按照以下要求进行整改，确保与移动端 API 对接模块的设计文档完全兼容。

## 整改目标

1. 支持移动端要求的认证头格式
2. 实现端点自动发现机制
3. 实现服务器健康检查接口
4. 生成 OpenAPI 规范文档
5. 支持设备信息头

---

## 任务 1：认证头格式支持

### 需求描述

移动端 API 对接模块要求使用 `x-prismbox-user-token` 请求头进行认证，但当前后端只支持标准的 `Authorization: Bearer {token}` 格式。需要同时支持两种格式，保持向后兼容。

### 实现要求

1. **修改认证中间件** (`internal/api/middleware/auth.go`)
   - 修改 `AuthMiddleware` 函数，优先检查 `x-prismbox-user-token` 头
   - 如果 `x-prismbox-user-token` 不存在，回退到 `Authorization: Bearer {token}` 格式
   - 保持现有的错误处理逻辑

2. **实现逻辑**
   ```go
   // 优先级顺序：
   // 1. 检查 x-prismbox-user-token 头
   // 2. 检查 Authorization: Bearer {token} 头
   // 3. 如果都不存在，返回 401 错误
   ```

3. **测试要求**
   - 使用 `x-prismbox-user-token` 头可以正常认证
   - 使用 `Authorization: Bearer` 头仍然可以正常认证（向后兼容）
   - 两种格式都返回相同的认证结果

### 代码位置

- 文件：`internal/api/middleware/auth.go`
- 函数：`AuthMiddleware`
- 同时更新 `FlexibleAuthMiddleware` 函数

---

## 任务 2：端点发现机制

### 需求描述

移动端需要实现端点自动发现功能，通过访问 `/.well-known/prismbox` 端点获取 API 端点信息。

### 实现要求

1. **添加 well-known 端点** (`internal/api/router.go`)
   - 在根路由添加 `GET /.well-known/prismbox` 端点
   - 该端点不需要认证，公开访问
   - 返回 JSON 格式的端点信息

2. **响应格式**
   ```json
   {
     "api": {
       "endpoint": "/api/v1"
     }
   }
   ```

3. **实现位置**
   - 在 `Router.Setup()` 方法中，在 `setupAPIV1()` 之前添加
   - 使用 `r.engine.GET("/.well-known/prismbox", ...)` 注册路由

4. **注意事项**
   - 端点路径必须是 `/.well-known/prismbox`（注意大小写）
   - 不需要认证，允许跨域访问
   - 响应 Content-Type 为 `application/json`

### 代码位置

- 文件：`internal/api/router.go`
- 方法：在 `Setup()` 方法中添加新的路由注册

---

## 任务 3：服务器健康检查接口

### 需求描述

移动端需要 `pingServer()` 接口来验证服务器端点是否可用。当前后端只有 `/api/v1/version` 接口，需要添加专门的健康检查接口。

### 实现要求

1. **添加 ping 接口** (`internal/api/router.go`)
   - 在 `/api/v1` 路由组下添加 `GET /api/v1/server/ping` 端点
   - 该端点不需要认证，公开访问
   - 返回简单的成功响应

2. **响应格式**
   ```json
   {
     "status": "ok",
     "timestamp": 1234567890
   }
   ```

3. **实现位置**
   - 在 `setupAPIV1()` 方法中，在 `v1.GET("/version", ...)` 附近添加
   - 可以创建一个新的方法 `getPing`，类似 `getVersion`

4. **可选增强**
   - 可以检查数据库连接状态
   - 可以检查关键服务状态
   - 返回更详细的健康信息

### 代码位置

- 文件：`internal/api/router.go`
- 方法：在 `setupAPIV1()` 方法中添加新路由
- 新增方法：`getPing(c *gin.Context)`

---

## 任务 4：OpenAPI/Swagger 文档生成

### 需求描述

移动端需要使用 OpenAPI 规范自动生成 API 客户端代码。当前后端没有 Swagger 文档，需要添加完整的 Swagger 支持。

### 实现要求

1. **安装依赖**
   ```bash
   go get -u github.com/swaggo/swag/cmd/swag
   go get -u github.com/swaggo/gin-swagger
   go get -u github.com/swaggo/files
   ```

2. **添加 Swagger 路由** (`internal/api/router.go`)
   - 在 `Setup()` 方法中添加 `setupSwagger()` 调用
   - 注册 `GET /swagger/*any` 路由
   - 使用 `ginSwagger.WrapHandler(swaggerFiles.Handler)`

3. **为所有 API 添加 Swagger 注释**
   - 在 `cmd/server/main.go` 添加主 Swagger 信息注释
   - 为每个 Handler 方法添加 Swagger 注释
   - 为所有 DTO 结构体添加 Swagger 模型注释

4. **Swagger 主信息注释示例** (`cmd/server/main.go`)
   ```go
   // @title           PrismBox Backend API
   // @version         1.0
   // @description     PrismBox 后端服务 API 文档
   // @termsOfService  https://prismbox.example.com/terms
   
   // @contact.name   API Support
   // @contact.url    https://prismbox.example.com/support
   // @contact.email  support@prismbox.example.com
   
   // @license.name  MIT
   // @license.url   https://opensource.org/licenses/MIT
   
   // @host      localhost:8080
   // @BasePath  /api/v1
   
   // @securityDefinitions.apikey BearerAuth
   // @in header
   // @name Authorization
   // @description 使用 "Bearer {token}" 格式，或使用 "x-prismbox-user-token: {token}" 格式
   ```

5. **Handler 注释示例** (`internal/api/v1/auth/handler.go`)
   ```go
   // Login 用户登录
   // @Summary      用户登录
   // @Description  使用邮箱和密码登录，返回访问令牌和刷新令牌
   // @Tags         Auth
   // @Accept       json
   // @Produce      json
   // @Param        input body LoginInput true "登录信息"
   // @Success      200 {object} response.ApiResponse{data=loginSuccessData} "登录成功"
   // @Failure      400 {object} response.ApiResponse "请求参数错误"
   // @Failure      401 {object} response.ApiResponse "认证失败"
   // @Router       /auth/login [post]
   func (h *Handler) Login(c *gin.Context) {
       // ...
   }
   ```

6. **生成文档命令**
   ```bash
   # 在项目根目录执行
   swag init -g cmd/server/main.go -o ./docs/swagger
   ```

7. **需要添加注释的文件**
   - `cmd/server/main.go` - 主 Swagger 信息
   - `internal/api/v1/auth/handler.go` - 认证相关接口
   - `internal/api/v1/media/handler.go` - 媒体相关接口
   - `internal/api/v1/group/handler.go` - 圈子相关接口
   - `internal/api/v1/share/handler.go` - 分享相关接口
   - `internal/api/v1/storage/handler.go` - 存储相关接口
   - 所有 DTO 结构体文件

8. **生成 OpenAPI JSON**
   - 确保生成的文档包含完整的 OpenAPI 3.0 规范
   - 输出文件：`docs/swagger/swagger.json` 或 `docs/swagger/openapi.json`

### 代码位置

- 文件：`internal/api/router.go` - 添加 Swagger 路由
- 文件：`cmd/server/main.go` - 添加主 Swagger 信息
- 文件：所有 Handler 文件 - 添加接口注释
- 文件：所有 DTO 文件 - 添加模型注释

---

## 任务 5：设备信息头支持

### 需求描述

移动端可能会发送 `deviceModel` 和 `deviceType` 请求头，用于服务器端记录和统计。当前后端不需要使用这些信息，但可以记录到日志中。

### 实现要求

1. **可选实现**
   - 在认证中间件或日志中间件中记录设备信息
   - 不需要验证这些头的格式
   - 仅用于日志记录，不影响业务逻辑

2. **实现位置**
   - 可以在 `internal/api/middleware/auth.go` 中记录
   - 或者在日志中间件中记录

3. **日志格式**
   ```go
   // 记录设备信息到日志
   log.Info("Request from device",
       logger.String("deviceModel", c.GetHeader("deviceModel")),
       logger.String("deviceType", c.GetHeader("deviceType")),
   )
   ```

### 代码位置

- 文件：`internal/api/middleware/auth.go` 或日志中间件
- 优先级：低

---

## 实施顺序建议

1. **第一阶段（必须）**
   - 任务 1：认证头格式支持
   - 任务 2：端点发现机制
   - 任务 3：服务器健康检查接口

2. **第二阶段（重要）**
   - 任务 4：OpenAPI/Swagger 文档生成

3. **第三阶段（可选）**
   - 任务 5：设备信息头支持

---

## 测试要求

### 任务 1 测试
```bash
# 测试 x-prismbox-user-token 头
curl -H "x-prismbox-user-token: YOUR_TOKEN" http://localhost:8080/api/v1/auth/profile

# 测试 Authorization Bearer 头（向后兼容）
curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:8080/api/v1/auth/profile
```

### 任务 2 测试
```bash
# 测试 well-known 端点
curl http://localhost:8080/.well-known/prismbox
# 期望返回：{"api":{"endpoint":"/api/v1"}}
```

### 任务 3 测试
```bash
# 测试 ping 接口
curl http://localhost:8080/api/v1/server/ping
# 期望返回：{"status":"ok","timestamp":1234567890}
```

### 任务 4 测试
```bash
# 访问 Swagger UI
curl http://localhost:8080/swagger/index.html

# 获取 OpenAPI JSON
curl http://localhost:8080/swagger/doc.json
```

---

## 注意事项

1. **向后兼容性**
   - 所有改动必须保持向后兼容
   - 现有的 `Authorization: Bearer` 格式必须继续工作

2. **错误处理**
   - 保持现有的错误响应格式
   - 使用 `response.ApiResponse` 统一响应格式

3. **代码风格**
   - 遵循项目现有的代码风格
   - 使用项目现有的日志系统（`pkg/logger`）

4. **文档更新**
   - 更新 API 架构文档（`doc/ARCHITECTURE/07-core-modules/07-api-architecture.md`）
   - 记录新增的端点和功能

---

## 验收标准

- [ ] 支持 `x-prismbox-user-token` 认证头
- [ ] 保持 `Authorization: Bearer` 向后兼容
- [ ] `/.well-known/prismbox` 端点正常返回
- [ ] `/api/v1/server/ping` 端点正常返回
- [ ] Swagger UI 可以正常访问
- [ ] OpenAPI JSON 可以正常生成和访问
- [ ] 所有现有测试通过
- [ ] 代码符合项目规范

---

## 参考文档

- PrismBox 移动端 API 对接模块详细设计文档：`doc/modules/API对接模块详细设计文档.md`
- PrismBox 移动端架构设计文档：`doc/PrismBox 移动端架构设计文档.md`
- Gin 框架文档：https://gin-gonic.com/docs/
- Swagger/OpenAPI 规范：https://swagger.io/specification/
- Swaggo 文档：https://github.com/swaggo/swag

---

**文档版本**：v1.0  
**创建日期**：2024年  
**维护者**：PrismBox 开发团队

