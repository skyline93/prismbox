# Swagger/OpenAPI 文档设置指南

## 前置要求

**重要**：当前 Swagger 依赖需要 Go 1.24 或更高版本。如果您的 Go 版本低于 1.24，请先升级 Go 版本。

## 安装步骤

### 1. 安装 Swagger 依赖

```bash
go get -u github.com/swaggo/swag/cmd/swag
go get -u github.com/swaggo/gin-swagger
go get -u github.com/swaggo/files
```

### 2. 安装 swag 命令行工具

```bash
go install github.com/swaggo/swag/cmd/swag@latest
```

### 3. 生成 Swagger 文档

在项目根目录执行：

```bash
swag init -g cmd/server/main.go -o ./docs/swagger
```

### 4. 启用 Swagger 路由

编辑 `internal/api/router.go`，取消注释 `setupSwagger()` 调用：

```go
// 4. Swagger 文档
r.setupSwagger()  // 取消注释这一行
```

同时取消注释 `setupSwagger()` 方法中的代码。

### 5. 添加 Swagger 注释

为所有 API 端点添加 Swagger 注释。示例：

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

### 6. 访问 Swagger UI

启动服务器后，访问：
- Swagger UI: http://localhost:8080/swagger/index.html
- OpenAPI JSON: http://localhost:8080/swagger/doc.json

## 需要添加注释的文件

- `cmd/server/main.go` - 主 Swagger 信息（已添加）
- `internal/api/v1/auth/handler.go` - 认证相关接口
- `internal/api/v1/media/handler.go` - 媒体相关接口
- `internal/api/v1/group/handler.go` - 圈子相关接口
- `internal/api/v1/share/handler.go` - 分享相关接口
- `internal/api/v1/storage/handler.go` - 存储相关接口
- 所有 DTO 结构体文件

## 参考文档

- Swaggo 文档：https://github.com/swaggo/swag
- Swagger 规范：https://swagger.io/specification/

