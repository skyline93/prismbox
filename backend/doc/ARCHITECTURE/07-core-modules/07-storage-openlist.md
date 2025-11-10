# 7.3 OpenList/AList 云存储对接模块

## 7.3.1 概述

OpenList/AList 存储对接模块提供了通过 OpenList/AList 统一接入多种云存储服务的能力。该模块作为次存储的一个实现，将 OpenList/AList 的 API 适配为标准的 SecondaryStorage 接口。

## 7.3.2 优缺点分析

### 优点

1. **统一接入**：通过 OpenList/AList 统一管理多种云存储服务（S3、百度网盘、阿里云盘、OneDrive、Google Drive 等）
2. **维护成本低**：无需维护各云存储的 SDK 和认证逻辑，由 OpenList/AList 统一处理
3. **灵活性高**：支持动态添加/移除存储，配置变更无需重启
4. **轻量高效**：资源占用较低，响应速度较好
5. **开源透明**：代码可审查，降低安全风险
6. **迁移友好**：支持从 Alist 导入配置，便于迁移

### 缺点

1. **依赖外部服务**：OpenList/AList 服务异常会影响备份功能
2. **性能损耗**：多一层 HTTP 调用，增加延迟
3. **API 兼容性**：需要适配 OpenList/AList 的 API，可能受其版本变更影响
4. **功能限制**：受限于 OpenList/AList 的能力，高级特性可能受限
5. **社区维护风险**：项目较新，长期维护需要观察

## 7.3.3 架构设计

### 模块结构

```
internal/storage/secondary/openlist/
├── client.go          # OpenList API 客户端
├── storage.go         # SecondaryStorage 接口实现
├── adapter.go         # 路径和参数适配器
├── pool_manager.go    # 存储池管理器
├── cache.go          # 缓存管理
├── retry.go          # 重试机制
└── config.go         # 配置结构
```

### 核心组件

#### OpenListClient

负责与 OpenList/AList 服务的 HTTP 通信：

```go
type OpenListClient struct {
    baseURL    string
    apiKey     string
    httpClient *http.Client
    cache      *Cache
    retry      *RetryPolicy
}

// 核心方法
func (c *OpenListClient) ListDrivers(ctx context.Context) ([]Driver, error)
func (c *OpenListClient) GetStorage(ctx context.Context, driverID string) (*StorageInfo, error)
func (c *OpenListClient) UploadFile(ctx context.Context, driverID, path string, data io.Reader) error
func (c *OpenListClient) DownloadFile(ctx context.Context, driverID, path string) (io.ReadCloser, error)
func (c *OpenListClient) DeleteFile(ctx context.Context, driverID, path string) error
func (c *OpenListClient) ListFiles(ctx context.Context, driverID, path string) ([]FileInfo, error)
```

#### OpenListStorage

实现 SecondaryStorage 接口，适配 OpenList/AList API：

```go
type OpenListStorage struct {
    client     *OpenListClient
    poolMgr    *PoolManager
    adapter    *PathAdapter
    config     *Config
}

func (s *OpenListStorage) Upload(ctx context.Context, key string, data io.Reader, size int64, opts *PutOptions) error {
    // 1. 选择存储池（驱动）
    poolID, err := s.poolMgr.SelectPool(size)
    if err != nil {
        return err
    }
    
    // 2. 路径适配
    openlistPath := s.adapter.AdaptPath(key, opts)
    
    // 3. 上传文件
    return s.client.UploadFile(ctx, poolID, openlistPath, data)
}
```

#### PathAdapter

路径适配器，处理内部路径与 OpenList/AList 路径的转换：

```go
type PathAdapter struct {
    basePath string
    mapping  map[string]string  // 虚拟路径映射
}

func (a *PathAdapter) AdaptPath(internalPath string, opts *PutOptions) string {
    // Hash-based 路径转换为 OpenList 路径
    // 例如: files/ab/cd/hash.jpg -> /album/files/ab/cd/hash.jpg
    return filepath.Join(a.basePath, internalPath)
}

func (a *PathAdapter) ResolvePath(openlistPath string) string {
    // OpenList 路径转换为内部路径
    return strings.TrimPrefix(openlistPath, a.basePath)
}
```

#### PoolManager

存储池管理器，管理 OpenList/AList 的多个存储驱动：

```go
type PoolManager struct {
    pools     map[string]*StoragePool
    mu        sync.RWMutex
    selector  PoolSelector
}

type StoragePool struct {
    ID          string      // 对应 OpenList 的 Driver ID
    Name        string
    Type        string      // 存储类型：s3, baidu, aliyun, etc.
    MaxSize     int64
    CurrentSize int64
    Priority    int
    Enabled     bool
    Config      *DriverConfig
}

func (pm *PoolManager) SelectPool(requiredSize int64) (string, error) {
    // 根据大小、优先级、负载均衡策略选择存储池
}
```

## 7.3.4 对接重点难点

### 重点

1. **API 接口适配**
   - 理解 OpenList/AList 的 REST API
   - 适配现有的 SecondaryStorage 接口规范
   - 处理认证和授权

2. **存储池映射**
   - 将 OpenList/AList 的存储驱动映射为存储池
   - 支持多存储池配置
   - 实现存储池选择策略

3. **路径映射**
   - 内部 Hash-based 路径与 OpenList/AList 路径的转换
   - 虚拟路径与实际路径的映射
   - 跨存储的文件操作

4. **错误处理与重试**
   - 网络异常处理
   - OpenList/AList 服务异常处理
   - 重试机制

### 难点

1. **路径映射复杂性**
   - OpenList/AList 路径与内部 Hash-based 路径映射
   - 虚拟路径与实际路径转换
   - 跨存储的文件操作

2. **认证与授权**
   - OpenList/AList 的认证机制
   - Token 管理与刷新
   - 权限传递与检查

3. **数据一致性**
   - 多存储服务的数据同步
   - 文件元数据一致性
   - 删除操作的级联处理

4. **异常恢复**
   - OpenList/AList 服务中断后的恢复
   - 文件上传失败的处理
   - 数据一致性修复

## 7.3.5 配置设计

```yaml
storage:
  secondary:
    enabled: true
    type: "openlist"
    openlist:
      # OpenList 服务配置
      base_url: "http://openlist:5244"
      api_key: "your-api-key"
      
      # 连接配置
      timeout: 30s
      max_retries: 3
      retry_backoff: 1s
      
      # 连接池配置
      max_connections: 100
      idle_timeout: 90s
      
      # 缓存配置
      cache:
        enabled: true
        ttl: 5m
        max_size: 100MB
      
      # 存储池配置（对应 OpenList 的 Drivers）
      pools:
        - id: "s3-backup"
          name: "S3 备份存储"
          driver_id: "s3-driver-1"
          type: "s3"
          max_size: "10TB"
          priority: 1
          enabled: true
        - id: "baidu-cloud"
          name: "百度网盘"
          driver_id: "baidu-driver-1"
          type: "baidu"
          max_size: "2TB"
          priority: 2
          enabled: true
        - id: "aliyun-drive"
          name: "阿里云盘"
          driver_id: "aliyun-driver-1"
          type: "aliyun"
          max_size: "1TB"
          priority: 3
          enabled: true
      
      # 路径映射
      path_mapping:
        base_path: "/album"
        virtual_paths:
          - virtual: "/files"
            physical: "/album/files"
```

