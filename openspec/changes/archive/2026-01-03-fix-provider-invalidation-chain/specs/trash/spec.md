## MODIFIED Requirements

### Requirement: 回收站恢复功能

回收站页面 SHALL 支持恢复已删除的资源。本地资源恢复时将文件从回收站复制回系统相册，远程资源恢复时调用后端 API。恢复操作完成后，系统 SHALL 立即刷新回收站数据，确保 UI 立即更新。

#### Scenario: 本地资源恢复
- **WHEN** 用户选择本地资源并点击恢复按钮
- **THEN** 系统 SHALL 从回收站复制文件回原始路径（`originalPath` 字段）
- **AND** 系统 SHALL 使用 photo_manager 将文件添加回系统相册（如需要）
- **AND** 系统 SHALL 删除回收站中的文件（`trashPath` 字段）
- **AND** 系统 SHALL 更新本地资产表：清空 `deletedAt`, `originalPath`, `trashPath` 字段，恢复 `path` 为原始路径
- **AND** 系统 SHALL 在恢复完成后立即刷新回收站数据，确保 UI 立即更新
- **AND** 系统 SHALL 同时 invalidate `trashAssetsProvider` 和 `trashSectionsProvider`，确保依赖链上的所有 provider 都刷新

#### Scenario: 远程资源恢复
- **WHEN** 用户选择远程资源并点击恢复按钮
- **THEN** 系统 SHALL 调用后端 API `POST /api/v1/media/:uuid/restore`
- **AND** 系统 SHALL 更新本地远程资产表的 `deletedAt` 字段为 `NULL`
- **AND** 系统 SHALL 在恢复完成后立即刷新回收站数据，确保 UI 立即更新
- **AND** 系统 SHALL 同时 invalidate `trashAssetsProvider` 和 `trashSectionsProvider`，确保依赖链上的所有 provider 都刷新
- **AND** 系统 SHALL 触发远程资产同步（如需要）

#### Scenario: 恢复操作错误处理
- **WHEN** 恢复操作失败
- **THEN** 系统 SHALL 显示错误提示
- **AND** 系统 SHALL 不更新数据库记录（如果文件操作失败）
- **AND** 系统 SHALL 允许用户重试恢复操作

#### Scenario: 批量恢复
- **WHEN** 用户在选择模式下选择多个资源并点击恢复按钮
- **THEN** 系统 SHALL 按资源类型分组执行恢复操作
- **AND** 系统 SHALL 批量恢复本地资源
- **AND** 系统 SHALL 批量调用后端 API 恢复远程资源
- **AND** 系统 SHALL 显示恢复进度（如需要）
- **AND** 系统 SHALL 在恢复完成后同时 invalidate `trashAssetsProvider` 和 `trashSectionsProvider`，确保回收站页面立即更新

### Requirement: 回收站永久删除功能

回收站页面 SHALL 支持永久删除已删除的资源。本地资源永久删除时将删除回收站文件，远程资源永久删除时调用后端 API。永久删除操作完成后，系统 SHALL 立即刷新回收站数据，确保 UI 立即更新。

#### Scenario: 本地资源永久删除
- **WHEN** 用户选择本地资源并点击永久删除按钮
- **THEN** 系统 SHALL 显示确认对话框（警告永久删除无法恢复）
- **AND** 用户确认后，系统 SHALL 删除回收站中的文件（`trashPath` 字段）
- **AND** 系统 SHALL 从数据库删除记录（硬删除）
- **AND** 系统 SHALL 在永久删除完成后立即刷新回收站数据，确保 UI 立即更新
- **AND** 系统 SHALL 同时 invalidate `trashAssetsProvider` 和 `trashSectionsProvider`，确保依赖链上的所有 provider 都刷新

#### Scenario: 远程资源永久删除
- **WHEN** 用户选择远程资源并点击永久删除按钮
- **THEN** 系统 SHALL 显示确认对话框（警告永久删除无法恢复）
- **AND** 用户确认后，系统 SHALL 调用后端 API `DELETE /api/v1/media/:uuid/purge`
- **AND** 系统 SHALL 从本地数据库删除远程资产记录（硬删除）
- **AND** 系统 SHALL 在永久删除完成后立即刷新回收站数据，确保 UI 立即更新
- **AND** 系统 SHALL 同时 invalidate `trashAssetsProvider` 和 `trashSectionsProvider`，确保依赖链上的所有 provider 都刷新

#### Scenario: 永久删除操作错误处理
- **WHEN** 永久删除操作失败
- **THEN** 系统 SHALL 显示错误提示
- **AND** 系统 SHALL 不删除数据库记录（如果文件操作失败）
- **AND** 系统 SHALL 允许用户重试永久删除操作

#### Scenario: 批量永久删除
- **WHEN** 用户在选择模式下选择多个资源并点击永久删除按钮
- **THEN** 系统 SHALL 显示确认对话框（警告永久删除无法恢复）
- **AND** 用户确认后，系统 SHALL 按资源类型分组执行永久删除操作
- **AND** 系统 SHALL 批量永久删除本地资源
- **AND** 系统 SHALL 批量调用后端 API 永久删除远程资源
- **AND** 系统 SHALL 显示删除进度（如需要）
- **AND** 系统 SHALL 在永久删除完成后同时 invalidate `trashAssetsProvider` 和 `trashSectionsProvider`，确保回收站页面立即更新

