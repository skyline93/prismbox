# backend-configuration Specification

## Purpose
TBD - created by archiving change fix-public-base-url-config-precedence. Update Purpose after archive.
## Requirements
### Requirement: 配置加载优先级

后端配置加载 SHALL 遵循优先级：**命令行参数（仅当用户显式传入）> 环境变量 > 配置文件 > 默认值**。未在命令行显式设置的 flag 不得以其默认值覆盖配置文件或环境变量中的同键配置。

#### Scenario: 配置文件中的 PublicBaseURL 生效
- **WHEN** 在 config.yaml 中设置 `server.public_base_url` 为某 URL，且未在命令行传入 `--server.public_base_url`
- **THEN** 运行时使用的 `PublicBaseURL` 为该 URL
- **AND** 不会使用代码中的默认值或空字符串覆盖

#### Scenario: 环境变量中的 PublicBaseURL 生效
- **WHEN** 设置环境变量 `ALBUM_SERVER_PUBLIC_BASE_URL` 为某 URL，且未在配置文件或命令行中覆盖
- **THEN** 运行时使用的 `PublicBaseURL` 为该 URL
- **AND** 不会使用代码中的默认值或空字符串覆盖

#### Scenario: 命令行显式传参覆盖配置与环境变量
- **WHEN** 用户在命令行传入 `--server.public_base_url=<url>`
- **THEN** 运行时使用的 `PublicBaseURL` 为该命令行参数值
- **AND** 忽略同键的配置文件与环境变量

#### Scenario: 默认值在无任何覆盖时生效
- **WHEN** 未在配置文件、环境变量或命令行中设置 `server.public_base_url`
- **THEN** 运行时使用的 `PublicBaseURL` 为代码中定义的默认值（如 `http://127.0.0.1:8080`）

### Requirement: Viper Unmarshal 与配置键一致

所有被 Viper Unmarshal 合并的后端配置结构体 SHALL 使用与配置文件、环境变量一致的键名。对嵌套及顶层字段，SHALL 在**所有**需要从 Viper 合并的字段上同时提供 `mapstructure` tag（与 YAML 键一致），包括字符串、整型与自定义类型（如 `types.Duration`、`types.Size`），不因类型不同而采用不同规则，以便后续维护者有一致的心智模型。

#### Scenario: server.Config 的 PublicBaseURL 从 config 与 env 合并
- **WHEN** 配置结构体（如 `server.Config`）的字段同时带有 `yaml:"public_base_url"` 与 `mapstructure:"public_base_url"`
- **THEN** Viper Unmarshal 时能通过键 `server.public_base_url` 从配置文件和环境变量取到值
- **AND** 该字段不再因键名不一致而保留默认值不被覆盖

#### Scenario: Duration/Size 等自定义类型在 Unmarshal 阶段统一解析
- **WHEN** 配置结构体中含有 `types.Duration` 或 `types.Size` 字段（如 `read_timeout`、`write_timeout`、`max_avatar_size`）
- **THEN** 这些字段 SHALL 同样带有与 YAML 键一致的 `mapstructure` tag
- **AND** Loader 在 Unmarshal 时 SHALL 通过 Viper/mapstructure 的 DecodeHook 将配置中的字符串解码为上述自定义类型，使所有配置项在同一阶段完成合并
- **AND** Loader SHALL NOT 保留与 Unmarshal 并行的第二套解析路径（如 bindCustomTypes）；仅通过 DecodeHook 在 Unmarshal 阶段完成自定义类型解析，以降低心智负担与维护成本

#### Scenario: 其它受 Unmarshal 影响的配置结构体
- **WHEN** 其它被同一 Loader Unmarshal 的配置结构体存在仅含 `yaml` tag 的字段
- **THEN** 对需要从 config/env 合并的字段补充与 YAML 键一致的 `mapstructure` tag（含自定义类型，并依赖 DecodeHook 解析）
- **AND** 避免同类「配置不生效」或规则不一致问题

