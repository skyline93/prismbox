# Tasks: add-backend-dev-docker-compose

## 1. 开发数据目录与初始化

- [x] 1.1 新增 `backend/deploy/init-dev.sh`（或等价脚本），创建 `deploy/data-dev` 下子目录：`postgresql`、`configs`、`public`、`cert`、`certbot-www/.well-known/acme-challenge`、`logs/nginx`，并设置合理权限（如 chmod 755）。
- [x] 1.2 在 `backend/README.md` 或单独开发文档中补充开发环境说明：使用 `make dev-init`、`make dev-up`、`make terminal` 的步骤，以及 `UID`/`GID`（或 `DEV_UID`/`DEV_GID`）环境变量说明（用于挂载权限）。

## 2. 开发 Entrypoint 脚本

- [x] 2.1 新增 `backend/deploy/docker-entrypoint-dev.sh`：可执行、shebang `#!/usr/bin/env bash`；若存在 `DEV_UID`/`DEV_GID`，则创建对应 group/user（若不存在），对 `/app` 执行 `chown -R $DEV_UID:$DEV_GID`，可选对 `/app/deploy/data-dev` 同样 chown；使用 gosu 或 su-exec 以该 UID:GID 执行传入的 command（默认 `tail -f /dev/null`）；若 base 镜像无 gosu，在脚本中安装或使用 su-exec。
- [x] 2.2 确保脚本在仓库中可执行（chmod +x），并在 CI 或 Makefile 中不破坏可执行位。

## 3. 开发 Compose 文件

- [x] 3.1 新增 `backend/docker-compose.dev.yaml`：顶层 `name: album-dev`，`version: '3.8'`；定义 networks `album-network`。
- [x] 3.2 添加服务 `postgresql`：与生产相同的 image、environment、healthcheck；volumes 使用 `./deploy/data-dev/postgresql:/var/lib/postgresql/data` 及 locale/timezone 只读；不设 container_name；networks 为 album-network。
- [x] 3.3 添加服务 `album-backend`：image 为现有 base 镜像；working_dir `/app`；volumes `.:/app`，可选 `go-mod-dev:/home/app/go/pkg/mod`，以及 `./deploy/data-dev` 挂载到 `/app/deploy/data-dev`（或仅挂载子目录以与 ALBUM_CONFIG_PATH 一致）；environment 与生产 album-backend 一致，仅 ALBUM_CONFIG_PATH、ALBUM_STORAGE_PRIMARY_LOCAL_BASE_PATH、ALBUM_AUTH_AVATAR_SAVE_PATH 指向 `/app/deploy/data-dev` 下路径；env 中传入 DEV_UID/DEV_GID（从 UID/GID 读取）；entrypoint 指向 `/app/deploy/docker-entrypoint-dev.sh`；command 为 `["tail", "-f", "/dev/null"]`；depends_on postgresql condition service_healthy；expose 或 ports 8080；networks album-network；不设 container_name。
- [x] 3.4 添加服务 `nginx`：与生产相同 image 与 environment；volumes 使用 `./deploy/data-dev/cert`、`./deploy/data-dev/certbot-www`、`./deploy/data-dev/logs/nginx`；depends_on album-backend；ports 可与生产一致或使用 18080/18443 以同机并存；networks album-network；不设 container_name。
- [x] 3.5 添加服务 `certbot`：与生产相同 image 与 entrypoint；volumes 使用 `./deploy/data-dev/cert`、`./deploy/data-dev/certbot-www`；profiles `[https]`；networks album-network；不设 container_name。
- [x] 3.6 若使用 Go 缓存卷，在 compose 中声明 volumes `go-mod-dev`。

## 4. Makefile 目标

- [x] 4.1 新增目标 `dev-init`：调用 `deploy/init-dev.sh` 或等价逻辑创建 `deploy/data-dev` 目录结构。
- [x] 4.2 新增目标 `dev-up`：执行 `docker compose -f docker-compose.dev.yaml up -d`（可选在 up 前调用 dev-init）。
- [x] 4.3 新增目标 `dev-down`：执行 `docker compose -f docker-compose.dev.yaml down`。
- [x] 4.4 新增目标 `terminal`（或 `dev-terminal`）：执行 `docker compose -f docker-compose.dev.yaml exec -w /app album-backend zsh`；可选支持 `-u "${UID:-1000}:${GID:-1000}"` 以与 host 用户一致（若 entrypoint 已切换为该用户则可省略）。
- [x] 4.5 新增目标 `dev-logs`、`dev-ps`：分别执行 logs -f 与 ps，使用 `docker-compose.dev.yaml`。
- [x] 4.6 在 `make help` 或注释中列出上述 dev 目标及简要说明。

## 5. 校验与文档

- [x] 5.1 确保 `openspec validate add-backend-dev-docker-compose --strict` 通过。
- [x] 5.2 更新 `backend/README.md`（或 doc）中「本地开发」章节：说明开发 compose 与生产隔离、依赖服务、`make dev-up` 与 `make terminal` 后可在容器内执行 `go run ./cmd/server`，以及首次初始化（如 go mod download、config init）的简要步骤。
