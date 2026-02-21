# Change: 后端存储架构长远重构与优化

## Why

当前后端存储架构存在路径与 key 语义混乱（BasePath 与存储池 LocalPath 职责不清）、配置层级多且默认值分散、PathResolver 与 StorageAdapter 双套 key 逻辑易不一致、缓存路径写死、存储池与 Primary 实现强耦合、次存储仅占位未实现等问题，导致维护复杂、扩展困难。从长远考虑需要统一 key/路径语义、收敛配置、集中 key 解析、解耦池与后端，并为读路径优化（记录文件所在池）和对账/缓存可配置化奠定基础。

## What Changes

- **统一 key 与相对路径语义**：约定存储层 key 即「相对路径」（如 `files/{hash[:2]}/{hash[2:4]}/{hash}[_variant].{ext}`），不包含 BasePath；实际文件路径为 `pool.Path + key`。BasePath 仅用于 temp、staging 及可配置的磁盘缓存目录。
- **集中 Key 格式与解析**：在存储层提供唯一的 key 构建/解析与 variant 常量，StorageAdapter 仅负责业务类型到 extension+variant 的映射并调用存储层 BuildKey，移除重复的 key 字符串拼接与解析实现。
- **配置收敛与分层**：存储必配项收敛（主存储类型、池根由 DB 管理）；temp/cache 路径与池相关配置分组并文档化；磁盘缓存路径、大小、TTL 可配置，去除写死的 `./cache`；Secondary 从默认生成 config 中隐藏，仅保留代码内类型与工厂占位。
- **存储池与后端解耦**：抽象「选池」与「在池上执行读写」，使 PrimaryStorage 可接受「池标识」或由调用方指定池，便于未来 S3 等无池或池即 bucket 的后端扩展。
- **写入时记录文件所在池、读时定向**：**本次重构即实现**。在媒体元数据中引入 pool_id 字段，主存储 Put 成功后写时记录 pool_id；读路径先查元数据得到 pool_id 再单池 Get（未命中时回退多池查找），实现读时定向。
- **生命周期与接口澄清**：应用退出时对 PrimaryStorage（及 PoolManager）执行 Close；明确 GetSignedURL 在本地存储下的语义（返回可被网关代理的 URL 或明确标注本地不支持）。
- **Secondary 配置收口**：Secondary 存储（openlist/s3/oss/cos）的具体实现与双写**不在此次实现**。默认生成的 config（如 loader 生成的 config.yaml）中 SHALL 不包含 `storage.secondary` 配置块；代码内保留 SecondaryStorage 类型与工厂占位（如 NewSecondaryStorage 返回未实现错误），不暴露给默认配置。
- **base_path 重构（降低心智负担）**：将配置中易与「池根」混淆的 `base_path` 弱化或收敛为单一「工作根」语义。可选方案：引入单一 `data_dir`（或 `working_dir`），temp、staging、cache 默认均置于其下固定子目录；或保留多路径但重命名为 `temp_staging_root`、`cache_path` 等，并在文档中明确「仅用于临时/缓存，媒体文件由存储池 location 决定」。**BREAKING**：配置键或默认值变更；**不对旧 base_path 键或旧配置格式做兼容**，用户需按新配置迁移。
- **存储池根路径仅使用绝对路径**：存储池的根路径（本地池的「位置」）SHALL 在持久化与使用时为绝对路径。创建/更新池时：要么仅接受绝对路径并校验，要么接受相对路径但在写入 DB 前用 `filepath.Abs()` 规范化后只存绝对路径，确保与进程 cwd 无关。**不对旧数据中已存的相对路径做运行时兼容**；若有历史数据需通过一次性迁移更新。
- **存储池位置采用 restic 风格 URI**：存储池的「位置」用单一 URI 字段（如 `location`）表达类型与路径，与 restic/rclone 等一致。本地池格式为 `local:///absolute/path`（三斜杠表示 path 为绝对路径）；未来云存储可为 `s3://bucket/prefix`、`oss://bucket/prefix` 等。API/DB 使用 `location` 作为唯一位置来源，解析后 scheme 对应存储类型，local 的 path 部分 SHALL 为绝对路径。**BREAKING**：API 与 DB 结构变更；**不对旧 local_path 字段或旧 API 做兼容**，仅使用新 location 格式；若有旧数据需通过一次性迁移脚本转为 location 后即仅读 location。
- **location 为必填且唯一位置来源、storage_type 由 location 派生**：对存储池而言，`location` 为必填属性；location URI 的 scheme 即存储类型（如 `local`、未来 `s3`），故**创建存储池时不再单独指定 storage_type**，由服务端从 location 解析 scheme 后写入 DB。代码中**不再**按「仅当 storage_type 为 local 时才解析/校验 location」分支；统一为「location 必填、必解析、scheme 即类型」。**不保留向后兼容**，仅保留最新方案（创建请求仅含 location 等必填项，响应与 DB 可保留 storage_type 字段由 location 派生，便于查询与展示）。

## Impact

- **Affected specs**: backend-storage（新增 capability）、backend-configuration（配置相关 delta，若涉及 storage 配置键与默认值文档）
- **Affected code**: `backend/internal/storage/`（config、factory、manager、interfaces）、`backend/internal/storage/primary/local/`（path_resolver、storage、pool_manager、cache、temp_manager）、`backend/internal/config/`（loader 默认配置）、`backend/internal/service/media/storage_adapter.go`、媒体服务与存储池服务调用处；媒体/媒体元数据模型若增加 pool_id 则涉及 repository 与 migration。base_path 重构与 URI/绝对路径涉及 storage 配置、storage_pools 表或 API DTO、pool_manager 与 PathResolver 的根路径来源、以及 CLI/API 创建与更新池的校验与迁移逻辑。
