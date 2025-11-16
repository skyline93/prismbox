# Project settings
PROJECT := github.com/album/backend
BIN_DIR := bin

# Version metadata (can be overridden by environment variables)
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo dev)
BUILD_TIME ?= $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
GIT_COMMIT ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo unknown)
GIT_BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)

# Shared ldflags
LDFLAGS := -X '$(PROJECT)/internal/version.Version=$(VERSION)' \
           -X '$(PROJECT)/internal/version.BuildTime=$(BUILD_TIME)' \
           -X '$(PROJECT)/internal/version.GitCommit=$(GIT_COMMIT)' \
           -X '$(PROJECT)/internal/version.GitBranch=$(GIT_BRANCH)'

# Docker 镜像配置
REGISTRY := registry.cn-shenzhen.aliyuncs.com/greene
IMAGE_NAME := album-backend
NGINX_IMAGE_NAME := album-nginx
ARCH ?= $(shell uname -m | sed 's/x86_64/amd64/; s/aarch64/arm64/')
PLATFORM := linux-$(ARCH)

# 镜像标签
IMAGE_VERSION_TAG := $(REGISTRY)/$(IMAGE_NAME):$(VERSION)-$(ARCH)
IMAGE_LATEST_TAG := $(REGISTRY)/$(IMAGE_NAME):latest-$(ARCH)
NGINX_IMAGE_VERSION_TAG := $(REGISTRY)/$(NGINX_IMAGE_NAME):$(VERSION)-$(ARCH)
NGINX_IMAGE_LATEST_TAG := $(REGISTRY)/$(NGINX_IMAGE_NAME):latest-$(ARCH)

# Docker Compose 命令检测
DOCKER_COMPOSE := $(shell if docker compose version >/dev/null 2>&1; then echo "docker compose"; else echo "docker-compose"; fi)

.PHONY: help all build build-server build-cli clean print-version docker-build docker-build-backend docker-build-nginx docker-push docker-push-backend docker-push-nginx docker-build-base deploy deploy-up deploy-down deploy-logs deploy-ps deploy-init

# 默认目标：显示帮助信息
.DEFAULT_GOAL := help

help: ## 显示此帮助信息
	@echo "Album Backend Makefile"
	@echo ""
	@echo "可用命令:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "示例:"
	@echo "  make build              # 构建 server 和 cli"
	@echo "  make docker-build       # 构建所有 Docker 镜像（backend + nginx）"
	@echo "  make docker-build ARCH=amd64  # 构建指定架构的镜像"
	@echo "  make docker-build-backend  # 仅构建 backend 镜像"
	@echo "  make docker-build-nginx    # 仅构建 nginx 镜像"
	@echo "  make docker-push        # 推送所有镜像到 registry"
	@echo "  make docker-push-backend  # 仅推送 backend 镜像"
	@echo "  make docker-push-nginx    # 仅推送 nginx 镜像"
	@echo "  make deploy             # 部署服务（确保镜像已构建）"
	@echo "  make deploy-up          # 启动服务"
	@echo "  make deploy-down        # 停止服务"
	@echo "  make deploy-logs        # 查看服务日志"
	@echo "  make print-version      # 显示版本信息"
	@echo ""

all: build ## 构建所有目标（server 和 cli）

build: build-server build-cli ## 构建 server 和 cli

build-server: ## 构建 server 二进制文件
	@echo ">> building server (version: $(VERSION))"
	@mkdir -p $(BIN_DIR)
	go build -ldflags "$(LDFLAGS)" -o $(BIN_DIR)/album-server ./cmd/server

build-cli: ## 构建 cli 二进制文件
	@echo ">> building cli (version: $(VERSION))"
	@mkdir -p $(BIN_DIR)
	go build -ldflags "$(LDFLAGS)" -o $(BIN_DIR)/album-cli ./cmd/cli

print-version: ## 显示版本和构建信息
	@echo "Version:    $(VERSION)"
	@echo "BuildTime:  $(BUILD_TIME)"
	@echo "GitCommit:  $(GIT_COMMIT)"
	@echo "GitBranch:  $(GIT_BRANCH)"
	@echo "Arch:       $(ARCH)"
	@echo "Platform:   $(PLATFORM)"

clean: ## 清理构建产物
	@echo ">> removing $(BIN_DIR)/"
	rm -rf $(BIN_DIR)

# Docker 构建目标
docker-build: docker-build-backend docker-build-nginx ## 构建所有 Docker 镜像（backend + nginx）

