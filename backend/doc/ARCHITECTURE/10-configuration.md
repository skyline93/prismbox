# 10. 配置管理

## 10.1 配置文件结构

```yaml
# configs/config.yaml
server:
  address: "0.0.0.0:8080"
  read_timeout: 30s
  write_timeout: 30s

database:
  type: "postgres"  # postgres, mysql, sqlite
  host: "localhost"
  port: 5432
  user: "mobile"
  password: "mobile"
  dbname: "mobile"
  sslmode: "disable"

storage:
  # 主存储配置（本地存储）
  primary:
    type: "local"
    local:
      base_path: "/data/uploads"
      
      # 存储池配置
      pools:
        - id: "pool-1"
          path: "/data/storage1"
          max_size: "1TB"
          priority: 1
          enabled: true
          auto_disable_threshold: 0.9
        - id: "pool-2"
          path: "/data/storage2"
          max_size: "2TB"
          priority: 2
          enabled: true
          auto_disable_threshold: 0.9
      
      # 临时文件配置
      temp:
        base_path: "/data/temp"
        max_age: "24h"
        max_size: "10GB"
        cleanup_interval: "1h"
      
      # 处理配置
      processing:
        enable_compression: true
        compression_level: 6
        enable_encryption: false
        encryption_key_path: "/etc/album/encryption.key"
      
      # 性能配置
      performance:
        cache_enabled: true
        cache_size: "1GB"
        cache_ttl: "24h"
        read_buffer_size: "64KB"
        write_buffer_size: "64KB"
  
  # 次存储配置（云存储备份，可选）
  secondary:
    enabled: true
    type: "openlist"  # openlist, s3, oss, cos
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
      
      # 路径映射
      path_mapping:
        base_path: "/album"
        virtual_paths:
          - virtual: "/files"
            physical: "/album/files"
    
    # 直接对接的云存储（可选）
    s3:
      region: "us-east-1"
      bucket: "my-bucket"
      access_key: "..."
      secret_key: "..."
  
  # 备份调度配置
  backup:
    enabled: true
    scheduler:
      scan_interval: "5m"        # 扫描间隔：5分钟
      batch_size: 100            # 批量处理大小：100个文件
      idle_threshold: 0.3        # 系统空闲阈值：30%
      max_concurrency: 5         # 最大并发数：5
      delay_execution: "5m"      # 延迟执行：5分钟
    
    # 备份策略
    strategy:
      priority: 1                # 低优先级
      retry_times: 3             # 重试次数
      retry_interval: "10m"      # 重试间隔：10分钟
      max_age: "24h"              # 最大等待时间：24小时

queue:
  concurrency: 10
  min_poll_interval_ms: 200
  max_poll_interval_ms: 3000

auth:
  jwt_secret: "..."
  access_token_expires_in: 30m
  refresh_token_expires_in: 720h

media:
  upload_dir: "./uploads"
  max_file_size: 100MB
  allowed_types: ["image/jpeg", "image/png", "video/mp4"]
```

## 10.2 环境变量支持

配置可以通过环境变量覆盖，优先级：环境变量 > 配置文件 > 默认值

