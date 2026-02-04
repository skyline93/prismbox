# Design: 修复 PublicBaseURL 配置优先级

## Context

- 后端使用 Viper 做配置管理：ReadInConfig 读 YAML，BindPFlags 绑定 pflag，Unmarshal 合并到结构体。文档约定优先级为：命令行 > 环境变量 > 配置文件 > 默认值。
- 实际表现：在 config.yaml 或环境变量中设置 `server.public_base_url` / `ALBUM_SERVER_PUBLIC_BASE_URL` 后，运行时仍使用代码中的默认值，未体现配置文件或环境变量。
- 根因分析见提案：一是 Unmarshal 使用 mapstructure，键名与 yaml/env 不匹配；二是已绑定且默认值为空的 flag 在 Viper 中优先于 config/env，导致空串覆盖。

## Goals / Non-Goals

- **Goals**：使 PublicBaseURL 及受影响的配置项严格遵循「命令行（仅当显式设置）> 环境变量 > 配置文件 > 默认值」；修复后部署仅改 config 或 env 即可生效。
- **Non-Goals**：不改动 Viper 库本身；不扩大为全量配置项的重构，仅修复当前暴露的问题及同模式字段。

## Decisions

### 1. 为 Unmarshal 涉及的结构体统一补充 mapstructure tag

- **决策**：在 `server.Config` 及被 Viper Unmarshal 的其它后端配置结构体中，**所有**需要从配置文件/环境变量合并的字段（含字符串、整型与自定义类型如 `types.Duration`、`types.Size`）均增加 `mapstructure` tag，与现有 YAML 键一致（如 `public_base_url`、`read_timeout`）。不保留「部分字段有 mapstructure、部分没有」的差异，避免后续维护与理解误区。
- **做法**：每个需合并字段同时保留 `yaml` 与 `mapstructure`（如 `ReadTimeout types.Duration \`yaml:"read_timeout" mapstructure:"read_timeout"\``）。自定义类型在 Unmarshal 阶段的解析由 DecodeHook 承担（见决策 4）。
- **替代**：若不对 Duration/Size 使用 DecodeHook，则只能对这类字段省略 mapstructure、改由 bindCustomTypes 后补，会导致与其它配置项处理路径不一致，增加认知负担。

### 2. 未显式设置的 flag 不覆盖配置/环境变量

- **决策**：对通过 BindPFlags 绑定且默认值为「空」或零值的 flag，在 Unmarshal 之后或合并逻辑中，仅当 pflag 的 `Changed()` 为 true 时才用该 flag 的值覆盖对应配置项；否则保留由环境变量或配置文件合并得到的值。
- **实现选项**：  
  - **A**：Unmarshal 后遍历需保护的 key（如 `server.public_base_url`），若 Viper 当前值来自绑定 flag 且 flag 未 Changed()，则用 Viper 从 config/env 再取一次并写回 cfg。  
  - **B**：不绑定「默认值为空且希望被 config/env 覆盖」的项到 Viper，改为 Parse 后若 flag.Changed() 则手动设置 cfg 对应字段。  
- **选用**：优先 A，在 Loader 内集中处理，避免 main 或多处散落逻辑；若 Viper 无法区分「值来自 flag 默认值」与「来自 config」，则采用 B，对 `server.public_base_url` 等少量项在 Load 完成后根据 flag.Changed() 做一次覆盖修正。
- **替代**：不绑定这些 flag 到 Viper（仅保留在 pflag 用于帮助与显式传参），则 Get 时不会拿到 flag 默认空串，自然以 config/env 为准；但需确保命令行显式传参时仍能写回配置，故需在 Parse 后根据 flag.Changed() 手动设置 cfg。

### 3. 测试与文档

- **决策**：为 PublicBaseURL 增加单元测试或集成测试：仅配置文件设置、仅环境变量设置、命令行显式设置、以及「配置文件 + 未设置 flag」组合，断言最终 cfg.Server.PublicBaseURL 符合优先级。在 loader 或架构文档中明确「未显式设置的 flag 不覆盖 config/env」的语义。

### 4. 自定义类型在 Unmarshal 阶段通过 DecodeHook 统一解析，并移除 bindCustomTypes

- **决策**：在 Loader 调用 Viper 的 `Unmarshal` 时传入 **DecodeHook**，在解码阶段将配置中的字符串转换为 `types.Duration` 与 `types.Size`，使 mapstructure 能正确填充这些字段。这样所有配置项（含 timeout、size 等）均在同一路径（Unmarshal）完成合并，规则一致。**不保留与 Unmarshal 并行的第二套解析路径**，以降低心智负担。
- **做法**：实现或组合 mapstructure 的 DecodeHookFunc：当源类型为 string、目标类型为 `types.Duration` 时，使用 `time.ParseDuration` 解析后转为 `types.Duration`；当目标类型为 `types.Size` 时，使用现有 `parseSizeString` 等逻辑解析。在 `loader.go` 中通过 Viper 提供的选项（如 `viper.DecodeHook(...)` 或等效的 DecoderConfigOption）将 Hook 注入 Unmarshal。
- **移除 bindCustomTypes**：当前 Loader 中仅有 `bindCustomTypes` / `bindCustomTypesRecursive` 负责 Duration 与 Size 的后补解析；引入 DecodeHook 后，上述两种类型均由 Unmarshal 阶段完成，**须移除** `bindCustomTypes`、`bindCustomTypesRecursive` 及其在 Load 中的调用。`parseSizeString` 可保留为包内工具函数供 DecodeHook 复用。配置解析仅保留「Unmarshal + DecodeHook」一条策略，避免多套逻辑并存导致后续维护困难。
- **替代**：若保留 bindCustomTypes 作为「兜底」或仅移除其中部分逻辑，会继续存在「部分字段 Unmarshal、部分后补」的差异，增加理解与修改成本，故不采用。

## Risks / Trade-offs

- **风险**：对其它同样「默认空 + BindPFlags」的 key（如 server.host、server.port、database.dsn 等）若也期望 config/env 优先，需一并按同一规则处理，否则会出现同类「配了不生效」问题。
- **缓解**：本次至少修复 PublicBaseURL；若采用「Unmarshal 后按 flag.Changed() 覆盖」的通用逻辑，可对所有已绑定的、默认值为空的 key 统一处理，减少遗漏。

## Migration Plan

- 无数据迁移。部署时若已在 config.yaml 或环境中配置 `public_base_url`，修复后无需改配置即可生效；若此前通过命令行传参，行为保持不变（仍以命令行为准）。可选：在 release note 中说明「修复了通过配置文件/环境变量设置 PublicBaseURL 不生效的问题」。

## Open Questions

- 无。若后续发现其它配置项也存在「仅 yaml tag」或「空 flag 覆盖」问题，按本设计同样方式修复并补充到 backend-configuration 规范即可。
