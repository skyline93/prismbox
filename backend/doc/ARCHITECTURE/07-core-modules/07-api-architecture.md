# 7.8 API 模块架构设计

## 7.8.1 概述

API 模块是 Album Backend 的对外接口层，负责处理所有客户端请求。该模块采用多协议支持设计，支持 HTTP/HTTPS 和 Unix Socket，并预留了 WebSocket 和 WebDAV 的扩展接口。所有 API 路由和响应格式与旧架构保持一致，确保客户端无需修改。

## 7.8.2 设计原则

### 核心设计理念

1. **向后兼容**：路由地址和请求响应结构与旧架构完全一致，不影响客户端
2. **多协议支持**：支持 HTTP/HTTPS 和 Unix Socket，方便本地访问和远程访问
3. **统一响应格式**：使用统一的 `ApiResponse` 结构，与旧架构一致
4. **模块化路由**：按功能模块组织路由，便于维护和扩展
5. **中间件链**：认证、日志、CORS 等通过中间件实现，职责清晰
6. **配置驱动**：通过配置管理模块统一管理服务器配置
7. **日志集成**：使用 `pkg/logger` 统一日志记录，支持链路追踪

## 7.8.3 目录结构

```
internal/api/
├── router.go                  # 路由注册器（统一入口）
├── response.go                # 统一响应格式（与旧架构一致）
├── dto/                       # 数据传输对象（请求/响应结构）
│   ├── media.go               # 媒体相关 DTO
│   ├── album.go               # 相册相关 DTO
│   ├── auth.go                # 认证相关 DTO
│   ├── group.go               # 圈子相关 DTO
│   └── share.go               # 分享相关 DTO
│
├── v1/                        # API v1 版本
│   ├── auth/                  # 认证相关 handlers
│   │   ├── handler.go         # 认证处理器
│   │   └── routes.go          # 认证路由注册
│   │
│   ├── media/                 # 媒体相关 handlers
│   │   ├── handler.go         # 媒体处理器
│   │   └── routes.go          # 媒体路由注册
│   │
│   ├── album/                 # 相册相关 handlers
│   │   ├── handler.go
│   │   └── routes.go
│   │
│   ├── group/                 # 圈子相关 handlers
│   │   ├── handler.go
│   │   └── routes.go
│   │
│   ├── share/                 # 分享相关 handlers
│   │   ├── handler.go
│   │   └── routes.go
│   │
│   ├── sync/                  # 同步相关 handlers
│   │   ├── handler.go
│   │   └── routes.go
│   │
│   └── version/               # 版本信息 handlers
│       ├── handler.go
│       └── routes.go
│
├── middleware/                # 中间件
│   ├── auth.go                # 认证中间件（JWT）
│   ├── cors.go                # CORS 中间件
│   ├── logger.go              # 日志中间件（使用 pkg/logger）
│   ├── recovery.go            # 恢复中间件
│   └── flexible_auth.go       # 灵活认证中间件（支持签名URL）
│
├── server/                    # 服务器抽象
│   ├── server.go              # Server 接口定义
│   ├── http_server.go         # HTTP/HTTPS 服务器实现
│   ├── unix_socket_server.go  # Unix Socket 服务器实现
│   └── future.go              # 未来协议接口预留（WebSocket/WebDAV）
│
└── swagger/                   # Swagger 文档
    ├── docs.go                # 生成的文档（swag init）
    └── swagger.yaml           # Swagger 配置
```

## 7.8.4 响应格式设计

### 统一响应结构（与旧架构一致）