### Requirement: 未显式设置的 Flag 不覆盖配置

对通过 BindPFlags 绑定到 Viper、且默认值为空或零值的命令行 flag，SHALL 仅在用户显式设置该 flag（如 pflag 的 `Changed()` 为 true）时，才以该 flag 的值覆盖配置文件或环境变量；否则 SHALL 保留由环境变量或配置文件合并得到的值。

#### Scenario: 未传 server.public_base_url 时不用空串覆盖
- **WHEN** 未在命令行传入 `--server.public_base_url`，且配置文件或环境变量中已设置该键
- **THEN** 最终配置中 `PublicBaseURL` 为配置文件或环境变量的值
- **AND** 不会因绑定 flag 的默认空字符串而被覆盖为空

#### Scenario: 显式传入空字符串
- **WHEN** 用户在命令行显式传入 `--server.public_base_url=""`
- **THEN** 最终配置中 `PublicBaseURL` 为空字符串（命令行显式覆盖）

### Requirement: 存储工作根单一语义（data_dir 或重命名 base_path）

存储模块的临时文件、staging 及磁盘缓存的工作根 SHALL 通过单一语义的配置提供，以降低与「池根」混淆的心智负担。可选实现方式：（A）引入单一 `data_dir`（或 `working_dir`），约定 temp、staging、cache 默认为其下固定子目录（如 `data_dir/temp`、`data_dir/staging`、`data_dir/cache`），仍允许 `temp.base_path`、`performance.cache_path` 等覆盖；（B）将原易混淆的 `base_path` 重命名为 `temp_staging_root` 或等价键，并在文档与配置注释中明确「仅用于临时/staging/缓存，媒体文件由存储池 location 决定」。默认配置与 env 映射 SHALL 仅使用新键或 data_dir；不保留对旧 base_path 键的兼容，文档化新键与升级步骤即可。

#### Scenario: 用户仅配置一个工作根时 temp/staging/cache 可推导
- **WHEN** 配置中存在 data_dir（或 working_dir）且未单独设置 temp.base_path 或 cache_path
- **THEN** 系统 SHALL 使用 data_dir 下的固定子目录（如 temp、staging、cache）作为对应根目录
- **AND** 文档 SHALL 明确说明媒体文件不在此根下，由存储池 location 决定

#### Scenario: 重命名后配置键语义明确
- **WHEN** 采用重命名方案（如 base_path 改为 temp_staging_root）
- **THEN** 配置键与文档 SHALL 明确标注该路径仅用于临时文件与 staging
- **AND** 磁盘缓存根目录 SHALL 仍由 performance.cache_path 单独配置或自 data_dir 派生

### Requirement: 媒体缩略图与预览图配置统一存放

媒体处理器所需的缩略图与预览图配置 SHALL 在后端统一配置中单处定义，键名清晰、与 Viper/环境变量映射一致。thumbnail 与 preview 各 SHALL 包含：单边 size（像素，表示长边上限）、format、quality。系统 SHALL NOT 为 thumbnail/preview 预设使用分散的 MaxWidth/MaxHeight/Crop 等多参数配置；仅使用单一 size 语义以与 Immich 对齐并降低维护成本。

#### Scenario: 配置键统一可覆盖

- **WHEN** 运维在配置文件或环境变量中设置 `media.thumbnail.size`、`media.preview.size` 等
- **THEN** 媒体处理器 SHALL 从该统一配置读取 thumbnail/preview 的 size、format、quality
- **AND** 配置加载优先级 SHALL 与现有后端配置一致（命令行 > 环境变量 > 配置文件 > 默认值）

#### Scenario: 默认值明确

- **WHEN** 未配置 media.thumbnail 或 media.preview 的 size
- **THEN** 系统 SHALL 使用代码或配置中定义的合理默认值（如 thumbnail 250、preview 1440）
- **AND** format、quality 亦 SHALL 有明确默认值并在同一配置块中定义

