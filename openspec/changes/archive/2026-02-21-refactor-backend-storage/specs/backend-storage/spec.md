# backend-storage Delta

## ADDED Requirements

### Requirement: 存储 Key 与相对路径语义统一

后端主存储 SHALL 将存储 key 定义为「相对于池根」的路径，格式为 `files/{hash[0:2]}/{hash[2:4]}/{hash}[_variant].{ext}`，不包含 BasePath。实际文件完整路径 SHALL 为 `filepath.Join(pool.Path, key)`。BasePath SHALL 仅用于临时文件、staging 及可配置的磁盘缓存根目录，不参与池内文件路径计算。

#### Scenario: 写入时路径由池根与 key 拼接
- **WHEN** 主存储执行 Put 且已选定存储池
- **THEN** 系统 SHALL 使用存储层统一的 BuildKey 得到相对路径 key
- **AND** 完整路径 SHALL 为 pool.Path 与 key 的 Join，不包含 BasePath 前缀

#### Scenario: 读取时仅用 key 在单池或已知池定位
- **WHEN** 主存储执行 Get 且调用方提供 key（及可选 pool_id）
- **THEN** 系统 SHALL 在目标池根下用 key 定位文件
- **AND** 若未提供 pool_id，系统 MAY 按现有多池查找策略回退，直至支持 pool_id 定向

#### Scenario: BasePath 仅用于 temp 与 cache
- **WHEN** 配置中存在 storage.primary.local.base_path（或重命名后的 temp_base_path）
- **THEN** 该路径 SHALL 仅用于临时文件目录、staging 目录及磁盘缓存根目录（若配置了 cache_path 则优先使用 cache_path）
- **AND** 池内文件路径 SHALL 不包含该 BasePath

### Requirement: Key 格式与解析单一来源

系统 SHALL 在存储层提供唯一的 key 构建与解析能力（如 BuildKey、ResolveKey、ParseKey），以及 variant 与格式常量（如 thumbnail、preview、thumbnail_WxH）。业务层（如 StorageAdapter）SHALL 仅负责将业务类型（original/thumbnail/preview）映射为 extension 与 variant，并调用存储层 BuildKey 生成 key，SHALL NOT 重复实现 key 字符串拼接或解析逻辑。

#### Scenario: 业务层只做类型到 extension+variant 映射
- **WHEN** 媒体服务需要生成缩略图或预览的存储 key
- **THEN** StorageAdapter SHALL 仅根据 itemType 与 mediaType 返回 extension 与 variant
- **AND** key 的字符串构建 SHALL 由存储层统一函数完成

#### Scenario: 解析 key 仅在一处实现
- **WHEN** 需要从 key 解析出 hash、extension、variant
- **THEN** 系统 SHALL 仅使用存储层提供的 ResolveKey 或等价解析函数
- **AND** 业务层 SHALL NOT 维护与存储层格式重复的 ParseStorageKey 等实现

### Requirement: 存储相关配置收敛与缓存可配置

主存储配置 SHALL 收敛必配项为主存储类型；池的根路径 SHALL 由数据库 storage_pools 表管理。临时文件与磁盘缓存的路径、大小、TTL SHALL 通过配置项提供（如 temp_base_path、cache_path、cache_size、cache_ttl），SHALL NOT 在代码中写死磁盘缓存目录（如 `./cache`）。PoolManager 与 Reconcile 等高级参数 SHALL 保留为可选并文档化默认值与调优场景。

#### Scenario: 磁盘缓存路径可配置
- **WHEN** 配置中存在 storage.primary.local.performance.cache_path（或等价键）
- **THEN** 磁盘缓存根目录 SHALL 使用该配置值
- **AND** 未配置时 SHALL 使用合理默认或禁用磁盘缓存，SHALL NOT 使用硬编码的 `./cache`

#### Scenario: 池根来自数据库
- **WHEN** 主存储为 local 且需要解析池路径
- **THEN** 池根路径 SHALL 来自 storage_pools 表的 location URI 解析结果（或等价唯一位置字段）
- **AND** 不在主存储配置中要求「全局池根」与 BasePath 混用

### Requirement: 存储池与后端解耦

系统 SHALL 在抽象上区分「选池」（根据策略选择池 ID）与「在给定池上执行读写」。PrimaryStorage 接口 SHALL 允许在可行时接受「池标识」或由调用方指定池，以便未来支持无池或池即 bucket 的后端（如 S3）时，选池与读写语义可独立扩展。

#### Scenario: 写入时先选池再写
- **WHEN** 主存储执行 Put
- **THEN** 系统 SHALL 先通过选池逻辑得到 pool_id（或等价）
- **AND** 再在该池上执行写入，不将「池列表与类型」硬编码在单一后端实现中

#### Scenario: 读路径可定向到单池
- **WHEN** 调用方已知对象所在池（如从元数据获得 pool_id）
- **THEN** 主存储 SHALL 支持仅在该池上执行 Get，避免遍历所有池
- **AND** 未提供池时 MAY 回退到多池查找

### Requirement: 写入时记录文件所在池与读时定向（本次重构即实现）

系统 SHALL 在本次重构中实现：写入主存储成功后，将对象 key 与所在池标识（pool_id）记录到媒体元数据（如 media 表或扩展表）中；读路径 SHALL 优先根据该记录确定池再执行 Get（读时定向），若记录不存在则回退到多池顺序查找。该能力 SHALL 在本 change 内交付，不推迟到后续。

