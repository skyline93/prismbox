# Design: 后端存储架构重构

## Context

- 主存储目前仅实现 local，通过 StorageManager 委托给 PrimaryStorage；存储池信息在 DB（storage_pools），由 PoolManager 内存缓存并异步增量落库；实际文件写在每个池的 LocalPath（pool.Path）。
- PathResolver 使用配置中的 BasePath 生成「相对路径」，但该路径已包含 basePath 前缀，与 pool.Path 拼接后语义混乱（例如 fullPath = pool.Path + (basePath + "files/ab/cd/xxx.jpg")）。
- Key 的格式与解析在 PathResolver（storage/primary/local）和 StorageAdapter（service/media）两处实现，variant 与扩展名约定重复，易不同步。
- 配置分散在 storage.config、loader.defaultConfig、pool_manager 的 normalize 中；磁盘缓存路径写死为 `./cache`。
- 读路径未记录文件所在池，Get 时需在所有池中顺序 Stat 直到命中；Reconcile 使用 filepath.Walk 全盘扫描，大容量时成本高。

## Goals / Non-Goals

- **Goals**: 统一 key 与路径语义；单一来源的 key 解析/构建；配置可维护、缓存可配置；池与后端解耦便于扩展；**本次即实现**媒体元数据 pool_id 字段与写时记录、读时定向；对账与缓存行为可配置；应用退出时正确 Close；Secondary 从默认 config 中隐藏。
- **Non-Goals**: 实现 Secondary 存储或双写；改变现有 API 对外行为（上传/下载 URL 与响应格式保持不变）；在本设计内引入新的对象存储后端实现。

## Decisions

### 1. Key 即相对路径、BasePath 仅用于非池目录

- **Decision**: 存储层 key 唯一表示「相对于池根」的路径，格式为 `files/{hash[0:2]}/{hash[2:4]}/{hash}[_variant].{ext}`，不包含任何 BasePath。实际文件路径为 `fullPath = filepath.Join(pool.Path, key)`。BasePath 仅用于 temp、staging 以及可配置的磁盘缓存根目录（若保留）。
- **Alternatives considered**: 保留当前「PathResolver 输出含 basePath 的路径」会导致多池下每个池目录内再出现 basePath 子目录，语义混乱；将 BasePath 当作「全局根」则与多池各自 LocalPath 冲突。故采用 key=相对路径、池根由 DB 管理的方案。

### 2. 单一 Key 格式与解析来源

- **Decision**: 在 `internal/storage`（或 `internal/storage/keys`）中定义 key 格式常量、variant 前缀（如 thumbnail、thumbnail_200x200、preview），并只保留一份 ResolveKey、BuildKey、ParseKey（或等价）。StorageAdapter 只做「业务类型 → extension + variant」，再调用存储层 BuildKey，不再重复实现 key 字符串拼接与解析。
- **Alternatives considered**: 保持两处实现并靠文档同步容易漂移；将解析完全放在 service 层会让存储层依赖业务类型。放在存储层并让业务层调用可保持边界清晰。

### 3. 配置收敛与缓存可配置

- **Decision**: 必配收敛为「主存储类型」；池的根路径由 DB 的 storage_pools 表管理，不再依赖一个全局 base_path 表示池根。Temp 与 cache 使用独立配置项（如 temp_base_path、cache_path、cache_size、cache_ttl），均从配置读取，去掉写死的 `./cache`。PoolManager/Reconcile 等高级参数保留为可选并文档化默认值与调优场景。
- **Alternatives considered**: 保持现有多层级嵌套不便于简单部署；将 cache 路径与 base_path 绑定会继续混淆「池根」与「进程工作目录」概念。

### 4. 池与后端解耦、本次即实现 pool_id 写时记录与读时定向

