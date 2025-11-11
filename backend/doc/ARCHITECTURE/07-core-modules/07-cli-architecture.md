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
    └── main.go             # CLI 入口

internal/
└── cli/
    ├── runtime.go          # 运行模式判断、应用构建（预留）
    ├── remote/
    │   └── client.go       # 远程调用封装（预留）
    ├── output.go           # 输出格式化工具（预留）
    └── errors.go           # 错误处理辅助（预留）

internal/version/
└── version.go              # 版本信息（ldflags 注入）
```

> 当前实现首先提供本地版本命令；随着功能扩展，可逐步补齐 `internal/cli` 下的工具代码。

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

- `local`：直接加载配置并构建 `app.App`，调用本地依赖。
- `remote`：通过 `internal/cli/remote.Client` 调用 API（未来扩展）。
- `auto`：优先 Unix Socket，其次 HTTP，否则退回本地模式（具体逻辑由 `internal/cli/runtime` 负责）。

每个命令通过 `commandProfile` 描述对模式的要求，执行前统一校验，确保用户得到明确提示。

## 7.11.4 命令划分

命令按功能域组织，典型结构：

- `album server`：服务启停、状态查看（本地/远程）。
- `album db`：数据库迁移、状态检查（主要本地）。
- `album tasks`：任务队列运行与调度（本地/远程）。
- `album media`：媒体上传、批量处理、重新生成（远程）。
- `album storage`：主/次存储、备份调度、缓存管理（远程）。
- `album version`：版本信息（本地优先，可回退远程）。

新增命令时，在 `internal/cli` 下创建对应实现文件，注册到入口即可。

## 7.11.5 远程访问约定

- 默认通过 Unix Socket 调用专用 REST API（建议挂载在 `/api/v1/admin/*`）。
- 提供 HTTP 回退能力，支持 TLS 与 Token 认证（由 `internal/cli/remote.Client` 统一处理）。
- 远程接口响应沿用 `api.ApiResponse`，便于前后端一致处理。

远程模式的缓存管理、存储操作、媒体上传等命令在未来迭代中添加。

## 7.11.6 本地版本命令实现

当前实现包含 `album version` 命令，直接读取 `internal/version` 包，输出构建时注入的版本信息。支持 `--json` Flag 返回结构化数据，易于自动化脚本使用。

`internal/version/version.go` 提供：

- 可通过 `-ldflags` 注入的变量（`Version`、`BuildTime`、`GitCommit`、`GitBranch`）。
- `version.Get()` 获取版本结构体。
- `version.MarshalJSON()` 输出格式化 JSON。

命令在远程模式下会提示用户切换到 `local/auto`，确保信息来源一致。

## 7.11.7 后续规划

- 完成远程客户端与认证封装，落地存储/缓存/媒体管理命令。
- 增加统一的输出与错误处理工具，支持表格展示与机器可读模式。
- 根据需要拆分命令包，编写单元测试与端到端测试，纳入 CI。

CLI 与现有服务共同演进，为运维、调试、自动化脚本提供统一入口。

