# 7.10 认证模块架构设计

## 7.10.1 概述

认证模块负责账号生命周期管理、凭证校验与访问控制支撑，确保新旧架构的接口行为保持一致。模块涵盖本地账号注册/登录、Apple ID 登录、刷新/注销令牌、头像上传以及受保护资源授权（JWT 与签名 URL）。

## 7.10.2 设计原则

1. **向后兼容**：所有路由与响应格式与旧架构一致，客户端无需改动。  
2. **分层清晰**：API Handler、Service、Repository、Model 各司其职，便于测试与扩展。  
3. **安全可配置**：令牌过期、签名密钥、Apple Bundle ID 等均通过配置中心统一管理。  
4. **易于扩展**：新增认证提供商或额外校验时，仅需扩展 Service 与 Repository 即可。  
5. **操作幂等**：注册/登录/刷新等接口保证幂等或友好的错误提示，避免重复提交导致的脏数据。

## 7.10.3 目录结构

```
internal/
├── api/
│   ├── middleware/auth.go          # AuthMiddleware & FlexibleAuthMiddleware
│   └── v1/auth/
│       ├── handler.go              # 认证 HTTP Handler
│       └── routes.go               # 认证路由注册
│
├── service/auth/
│   ├── service.go                  # 认证 Service 接口与实现
│   ├── password.go                 # 密码哈希与校验
│   ├── jwt.go                      # 访问/刷新令牌生成与校验
│   └── apple.go                    # Apple Identity Token Claims 定义
│
├── repository/
│   ├── interfaces.go               # User/AuthProvider/RefreshToken 仓储接口
│   ├── user.go
│   ├── auth_provider.go
│   └── refresh_token.go
│
├── database/models/
│   └── user.go                     # User/AuthProvider/RefreshToken 模型定义
│
├── app/
│   ├── app.go                      # App 结构体持有 AuthService、URLSigner、仓储
│   └── builder.go                  # BuildSecurity/BuildRepositories/BuildServices
│
├── config/modules/
│   ├── auth.go                     # 认证配置结构体与校验
│   └── server.go                   # PublicBaseURL
│
└── urlsigner/
    └── signer.go                   # 签名 URL 生成与校验
```

## 7.10.4 数据模型

| 模型 | 关键字段 | 说明 |
| --- | --- | --- |
| `User` | `Email`（唯一）、`Username`（可空）、`Password`（可空）、`Avatar` | 账号主体，支持仅 Apple 登录的无密码用户。 |
| `AuthProvider` | `ProviderName`、`ProviderUserID`、`UserID` | 记录第三方授权关系；当前仅支持 `apple`，便于未来扩展 Google 等。 |
| `RefreshToken` | `Token`（唯一）、`ExpiresAt`、`IsRevoked` | 管理刷新令牌存续期，可被撤销或过期后失效。 |

所有模型统一继承 `gorm.Model`（或包含其字段），便于使用软删除、时间戳等能力。

## 7.10.5 仓储层

仓储接口定义于 `internal/repository/interfaces.go`，实现提供如下能力：

- **UserRepository**
  - 创建用户、通过 Email/ID 查询用户。
  - 判断用户名或邮箱是否已存在（注册冲突检查）。
  - 更新密码、更新头像文件名。
- **AuthProviderRepository**
  - 为用户创建新的第三方绑定。
  - 通过 Provider + UserID 检查是否已绑定。
  - 通过 Provider + ProviderUserID 检测是否存在交叉绑定冲突。
- **RefreshTokenRepository**
  - 创建刷新令牌记录。
  - 根据 Token 查询仍有效且未撤销的记录。
  - 将 Token 标记为撤销，支持幂等登出。

所有操作均使用 `WithContext`，确保在 Handler 层可透传 `context.Context`。

## 7.10.6 服务层

`internal/service/auth/service.go` 暴露 `Service` 接口，核心职责：

- **注册（Register）**：检查用户名/邮箱冲突，生成密码哈希，创建用户。
- **登录（Login）**：验证密码，生成访问/刷新令牌，并持久化刷新令牌。
- **Apple 登录（AppleLogin）**：
  - 使用 `github.com/MicahParks/keyfunc/v3` 拉取 Apple JWKS 验签。
  - 校验 Issuer、Audience、Email 等声明。
  - 按邮箱决定是新建用户还是关联现有用户，并处理 Apple ID 绑定。
- **设置密码（SetPassword）**：仅允许当前无密码的第三方账号设置密码。
- **刷新令牌（RefreshToken）**：校验未撤销且未过期的刷新令牌，签发新的访问令牌。
- **登出（Logout）**：撤销指定的刷新令牌，保证后续无法继续刷新。
- **查询资料（GetProfile）**：组合头像访问 URL，返回基本信息、是否已设置密码等。
- **上传头像（UploadAvatar）**：校验大小与扩展名，保存文件并更新数据库记录。
- **访问令牌校验（ValidateAccessToken）**：供中间件复用，解析 JWT 并返回用户 ID。

服务内部依赖：

