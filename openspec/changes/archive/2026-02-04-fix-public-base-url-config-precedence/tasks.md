## 1. 实现

- [x] 1.1 为 `server.Config` 及同 Loader 下其它需从 Viper 合并的配置结构体字段补充 `mapstructure` tag（与 yaml 键一致），至少包含 `PublicBaseURL` 对应 `public_base_url`
- [x] 1.2 **DecodeHook**：在 Loader 的 Unmarshal 中注入 DecodeHook，将 string 解码为 `types.Duration`（如 `time.ParseDuration`）与 `types.Size`（复用现有 parseSizeString 逻辑），使 Unmarshal 阶段即可正确填充 read_timeout、write_timeout、idle_timeout 等字段
- [x] 1.3 为 `server.Config` 的 `ReadTimeout`、`WriteTimeout`、`IdleTimeout` 补回 `mapstructure:"read_timeout"` 等 tag，与其它字段规则一致；确认其它被同一 Loader Unmarshal 的配置结构体中的 Duration/Size 字段均带 mapstructure 并由 DecodeHook 解析
- [x] 1.4 在配置加载流程中实现「未显式设置的 flag 不覆盖 config/env」：在 Unmarshal 之后根据 pflag 的 `Changed()` 对 `server.public_base_url` 等绑定且默认值为空的项做修正
- [x] 1.5 确保 `backend/internal/config/flags.go` 与 `backend/cmd/server/main.go` 中 flag 解析与 Load 的调用顺序与上述语义一致

## 2. 移除 bindCustomTypes（单一策略）

- [x] 2.1 在 DecodeHook 覆盖 Duration、Size 后，**移除** `bindCustomTypes`、`bindCustomTypesRecursive` 及其在 `Load` 中的调用；保留 `parseSizeString` 为包内工具函数供 DecodeHook 复用；确保配置解析仅存在 Unmarshal + DecodeHook 一条路径，无多套策略

## 3. 测试与质量

- [x] 3.1 为 PublicBaseURL 配置优先级添加单元测试或集成测试：仅配置文件、仅环境变量、仅命令行显式、以及「配置文件 + 未设置 flag」等组合，断言最终 `cfg.Server.PublicBaseURL` 符合约定优先级
- [x] 3.2 增加或调整测试，确认从配置文件读取的 read_timeout/write_timeout/idle_timeout 经 DecodeHook 后正确解析（可与现有 config 测试共用同一配置文件）
- [x] 3.3 运行现有后端测试与静态检查（如 go build、linter），确保无回归

## 4. 文档

- [x] 4.1 在 `backend/internal/config/loader.go` 或相关架构文档中明确「未显式设置的命令行 flag 不覆盖配置文件与环境变量」的语义
- [x] 4.2 在 loader 或 design 中简要说明「自定义类型（Duration、Size）在 Unmarshal 阶段通过 DecodeHook 统一解析，所有需合并字段均带 mapstructure」，便于后续维护者理解
