# Change: 彻底清理后端 changelog 功能模块

## Why

changelog 模块是后端的一个废弃功能模块，当前处于废弃状态，后续将被清理。该模块：

1. **未被使用**：虽然代码存在，但功能已被其他同步机制替代（如 `sync` 模块）
2. **增加维护成本**：保留废弃代码会增加代码库复杂度，影响可维护性
3. **存在潜在问题**：changelog 的适配器逻辑（`ChangelogAwareMediaRepository`）可能导致数据更新问题（如远程资产删除时软删除失败）
4. **代码冗余**：与现有的 `sync` 模块功能重叠，造成代码冗余

**根本原因**：changelog 模块设计用于提供变更日志同步功能，但项目已采用更直接的流式同步机制（`sync` 模块），changelog 模块不再需要。

## What Changes

- **REMOVED**: 删除 `backend/internal/changelog/` 目录下的所有文件（9个文件）
- **REMOVED**: 删除 `backend/internal/api/v1/changelog/` 目录下的所有文件（2个文件）
- **MODIFIED**: 从 `backend/internal/app/app.go` 中移除 `ChangelogEngine` 和 `ChangelogFactory` 字段
- **MODIFIED**: 从 `backend/internal/app/builder.go` 中移除 `BuildChangelog()` 方法调用和相关逻辑
- **MODIFIED**: 从 `backend/internal/app/builder.go` 中移除 MediaRepository 的 changelog 包装逻辑
- **MODIFIED**: 从 `backend/internal/api/router.go` 中移除 changelog 路由注册
- **MODIFIED**: 从 `backend/internal/config/config.go` 中移除 `Changelog` 配置字段
- **MODIFIED**: 从 `backend/configs/config.yaml` 中移除 `changelog` 配置节
- **MODIFIED**: 从 `backend/internal/database/models/media.go` 中移除 `ChangelogModel` 接口实现方法（`GetRecordID`, `GetTableName`, `GetIsolationKey`, `GetIsolationValue`）
- **MODIFIED**: 修复 `backend/internal/repository/media.go` 中的 `Update` 方法，添加 `RowsAffected` 检查（解决远程资产删除问题）

## Impact

- **Affected specs**: 无（changelog 模块没有对应的规范）
- **Affected code**: 
  - `backend/internal/changelog/` - 整个目录删除
  - `backend/internal/api/v1/changelog/` - 整个目录删除
  - `backend/internal/app/app.go` - 移除 changelog 相关字段
  - `backend/internal/app/builder.go` - 移除 changelog 构建逻辑
  - `backend/internal/api/router.go` - 移除 changelog 路由
  - `backend/internal/config/config.go` - 移除 changelog 配置
  - `backend/configs/config.yaml` - 移除 changelog 配置
  - `backend/internal/database/models/media.go` - 移除 ChangelogModel 接口实现
  - `backend/internal/repository/media.go` - 修复 Update 方法
- **Breaking changes**: 
  - **BREAKING**: 如果任何客户端依赖 changelog API 端点，这些端点将被移除
  - **BREAKING**: 配置文件中的 `changelog` 配置节将被移除
- **Migration**: 
  - 数据库表 `changelogs` 和 `client_sync_statuses` 可以保留（不影响功能），或通过迁移脚本删除
  - 配置文件需要移除 `changelog` 配置节

