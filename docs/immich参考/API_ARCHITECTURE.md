# Immich 移动端 API 对接架构文档

## 目录

1. [架构概述](#架构概述)
2. [核心设计理念](#核心设计理念)
3. [技术栈与依赖](#技术栈与依赖)
4. [认证机制](#认证机制)
5. [HTTP/HTTPS 支持](#httphttps-支持)
6. [端点发现与配置](#端点发现与配置)
7. [错误处理机制](#错误处理机制)
8. [重试机制](#重试机制)
9. [请求头管理](#请求头管理)
10. [媒体资源上传下载](#媒体资源上传下载)
11. [平台差异处理](#平台差异处理)
12. [安全考虑](#安全考虑)
13. [最佳实践](#最佳实践)
14. [实现参考](#实现参考)

---

## 架构概述

Immich 移动端采用**统一的 API 服务架构**，通过 OpenAPI 生成的客户端与后台 API 对接，实现了完整的认证、HTTP/HTTPS 支持、错误处理和重试机制。

### 核心特点

- **统一认证机制**：Token 认证，自动注入请求头
- **灵活协议支持**：支持 HTTP/HTTPS，可配置 SSL 证书
- **智能端点发现**：支持 well-known 自动发现，自动验证可用性
- **完善错误处理**：统一异常处理，401 自动跳转登录
- **自动重试机制**：后台任务自动重试，网络失败回退缓存
- **安全存储**：Token 存储在平台安全存储，防止泄露
- **自定义头支持**：支持自定义请求头，适配企业环境

### 架构图

```
┌─────────────────────────────────────────────────────────────┐
│                   应用层 (Application Layer)                 │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  UI Components / Providers                            │   │
│  │  - 用户界面组件                                        │   │
│  │  - 状态管理                                            │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ API Calls
                            │
┌─────────────────────────────────────────────────────────────┐
│                 服务层 (Service Layer)                       │
│                                                               │
│  ┌──────────────────┐         ┌──────────────────┐          │
│  │  AuthService      │         │  UploadService  │          │
│  │  - 登录/登出      │         │  - 文件上传      │          │
│  │  - Token 管理     │         │  - 任务管理      │          │
│  └──────────────────┘         └──────────────────┘          │
│                                                               │
│  ┌──────────────────┐         ┌──────────────────┐          │
│  │  DownloadService  │         │  Other Services  │          │
│  │  - 文件下载       │         │  - 各种业务服务   │          │
│  │  - 任务管理       │         │                  │          │
│  └──────────────────┘         └──────────────────┘          │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ Repository Pattern
                            │
┌─────────────────────────────────────────────────────────────┐
│               仓库层 (Repository Layer)                      │
│                                                               │
│  ┌──────────────────┐         ┌──────────────────┐          │
│  │  AuthApiRepository│         │  UploadRepository│          │
│  │  - API 调用封装   │         │  - 上传任务管理   │          │
│  └──────────────────┘         └──────────────────┘          │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ ApiService
                            │
┌─────────────────────────────────────────────────────────────┐
│              API 服务层 (API Service Layer)                  │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  ApiService                                           │   │
│  │  - 端点管理                                           │   │
│  │  - 认证头注入                                         │   │
│  │  - OpenAPI 客户端管理                                 │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
│  ┌──────────────────┐         ┌──────────────────┐          │
│  │  OpenAPI Clients  │         │  HttpSSLOptions  │          │
│  │  - UsersApi       │         │  - SSL 配置      │          │
│  │  - AssetsApi      │         │  - 证书管理      │          │
│  │  - AlbumsApi      │         │                  │          │
│  │  - ...            │         │                  │          │
│  └──────────────────┘         └──────────────────┘          │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ HTTP/HTTPS
                            │
┌─────────────────────────────────────────────────────────────┐
│           网络层 (Network Layer)                            │
│                                                               │
│  ┌──────────────────┐         ┌──────────────────┐          │
│  │  Dart HTTP       │         │  Background      │          │
│  │  - 标准 API 调用  │         │  Downloader      │          │
│  │  - HttpOverrides │         │  - 上传/下载任务 │          │
│  └──────────────────┘         └──────────────────┘          │
│                                                               │
│  ┌──────────────────┐         ┌──────────────────┐          │
│  │  Android Native  │         │  iOS Native      │          │
│  │  - SSLContext    │         │  - System Network│          │
│  │  - TrustManager  │         │  - SSL Config    │          │
│  └──────────────────┘         └──────────────────┘          │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ Internet
                            │
┌─────────────────────────────────────────────────────────────┐
│                 服务器 (Server)                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Immich Server API                                    │   │
│  │  - RESTful API                                        │   │
│  │  - Token 验证                                         │   │
│  │  - 文件上传/下载                                      │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## 核心设计理念

### 1. 统一认证机制（Unified Authentication）

**设计目标**：
- 所有 API 请求自动携带认证信息
- Token 统一管理，避免重复代码
- 支持 Token 刷新和失效处理

**实现策略**：
- 通过 `Authentication` 接口自动注入认证头
- Token 存储在安全存储中
- 401 错误自动触发重新登录流程

**优势**：
- 代码简洁，无需在每个请求中手动添加认证头
- 安全性高，Token 统一管理
- 易于维护，认证逻辑集中

### 2. 灵活协议支持（Flexible Protocol Support）

**设计目标**：
- 支持 HTTP 和 HTTPS
- 支持自签名证书（开发/内网场景）
- 支持客户端证书（双向 TLS）

**实现策略**：
- URL 自动识别协议（根据 scheme）
- 全局 SSL 配置（HttpOverrides）
- 平台特定 SSL 配置（Android/iOS）

**优势**：
- 适应不同部署场景
- 开发和生产环境灵活切换
- 企业内网友好

### 3. 智能端点发现（Smart Endpoint Discovery）

**设计目标**：
- 自动发现 API 端点
- 验证端点可用性
- 支持端点切换（本地/远程）

**实现策略**：
- 优先尝试 `/.well-known/immich` 发现端点
- 使用 `pingServer()` 验证端点可用性
- 支持本地端点自动切换（基于 WiFi）

**优势**：
- 用户体验好，无需手动配置完整路径
- 支持复杂部署场景（反向代理、CDN）
- 自动适配服务器配置

### 4. 完善错误处理（Comprehensive Error Handling）

**设计目标**：
- 统一错误类型和处理
- 自动处理认证失效
- 友好的错误提示

**实现策略**：
- 使用 `ApiException` 统一错误格式
- 401 错误自动跳转登录
- 网络错误自动重试

**优势**：
- 错误处理一致
- 用户体验好
- 易于调试和维护

### 5. 自动重试机制（Automatic Retry）

**设计目标**：
- 网络临时故障自动恢复
- 减少用户手动重试
- 提升成功率

**实现策略**：
- 后台任务自动重试（可配置次数）
- 指数退避策略（部分场景）
- 缓存回退机制

**优势**：
- 提升用户体验
- 减少失败率
- 适应网络波动

---

## 技术栈与依赖

### 核心依赖

- **openapi**：OpenAPI 生成的 API 客户端
- **http**：Dart HTTP 客户端
- **background_downloader**：后台上传/下载任务管理
- **flutter_secure_storage**：安全存储（Token）

### 平台原生 API

- **Android**：
  - `HttpsURLConnection`：HTTPS 连接
  - `SSLContext`：SSL 配置
  - `TrustManager`：证书验证
- **iOS**：
  - `URLSession`：网络请求
  - `Security Framework`：SSL 和证书管理

### 自定义组件

- **ApiService**：统一 API 服务管理
- **HttpSSLOptions**：SSL/TLS 配置管理
- **HttpSSLCertOverride**：SSL 证书覆盖实现

---

## 认证机制

### 4.1 认证方式

**Token 认证**：
- 使用 Access Token 进行身份认证
- Token 通过登录接口获取：`POST /auth/login`
- Token 存储在本地持久化存储（Store）和安全存储（Keychain/Keystore）
- 所有 API 请求自动携带 Token

**Token 传递方式**：
- 请求头：`x-immich-user-token: {accessToken}`
- 通过 `Authentication.applyToParams()` 自动注入
- 每个请求都会自动添加认证头

### 4.2 Token 管理流程

**登录流程**：
1. 用户输入服务器 URL、邮箱和密码
2. 调用 `validateServerUrl()` 验证服务器可访问性
   - 检查 `/.well-known/immich` 端点发现
   - 调用 `pingServer()` 验证端点可用性
3. 调用 `login()` 获取 Access Token
   - 请求体包含邮箱和密码
   - 返回 Access Token 和用户信息
4. 调用 `saveAuthInfo()` 保存 Token 和用户信息
   - 存储 Token 到本地 Store
   - 存储 Token 到平台安全存储（用于 Widget 扩展）
   - 设置设备信息头（deviceModel、deviceType）
5. 初始化 API 客户端，设置端点

**Token 存储**：
- **本地 Store**：键为 `StoreKey.accessToken`，用于应用内访问
- **平台安全存储**：
  - iOS：Keychain
  - Android：Keystore
  - 用于 Widget 扩展访问
- **同步机制**：登录时同时写入两个存储位置

**Token 验证**：
- 应用启动时通过 `AuthGuard` 验证 Token 有效性
- 调用 `validateAccessToken()` 检查 Token 状态
- 401 未授权时自动跳转登录页
- Token 失效时清除本地数据

### 4.3 自定义请求头

**支持机制**：
- 用户可配置自定义请求头（JSON 格式）
- 存储在 `StoreKey.customHeaders`
- 自动合并到所有 API 请求头中

**使用场景**：
- 反向代理认证（如 Nginx Basic Auth）
- 自定义 API 网关认证
- 企业内网特殊认证需求

**实现方式**：
- 在 `ApiService.getRequestHeaders()` 中合并自定义头
- 与 Token 一起自动注入
- 支持动态更新（修改后立即生效）

---

## HTTP/HTTPS 支持

### 5.1 协议支持

**默认协议**：
- 优先使用 HTTPS（默认）
- 支持 HTTP（开发/内网场景）
- 通过 URL 解析自动识别协议

**URL 解析规则**：
- 格式：`[schema://]host[:port][/path]`
- schema 可选，默认 HTTPS
- 自动补全 `/api` 路径（如需要）

**协议选择**：
- 用户配置的服务器 URL 决定协议
- 支持手动切换（开发环境）
- 生产环境建议强制 HTTPS

### 5.2 SSL/TLS 证书处理

**自签名证书支持**：
- 用户可开启"允许自签名证书"选项
- 通过 `HttpSSLOptions` 全局配置
- 仅对已登录用户的服务器域名生效（安全限制）

**实现机制**：
- 使用 `HttpOverrides.global` 设置全局 HTTP 客户端
- 通过 `badCertificateCallback` 回调处理证书验证
- 检查服务器主机名匹配，避免中间人攻击

**安全限制**：
- 仅对配置的服务器主机名放宽验证
- 未登录时不允许自签名证书
- 记录证书验证失败日志

**客户端证书支持**：
- 支持 PKCS12 格式（.p12/.pfx）
- 用户可导入客户端证书和密码
- 用于双向 TLS 认证场景
- 证书存储在安全存储中

### 5.3 平台特定实现

**Android 平台**：
- 通过 MethodChannel 调用原生代码
- 配置 `HttpsURLConnection` 的 SSLContext
- 设置自定义 TrustManager 和 HostnameVerifier
- 影响所有使用 `HttpsURLConnection` 的请求（包括 background_downloader）

**iOS 平台**：
- 使用 Dart 的 `HttpOverrides` 机制
- 通过 `SecurityContext` 配置证书
- 系统级 SSL 验证
- background_downloader 使用系统网络栈

**配置时机**：
- 应用启动时应用 SSL 配置
- 后台工作器初始化时应用 SSL 配置
- 用户修改 SSL 设置时立即应用

---

## 端点发现与配置

### 6.1 端点解析流程

**自动发现机制**：
1. 首先尝试访问 `/.well-known/immich`
   - 发送 GET 请求到 `{baseUrl}/.well-known/immich`
   - 解析返回的 JSON 获取 API 端点
   - 支持相对路径和绝对路径
2. 如果发现失败，使用用户输入的 URL
   - 自动补全 `/api` 后缀（如需要）
   - 验证端点格式
3. 调用 `pingServer()` 验证端点可用性
   - 超时时间：5 秒
   - 验证失败抛出 `ApiException(503)`

**端点验证**：
- 调用 `pingServer()` 验证端点可用性
- 超时时间：5 秒
- 验证失败抛出 `ApiException(503)`
- 验证成功保存端点

### 6.2 端点存储

**持久化**：
- 验证成功后存储到 `StoreKey.serverEndpoint`
- 应用启动时自动恢复
- 支持本地端点和远程端点切换

**端点切换**：
- 支持本地端点和远程端点切换
- 基于 WiFi 名称自动切换（可选）
- 手动切换端点

**端点格式**：
- 完整 URL：`https://example.com/api`
- 包含协议、主机、端口（可选）、路径
- 自动处理路径拼接

---

## 错误处理机制

### 7.1 错误类型分类

**网络层错误**：
- `SocketException`：网络连接失败
- `TlsException`：SSL/TLS 握手失败
- `IOException`：I/O 操作失败
- `ClientException`：HTTP 连接失败
- `TimeoutException`：请求超时

**API 层错误**：
- `ApiException`：标准 API 错误
  - 包含 HTTP 状态码
  - 包含错误消息
  - 包含错误堆栈

**业务层错误**：
- 401 未授权：Token 失效或无效
- 403 禁止访问：权限不足
- 404 资源不存在：资源已删除或不存在
- 500 服务器错误：服务器内部错误

### 7.2 错误处理策略

**401 未授权处理**：
- 检测到 401 时自动清除本地认证信息
- 跳转到登录页面
- 记录错误日志
- 通知用户重新登录

**网络错误处理**：
- 捕获所有网络异常
- 转换为 `ApiException` 统一格式
- 记录详细错误信息
- 提供用户友好的错误提示

**超时处理**：
- 关键操作设置超时（如 pingServer：5 秒）
- 超时后返回失败，不阻塞应用
- 用户可手动重试
- 记录超时日志

### 7.3 错误日志

**日志记录**：
- 使用 `Logger` 记录错误
- 区分严重程度（severe、warning、info）
- 记录错误堆栈和上下文信息

**日志内容**：
- 错误类型和消息
- 请求 URL 和方法
- 响应状态码和内容
- 错误堆栈
- 时间戳

---

## 重试机制

### 8.1 自动重试策略

**后台任务重试**：
- 使用 `TaskStatus.waitingToRetry` 状态
- 由后台任务调度器自动重试
- 适用于文件上传等长时间任务
- 默认重试次数：3 次

**网络请求重试**：
- 图片加载失败时回退到缓存
- 缓存未命中时显示错误
- 用户可手动触发重试

### 8.2 重试场景

**可重试的错误**：
- 网络临时故障
- 服务器临时不可用（5xx）
- 超时错误
- 连接中断

**不可重试的错误**：
- 401 未授权（需要重新登录）
- 403 禁止访问
- 404 资源不存在
- 客户端错误（4xx，除 401 外）

### 8.3 重试实现

**指数退避**（部分场景）：
- 避免频繁重试
- 逐步增加重试间隔
- 限制最大重试次数

**缓存回退**：
- 网络失败时优先使用缓存
- 提供降级体验
- 减少用户感知的失败

**重试配置**：
- 可配置重试次数
- 可配置重试间隔
- 可配置重试条件

---

## 请求头管理

### 9.1 默认请求头

**自动添加的请求头**：
- `User-Agent`：应用版本和设备信息
- `deviceModel`：设备型号
- `deviceType`：iOS/Android
- `x-immich-user-token`：认证 Token
- `Content-Type`：根据请求类型自动设置
- `Accept`：根据 API 需求设置

### 9.2 设备信息头

**设备识别**：
- iOS：使用 `utsname.machine` 获取设备型号
- Android：使用 `androidInfo.model` 获取设备型号
- 用于服务器端设备管理和统计

**设备信息设置**：
- 登录时自动设置设备信息头
- 设备信息头在所有请求中自动携带
- 支持设备信息更新

### 9.3 自定义头管理

**自定义头获取**：
- 从 Store 读取自定义头配置
- JSON 格式存储
- 自动解析和合并

**自定义头应用**：
- 与 Token 一起自动注入
- 支持动态更新
- 所有 API 请求自动携带

---

## 媒体资源上传下载

### 10.1 上传机制

**上传任务创建**：
- 使用 `background_downloader` 的 `UploadTask`
- 任务包含：
  - `url`：完整端点 URL（包含协议）
  - `headers`：认证头（Token + 自定义头）
  - `httpRequestMethod`：POST
  - `fields`：表单字段（文件名、设备 ID、时间戳等）
  - `fileField`：文件字段名（assetData）

**认证头注入**：
- 通过 `ApiService.getRequestHeaders()` 获取认证头
- 包含 Token 和自定义头
- 在任务创建时传入 `headers` 参数
- background_downloader 在原生层将头添加到 HTTP 请求

**HTTP/HTTPS 支持**：
- URL 自动识别协议（根据 scheme）
- background_downloader 根据 URL scheme 选择协议
- SSL 配置通过平台原生方法应用

**上传重试**：
- 默认重试次数：3 次
- background_downloader 自动处理
- 网络错误时自动重试

### 10.2 下载机制

**下载任务创建**：
- 使用 `background_downloader` 的 `DownloadTask`
- 任务包含：
  - `url`：完整资源 URL（包含协议）
  - `headers`：认证头（Token + 自定义头）
  - `filename`：保存的文件名
  - `group`：任务组（用于分类管理）

**认证头注入**：
- 通过 `ApiService.getRequestHeaders()` 获取认证头
- 包含 Token 和自定义头
- 在任务创建时传入 `headers` 参数
- background_downloader 在原生层将头添加到 HTTP 请求

**HTTP/HTTPS 支持**：
- URL 自动识别协议（根据 scheme）
- background_downloader 根据 URL scheme 选择协议
- SSL 配置通过平台原生方法应用

**下载任务分组**：
- `kDownloadGroupImage`：图片下载
- `kDownloadGroupVideo`：视频下载
- `kDownloadGroupLivePhoto`：Live Photo 下载
- 不同组独立管理，支持按组配置并发数

### 10.3 background_downloader 集成

**初始化配置**：
- 在后台工作器初始化时配置
- 设置最大并发数、每个主机最大并发数、每个组最大并发数
- Android 大文件（>256MB）使用前台服务

**SSL 配置**：
- Dart 层通过 `HttpOverrides.global` 配置（影响标准 HTTP 请求）
- Android 通过 MethodChannel 配置系统 SSL（影响 background_downloader）
- iOS 依赖系统网络栈

**任务管理**：
- 注册任务状态回调
- 注册任务进度回调
- 支持任务取消和暂停

---

## 平台差异处理

### 11.1 Android 平台

**SSL 配置**：
- 通过 MethodChannel 调用原生代码
- 配置系统级 SSLContext
- 设置 `HttpsURLConnection.setDefaultSSLSocketFactory()`
- 设置 `HttpsURLConnection.setDefaultHostnameVerifier()`
- background_downloader 使用系统默认配置

**后台服务**：
- 大文件（>256MB）使用前台服务
- 确保后台下载不被系统杀死
- 显示下载通知

**网络权限**：
- 需要 INTERNET 权限
- 需要 ACCESS_NETWORK_STATE 权限（可选）

### 11.2 iOS 平台

**SSL 配置**：
- 依赖系统网络栈
- 系统级 SSL 验证
- 自签名证书需要用户信任（通过系统设置或应用内配置）

**后台下载**：
- 使用系统后台下载 API
- 支持应用被杀死后继续下载
- 需要配置后台模式权限（Background Modes）

**网络配置**：
- 需要配置 App Transport Security（ATS）
- 支持自定义 ATS 例外（开发环境）

---

## 安全考虑

### 12.1 认证安全

**Token 存储**：
- Token 存储在平台安全存储
- iOS：Keychain
- Android：Keystore
- 不在任务中明文存储
- 每次创建任务时动态获取

**传输安全**：
- 优先使用 HTTPS
- Token 通过请求头传输
- 不在 URL 中暴露 Token
- 不在日志中记录 Token

### 12.2 SSL 安全

**证书验证**：
- 默认严格验证 SSL 证书
- 自签名证书需要用户明确授权
- 仅对已登录服务器域名放宽验证
- 防止中间人攻击

**客户端证书**：
- 支持双向 TLS 认证
- 证书存储在安全存储中
- 适用于企业内网场景

### 12.3 自定义头安全

**验证机制**：
- 自定义头仅用于已登录用户
- 服务器端验证 Token 有效性
- 防止未授权访问

**存储安全**：
- 自定义头存储在本地 Store
- 不存储在平台安全存储（非敏感信息）
- 支持用户清除

---

## 最佳实践

### 13.1 API 调用规范

**统一使用 ApiService**：
- 所有 API 调用通过 `ApiService` 的各个 API 实例
- 不要直接创建 `ApiClient`
- 确保认证头自动添加

**错误处理**：
- 始终捕获 `ApiException`
- 根据状态码采取不同策略
- 记录错误日志
- 提供用户友好的错误提示

### 13.2 端点配置

**URL 格式**：
- 使用完整 URL（包含协议）
- 支持相对路径（通过 well-known 发现）
- 自动处理路径拼接

**验证端点**：
- 首次配置时验证端点可用性
- 应用启动时检查端点有效性
- 提供友好的错误提示

### 13.3 安全建议

**生产环境**：
- 强制使用 HTTPS
- 禁用自签名证书（除非必要）
- 定期更新应用和依赖
- 使用强密码和安全的 Token

**开发环境**：
- 可以使用 HTTP 和自签名证书
- 注意保护开发服务器访问
- 不要在生产环境使用开发配置

### 13.4 性能优化

**连接复用**：
- 使用连接池
- 复用 HTTP 客户端
- 减少连接建立开销

**请求优化**：
- 合并多个请求（如可能）
- 使用缓存减少请求
- 合理设置超时时间

---

## 实现参考

### 14.1 关键文件位置

#### API 服务实现
- `mobile/lib/services/api.service.dart`：统一 API 服务管理
- `mobile/lib/services/auth.service.dart`：认证服务
- `mobile/lib/repositories/auth_api.repository.dart`：认证 API 仓库

#### SSL 配置实现
- `mobile/lib/utils/http_ssl_options.dart`：SSL 配置管理
- `mobile/lib/utils/http_ssl_cert_override.dart`：SSL 证书覆盖实现
- `mobile/android/app/src/main/kotlin/app/alextran/immich/HttpSSLOptionsPlugin.kt`：Android 原生 SSL 配置

#### 上传下载实现
- `mobile/lib/services/upload.service.dart`：上传服务
- `mobile/lib/services/download.service.dart`：下载服务
- `mobile/lib/repositories/upload.repository.dart`：上传仓库
- `mobile/lib/repositories/download.repository.dart`：下载仓库

#### OpenAPI 客户端
- `mobile/openapi/lib/api_client.dart`：OpenAPI 客户端基础实现
- `mobile/openapi/lib/api/`：各种 API 客户端（自动生成）

### 14.2 关键接口

#### 认证接口
```dart
// 获取认证头
static Map<String, String> getRequestHeaders()

// 设置 Access Token
Future<void> setAccessToken(String accessToken)

// 验证端点
Future<String> resolveAndSetEndpoint(String serverUrl)
```

#### SSL 配置接口
```dart
// 应用 SSL 配置
static void apply({bool applyNative = true})

// 从设置应用 SSL 配置
static void applyFromSettings(bool newValue)
```

#### 上传下载接口
```dart
// 创建上传任务
Future<UploadTask> buildUploadTask(File file, {...})

// 创建下载任务
DownloadTask _buildDownloadTask(String id, String filename, {...})
```

### 14.3 配置选项

#### 用户设置
- `Setting.allowSelfSignedSSLCert`：是否允许自签名证书
- `Setting.customHeaders`：自定义请求头（JSON 格式）
- `StoreKey.serverEndpoint`：服务器端点 URL
- `StoreKey.accessToken`：访问令牌

#### SSL 配置
- 自签名证书：用户可开启/关闭
- 客户端证书：支持 PKCS12 格式
- 服务器主机名：用于验证自签名证书

#### 任务配置
- 最大并发数：6
- 每个主机最大并发数：6
- 每个组最大并发数：3
- 默认重试次数：3
- Android 前台服务阈值：256MB

### 14.4 扩展点

#### 自定义认证方式
- 实现 `Authentication` 接口
- 在 `applyToParams()` 中添加认证头
- 集成到 `ApiService`

#### 自定义 SSL 配置
- 扩展 `HttpSSLOptions`
- 实现自定义证书验证逻辑
- 集成到平台原生代码

#### 自定义错误处理
- 扩展 `ApiException`
- 实现自定义错误处理逻辑
- 集成到错误处理流程

---

## 总结

Immich 移动端 API 对接架构通过以下核心机制实现了安全、灵活、可靠的 API 通信：

1. **统一认证机制**：Token 认证，自动注入请求头，支持自定义头
2. **灵活协议支持**：支持 HTTP/HTTPS，可配置 SSL 证书，支持自签名和客户端证书
3. **智能端点发现**：支持 well-known 自动发现，自动验证可用性
4. **完善错误处理**：统一异常处理，401 自动跳转登录，友好的错误提示
5. **自动重试机制**：后台任务自动重试，网络失败回退缓存
6. **安全存储**：Token 存储在平台安全存储，防止泄露
7. **平台适配**：Android 和 iOS 平台特定实现，确保兼容性

该架构设计充分考虑了安全性、灵活性和用户体验的平衡，可以作为其他相册应用的重要参考。

---

**文档版本**：1.0  
**最后更新**：2024  
**维护者**：Immich 开发团队

