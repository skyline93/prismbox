# 6. 容器部署

## 6.1 Dockerfile 设计

采用多阶段构建：
1. **构建阶段**：使用 `golang:alpine` 镜像，编译应用
2. **运行阶段**：使用 `alpine:latest` 镜像，只包含运行时依赖

## 6.2 构建参数

Docker 构建时通过 `ARG` 传递版本信息：

```dockerfile
ARG VERSION=dev
ARG BUILD_TIME
ARG GIT_COMMIT
ARG GIT_BRANCH

RUN make build-server VERSION=${VERSION} \
    BUILD_TIME=${BUILD_TIME} \
    GIT_COMMIT=${GIT_COMMIT} \
    GIT_BRANCH=${GIT_BRANCH}
```

## 6.3 docker-compose 配置

包含：
- **backend** 服务：应用主服务
- **postgres** 服务：数据库服务
- 网络配置
- 卷挂载
- 环境变量

## 6.4 健康检查

Dockerfile 中包含健康检查配置，确保容器正常运行。

