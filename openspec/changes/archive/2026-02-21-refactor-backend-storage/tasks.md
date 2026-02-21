# Tasks: refactor-backend-storage

## 1. Key 与路径语义统一

- [x] 1.1 在存储层定义 key 格式常量与相对路径格式（如 `files/{hash[:2]}/{hash[2:4]}/{hash}[_variant].{ext}`），并实现仅输出相对路径的 PathResolver（ResolveFilePath 返回相对路径，不包含 BasePath）。
- [x] 1.2 修改 LocalStorage Put/Get/Delete/Exists/Stat/GetSignedURL 等，使 fullPath = filepath.Join(pool.Path, key)，其中 key 为相对路径；PathResolver 的 basePath 仅用于 ResolveTempPath、ResolveStagingPath 及后续可配置的 cache 根目录。
- [x] 1.3 将配置中 BasePath 的语义文档化（仅 temp/staging/cache），并在 loader defaultConfig 或注释中说明与池根的关系。

## 2. Key 解析与构建单一来源

- [x] 2.1 在 internal/storage 或 internal/storage/keys 中提供统一的 BuildKey、ResolveKey（及必要时 ParseKey），以及 variant 常量（如 thumbnail、preview、thumbnail_200x200）；PathResolver 保留 ResolveFilePath 但仅基于相对路径逻辑，与上述函数共享格式约定。
- [x] 2.2 修改 StorageAdapter：移除重复的 BuildStorageKey、ParseStorageKey、BuildDynamicThumbnailKey 等中的 key 字符串拼接与解析，改为调用存储层统一 BuildKey；StorageAdapter 仅保留业务类型到 extension+variant 的映射（ToStorageOptions、GetThumbnailKey、GetPreviewKey 等调用存储层 BuildKey）。
- [x] 2.3 为 key 格式与 variant 常量补充单元测试，确保解析与构建往返一致及与现有 key 格式兼容。

## 3. 配置收敛与缓存可配置、Secondary 从默认 config 隐藏

- [x] 3.1 在 storage.config 中增加磁盘缓存路径配置项（如 performance.cache_path），并在 LocalStorage 的 CacheManager 构造时使用该配置；移除 cache.go 中写死的 `./cache`，未配置时使用默认目录或禁用磁盘缓存并文档化。
- [x] 3.2 确保 storage.primary.local.temp.base_path、storage.primary.local.performance.cache_path 等键带有 mapstructure tag，并在 config/loader 中为 storage 相关环境变量覆盖补全（与现有 storage.primary.local.base_path 类似），使 Viper 与 env 合并生效。
- [x] 3.3 将 PoolManager、Temp、Processing、Performance 的默认值收敛到单一来源（如 loader defaultConfig 或 storage 包内 default 函数），减少 pool_manager 中 normalize 与 loader 的重复默认值；文档化高级参数（flush_interval、reconcile_interval 等）的默认值与调优场景。
- [x] 3.4 默认生成的配置（Loader 的 defaultConfig 或首次生成 config.yaml 时的输出）SHALL 不包含 `storage.secondary`；代码内保留 SecondaryStorageConfig 类型与 NewSecondaryStorage 工厂占位（返回未实现错误），不删除接口与类型定义。

## 4. 媒体元数据 pool_id 与写时记录、读时定向（本次实现）

- [x] 4.1 在媒体元数据中增加 pool_id 字段（如 media 表或与 key 关联的扩展表），并在主存储 Put 成功后写时记录该关联；设计时考虑 key 与 media 的对应关系（如按 media_uuid + variant 或 storage_key 存储 pool_id），包含 DB migration。
- [x] 4.2 修改主存储 Get（及 Exists/Stat 等需定位文件的接口）：若调用方传入或可从元数据解析出 pool_id，则仅在该池下用 key 查找；未提供 pool_id 时保留现有多池顺序查找作为回退。
- [x] 4.3 在媒体服务或调用存储的层在 Get 前查询 pool_id（若存在）并传入主存储，实现读时定向；为 pool_id 写入与读取路径增加单元测试或集成测试。

## 5. 生命周期与 GetSignedURL

- [x] 5.1 为 PrimaryStorage 或 LocalStorage/PoolManager 定义 Close 方法，在其中停止 delta worker、cache refresher、reconciler 等 goroutine（PoolManager 已有 Close，确保 LocalStorage 暴露并在应用退出时调用）。
- [x] 5.2 在 App 或 cmd/server main 的优雅退出流程中调用 PrimaryStorage 的 Close（若接口存在），确保在 HTTP 服务 Shutdown 之后、进程退出前执行。
- [x] 5.3 明确本地存储 GetSignedURL 的语义：在实现或接口注释中说明返回值为可经 API 网关访问的 URL 或仅内部使用的路径；若当前返回本地路径，在文档或注释中标注「对外签名 URL 由 API 层实现」。

