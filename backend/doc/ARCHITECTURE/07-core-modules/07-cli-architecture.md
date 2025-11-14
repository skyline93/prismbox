# 7.11 命令行架构设计

## 7.11.1 概述

命令行工具（CLI）是 Album Backend 的辅助运维入口，兼容本地运维和远程管理场景。CLI 采用 `github.com/urfave/cli/v2` 构建，沿用主工程的配置、依赖注入与日志体系，提供一致的使用体验。

### 设计目标

- **双模式运行**：支持本地模式（直接调用内部组件）与远程模式（通过 Unix Socket / HTTP 调用 API）。
- **模块化扩展**：命令按照功能域拆分，便于增量扩展。
- **一致的配置体验**：复用 `configs/config.yaml` 与环境变量覆盖机制。
- **结构化输出**：统一输出 JSON/表格，便于自动化脚本集成。

## 7.11.2 目录结构

```
cmd/
└── cli/
    ├── main.go             # CLI 入口
    ├── upload.go           # 上传命令实现
    └── media.go            # 媒体运维命令实现

internal/
└── cli/
    ├── media/
    │   ├── options.go      # 上传选项与任务解析
    │   └── uploader.go     # 上传逻辑（单文件/批量、进度条、并发控制）
    └── remote/
        └── client.go       # 远程调用封装（HTTP/Unix Socket、认证、上传接口）

internal/version/
└── version.go              # 版本信息（ldflags 注入）
```

> 当前实现已包含上传命令与远程客户端；媒体运维命令（list/info）为占位实现，待后续扩展。

## 7.11.3 全局选项与运行模式

CLI 入口在 `cmd/cli/main.go` 中注册全局 Flag：

| Flag | 默认值 | 作用 |
| ---- | ------ | ---- |
| `--config, -c` | `configs/config.yaml` | 指定配置文件路径。 |
| `--env-prefix` | `ALBUM_` | 覆盖配置的环境变量前缀。 |
| `--mode` | `auto` | 运行模式：`auto`（自动判断）、`local`（仅本地）、`remote`（仅远程）。 |
| `--socket-path` | `""` | 远程模式的 Unix Socket 路径。 |
| `--base-url` | `""` | 远程模式的 HTTP BaseURL。 |

`mode` Flag 确定命令执行方式：

- `local`：直接加载配置并构建 `app.App`，调用本地依赖（当前仅 `version` 命令支持）。
- `remote`：通过 `internal/cli/remote.Client` 调用 API（当前 `upload` 和 `media` 命令使用）。
- `auto`：优先 Unix Socket，其次 HTTP，否则退回本地模式（具体逻辑由 `internal/cli/runtime` 负责，待实现）。

每个命令通过 `commandProfile` 描述对模式的要求，执行前统一校验，确保用户得到明确提示。

## 7.11.4 命令划分

命令采用**核心命令扁平化 + 插件式命名空间**的组合设计：

### 核心命令（扁平化）

- `album upload`：媒体文件上传（支持单文件/批量，远程模式）。
  - 单文件：`album upload --file <path>`
  - 批量目录：`album upload --dir <directory>`
  - 批量清单：`album upload --manifest <manifest.json>`
  - 通过 Flag 控制模式，无需子命令层级。

- `album version`：版本信息（本地模式）。

### 插件式命名空间（扩展性）

- `album media`：媒体运维命令命名空间（远程模式）。
  - `album media list`：列出媒体资源（开发中）。
  - `album media info <uuid>`：查看媒体详情（开发中）。
  - 未来可扩展：`delete`、`retry`、`transfer` 等。

### 未来规划

- `album server`：服务启停、状态查看（本地/远程）。
- `album db`：数据库迁移、状态检查（主要本地）。
- `album tasks`：任务队列运行与调度（本地/远程）。
- `album storage`：主/次存储、备份调度、缓存管理（远程）。

新增命令时，在 `internal/cli` 下创建对应实现文件，注册到入口即可。

## 7.11.5 远程访问约定

- 默认通过 Unix Socket 调用 REST API（`/api/v1/*`），支持 HTTP 回退（通过 `--base-url` 指定）。
- 认证方式：使用邮箱密码登录（`--email` / `--password`），CLI 自动调用 `/api/v1/auth/login` 获取访问令牌。
  - 密码建议通过环境变量 `ALBUM_CLI_PASSWORD` 提供，避免在命令行暴露。
- 远程接口响应沿用 `api.ApiResponse`，便于前后端一致处理。
- `internal/cli/remote.Client` 封装 HTTP/Unix Socket 调用、认证流程与错误处理。

