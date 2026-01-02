## ADDED Requirements

### Requirement: 三层配置架构

应用 SHALL 使用三层配置架构管理所有配置项：

1. **编译时配置（Build-time Config）**：编译时确定，修改需重新编译
2. **运行时系统配置（Runtime System Config）**：应用级常量，运行时生效
3. **用户设置（User Settings）**：用户可配置，持久化存储

#### Scenario: 编译时配置定义
- **WHEN** 需要定义服务器地址、应用标识等编译时确定的配置
- **THEN** 配置定义在 `lib/config/app_config.dart` 中
- **AND** 配置使用 `const` 关键字，编译时确定

#### Scenario: 运行时系统配置定义
- **WHEN** 需要定义网络超时、任务间隔等系统级配置
- **THEN** 配置定义在 `lib/core/config/` 目录下的相应配置类中
- **AND** 配置通过 `ConfigRegistry` 统一访问

#### Scenario: 用户设置定义
- **WHEN** 需要定义主题、语言等用户可配置的设置
- **THEN** 设置定义在 `lib/core/settings/app_setting.dart` 中
- **AND** 设置通过 `AppSetting` 类访问，持久化存储在 `StoreService` 中

### Requirement: 配置注册表

应用 SHALL 提供配置注册表（`ConfigRegistry`）作为系统配置的统一访问入口。

#### Scenario: 配置注册表初始化
- **WHEN** 应用启动时
- **THEN** `ConfigRegistry` 自动初始化所有系统配置类
- **AND** 配置类按功能域组织（Network、Task、Cache 等）

#### Scenario: 配置访问
- **WHEN** 需要访问系统配置
- **THEN** 通过 `ConfigRegistry.network.connectTimeout` 等统一接口访问
- **AND** 配置访问是类型安全的，编译期检查

### Requirement: 网络配置管理

应用 SHALL 通过 `NetworkConfig` 类统一管理所有网络相关配置。

#### Scenario: 网络超时配置
- **WHEN** 需要配置 API 连接超时、接收超时等
- **THEN** 配置定义在 `NetworkConfig` 类中
- **AND** 配置通过 `ConfigRegistry.network` 访问
- **AND** 所有网络服务使用统一配置，不再硬编码

#### Scenario: 重试策略配置
- **WHEN** 需要配置网络请求重试次数、重试间隔等
- **THEN** 配置定义在 `NetworkConfig` 类中
- **AND** 配置可通过 `ConfigRegistry.network` 访问

### Requirement: 任务配置管理

应用 SHALL 通过 `TaskConfig` 类统一管理所有任务相关配置。

#### Scenario: 上传任务配置
- **WHEN** 需要配置上传任务最大时长、检查间隔等
- **THEN** 配置定义在 `TaskConfig` 类中
- **AND** 配置通过 `ConfigRegistry.task` 访问
- **AND** 所有任务服务使用统一配置，不再硬编码

#### Scenario: 轮询配置
- **WHEN** 需要配置任务轮询间隔、超时时间等
- **THEN** 配置定义在 `TaskConfig` 类中
- **AND** 配置可通过 `ConfigRegistry.task` 访问

### Requirement: 缓存配置管理

应用 SHALL 通过 `CacheConfig` 类统一管理所有缓存相关配置。

#### Scenario: 缓存 TTL 配置
- **WHEN** 需要配置缓存过期时间、大小限制等
- **THEN** 配置定义在 `CacheConfig` 类中
- **AND** 配置通过 `ConfigRegistry.cache` 访问

### Requirement: 配置单一来源

应用 SHALL 确保每个配置项只有一个定义来源，消除配置冲突。

#### Scenario: SSL 配置统一
- **WHEN** 需要配置 SSL 相关设置
- **THEN** 配置仅定义在 `AppConfig.ssl` 中
- **AND** 移除 `StoreKey.allowSelfSignedSSLCert` 等废弃配置项
- **AND** 所有代码统一使用 `AppConfig.ssl` 访问

#### Scenario: 服务器地址配置统一
- **WHEN** 需要配置服务器地址
- **THEN** 配置仅定义在 `AppConfig.api.serverBaseUrl` 中
- **AND** 移除废弃的 `StoreKey.serverUrl` 和 `serverEndpoint`
- **AND** 所有代码统一使用 `AppConfig.api` 访问

### Requirement: 配置文档化

应用 SHALL 为所有配置项提供清晰的文档说明。

#### Scenario: 配置类文档
- **WHEN** 定义配置类
- **THEN** 配置类包含类级别文档，说明用途和范围
- **AND** 每个配置字段包含字段文档，说明用途、默认值、调整建议

#### Scenario: 配置项清单
- **WHEN** 需要查找配置项
- **THEN** 可以通过配置类文档快速定位
- **AND** 配置项有清晰的分类和说明

### Requirement: 配置类型安全

应用 SHALL 使用强类型配置，避免字符串键和运行时错误。

#### Scenario: 类型安全访问
- **WHEN** 访问配置
- **THEN** 使用强类型接口（如 `ConfigRegistry.network.connectTimeout`）
- **AND** 编译期检查配置存在性和类型正确性
- **AND** IDE 提供自动补全和类型提示

#### Scenario: 配置验证
- **WHEN** 配置值不符合预期范围
- **THEN** 应用启动时进行验证并记录警告
- **AND** 提供合理的默认值

### Requirement: 向后兼容迁移

应用 SHALL 在重构过程中保持向后兼容，逐步迁移现有代码。

#### Scenario: 废弃 API 标记
- **WHEN** 替换旧的配置访问方式
- **THEN** 旧 API 标记为 `@Deprecated`
- **AND** 提供迁移指南和示例
- **AND** 保留旧 API 直到所有代码迁移完成

#### Scenario: 渐进式迁移
- **WHEN** 迁移现有代码使用新配置
- **THEN** 分模块逐步迁移
- **AND** 每个模块迁移后验证功能正常
- **AND** 保持代码可运行状态

