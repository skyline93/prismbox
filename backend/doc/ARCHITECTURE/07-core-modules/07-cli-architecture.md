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