远程模式的缓存管理、存储操作等命令在未来迭代中添加。

## 7.11.6 上传命令实现

### 命令参数

`album upload` 支持以下 Flag：

| Flag | 说明 | 默认值 |
| ---- | ---- | ------ |
| `--file` | 上传单个文件路径 | - |
| `--dir` | 批量上传目录（递归扫描） | - |
| `--manifest` | 批量上传清单文件（JSON/YAML） | - |
| `--concurrency` | 批量上传并发数 | 4 |
| `--on-error` | 错误处理策略：`skip`（继续）或 `stop`（停止） | `skip` |
| `--email` | 登录邮箱（必填，支持 `ALBUM_CLI_EMAIL` 环境变量） | - |
| `--password` | 登录密码（必填，支持 `ALBUM_CLI_PASSWORD` 环境变量） | - |
| `--json` | JSON 格式输出 | `false` |
| `--quiet` | 安静模式，不显示进度条 | `false` |
| `--dry-run` | 仅校验任务，不实际上传 | `false` |
| `--timeout` | 接口超时时间 | `2m` |

`--file`、`--dir`、`--manifest` 互斥，必须且仅能指定其中一个。

### 自动参数推断

为简化使用，以下参数自动从文件获取或生成，无需手动指定：

- **`item-type`**：根据文件扩展名自动推断（`image` / `video`）。
- **`cloud-uuid`**：自动生成 UUID（如未在 manifest 中指定）。
- **`capture-at`**：默认使用文件修改时间（如未在 manifest 中指定）。
- **`hash`**：自动计算文件 SHA256 哈希值。

Manifest 文件可覆盖上述自动推断值，格式示例：

```json
[
  {
    "file_path": "/path/to/image.jpg",
    "item_type": "image",
    "cloud_uuid": "custom-uuid-optional",
    "capture_at": "2024-01-01T12:00:00Z"
  }
]
```

### 进度条与并发控制

- **单文件上传**：显示字节级进度条（使用 `github.com/schollz/progressbar/v3`）。
- **批量上传**：显示总体进度条（文件数/总字节数），支持并发控制。
- **并发执行**：使用 worker 池模式，通过 `--concurrency` 控制并发数。
- **错误处理**：`--on-error=skip` 时跳过错误继续上传，`stop` 时遇到错误立即停止。

### 实现位置

- `cmd/cli/upload.go`：命令入口与参数解析。
- `internal/cli/media/uploader.go`：上传逻辑（单文件/批量、进度条、并发控制）。
- `internal/cli/media/options.go`：选项定义、任务解析（目录扫描、manifest 解析）。
- `internal/cli/remote/client.go`：远程调用封装（登录、上传接口调用）。

## 7.11.7 本地版本命令实现

当前实现包含 `album version` 命令，直接读取 `internal/version` 包，输出构建时注入的版本信息。支持 `--json` Flag 返回结构化数据，易于自动化脚本使用。

`internal/version/version.go` 提供：

- 可通过 `-ldflags` 注入的变量（`Version`、`BuildTime`、`GitCommit`、`GitBranch`）。
- `version.Get()` 获取版本结构体。
- `version.MarshalJSON()` 输出格式化 JSON。

命令在远程模式下会提示用户切换到 `local/auto`，确保信息来源一致。

## 7.11.8 后续规划

- 完成 `album media list` 和 `album media info` 命令实现，对接后端 API。
- 增加统一的输出与错误处理工具，支持表格展示与机器可读模式。
- 实现 `album server`、`album db`、`album tasks`、`album storage` 等运维命令。
- 根据需要拆分命令包，编写单元测试与端到端测试，纳入 CI。
- 支持本地模式回退（当远程不可用时，直接调用本地 Service 层）。

CLI 与现有服务共同演进，为运维、调试、自动化脚本提供统一入口。

## 7.11.9 存储管理命令（`album storage`）

> 目标：为主/次存储池提供可观测、可控、可操作的 CLI 入口，覆盖常见运维场景（查看、扩展、禁用、刷新、对账、容量比对、迁移预案）。

### 命令树

```
album storage
└── pool
    ├── list                      # 列出存储池
    ├── info <uuid>               # 查看单个存储池详情
    ├── add                       # 新增存储池
    ├── update <uuid>             # 更新存储池配置
    ├── enable <uuid>             # 启用写入
    ├── disable <uuid>            # 禁用写入（维护/退役）
    ├── refresh                   # 触发 PoolManager 缓存刷新
    ├── reconcile                 # 触发一次对账（扫描磁盘）
    └── usage                     # 查看容量对比（DB vs 实际）
```