- **Decision**: 抽象上区分「选池」与「在给定池上执行读写」。**本次重构即实现**：在媒体元数据中增加 pool_id 字段（或等价关联），主存储 Put 成功后写时记录；读路径先查元数据得到 pool_id，再只对该池执行 Get（无记录时回退多池顺序查找）。不推迟到后续 change。
- **Alternatives considered**: 不记录 pool_id 则读路径无法优化；在 key 中编码 pool_id 会破坏 key 的稳定性与去重语义；将实现推迟到后续会增加多次迁移。故采用本次即实现元数据记录池与读时定向。

### 5. Secondary 配置从默认 config 中隐藏

- **Decision**: 默认生成的配置文件（如 Loader 在无配置文件时生成的 config.yaml 或 defaultConfig 序列化结果）SHALL 不包含 `storage.secondary` 配置块。代码内保留 SecondaryStorage 接口、SecondaryStorageConfig 类型及 NewSecondaryStorage 工厂占位（返回未实现错误），供未来实现时启用；不在默认配置中暴露 secondary，避免用户误配。
- **Alternatives considered**: 保留 secondary 在默认 config 并标 experimental 仍会生成无效块；完全移除类型会增加日后实现的改动面。故采用「默认 config 不生成 secondary，代码保留类型与占位」。

### 6. GetSignedURL 与 Close 语义

- **Decision**: 本地存储的 GetSignedURL 要么返回「经 API 网关/代理可访问的 URL」（由上层拼 baseURL + 路由），要么在接口文档中明确「本地存储返回本地路径，仅服务端内部使用；对外签名 URL 由 API 层另行实现」。应用关闭时，在 App 或 main 中调用 PrimaryStorage 的 Close（若接口存在），确保 PoolManager 的 delta worker、cache refresher、reconciler 等 goroutine 正常退出。
- **Alternatives considered**: 保持当前返回本地文件路径会在远程/前端场景产生误导；不调用 Close 会导致优雅退出时 goroutine 泄漏。

### 7. base_path 重构（单一工作根或重命名，降低心智负担）

- **Decision**: 配置中不再使用易与「池根」混淆的单一 `base_path` 作为「万能根」名称。采用以下之一或组合：（A）引入单一 `data_dir`（或 `working_dir`），约定 temp、staging、cache 默认为其下固定子目录（如 `data_dir/temp`、`data_dir/staging`、`data_dir/cache`），用户只需配置一个路径；（B）保留多路径时，将原 `base_path` 重命名为 `temp_staging_root` 或仅保留 `temp.base_path` 与 `performance.cache_path`，并在文档与注释中明确「仅用于临时/缓存，媒体文件由存储池 location 决定」。实现时 PathResolver 与 TempFileManager 的根目录来源统一从新键或派生路径读取。
- **Alternatives considered**: 保留 `base_path` 名称会继续让用户误以为「媒体也在这下面」；完全移除「工作根」配置则 temp/staging/cache 无处可放。故采用单一 data_dir 或重命名以降低心智负担，同时保留可配置性。

### 8. 存储池根路径仅使用绝对路径

- **Decision**: 存储池的根路径（本地池在磁盘上的位置）在持久化与运行时 SHALL 为绝对路径。创建或更新本地池时：要么 API/CLI 仅接受绝对路径并在服务端校验（非绝对则报错），要么接受相对路径但在写入 DB 前使用 `filepath.Abs()` 规范化后只存储绝对路径。PoolManager 与 PathResolver 使用的池根 SHALL 来自该规范化后的值，确保与进程 cwd 无关、多实例行为一致。
- **Alternatives considered**: 允许仅存相对路径会导致不同启动方式（systemd、docker、手工运行）下同一配置指向不同目录；仅校验但不规范化则用户必须自己填绝对路径，体验略差。故采用「接受相对路径则自动 Abs 后存库」或「仅接受绝对路径」两种策略之一并在文档中明确。

### 9. 存储池位置采用 restic 风格 URI