```go
// internal/api/response.go
package api

import (
    "net/http"
    "github.com/gin-gonic/gin"
)

// ApiResponse 统一 API 响应格式（与旧架构一致）
type ApiResponse struct {
    Code    int         `json:"code"`     // 0=成功, 1=失败
    Message string      `json:"message"`  // 响应消息
    Data    interface{} `json:"data,omitempty"` // 响应数据
}

// 响应辅助函数
func Success(c *gin.Context, message string, data interface{}) {
    c.JSON(http.StatusOK, ApiResponse{
        Code:    0,
        Message: message,
        Data:    data,
    })
}

func Error(c *gin.Context, message string) {
    c.JSON(http.StatusBadRequest, ApiResponse{
        Code:    1,
        Message: message,
        Data:    nil,
    })
}

func ErrorAuth(c *gin.Context, message string) {
    c.JSON(http.StatusUnauthorized, ApiResponse{
        Code:    1,
        Message: message,
        Data:    nil,
    })
}

func Created(c *gin.Context, message string, data interface{}) {
    c.JSON(http.StatusCreated, ApiResponse{
        Code:    0,
        Message: message,
        Data:    data,
    })
}

func NoContent(c *gin.Context) {
    c.Status(http.StatusNoContent)
}
```

## 7.8.5 路由设计

### 路由结构（与旧架构一致）

所有路由地址与旧架构保持一致，确保客户端无需修改：

```
/api/v1/
  ├── auth/
  │   ├── POST /register
  │   ├── POST /login
  │   ├── POST /refresh
  │   ├── POST /logout
  │   ├── POST /apple/login
  │   ├── GET /profile (protected)
  │   ├── POST /avatar (protected)
  │   └── POST /password/set (protected)
  │
  ├── media/
  │   ├── POST /upload-stream (protected)
  │   ├── GET / (protected)
  │   ├── POST /check_hashes (protected)
  │   ├── GET /changes (protected)
  │   ├── GET /:uuid (protected)
  │   ├── DELETE /:uuid (protected)
  │   ├── POST /:uuid/restore (protected)
  │   ├── DELETE /:uuid/purge (protected)
  │   ├── GET /:uuid/download/original (flexible auth)
  │   ├── GET /:uuid/download/preview (flexible auth)
  │   └── GET /:uuid/download/thumbnail (flexible auth)
  │
  ├── albums/
  │   ├── POST / (protected)
  │   ├── GET / (protected)
  │   ├── GET /:uuid (protected)
  │   ├── POST /:uuid/items (protected)
  │   └── DELETE /:uuid (protected)
  │
  ├── groups/
  │   ├── POST / (protected)
  │   ├── GET / (protected)
  │   ├── POST /join (protected)
  │   ├── POST /:uuid/leave (protected)
  │   ├── GET /:uuid (protected)
  │   ├── PUT /:uuid (protected)
  │   ├── POST /:uuid/posts (protected)
  │   ├── GET /:uuid/feed (protected)
  │   ├── GET /:uuid/media/:media_uuid/thumbnail (protected)
  │   ├── GET /:uuid/media/:media_uuid/preview (protected)
  │   ├── GET /:uuid/members (protected)
  │   ├── POST /:uuid/members/invite (protected)
  │   └── DELETE /:uuid/members/:userId (protected)
  │
  ├── posts/
  │   ├── POST /:postId/comments (protected)
  │   └── GET /:postId/comments (protected)
  │
  ├── comments/
  │   └── DELETE /:commentId (protected)
  │
  ├── shares/
  │   ├── POST / (protected)
  │   ├── GET /with-me (protected)
  │   └── GET /:share_token/meta (public)
  │
  └── sync/ (protected - 由 changelog 模块注册)
      ├── GET /sync - 增量同步
      ├── GET /sync/full_init - 全量同步初始化
      └── GET /sync/full_data - 全量同步数据
```

### 路由注册器