所有子命令默认要求 **远程模式**，通过 REST API 调用后台；若未来提供本地模式，可在 `commandProfile` 中调整。

### 统一 Flags

所有需要鉴权的子命令共享以下 Flags（与 `album upload` 一致）：

| Flag | 说明 |
| ---- | ---- |
| `--email`, `--password` | 管理员账号，支持 `ALBUM_CLI_EMAIL` / `ALBUM_CLI_PASSWORD` 环境变量 |
| `--timeout` | 请求超时，默认 `2m` |
| `--json` | JSON 格式输出 |
| `--base-url` / `--socket-path` | 复用 CLI 全局 Flag，决定远程调用方式 |

### 各子命令行为

1. **`pool list`**
   - Flags：`--type`（local/s3/...）、`--status`（active/disabled/...）
   - 输出：表格列示 `UUID/Name/Type/Enabled/Status/Usage%/Priority/LastCheckedAt`，或 JSON。
   - API：`GET /api/v1/storage/pools?storage_type=&status=`

2. **`pool info <uuid>`**
   - 返回单个存储池详情，包括 `cloud_config` 摘要、当前容量、状态、描述、最近对账时间等。
   - API：`GET /api/v1/storage/pools/{uuid}`

3. **`pool add`**
   - Flags：
     - `--name`（必填）、`--type`（必填）
     - `--local-path`（type=local 必填）
     - `--cloud-config`（JSON 字符串或 `@path/to/file.json`）
     - `--max-size`（支持 `500GB/1TB` 等写法）
     - `--priority`, `--auto-disable-threshold`, `--enabled`, `--description`
   - API：`POST /api/v1/storage/pools`
   - 成功后提示立即执行 `pool refresh` 以让在线实例感知变更。

4. **`pool update <uuid>`**
   - Flags 与 `add` 相同但全部可选；CLI 仅发送被修改的字段。
   - 支持修改描述、容量、阈值、优先级、路径/云配置等。
   - API：`PATCH /api/v1/storage/pools/{uuid}`

5. **`pool enable/disable <uuid>`**
   - 用于临时维护或恢复写入。
   - API：`POST /api/v1/storage/pools/{uuid}/enable` / `.../disable`
   - CLI 会提示操作 ID 并建议刷新缓存。

6. **`pool refresh`**
   - Flags：`--node`（指定节点，默认广播），`--async`
   - API：`POST /api/v1/storage/pools/refresh`
   - 后端负责唤醒各实例执行 `PoolManager.InvalidateCache`。

7. **`pool reconcile`**
   - Flags：`--pool <uuid>`（缺省全量）、`--dry-run`、`--parallel`
   - API：`POST /api/v1/storage/pools/reconcile`
   - 后端以 Job 形式串行执行，CLI 可获取任务 ID 与结果。

8. **`pool usage`**
   - 展示数据库记录容量与实际扫描（或 PoolManager 缓存）之间的偏差：`UUID | DB Size | Actual Size | Drift% | CheckedAt`
   - API：`GET /api/v1/storage/pools/usage`

### 输出规范

- 默认使用 `text/tabwriter` 以表格方式展示。
- `--json` 时输出结构化数据，方便脚本集成。
- 所有命令统一错误格式：明确 HTTP 状态码 / API message。

### 后端配合

- 需要实现对应 REST API（已在 `internal/api/v1/storage` 落地），复用 Service/Repository。
- 关键操作（disable/reconcile/add/update）需鉴权并记录审计日志。
- 若命令在本地模式运行，可直接通过 `Builder` 构建 app 后调用 Service 层；文档先按远程方案实现。

## 7.11.10 首次部署初始化命令（`album init *`）

> 目标：当主服务尚未启动时，为运维人员提供本地初始化工具，完成配置生成、基础资源（存储池、管理员账户）创建，确保服务可顺利拉起。全部命令运行在 **local 模式**，直接加载配置和数据库，不依赖 HTTP/Unix Socket。

### 使用场景

1. 全新部署：数据库为空，需要一次性准备配置/存储池/管理员。
2. 服务启动失败，日志提示 “no enabled storage pools for type local” 或缺少管理员登录。
3. 容器化/自动化场景中，通过 Init Job 一次性完成基础准备。

### 典型流程

```
album --config configs/config.yaml init config --storage-path /data/storage1
album --config configs/config.yaml init migrate
album --config configs/config.yaml init storage --local-path /data/storage1 --max-size 1TB
album --config configs/config.yaml init admin --email you@example.com --password 'StrongPass' --reset-password
```

### 配置文件初始化（`album init config`）