docker-build-backend: ## 构建 Backend Docker 镜像
	@echo ">> building backend docker image (version: $(VERSION), arch: $(ARCH))"
	@echo ">> Dockerfile: deploy/$(PLATFORM)/Dockerfile"
	@echo ">> Version tag: $(IMAGE_VERSION_TAG)"
	@echo ">> Latest tag: $(IMAGE_LATEST_TAG)"
	docker build \
		-f deploy/$(PLATFORM)/Dockerfile \
		--build-arg VERSION=$(VERSION) \
		--build-arg BUILD_TIME=$(BUILD_TIME) \
		--build-arg GIT_COMMIT=$(GIT_COMMIT) \
		--build-arg GIT_BRANCH=$(GIT_BRANCH) \
		-t $(IMAGE_VERSION_TAG) \
		-t $(IMAGE_LATEST_TAG) \
		.
	@echo ">> backend image built successfully"
	@echo ">>   - $(IMAGE_VERSION_TAG)"
	@echo ">>   - $(IMAGE_LATEST_TAG)"

docker-build-nginx: ## 构建 Nginx Docker 镜像
	@echo ">> building nginx docker image (version: $(VERSION), arch: $(ARCH))"
	@echo ">> Dockerfile: deploy/$(PLATFORM)/Dockerfile.nginx"
	@echo ">> Version tag: $(NGINX_IMAGE_VERSION_TAG)"
	@echo ">> Latest tag: $(NGINX_IMAGE_LATEST_TAG)"
	docker build \
		-f deploy/$(PLATFORM)/Dockerfile.nginx \
		-t $(NGINX_IMAGE_VERSION_TAG) \
		-t $(NGINX_IMAGE_LATEST_TAG) \
		.
	@echo ">> nginx image built successfully"
	@echo ">>   - $(NGINX_IMAGE_VERSION_TAG)"
	@echo ">>   - $(NGINX_IMAGE_LATEST_TAG)"

# Docker 推送目标
docker-push: docker-push-backend docker-push-nginx ## 推送所有 Docker 镜像到 registry

docker-push-backend: ## 推送 Backend Docker 镜像到 registry
	@echo ">> pushing backend docker images to registry"
	docker push $(IMAGE_VERSION_TAG)
	docker push $(IMAGE_LATEST_TAG)
	@echo ">> backend images pushed successfully"
	@echo ">>   - $(IMAGE_VERSION_TAG)"
	@echo ">>   - $(IMAGE_LATEST_TAG)"

docker-push-nginx: ## 推送 Nginx Docker 镜像到 registry
	@echo ">> pushing nginx docker images to registry"
	docker push $(NGINX_IMAGE_VERSION_TAG)
	docker push $(NGINX_IMAGE_LATEST_TAG)
	@echo ">> nginx images pushed successfully"
	@echo ">>   - $(NGINX_IMAGE_VERSION_TAG)"
	@echo ">>   - $(NGINX_IMAGE_LATEST_TAG)"

# Docker 基础镜像构建
docker-build-base: ## 构建基础镜像（用于构建应用镜像）
	@echo ">> building base image for $(PLATFORM)"
	docker build -f deploy/$(PLATFORM)/Dockerfile.base \
		-t $(REGISTRY)/album-base:$(PLATFORM)-latest \
		.
	@echo ">> base image built: $(REGISTRY)/album-base:$(PLATFORM)-latest"

# 部署相关命令
deploy-init: ## 初始化部署环境（创建必要目录）
	@echo ">> initializing deployment environment"
	@if [ ! -d "deploy/data/postgresql" ]; then \
		echo ">> first deployment, running init script..."; \
		bash deploy/init.sh; \
	else \
		echo ">> deployment already initialized"; \
	fi
	@chmod +x deploy/docker-entrypoint.sh 2>/dev/null || true
	@chmod +x deploy/docker-entrypoint-backend.sh 2>/dev/null || true

deploy-up: deploy-init ## 启动服务
	@echo ">> starting services with $(DOCKER_COMPOSE)"
	@echo ">> using image: $(IMAGE_LATEST_TAG)"
	@ALBUM_ARCH=$(ARCH) $(DOCKER_COMPOSE) up -d
	@echo ">> services started"
	@echo ""
	@echo "Service status:"
	@ALBUM_ARCH=$(ARCH) $(DOCKER_COMPOSE) ps
	@echo ""
	@echo "View logs: make deploy-logs"
	@echo "Stop services: make deploy-down"
	@echo "API: http://localhost/api/v1"

deploy-down: ## 停止服务
	@echo ">> stopping services"
	@ALBUM_ARCH=$(ARCH) $(DOCKER_COMPOSE) down
	@echo ">> services stopped"

deploy-logs: ## 查看服务日志（实时跟踪）
	@ALBUM_ARCH=$(ARCH) $(DOCKER_COMPOSE) logs -f

deploy-ps: ## 查看服务状态
	@ALBUM_ARCH=$(ARCH) $(DOCKER_COMPOSE) ps

deploy: docker-build deploy-up ## 部署服务（构建镜像并启动服务）
	@echo ""
	@echo "=========================================="
	@echo "Deployment completed!"
	@echo "=========================================="
