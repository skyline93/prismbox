# backend-configuration Delta

## ADDED Requirements

### Requirement: 存储相关路径与缓存可配置

存储模块的临时文件根路径、staging 路径及磁盘缓存根路径 SHALL 通过配置提供（如 `storage.primary.local.temp.base_path`、`storage.primary.local.performance.cache_path` 或等价键），并 SHALL 遵循与 Viper Unmarshal 一致的 mapstructure 键名。磁盘缓存路径 SHALL NOT 在代码中硬编码（如 `./cache`）；未配置时 SHALL 使用文档化的默认值或禁用磁盘缓存。

#### Scenario: 磁盘缓存路径从配置读取
- **WHEN** 配置中存在 storage.primary.local.performance.cache_path（或等价键）
- **THEN** 存储模块 SHALL 使用该值作为磁盘缓存根目录
- **AND** 该字段 SHALL 带有与 YAML 键一致的 mapstructure tag，以便环境变量与配置文件合并生效

#### Scenario: 未配置缓存路径时的行为
- **WHEN** 未配置 cache_path 且启用磁盘缓存
- **THEN** 系统 SHALL 使用文档化的默认路径或禁用磁盘缓存
- **AND** SHALL NOT 使用硬编码的固定相对路径（如 `./cache`）作为默认值写入不可配置的代码路径

### Requirement: 默认生成配置不包含 Secondary 存储块

后端在生成默认配置（如配置文件不存在时由 Loader 生成并写出的 config.yaml，或 defaultConfig 的序列化结果）时，SHALL NOT 包含 `storage.secondary` 配置块。Secondary 存储的类型与工厂占位（如 NewSecondaryStorage）SHALL 仅保留在代码内，不通过默认配置暴露给用户，避免未实现功能被误配。

#### Scenario: 首次生成 config 无 secondary 块
- **WHEN** 配置加载器因配置文件不存在而生成默认配置并写入文件
- **THEN** 生成的 YAML SHALL 不包含 `storage.secondary` 键或其子键
- **AND** 主存储（primary）相关配置 SHALL 正常生成

#### Scenario: 代码内仍保留 Secondary 类型与工厂
- **WHEN** 调用方依赖 SecondaryStorageConfig 或 NewSecondaryStorage
- **THEN** 类型定义与工厂函数 SHALL 仍存在于代码中（工厂可返回未实现错误）
- **AND** 仅默认配置输出中不包含 secondary，不影响代码结构

## ADDED Requirements

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