```go
// internal/api/router.go
package api

import (
    "github.com/album/backend/internal/app"
    "github.com/album/backend/internal/api/v1/auth"
    "github.com/album/backend/internal/api/v1/media"
    "github.com/album/backend/internal/api/v1/album"
    "github.com/album/backend/internal/api/v1/group"
    "github.com/album/backend/internal/api/v1/share"
    "github.com/album/backend/internal/api/v1/changelog"
    "github.com/album/backend/internal/api/v1/version"
    "github.com/album/backend/internal/api/middleware"
    "github.com/gin-gonic/gin"
    swaggerFiles "github.com/swaggo/files"
    ginSwagger "github.com/swaggo/gin-swagger"
)

type Router struct {
    engine *gin.Engine
    app    *app.App
}

func NewRouter(app *app.App) *Router {
    r := gin.Default()
    return &Router{
        engine: r,
        app:    app,
    }
}

func (r *Router) Setup() {
    // 1. 全局中间件
    r.setupGlobalMiddleware()
    
    // 2. 静态资源
    r.setupStaticFiles()
    
    // 3. 公共路由
    r.setupPublicRoutes()
    
    // 4. API v1 路由组
    r.setupAPIV1()
    
    // 5. Swagger 文档
    r.setupSwagger()
}

func (r *Router) setupGlobalMiddleware() {
    // 日志中间件（使用 pkg/logger）
    r.engine.Use(middleware.LoggerMiddleware())
    
    // 恢复中间件
    r.engine.Use(middleware.RecoveryMiddleware())
    
    // CORS 中间件
    r.engine.Use(middleware.CORSMiddleware())
}

func (r *Router) setupAPIV1() {
    v1 := r.engine.Group("/api/v1")
    
    // 注册各模块路由
    auth.RegisterRoutes(v1, r.app)
    media.RegisterRoutes(v1, r.app)
    album.RegisterRoutes(v1, r.app)
    group.RegisterRoutes(v1, r.app)
    share.RegisterRoutes(v1, r.app)
    changelog.RegisterRoutes(v1, r.app)  // 如果 changelog 模块启用
    version.RegisterRoutes(v1, r.app)
}

func (r *Router) Engine() *gin.Engine {
    return r.engine
}
```

## 7.8.6 Handler 设计模式

### Handler 职责

每个 Handler 只负责：
1. **请求解析**：解析 URL 参数、查询参数、请求体
2. **参数验证**：使用 Gin 的 binding 验证参数
3. **调用 Service**：调用 Service 层处理业务逻辑
4. **响应格式化**：使用统一的 `api.Success` 等方法格式化响应

### Handler 示例

```go
// internal/api/v1/media/handler.go
package media

import (
    "github.com/album/backend/internal/api"
    "github.com/album/backend/internal/api/dto"
    "github.com/album/backend/internal/service"
    "github.com/album/backend/pkg/logger"
    "github.com/gin-gonic/gin"
)

type Handler struct {
    mediaService service.MediaService
    logger       logger.Logger
}

func NewHandler(mediaService service.MediaService) *Handler {
    return &Handler{
        mediaService: mediaService,
        logger:       logger.New("api.v1.media"),
    }
}

func (h *Handler) GetMedias(c *gin.Context) {
    // 1. 解析请求参数
    var req dto.GetMediasRequest
    if err := c.ShouldBindQuery(&req); err != nil {
        api.Error(c, "Invalid request parameters")
        return
    }
    
    // 2. 获取用户ID（从中间件注入）
    userID := getUserID(c)
    
    // 3. 调用 Service 层
    medias, err := h.mediaService.GetMedias(c.Request.Context(), userID, req)
    if err != nil {
        h.logger.Error("Failed to get medias",
            logger.WithContext(c.Request.Context()),
            logger.Error(err),
        )
        api.Error(c, "Failed to get medias")
        return
    }
    
    // 4. 格式化响应
    api.Success(c, "Success", medias)
}

// internal/api/v1/media/routes.go
package media

import (
    "github.com/album/backend/internal/app"
    "github.com/album/backend/internal/api/middleware"
    "github.com/gin-gonic/gin"
)

func RegisterRoutes(rg *gin.RouterGroup, app *app.App) {
    handler := NewHandler(app.MediaService)
    
    // 受保护的路由组
    protected := rg.Group("/media")
    protected.Use(middleware.AuthMiddleware(app.Config.Auth.JWTSecret))
    {
        protected.POST("/upload-stream", handler.UploadStream)
        protected.GET("", handler.GetMedias)
        protected.POST("/check_hashes", handler.CheckHashes)
        protected.GET("/changes", handler.GetChanges)
        protected.GET("/:uuid", handler.GetMediaDetail)
        protected.DELETE("/:uuid", handler.Delete)
        protected.POST("/:uuid/restore", handler.Restore)
        protected.DELETE("/:uuid/purge", handler.Purge)
    }
    
    // 灵活认证的路由组（支持 JWT 或签名 URL）
    download := rg.Group("/media")
    download.Use(middleware.FlexibleAuthMiddleware(app.Config.Auth.JWTSecret, app.URLSigner))
    {
        download.GET("/:uuid/download/original", handler.DownloadOriginal)
        download.GET("/:uuid/download/preview", handler.DownloadPreview)
        download.GET("/:uuid/download/thumbnail", handler.DownloadThumbnail)
    }
}
```

