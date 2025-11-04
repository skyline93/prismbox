# 16. 部署流程

## 16.1 本地开发

```bash
# 1. 启动数据库
docker-compose -f deployments/docker/docker-compose.yml up -d postgres

# 2. 运行服务
go run cmd/server/main.go
```

## 16.2 构建和部署

```bash
# 1. 构建
make build VERSION=v1.0.0

# 2. 构建 Docker 镜像
make docker-build VERSION=v1.0.0

# 3. 部署
docker-compose -f deployments/docker/docker-compose.yml up -d
```

## 16.3 版本验证

```bash
# 查看版本
./bin/cli version
curl http://localhost:8080/api/v1/version
```

