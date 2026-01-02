## 1. 建立配置架构基础

- [x] 1.1 创建 `lib/core/config/config_registry.dart` - 配置注册表统一入口
- [x] 1.2 创建 `lib/core/config/network_config.dart` - 网络配置类（超时、重试等）
- [x] 1.3 创建 `lib/core/config/task_config.dart` - 任务配置类（上传超时、检查间隔等）
- [x] 1.4 创建 `lib/core/config/cache_config.dart` - 缓存配置类（TTL、大小限制等）
- [x] 1.5 扩展 `lib/core/config/sync_config.dart` - 保持现有结构，添加文档说明

## 2. 提取硬编码配置值

- [x] 2.1 从 `api_service.dart` 提取网络超时配置到 `NetworkConfig`
- [x] 2.2 从 `task_status_repair_service.dart` 提取任务配置到 `TaskConfig`
- [x] 2.3 从 `upload_orchestrator.dart` 提取轮询和超时配置到 `TaskConfig`
- [x] 2.4 从 `backup_state_refresh_service.dart` 提取刷新间隔配置
- [x] 2.5 识别并提取其他服务中的硬编码配置值

## 3. 清理配置冲突

- [x] 3.1 移除 `StoreKey.allowSelfSignedSSLCert`（已废弃）
- [x] 3.2 确认并清理 `StoreKey.serverUrl` 和 `serverEndpoint`（如已废弃）
- [x] 3.3 统一 SSL 配置来源为 `AppConfig.ssl`
- [x] 3.4 更新 `http_ssl_options.dart` 移除废弃方法

## 4. 重构配置访问

- [x] 4.1 更新 `api_service.dart` 使用 `NetworkConfig`
- [x] 4.2 更新 `task_status_repair_service.dart` 使用 `TaskConfig`
- [x] 4.3 更新 `upload_orchestrator.dart` 使用 `TaskConfig`
- [x] 4.4 更新其他使用硬编码配置的服务类
- [ ] 4.5 更新配置访问文档和示例

## 5. 配置验证和文档

- [x] 5.1 为每个配置类添加类级别文档
- [x] 5.2 为每个配置项添加字段文档（用途、默认值、调整建议）
- [ ] 5.3 添加配置值范围验证（如需要）
- [ ] 5.4 创建配置项清单文档
- [ ] 5.5 更新 README 说明配置架构

## 6. 代码质量检查

- [x] 6.1 运行 `dart analyze` 检查代码质量
- [x] 6.2 运行 `dart format` 格式化代码
- [x] 6.3 检查所有配置类是否遵循命名规范
- [x] 6.4 验证配置访问的类型安全性

## 7. 单元测试

- [ ] 7.1 为 `ConfigRegistry` 编写单元测试
- [ ] 7.2 为 `NetworkConfig` 编写单元测试
- [ ] 7.3 为 `TaskConfig` 编写单元测试
- [ ] 7.4 为 `CacheConfig` 编写单元测试
- [ ] 7.5 测试配置验证逻辑（如需要）

