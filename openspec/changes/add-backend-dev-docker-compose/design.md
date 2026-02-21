# Design: 后端开发 Docker Compose 环境

## Context

- 生产环境使用 `backend/docker-compose.yaml`，服务包括 postgresql、album-backend（多阶段构建的应用镜像）、nginx、certbot；数据与配置在 `deploy/data`。
- 现有 base 镜像（`Dockerfile.base`）已包含 Go、ImageMagick、ffmpeg、zsh、delve，且 `CMD ["tail", "-f", "/dev/null"]`，适合作为开发容器基础；应用镜像是多阶段构建结果，无源码与 Go 工具链，无法在容器内 `go run`。
- 开发需在容器内挂载宿主机 backend 根目录，并保证该目录在容器内可写，以便 `go run`、生成配置与日志等不因权限失败；不同宿主（Linux UID 1000、macOS 501 等）需统一处理。

## Goals / Non-Goals

- **Goals**：提供与生产隔离的开发 compose；包含 postgresql、nginx、certbot、album-backend（开发形态）；配置与生产一致；`make terminal` 进入 zsh 且工作目录为项目根，可执行 `go run ./cmd/server`；挂载目录权限正确，应用可读写。
- **Non-Goals**：不修改生产 compose 或生产镜像构建流程；不要求支持与生产同时同机运行（端口可另行约定）；不实现 IDE 远程调试集成（仅预留 delve 环境）。

## Decisions

### 1. 隔离方式

- **Compose 项目名**：开发 compose 顶层设置 `name: album-dev`，所有资源归属该项目，与默认/生产项目分离。
- **数据目录**：开发使用 `./deploy/data-dev` 作为数据根，与生产 `./deploy/data` 分离，避免混用或误删生产数据。
- **容器名**：开发 compose 中不设置 `container_name`，由 Compose 生成带项目前缀的名称（如 `album-dev-album-backend-1`），避免与生产固定容器名冲突。

### 2. 开发 backend 服务形态

- **镜像**：使用现有 base 镜像（如 `registry.cn-shenzhen.aliyuncs.com/greene/album-base:linux-amd64-latest`），不引入新镜像类型。
- **挂载**：`.:/app`，working_dir `/app`，使容器内当前目录即项目根。
- **进程**：保持 `tail -f /dev/null`，由开发 entrypoint 在完成 chown 后以目标用户执行，容器常驻以便 `exec`。
- **服务名**：保持 `album-backend`，以便 nginx 的 `proxy_pass http://album-backend:8080` 与生产一致，无需改 nginx 配置。

### 3. 挂载目录权限

- **方案**：采用「开发 entrypoint + DEV_UID/DEV_GID」：容器启动时以 root（或 base 默认用户）执行 entrypoint；entrypoint 读取 `DEV_UID`/`DEV_GID`（由 compose 从 host `UID`/`GID` 传入），在容器内创建对应用户/组（若不存在），对 `/app`（及可选 `/app/deploy/data-dev`）执行 `chown -R`，再用 gosu/su-exec 以该用户执行 `tail -f /dev/null`。
- **Alternatives considered**：仅设置 `user: "${UID}:${GID}"` 需镜像内已存在该 UID/GID，Mac 常见 501:20 与 base 默认 1000 不一致；在镜像构建时传入 host UID/GID 会导致每位开发者构建自己的镜像，不利于统一；故选用运行时 entrypoint 动态 chown。

### 4. Nginx / Certbot 与生产一致

- 开发 compose 中 nginx、certbot 的镜像、环境变量、volume 路径结构与生产一致，仅将挂载路径从 `./deploy/data/...` 改为 `./deploy/data-dev/...`；certbot 仍使用 `profiles: [https]`。

### 5. 端口（可选）

- 若需与生产同机并存：开发 nginx 可使用不同宿主机端口（如 18080、18443）；否则可与生产相同（80、443），依赖项目名与数据目录隔离。

## Risks / Trade-offs

- **Entrypoint 依赖挂载**：entrypoint 脚本位于源码 `deploy/docker-entrypoint-dev.sh`，通过 `.:/app` 挂载后可在容器内以 `/app/deploy/docker-entrypoint-dev.sh` 执行；若挂载顺序或权限导致脚本不可执行，需在 entrypoint 中加 fallback（如用 `bash /app/deploy/docker-entrypoint-dev.sh`）。
- **Base 镜像无 gosu**：若 base 镜像未安装 gosu，需在 entrypoint 中安装或改用 su-exec；或约定开发用 base 镜像增加 gosu 安装。

## Migration Plan

- 无生产数据迁移；开发为新增文件与 Make 目标，不影响现有 `docker-compose.yaml` 或 `deploy-up`/`deploy-down`。
- 回滚：删除 `docker-compose.dev.yaml`、`docker-entrypoint-dev.sh`、Make 中 dev 目标及 `deploy/data-dev` 即可。

## Open Questions

- 无；若后续需支持 ARM64 开发机，可补充 `album-base:linux-arm64-latest` 的选用说明与 Make 变量。