## 7.8.7 多协议支持设计

### Server 接口抽象

```go
// internal/api/server/server.go
package server

import (
    "context"
)

// Server 统一的服务器接口
type Server interface {
    // Start 启动服务器（阻塞调用）
    Start() error
    
    // Stop 停止服务器（优雅关闭）
    Stop(ctx context.Context) error
    
    // Address 返回服务器监听地址
    Address() string
    
    // Protocol 返回协议类型（http, https, unix, ws, webdav）
    Protocol() string
}

// Protocol 协议类型常量
const (
    ProtocolHTTP     = "http"
    ProtocolHTTPS    = "https"
    ProtocolUnix     = "unix"
    ProtocolWebSocket = "ws"      // 未来支持
    ProtocolWebDAV   = "webdav"   // 未来支持
)
```

### HTTP/HTTPS 服务器

```go
// internal/api/server/http_server.go
package server

import (
    "context"
    "net/http"
    "time"
    "github.com/gin-gonic/gin"
)

type HTTPServer struct {
    router   *gin.Engine
    server   *http.Server
    config   *HTTPServerConfig
}

type HTTPServerConfig struct {
    Address      string
    TLSEnabled   bool
    CertFile     string
    KeyFile      string
    ReadTimeout  time.Duration
    WriteTimeout time.Duration
    IdleTimeout  time.Duration
}

func NewHTTPServer(router *gin.Engine, config *HTTPServerConfig) *HTTPServer {
    return &HTTPServer{
        router: router,
        config: config,
    }
}

func (s *HTTPServer) Start() error {
    s.server = &http.Server{
        Addr:         s.config.Address,
        Handler:      s.router,
        ReadTimeout:  s.config.ReadTimeout,
        WriteTimeout: s.config.WriteTimeout,
        IdleTimeout:  s.config.IdleTimeout,
    }
    
    if s.config.TLSEnabled {
        return s.server.ListenAndServeTLS(s.config.CertFile, s.config.KeyFile)
    }
    return s.server.ListenAndServe()
}

func (s *HTTPServer) Stop(ctx context.Context) error {
    return s.server.Shutdown(ctx)
}

func (s *HTTPServer) Address() string {
    return s.config.Address
}

func (s *HTTPServer) Protocol() string {
    if s.config.TLSEnabled {
        return ProtocolHTTPS
    }
    return ProtocolHTTP
}
```

### Unix Socket 服务器

```go
// internal/api/server/unix_socket_server.go
package server

import (
    "context"
    "fmt"
    "net"
    "net/http"
    "os"
    "time"
    "github.com/gin-gonic/gin"
)

type UnixSocketServer struct {
    router   *gin.Engine
    server   *http.Server
    listener net.Listener
    config   *UnixSocketServerConfig
}

type UnixSocketServerConfig struct {
    SocketPath   string
    Mode         os.FileMode
    ReadTimeout  time.Duration
    WriteTimeout time.Duration
    IdleTimeout  time.Duration
}

func NewUnixSocketServer(router *gin.Engine, config *UnixSocketServerConfig) *UnixSocketServer {
    return &UnixSocketServer{
        router: router,
        config: config,
    }
}

func (s *UnixSocketServer) Start() error {
    // 删除已存在的 socket 文件
    if _, err := os.Stat(s.config.SocketPath); err == nil {
        if err := os.Remove(s.config.SocketPath); err != nil {
            return fmt.Errorf("failed to remove existing socket: %w", err)
        }
    }
    
    // 创建 Unix Socket 监听器
    listener, err := net.Listen("unix", s.config.SocketPath)
    if err != nil {
        return fmt.Errorf("failed to listen on unix socket: %w", err)
    }
    
    // 设置 socket 文件权限
    if err := os.Chmod(s.config.SocketPath, s.config.Mode); err != nil {
        listener.Close()
        return fmt.Errorf("failed to set socket permissions: %w", err)
    }
    
    s.listener = listener
    
    // 创建 HTTP 服务器（复用 Gin 路由）
    s.server = &http.Server{
        Handler:      s.router,
        ReadTimeout:  s.config.ReadTimeout,
        WriteTimeout: s.config.WriteTimeout,
        IdleTimeout:  s.config.IdleTimeout,
    }
    
    return s.server.Serve(listener)
}

func (s *UnixSocketServer) Stop(ctx context.Context) error {
    err := s.server.Shutdown(ctx)
    if s.listener != nil {
        s.listener.Close()
    }
    // 删除 socket 文件
    if _, statErr := os.Stat(s.config.SocketPath); statErr == nil {
        os.Remove(s.config.SocketPath)
    }
    return err
}

func (s *UnixSocketServer) Address() string {
    return s.config.SocketPath
}

func (s *UnixSocketServer) Protocol() string {
    return ProtocolUnix
}
```

