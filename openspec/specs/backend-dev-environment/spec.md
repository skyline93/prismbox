# backend-dev-environment Specification

## Purpose
TBD - created by archiving change add-backend-dev-docker-compose. Update Purpose after archive.
## Requirements
### Requirement: 开发 Compose 与生产隔离

后端 SHALL 提供独立的开发用 Docker Compose 配置，与生产 Compose 在项目名、数据目录与容器命名上完全隔离，使开发与生产环境可分别启动、互不影响、不冲突。

#### Scenario: 项目名与数据目录隔离
- **WHEN** 使用开发 compose 启动（如 `docker compose -f docker-compose.dev.yaml up -d`）
- **THEN** Compose 项目名 SHALL 为独立值（如 `album-dev`），与生产所用项目名或默认项目名不同
- **AND** 开发用数据（PostgreSQL、配置、证书、日志等）SHALL 存放在独立目录（如 `backend/deploy/data-dev`），与生产数据目录（如 `backend/data`）分离
- **AND** 开发 compose 中服务 SHALL 不设置固定 container_name，由 Compose 按项目名生成容器名，避免与生产容器名冲突

#### Scenario: 开发与生产可分别启停
- **WHEN** 生产 compose 与开发 compose 均存在且未修改
- **THEN** 启动开发 compose  SHALL NOT 依赖或影响生产 compose 的容器、网络或卷
- **AND** 停止开发 compose SHALL NOT 停止或删除生产 compose 的资源

### Requirement: 开发 Compose 包含全部依赖服务

开发用 Docker Compose SHALL 包含与生产一致的依赖服务集合：PostgreSQL、Nginx、Certbot（可选 profile），以及后端应用服务（开发形态），以便在开发环境中完整验证与生产一致的服务拓扑与配置。

#### Scenario: 四类服务均可在开发 compose 中定义
- **WHEN** 查阅开发 compose 文件
- **THEN** 存在 postgresql、album-backend（开发形态）、nginx 服务定义
- **AND** 存在 certbot 服务定义，且通过 profiles（如 `https`）控制是否启动，与生产行为一致
- **AND** nginx 的 upstream 指向 album-backend 服务名（与生产一致，如 `album-backend:8080`）

#### Scenario: 配置与生产对齐
- **WHEN** 比较开发 compose 与生产 compose 中同名服务的环境变量与卷路径结构
- **THEN** 开发 compose 中 postgresql、nginx、certbot 的环境变量及卷路径语义 SHALL 与生产一致
- **AND** 仅数据根路径 SHALL 从生产目录（如 `data`）改为开发目录（如 `deploy/data-dev`）

### Requirement: 开发后端服务挂载源码并常驻

开发 compose 中的 album-backend 服务 SHALL 使用现有 base 镜像（含 Go、工具链与 zsh），将宿主机后端项目根目录挂载到容器内固定工作目录（如 `/app`），并以常驻进程（如 `tail -f /dev/null`）保持容器运行，以便开发者通过 `exec` 进入容器后在项目根目录执行 `go run` 或 `make build`，无需重新构建应用镜像。

#### Scenario: 工作目录与挂载一致
- **WHEN** 开发 compose 中 album-backend 服务已定义
- **THEN** working_dir SHALL 为挂载后的项目根（如 `/app`）
- **AND** volumes SHALL 包含宿主机当前后端根目录到该路径的挂载（如 `.:/app`）
- **AND** 服务 SHALL 不直接启动应用进程，而启动常驻命令（如 `tail -f /dev/null`），以便 `docker compose exec` 进入

#### Scenario: exec 进入后可直接运行 Go
- **WHEN** 开发者执行约定命令（如 `make terminal`）进入 album-backend 容器
- **THEN** 进入的 shell SHALL 为 zsh
- **AND** 当前工作目录 SHALL 为容器内项目根（如 `/app`）
- **AND** 在未修改代码的前提下，执行 `go run ./cmd/server` 或等价命令 SHALL 能启动应用（在依赖与配置已就绪的前提下）

### Requirement: 开发挂载目录权限可写

开发 compose 中 album-backend 服务 SHALL 通过开发专用 entrypoint 与宿主 UID/GID 传入（如 DEV_UID/DEV_GID），在容器启动时对挂载的项目根目录（及开发数据目录）执行 chown，并以该用户运行常驻进程，确保容器内对挂载目录具有读写权限，避免因权限导致应用或工具（如 go run、生成配置）失败。

#### Scenario: entrypoint 根据 DEV_UID/DEV_GID 修正权限
- **WHEN** 开发 compose 中 album-backend 配置了开发 entrypoint 且传入 DEV_UID/DEV_GID（如从 host UID/GID 读取）
- **THEN** entrypoint SHALL 在容器内创建或确认对应用户/组后，对挂载的项目根（如 `/app`）执行 chown
- **AND** 常驻进程（如 tail -f /dev/null）SHALL 以该 UID/GID 运行
- **AND** 开发者通过 `make terminal` 进入后，在该目录下执行 `go run` 或写入文件 SHALL 不因权限错误失败（在文件系统与挂载正常的前提下）

#### Scenario: 开发数据目录可写
- **WHEN** 应用在开发容器内将配置或运行时数据写入开发数据目录（如 `/app/deploy/data-dev`）
- **THEN** entrypoint 或挂载方式 SHALL 保证该目录在容器内对运行用户可写
- **AND** 生成的配置文件或日志 SHALL 可被应用正常读取与更新

### Requirement: 开发环境入口与文档

后端 SHALL 提供 Makefile 目标与文档，使开发者能通过 `dev-init`、`dev-up`、`terminal`（或 `dev-terminal`）等步骤启动开发环境并进入容器；文档 SHALL 说明开发数据目录结构、首次初始化（如 go mod download、配置生成）及与生产 compose 的隔离关系。

#### Scenario: Make 目标可用
- **WHEN** 开发者在 backend 根目录执行 `make dev-up`（或等价目标）
- **THEN** 开发 compose 定义的服务 SHALL 被启动
- **AND** 执行 `make terminal`（或 `dev-terminal`）SHALL 进入 album-backend 容器的 zsh，且工作目录为项目根
- **AND** 存在 `make dev-down`、`dev-logs`、`dev-ps` 等目标以便停止与观察开发环境

#### Scenario: 开发数据目录可初始化
- **WHEN** 开发者首次使用开发 compose 或执行 `make dev-init`（或等价）
- **THEN** 开发数据根目录（如 `deploy/data-dev`）下 SHALL 存在与生产数据目录结构一致的必要子目录（如 postgresql、configs、public、cert、certbot-www、logs/nginx）
- **AND** 文档或脚本 SHALL 说明如何生成首次配置（如 CLI init config）及可选环境变量（UID/GID 或 DEV_UID/DEV_GID）

