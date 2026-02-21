# Change: 增加后端开发用 Docker Compose 环境

## Why

开发人员当前只能通过构建生产镜像并在生产 compose 中运行来验证后端代码，无法在容器内挂载本地源码、进入 shell 后直接执行 `go run` 或 `make build` 做快速迭代。需要提供一套与生产隔离的开发用 docker-compose，包含全部依赖服务（PostgreSQL、Nginx、Certbot），配置与生产尽量一致，且解决挂载目录权限问题，使 `make terminal` 进入 zsh 后能在项目根目录直接运行应用。

## What Changes

- 新增开发用 compose 文件（如 `backend/docker-compose.dev.yaml`），使用独立项目名（如 `album-dev`）与独立数据目录（如 `backend/deploy/data-dev`），与生产 compose 及 `deploy/data` 完全隔离。
- 开发 compose 包含四类服务：postgresql、album-backend（开发形态）、nginx、certbot；环境变量与卷路径与生产对齐，仅数据根目录改为 `data-dev`，backend 服务使用 base 镜像 + 源码挂载 + 常驻进程。
- 开发用 `album-backend` 服务：基于现有 base 镜像、working_dir `/app`、挂载 `.:/app`，可选 Go module 缓存卷；通过开发专用 entrypoint 在启动时根据 `DEV_UID`/`DEV_GID` 创建用户并 chown `/app`，避免挂载目录权限导致应用无法读写。
- 新增开发入口脚本（如 `backend/deploy/docker-entrypoint-dev.sh`），实现 chown 与 gosu/su-exec 切换用户后执行 `tail -f /dev/null`，供开发 compose 的 album-backend 使用。
- Makefile 新增目标：`dev-up`、`dev-down`、`terminal`（或 `dev-terminal`）、`dev-init`、`dev-logs`、`dev-ps`；`terminal` 通过 `docker compose -f docker-compose.dev.yaml exec -w /app album-backend zsh` 进入容器 zsh，当前目录为项目根目录。
- 开发数据目录初始化脚本或文档：创建 `deploy/data-dev` 下 postgresql、configs、public、cert、certbot-www、logs/nginx 等子目录，供开发 compose 使用。

## Impact

- Affected specs: **backend-dev-environment**（新增 capability）
- Affected code: `backend/docker-compose.dev.yaml`（新文件）、`backend/deploy/docker-entrypoint-dev.sh`（新文件）、`backend/deploy/init-dev.sh` 或等价初始化逻辑（新文件或扩展现有 init）、`backend/Makefile`（新增 dev 相关目标）、可选 `.env.example` 或文档中补充 `UID`/`GID`/`DEV_UID`/`DEV_GID` 说明。