- **Decision**: 存储池的「位置」用单一 URI 字段（如 `location`）表示，与 restic/rclone 习惯一致。本地池格式为 `local:///absolute/path`（三斜杠表示 authority 为空、path 为绝对路径）；未来扩展可为 `s3://bucket/prefix`、`oss://bucket/prefix` 等。API 与 DB 使用 `location` 作为唯一位置来源；解析后 scheme 对应 `storage_type`，local 的 path 部分 SHALL 为绝对路径（解析时校验或做 Abs）。创建/更新池时，调用方仅传入 `location`。PoolManager 与后端在使用时仅从 `location` 解析池根路径。**不对旧 `local_path` 字段或旧 API 做兼容**；若有旧数据，仅通过一次性迁移脚本转为 `location` 后即只读 `location`。
- **Alternatives considered**: 保留 `storage_type` + `local_path` 两栏割裂类型与位置，心智负担较大；兼容旧字段会导致长期双路径逻辑与文档复杂。故采用 URI 单一字段且不保留旧方案兼容。

### 10. location 必填、storage_type 由 location 派生（创建时不指定类型）

- **Decision**: 对存储池而言，`location` 为必填属性；location URI 的 scheme 即存储类型（如 `local`、未来 `s3`）。**创建存储池时调用方不再单独指定 storage_type**；服务端从 location 解析出 scheme，规范化 location 后，将 scheme 作为 storage_type 写入 DB。代码中**不**再按「仅当 storage_type 为 local 时才解析/校验 location」分支；统一逻辑为：location 必填 → Parse(location) → scheme 即类型，按 scheme 做路径规范化（如 local 用 BuildLocal）。响应与 DB 可保留 storage_type 字段（由 location 派生），便于列表筛选与展示。**不保留向后兼容**，仅保留最新方案。
- **Alternatives considered**: 创建时同时传 storage_type 与 location 会导致冗余与不一致可能；按类型分支解析 location 增加分支且易漏改。故采用「创建仅 location、类型从 scheme 派生、统一解析无类型分支」。

## Risks / Trade-offs

- **不兼容旧方案与旧数据**：本提案**不对旧配置键（如 base_path）、旧 DB 字段（如 local_path）或旧路径布局做运行时兼容**。已存在的数据与配置需通过一次性迁移脚本或用户自行迁移后使用新格式；部署升级前需完成迁移或接受从新结构重新开始。
- **性能**：引入 pool_id 查询会增加一次 DB 或缓存查找，但可避免多池 Stat，整体读路径预期更稳定；对账按池或按批可降低单次 Walk 范围，需在实现时保留「全量对账」选项用于修复一致性。

## Migration Plan

1. **Phase 1（本 change 已交付）**：实现新 key=相对路径语义、PathResolver 只输出相对路径、统一 key 解析到存储层、配置收敛与 cache 可配置、StorageAdapter 调用存储层 BuildKey、**媒体元数据 pool_id 字段与写时记录、读时定向**、应用退出时 Close；默认生成 config 不包含 storage.secondary。
2. **Phase 2（base_path 重构）**：引入 `data_dir` 或重命名 `base_path` 为 `temp_staging_root`（或等价）；更新 loader 默认配置与 env 映射；PathResolver/TempFileManager 仅从新键或派生路径读取。**不保留对旧 base_path 键的兼容**；文档化新配置键与升级步骤。
3. **Phase 3（池绝对路径 + URI）**：API/DB 仅使用 `location`（URI）；移除或废弃 `local_path` 列；创建/更新池时仅接受 location，校验或规范化绝对路径；PoolManager 仅从 `location` 解析 scheme 与 path。提供**一次性**迁移脚本：将现有 `local_path` 转为 `location = local:///filepath.Abs(local_path)` 并写入 DB，迁移完成后代码仅读 `location`，**不保留读时回退 local_path**。
4. **Rollback**：无运行时兼容；回滚需恢复旧代码与旧数据结构，或从备份恢复数据。

## Open Questions

- 无（已决：本次即实现 pool_id 写时记录与读时定向；Secondary 从默认 config 中隐藏，仅保留代码内类型与工厂占位）。