### 未来协议接口预留

```go
// internal/api/server/future.go
package server

// WebSocketServer 未来 WebSocket 服务器接口（预留）
// 当需要实现时，只需实现 Server 接口即可
type WebSocketServer interface {
    Server
    // 未来可以添加 WebSocket 特有的方法
    // RegisterHandler(pattern string, handler WebSocketHandler)
}

// WebDAVServer 未来 WebDAV 服务器接口（预留）
type WebDAVServer interface {
    Server
    // 未来可以添加 WebDAV 特有的方法
    // SetFileSystem(fs FileSystem)
}

// 当需要实现时，创建对应的实现文件：
// - websocket_server.go（实现 WebSocketServer 接口）
// - webdav_server.go（实现 WebDAVServer 接口）
```

## 7.8.8 中间件设计

### 日志中间件（使用 pkg/logger）

```go
// internal/api/middleware/logger.go
package middleware

import (
    "time"
    "github.com/album/backend/pkg/logger"
    "github.com/gin-gonic/gin"
)

func LoggerMiddleware() gin.HandlerFunc {
    log := logger.New("api")
    
    return func(c *gin.Context) {
        start := time.Now()
        
        // 生成 request_id
        requestID := c.GetString("request_id")
        if requestID == "" {
            requestID = generateRequestID()
            c.Set("request_id", requestID)
        }
        
        // 将 request_id 注入到 context
        ctx := logger.WithRequestID(c.Request.Context(), requestID)
        c.Request = c.Request.WithContext(ctx)
        
        // 处理请求
        c.Next()
        
        // 记录请求日志
        latency := time.Since(start)
        fields := []logger.Field{
            logger.String("method", c.Request.Method),
            logger.String("path", c.Request.URL.Path),
            logger.Int("status", c.Writer.Status()),
            logger.String("ip", c.ClientIP()),
            logger.Duration("latency", latency),
            logger.RequestID(requestID),
        }
        
        if userID, exists := c.Get("user_id"); exists {
            if uid, ok := userID.(uint); ok {
                fields = append(fields, logger.UserID(uid))
            }
        }
        
        if c.Writer.Status() >= 500 {
            log.Error("HTTP request failed", fields...)
        } else if c.Writer.Status() >= 400 {
            log.Warn("HTTP request error", fields...)
        } else {
            log.Info("HTTP request", fields...)
        }
    }
}
```

### 认证中间件

```go
// internal/api/middleware/auth.go
package middleware

import (
    "github.com/album/backend/internal/api"
    "github.com/gin-gonic/gin"
)

// AuthMiddleware 标准 JWT 认证中间件（用于受保护路由）
func AuthMiddleware(jwtSecret string) gin.HandlerFunc {
    return func(c *gin.Context) {
        // JWT 验证逻辑
        // 验证成功后，将 user_id 注入到 context
        // ...
    }
}

// FlexibleAuthMiddleware 灵活认证中间件（支持 JWT 或签名 URL）
func FlexibleAuthMiddleware(jwtSecret string, urlSigner interface{}) gin.HandlerFunc {
    return func(c *gin.Context) {
        // 1. 先尝试 JWT 认证
        // 2. 如果失败，尝试签名 URL 验证
        // ...
    }
}
```