- `UserRepository` / `AuthProviderRepository` / `RefreshTokenRepository`
- 数据库事务（Apple 登录首次注册时）
- 配置项（JWT 密钥、过期时间、Apple Bundle ID、头像路径、签名 URL TTL）
- `urlsigner.Signer`（通过 `App` 注入，用于灵活认证中间件）

## 7.10.7 API 层

`internal/api/v1/auth/handler.go` 提供与旧架构一致的 REST 接口：

| 路由 | 方法 | 说明 |
| --- | --- | --- |
| `/api/v1/auth/register` | POST | 注册账号。 |
| `/api/v1/auth/login` | POST | 登录并返回访问/刷新令牌。 |
| `/api/v1/auth/apple/login` | POST | Apple ID 登录。 |
| `/api/v1/auth/refresh` | POST | 使用刷新令牌获取新的访问令牌。 |
| `/api/v1/auth/logout` | POST | 撤销刷新令牌。 |
| `/api/v1/auth/profile` | GET | 获取当前登录用户信息。 |
| `/api/v1/auth/avatar` | POST | 上传头像。 |
| `/api/v1/auth/password/set` | POST | 为第三方账号设置密码。 |

所有 Handler 复用统一响应格式，并对错误类型做精细化提示以保持兼容。

## 7.10.8 中间件与安全工具

- `AuthMiddleware`：校验 `Authorization: Bearer <token>`，设置 `userID` 到 `gin.Context`。`authService` 不可用时直接返回 401。
- `FlexibleAuthMiddleware`：先尝试 JWT 验证，失败后回退到签名 URL（`urlsigner.Signer`）。用于媒体下载等支持公开链接的场景。
- `MustGetUserID`：封装从上下文获取用户 ID 的逻辑，失败时直接返回 401。
- `urlsigner.Signer`：生成/验证带 `expires` 与可选 `uid` 参数的签名链接，供灵活认证中间件与分享能力使用。

## 7.10.9 配置与环境变量

认证模块配置位于 `configs/config.yaml`：

```yaml
server:
  host: "0.0.0.0"
  port: 8080
  public_base_url: "http://localhost:8080"

auth:
  jwt_secret: "your-secret-key-here"
  access_token_expires_in: "30m"
  refresh_token_expires_in: "720h"
  apple_app_bundle_id: ""
  avatar_save_path: "./public/avatars"
  max_avatar_size: "5MB"
  url_signer_secret: "signer-secret"
  signed_url_load_ttl: "30m"
```

支持的环境变量（覆盖 YAML，全部为可选）：

- `SERVER_PUBLIC_BASE_URL`
- `AUTH_JWT_SECRET`
- `AUTH_ACCESS_TOKEN_EXPIRES_IN`
- `AUTH_REFRESH_TOKEN_EXPIRES_IN`
- `AUTH_APPLE_APP_BUNDLE_ID`
- `AUTH_AVATAR_SAVE_PATH`
- `AUTH_MAX_AVATAR_SIZE`
- `AUTH_URL_SIGNER_SECRET`
- `AUTH_SIGNED_URL_LOAD_TTL`

## 7.10.10 典型流程

1. **注册**
   - Handler 验证请求体 → Service 检查冲突 → 生成密码哈希 → 创建 User → 返回用户 ID。
2. **登录**
   - Handler 验证密码 → Service 生成访问/刷新令牌 → 写入刷新令牌仓储 → 返回 TokenPair。
3. **Apple 登录**
   - Handler 接收 Identity Token → Service 调用 JWKS 验证 → 根据邮箱决定创建/绑定用户 → 返回 TokenPair。
4. **刷新令牌**
   - Handler 校验参数 → Service 查询刷新令牌表 → 检查过期/撤销 → 生成新的访问令牌。
5. **登出**
   - Handler 传入刷新令牌 → Service 调用 `RevokeByToken` → 返回成功或 token 无效提示。
6. **上传头像**
   - Middleware 注入 userID → Handler 校验文件 → Service 写入磁盘并更新数据库 → 返回新的头像 URL。
7. **灵活认证访问**
   - `FlexibleAuthMiddleware` 先尝试 JWT → 若失败尝试 `Signer.Validate` → 允许匿名访问带签名的下载链接。

## 7.10.11 错误与日志

- Service 层在关键路径使用 `logger.New("service.auth")` 记录成功、错误及警告信息。
- 所有对外错误均映射为兼容旧架构的提示（例如密码错误 → `Invalid email or password`）。
- Apple 登录失败、上传头像失败等场景会包含详细 `err.Error()`，便于故障排查。

## 7.10.12 后续规划

- **多提供商支持**：当前仅实现 Apple，可在 `AuthProvider` 基础上扩展 Google、微信等登录方式。
- **安全增强**：引入刷新令牌旋转、IP/设备指纹等高级特性。
- **权限体系**：后续与 RBAC/ABAC 集成，实现细粒度授权控制。
- **审计日志**：记录登录、登出、密码修改等关键操作，满足审计与合规需求。