#### Scenario: 写入成功后记录 pool_id
- **WHEN** 主存储 Put 成功且已选定池
- **THEN** 系统 SHALL 将 (key 或 media 标识, pool_id) 持久化到媒体相关表或扩展表
- **AND** 后续 Get  SHALL 可依据该记录定位池

#### Scenario: 读取时优先按 pool_id 定位
- **WHEN** 主存储 Get 被调用且存在该 key 的 pool_id 记录
- **THEN** 系统 SHALL 仅在该池下用 key 查找文件
- **AND** 若文件不存在再按策略回退（如记录过期或迁移导致）

### Requirement: 存储生命周期与 GetSignedURL 语义

应用关闭时，系统 SHALL 调用 PrimaryStorage 的 Close（或等价生命周期方法），以确保 PoolManager 的 delta worker、cache refresher、reconciler 等后台 goroutine 正常退出。本地存储的 GetSignedURL SHALL 要么返回可由 API 网关/代理访问的 URL，要么在接口或文档中明确「本地存储返回路径仅服务端内部使用；对外签名 URL 由 API 层实现」。

#### Scenario: 应用退出时关闭主存储
- **WHEN** 应用（如 HTTP 服务）收到关闭信号并执行优雅退出
- **THEN** 系统 SHALL 在退出前调用 PrimaryStorage 的 Close
- **AND** PoolManager 的 delta 刷新、缓存刷新、对账等 goroutine SHALL 在 Close 后结束

#### Scenario: GetSignedURL 语义明确
- **WHEN** 主存储为本地且调用 GetSignedURL
- **THEN** 实现 SHALL 要么返回基于 PublicBaseURL 与路由的可访问 URL，要么在文档中说明返回值为本地路径、仅内部使用
- **AND** 不得误导调用方将返回值直接作为对外签名 URL 使用（若未由 API 层包装）

## ADDED Requirements

### Requirement: 存储池位置为 URI 且本地池根为绝对路径

存储池的「位置」SHALL 用单一 URI 字段（如 location）表示，与 restic/rclone 等习惯一致。本地池的 URI 格式 SHALL 为 `local:///absolute/path`（三斜杠表示 path 为绝对路径）。系统 SHALL 在持久化与使用时将本地池根路径视为绝对路径；创建或更新本地池时，SHALL 仅接受绝对路径并校验，或在写入前用 `filepath.Abs()` 规范化后只存绝对路径，确保与进程 cwd 无关、多实例行为一致。系统 SHALL NOT 保留对旧 local_path 字段或旧位置格式的兼容读取；若有旧数据需通过一次性迁移转为 location 后仅使用 location。

#### Scenario: 创建本地池时位置为 URI 或规范化为绝对路径
- **WHEN** 调用方创建或更新类型为 local 的存储池并传入路径（或 location）
- **THEN** 系统 SHALL 将池根路径以绝对路径形式持久化（若传入相对路径则先 Abs 再存，或拒绝非绝对路径）
- **AND** 若采用 URI 字段，location SHALL 为 `local:///` 加上该绝对路径

#### Scenario: 从 URI 解析池根供读写使用
- **WHEN** PoolManager 或主存储需要解析池的根路径
- **THEN** 系统 SHALL 从 location URI 的 path 部分得到池根
- **AND** 该 path 部分 SHALL 为绝对路径（local 类型）

#### Scenario: 未来扩展 scheme 与云存储
- **WHEN** 支持非本地存储（如 s3、oss）时
- **THEN** location SHALL 使用对应 scheme（如 `s3://bucket/prefix`、`oss://bucket/prefix`）
- **AND** 解析逻辑 SHALL 按 scheme 分发，本地仍使用 path 部分为绝对路径

### Requirement: 创建存储池仅使用 location、存储类型由 URI scheme 派生

存储池的 location SHALL 为必填属性。创建存储池时，系统 SHALL 仅接受 location（URI），SHALL NOT 要求或接受调用方单独传入 storage_type；storage_type SHALL 由 location URI 的 scheme 解析得到（如 `local`、未来 `s3`）并写入 DB。解析与校验逻辑 SHALL 统一基于 location（必填、必解析），SHALL NOT 按 storage_type 分支「仅当某类型时才解析 location」。响应与 DB 可保留 storage_type 字段（由 location 派生），用于列表筛选与展示。系统 SHALL NOT 保留「创建时同时指定 storage_type 与 location」的向后兼容。

#### Scenario: 创建池仅传 location
- **WHEN** 调用方创建存储池并仅提供 location（如 `local:///absolute/path`）
- **THEN** 系统 SHALL 解析 location 得到 scheme 与 path
- **AND** 将 scheme 作为 storage_type 写入 DB，规范化后的 location 写入 DB
- **AND** SHALL NOT 要求或使用请求体中的 storage_type 字段

#### Scenario: 解析与规范化不按 storage_type 分支
- **WHEN** 服务端创建或更新池、或 PoolManager 将 DB 模型转为缓存对象
- **THEN** 系统 SHALL 统一从 location 解析（必填、必解析）
- **AND** 按 scheme 做路径规范化（如 local 用 BuildLocal），SHALL NOT 先判断 storage_type 再决定是否解析 location