## 7.8.9 配置集成

### 服务器配置结构

服务器配置通过 `internal/config/modules/server.go` 定义，详细设计请参考 [10. 配置管理](../10-configuration.md)。

配置示例：

```yaml
server:
  http:
    enabled: true
    address: "0.0.0.0:8080"
    read_timeout: "30s"
    write_timeout: "30s"
    idle_timeout: "120s"
    tls:
      enabled: false
      cert_file: ""
      key_file: ""
  
  unix:
    enabled: true
    socket_path: "/tmp/album.sock"
    mode: "0666"
    read_timeout: "30s"
    write_timeout: "30s"
    idle_timeout: "120s"
```

## 7.8.10 Swagger 文档集成

### 文档生成

使用 `swaggo/swag` 生成 Swagger 文档：

```go
// @Summary      获取媒体列表
// @Description  获取当前用户的媒体列表
// @Tags         Media
// @Accept       json
// @Produce      json
// @Param        page query int false "页码"
// @Param        page_size query int false "每页数量"
// @Success      200 {object} api.ApiResponse{data=[]dto.MediaResponse}
// @Failure      400 {object} api.ApiResponse
// @Router       /api/v1/media [get]
// @Security     BearerAuth
func (h *Handler) GetMedias(c *gin.Context) {
    // ...
}
```

### 路由注册

```go
func (r *Router) setupSwagger() {
    r.engine.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))
}
```

## 7.8.11 服务器启动

### 主入口设计

```go
// cmd/server/main.go
func main() {
    // 1. 加载配置
    cfg := loadConfig()
    
    // 2. 初始化日志系统
    initLogger(cfg)
    
    // 3. 构建应用（依赖注入）
    app := buildApp(cfg)
    
    // 4. 创建路由
    router := api.NewRouter(app)
    router.Setup()
    
    // 5. 创建并启动服务器（根据配置）
    servers := []server.Server{}
    
    if cfg.Server.HTTP.Enabled {
        httpServer := server.NewHTTPServer(router.Engine(), cfg.Server.HTTP)
        servers = append(servers, httpServer)
    }
    
    if cfg.Server.Unix.Enabled {
        unixServer := server.NewUnixSocketServer(router.Engine(), cfg.Server.Unix)
        servers = append(servers, unixServer)
    }
    
    // 6. 启动所有服务器（并发）
    startServers(servers)
}
```

## 7.8.12 设计要点总结

### 兼容性保证

- ✅ **路由地址一致**：所有路由地址与旧架构完全一致
- ✅ **响应格式一致**：使用统一的 `ApiResponse` 结构，与旧架构一致
- ✅ **DTO 结构一致**：请求/响应结构与旧架构一致

### 多协议支持

- ✅ **HTTP/HTTPS**：直接实现，支持 TLS
- ✅ **Unix Socket**：直接实现，支持本地访问
- ✅ **WebSocket/WebDAV**：预留接口，未来实现

### 架构集成

- ✅ **配置集成**：使用 `internal/config` 模块管理配置
- ✅ **日志集成**：使用 `pkg/logger` 统一日志记录
- ✅ **依赖注入**：通过 `internal/app` 进行依赖注入
- ✅ **中间件链**：认证、日志、CORS 等通过中间件实现

### 扩展性

- ✅ **模块化路由**：按功能模块组织，易于扩展
- ✅ **服务器抽象**：通过 `Server` 接口统一抽象，易于添加新协议
- ✅ **Swagger 文档**：自动生成 API 文档，便于客户端集成

## 7.8.13 相关文档

- [3. 分层架构](../03-layered-architecture.md) - API 层的职责和特点
- [4. 依赖注入](../04-dependency-injection.md) - API 模块的依赖注入方式
- [10. 配置管理](../10-configuration.md) - 服务器配置结构
- [11. 错误处理](../11-error-handling.md) - 统一错误响应格式
- [15. 监控和运维](../15-monitoring.md) - API 日志和监控

