# Design: 清理 changelog 模块

## Context

changelog 模块是后端的一个废弃功能模块，设计用于提供变更日志（Change Data Capture）同步功能。但项目已采用更直接的流式同步机制（`sync` 模块），changelog 模块不再需要。

当前 changelog 模块存在的问题：
1. 代码存在但未被使用
2. `ChangelogAwareMediaRepository` 适配器逻辑可能导致数据更新问题
3. 增加代码库复杂度和维护成本

## Goals / Non-Goals

### Goals
- 彻底移除 changelog 模块的所有代码
- 清理所有对 changelog 的引用和依赖
- 修复因 changelog 适配器导致的数据更新问题
- 保持代码库简洁，减少维护成本

### Non-Goals
- 不迁移 changelog 数据库表（可以保留，不影响功能）
- 不提供 changelog 功能的替代实现（已有 sync 模块）

## Decisions

### Decision 1: 数据库表处理

**决策**：保留 `changelogs` 和 `client_sync_statuses` 数据库表，不删除。

**理由**：
- 删除表需要数据库迁移脚本，增加复杂度
- 保留表不影响功能，只是占用少量存储空间
- 如果未来需要，可以手动删除

**替代方案考虑**：
- 创建迁移脚本删除表：需要额外的迁移逻辑，当前不必要

### Decision 2: MediaRepository 包装逻辑移除

**决策**：直接移除 changelog 包装逻辑，使用原始 MediaRepository。

**理由**：
- changelog 包装逻辑可能导致数据更新问题（如 `Update` 方法使用 `FindByUUID` 而不是 `FindActiveByUUIDAndUser`）
- 移除包装后，MediaRepository 直接使用原始实现，逻辑更清晰

**影响**：
- `BuildRepositories()` 方法中的条件判断逻辑可以简化
- MediaRepository 不再需要适配器包装

### Decision 3: Update 方法修复

**决策**：在 `mediaRepository.Update` 方法中添加 `RowsAffected` 检查。

**理由**：
- 修复因 changelog 适配器导致的数据更新问题
- 确保更新操作真正执行，如果没有影响任何行，返回错误

**实现**：
```go
if result.RowsAffected == 0 {
    return gorm.ErrRecordNotFound
}
```

## Risks / Trade-offs

### Risks
- **低风险**：如果任何客户端依赖 changelog API 端点，这些端点将被移除
  - **缓解**：changelog 模块已废弃，应该没有客户端在使用

- **低风险**：配置文件变更可能导致配置加载失败
  - **缓解**：配置字段是可选的，移除后不会导致错误

### Trade-offs
- **代码简洁性 vs 功能完整性**：选择代码简洁性，移除未使用的功能
- **立即清理 vs 渐进式清理**：选择立即清理，减少技术债务

## Migration Plan

### 步骤
1. 删除所有 changelog 相关代码文件
2. 清理所有引用和导入
3. 修复 MediaRepository Update 方法
4. 验证代码编译和运行

### 回滚
如果出现问题，可以通过 Git 回滚到清理前的版本。

## Open Questions

- 是否需要创建数据库迁移脚本删除 changelog 表？（当前决策：不需要）

