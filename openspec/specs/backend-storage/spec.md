# backend-storage Specification

## Purpose
TBD - created by archiving change refactor-backend-storage. Update Purpose after archive.
## Requirements
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