- 功能：当配置文件不存在时，基于默认模板写入一份可直接使用的 `config.yaml`，并自动生成 JWT / URL 签名密钥。可通过 Flag 覆盖数据库、Server、存储路径等关键字段。
- 常用 Flags：

| Flag | 说明 | 默认值 |
| ---- | ---- | ------ |
| `--force` | 已存在配置时仍然覆盖 | `false` |
| `--db-type` | 数据库类型（`sqlite`/`postgres`） | 模板默认 |
| `--database-dsn` | 数据库 DSN | 模板默认 |
| `--server-host` / `--server-port` | 服务监听地址/端口 | 模板默认 |
| `--public-base-url` | 对外访问地址 | 模板默认 |
| `--storage-path` | `storage.primary.local.base_path` | `./uploads` |
| `--temp-path` | 临时文件目录 | `./data` |
| `--jwt-secret` | 自定义 JWT 密钥（留空则自动生成） | - |
| `--url-signer-secret` | 自定义 URL 签名密钥（留空则自动生成） | - |

命令输出包含最终写入路径，并支持 `--json`。

### 数据库迁移（`album init migrate`）

- 功能：加载配置并直接对目标数据库执行 GORM 自动迁移（业务表 + `pkg/gq` 任务表），等效于应用启动时的 `AutoMigrate`。
- 无额外 Flags，仅提供 `--json`；执行成功后输出“数据库迁移完成”或 JSON 状态。
- 适用于新环境建库、升级版本后的结构同步，避免必须先启动主服务。

### 存储池初始化（`album init storage`）

- 功能：向 `storage_pools` 表写入首个 `local` 存储池，供主服务启动时使用。
- 常用 Flags：与之前一致（`--name`、`--local-path`、`--max-size`、`--force` 等），详见命令帮助。
- 执行步骤：
  1. 加载 `--config`；
  2. 连接数据库并检查现有存储池；
  3. 在无记录或 `--force` 场景下创建存储池；
  4. 输出结构化信息（支持 `--json`）。
- 完成后若主服务已运行，可执行 `album storage pool refresh` 让各实例即时加载。

### 管理员账户初始化（`album init admin`）

- 功能：绕过 HTTP API，直接访问数据库，创建或重置管理员账户，以便后续远程 CLI 登录。
- 常用 Flags：

| Flag | 说明 | 默认值 |
| ---- | ---- | ------ |
| `--email` | 管理员邮箱（Env: `ALBUM_INIT_ADMIN_EMAIL`） | - |
| `--password` | 管理员密码（Env: `ALBUM_INIT_ADMIN_PASSWORD`） | - |
| `--username` | 用户名（缺省取邮箱前缀） | `邮箱前缀` |
| `--reset-password` | 邮箱已存在时执行密码重置 | `false` |
| `--json` | JSON 输出 | `false` |

命令会对密码执行 bcrypt 加密，并在需要时更新用户名。

### 容器化自动化脚本

`backend/scripts/init-container.sh` 封装了完整初始化流程，可在 Kubernetes Init Container 或任意 CI/CD 步骤中执行：

1. `album init config`：根据挂载路径生成/覆盖配置；
2. `album init migrate`：确保数据库结构与当前版本一致；
3. `album init storage --force`：注册宿主机/卷的本地存储池；
4. `album init admin --reset-password`：确保管理员凭据与容器环境变量一致。

核心环境变量：

| 变量 | 说明 | 默认值 |
| ---- | ---- | ------ |
| `CLI_BIN` | CLI 可执行文件路径 | `album` |
| `CONFIG_PATH` | 配置文件写入路径 | `/data/configs/config.yaml` |
| `STORAGE_PATH` | 主存储挂载路径 | `/data/storage` |
| `MAX_SIZE` | 存储池容量 | `1TB` |
| `ADMIN_EMAIL` / `ADMIN_PASSWORD` / `ADMIN_USERNAME` | 管理员凭据 | - / - / `admin` |
| `INIT_FORCE` | 是否强制覆盖配置 | `true` |

脚本默认 `set -euo pipefail`，若任一步骤失败会立即退出，适合自动化部署。

### 最佳实践

1. 运行 `album init config` 生成配置文件，并根据环境需求调整 DSN、路径等；
2. 执行 `album init migrate`，确保数据库结构与当前版本对齐；
3. 确保数据库和存储卷已就绪，再执行 `album init storage`；
4. 使用 `album init admin` 写入（或重置）管理员账号；
5. 在容器/自动化场景中，可直接运行 `scripts/init-container.sh` 串联全部操作；
6. 启动主服务；若需更多存储池，可使用 `album storage pool add` 或后台管理界面。

