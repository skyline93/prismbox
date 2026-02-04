# Change: 修复后端 PublicBaseURL 配置优先级

## Why

后端通过 Viper 加载配置时，文档与注释声明的优先级为「命令行参数 > 环境变量 > 配置文件 > 默认值」，但 `PublicBaseURL` 实际未优先使用 `config.yaml` 或环境变量，导致部署时在配置文件或环境中设置的公共基础 URL 不生效。根因有两类：（1）Viper 的 Unmarshal 使用 mapstructure，仅根据 `mapstructure` tag 或字段名解析键，当前 `server.Config` 仅使用 `yaml` tag，键名与配置文件/环境变量中的 `public_base_url` 不一致，导致该字段未被合并；（2）通过 BindPFlags 绑定的 flag 默认值为空字符串时，Viper 会以该空值覆盖配置文件与环境变量。

## What Changes

- 为 Viper Unmarshal 所涉后端配置结构体（如 `server.Config` 及同层/嵌套中受影响的类型）**统一**补充 `mapstructure` tag，使键与配置文件、环境变量一致（如 `public_base_url`、`read_timeout` 等），确保所有配置项（含字符串、整型与自定义类型）均在同一阶段从 config 与 env 合并，避免「部分字段靠 Unmarshal、部分靠 bindCustomTypes」的差异。
- 在 Loader 的 Unmarshal 阶段使用 **Viper DecodeHook**：将配置中的字符串解码为 `types.Duration`（如 `"1h0m0s"`）与 `types.Size`（如 `"10GB"`），使 mapstructure 能正确填充这些自定义类型字段，从而 **所有字段均可带 mapstructure**，无需对 Duration/Size 做「不加 mapstructure、改由 bindCustomTypes 后补」的特殊处理。
- 在引入 DecodeHook 后，**移除** `bindCustomTypes` 及其递归逻辑（当前仅处理 Duration、Size，均由 DecodeHook 覆盖），**不保留多套策略**，配置解析仅保留「Unmarshal + DecodeHook」一条路径，降低心智负担与维护成本。
- 调整绑定到 Viper 的 flag 行为：对「未显式在命令行设置」的 flag（如通过 pflag 的 `Changed()` 判断），不以其默认空值覆盖配置文件或环境变量；仅在用户显式传入对应命令行参数时，命令行才覆盖配置/环境变量。
- 在配置加载流程或文档中明确并保持上述优先级语义，并补充或更新与 PublicBaseURL 及 timeout 等相关的单测/集成测试，验证配置文件与环境变量生效。

## Impact

- Affected specs: 新增 `backend-configuration` 能力，约定后端配置加载优先级与 Viper/flag 使用方式。
- Affected code: `backend/internal/config/loader.go`（DecodeHook、Unmarshal 选项、**移除** bindCustomTypes/bindCustomTypesRecursive 及对其调用）、`backend/internal/server/config.go`（所有需合并字段含 Duration 统一带 mapstructure）、`backend/internal/config/flags.go`、以及可能使用 Viper Unmarshal 的其他配置结构体；`backend/cmd/server/main.go` 中与 flag 绑定/解析顺序相关的逻辑。
