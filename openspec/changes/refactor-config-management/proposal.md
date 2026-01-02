# Change: 重构配置管理架构

## Why

当前移动端应用的配置管理存在以下问题：

1. **配置分散**：配置分布在多个位置（`lib/config/`、`lib/core/config/`、`lib/core/settings/`），缺乏统一管理
2. **类型边界不清**：编译时配置、运行时系统配置、用户设置之间的边界不清晰
3. **硬编码配置值**：大量配置值（超时、间隔、阈值）分散在各个服务类中，难以维护和调整
4. **配置冲突风险**：同一配置项可能存在于多个位置（如 SSL 配置），存在冲突风险
5. **缺乏统一访问接口**：没有统一的配置访问入口，查找和修改配置困难

这些问题导致配置管理混乱，影响代码的可维护性和可扩展性。

## What Changes

- **BREAKING**: 建立三层配置架构（编译时配置、运行时系统配置、用户设置）
- **BREAKING**: 创建配置注册表（`ConfigRegistry`）作为统一访问入口
- **BREAKING**: 提取分散的硬编码配置值到统一的配置类中
- **BREAKING**: 清理配置冲突，统一配置来源
- **BREAKING**: 重构配置访问方式，使用统一的访问模式
- 添加配置验证和文档

## Impact

- **Affected specs**: 新增 `configuration-management` 能力规范
- **Affected code**: 
  - `lib/config/app_config.dart` - 保留并明确职责
  - `lib/core/config/` - 重构为系统配置目录
  - `lib/core/settings/app_setting.dart` - 保留并明确职责
  - 所有使用硬编码配置值的服务类（网络、任务、缓存等）
- **Migration**: 需要逐步迁移现有代码使用新的配置访问方式