## 6. 校验与文档

- [x] 6.1 运行 `openspec validate refactor-backend-storage --strict` 并确保通过。
- [x] 6.2 更新后端存储相关文档（如 internal/storage/primary/local/README.md 或顶层 docs）：说明 key=相对路径、BasePath 仅用于 temp/cache、配置项 cache_path 与 temp base_path、池根来自 DB、读路径 pool_id 定向等。
- [x] 6.3 为 PathResolver、统一 BuildKey/ResolveKey、StorageAdapter 调用处补充或更新单元测试；必要时为 Put 后 pool_id 写入与 Get 时 pool_id 定向增加集成测试或测试用例。

## 7. base_path 重构（降低心智负担）

- [x] 7.1 在配置中引入单一 `data_dir`（或 `working_dir`），或将 `storage.primary.local.base_path` 重命名为 `temp_staging_root`（或等价键）；在 loader defaultConfig 与 env 映射中更新键名与文档说明「仅用于临时/staging/缓存，媒体由存储池 location 决定」。
- [x] 7.2 修改 PathResolver、TempFileManager 及 CacheManager 的根目录来源：若采用 data_dir，则 temp/staging/cache 默认为 data_dir 下固定子目录，仍允许 temp.base_path、performance.cache_path 覆盖；若采用重命名，则仅从新键读取并保持现有逻辑结构。
- [x] 7.3 更新 STORAGE_CONFIGURATION.md 与 backend-configuration 相关文档：明确工作根与池根的区别、新配置键或 data_dir 子目录约定；不保留旧 base_path 兼容，仅文档化新配置与升级步骤。

## 8. 存储池根路径仅使用绝对路径

- [x] 8.1 在存储池创建/更新逻辑（API handler、storagepool service、CLI）中：对 local 类型，若传入路径为相对路径则使用 `filepath.Abs()` 规范化后写入 DB，或仅接受绝对路径并校验（非绝对则返回错误）；在文档中明确行为。
- [x] 8.2 PoolManager 与 PathResolver 使用池根时，仅读取并信任 DB 中已规范化的绝对路径；不保留对历史相对路径的运行时兼容。若有旧数据需通过一次性迁移脚本批量更新为绝对路径后再使用。
- [x] 8.3 为创建/更新池的路径校验或规范化添加单元测试；更新 STORAGE_CONFIGURATION.md 与 API/CLI 文档说明「池根路径以绝对路径存储」。

## 9. 存储池位置采用 restic 风格 URI

- [x] 9.1 在 API DTO 与 DB 模型中以 `location` 作为唯一位置字段，格式为 URI：本地池为 `local:///absolute/path`；解析时 scheme 对应 storage_type，path 部分为池根且 SHALL 为绝对路径。移除或废弃 `local_path` 字段，不对其做兼容读取。
- [x] 9.2 实现 URI 解析与序列化：从 location 解析出 storage_type 与池根路径；创建/更新池时仅接受 location；PoolManager 仅从 location 解析出 Path 供 LocalStorage 使用。
- [x] 9.3 提供一次性数据迁移脚本：将现有 storage_pools 表中 local_path 非空记录转为 location = `local:///` + filepath.Abs(local_path) 并写入；迁移完成后代码仅读 location，不保留读时回退 local_path。
- [x] 9.4 更新 API 文档、CLI 帮助与 STORAGE_CONFIGURATION.md：说明 location URI 格式、local 与未来 s3/oss 示例；Swagger/OpenAPI 与 env 示例同步更新。

## 10. location 为唯一位置来源、storage_type 由 location 派生

- [x] 10.1 创建存储池 API/CLI：仅接受 `location`（必填），不再接受 `storage_type`；服务端从 location URI 解析 scheme，将 scheme 作为 storage_type 写入 DB，并规范化 location 后持久化。
- [x] 10.2 移除「仅当 storage_type 为 local 时才解析/校验 location」等分支：创建与更新逻辑统一为「location 必填、必 Parse(location)、按 scheme 做规范化」；PoolManager 的 convertModelToPool 等处统一从 location 解析路径与类型，不再按 model.StorageType 分支。
- [x] 10.3 请求体与 Swagger：createPoolRequest 移除 `storage_type` 必填项，改为 `location` 必填；响应与 DB 保留 `storage_type` 字段（由 location 派生，只读）；CLI 创建池参数仅保留 `--location` 等，去掉 `--storage-type`。
- [x] 10.4 更新 STORAGE_CONFIGURATION.md 与 API 文档：说明创建池只需提供 location，存储类型由 URI scheme 决定；不保留旧「同时指定 storage_type + location」的兼容。
