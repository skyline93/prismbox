## ADDED Requirements

### Requirement: 回收站数据展示

回收站页面 SHALL 展示已软删除的本地资产和远程资产。系统 SHALL 支持按删除时间分组展示，支持过滤选项（全部/仅本地/仅远程）。

#### Scenario: 回收站数据查询
- **WHEN** 加载回收站数据
- **THEN** 系统 SHALL 查询本地资产表中 `deletedAt IS NOT NULL` 的记录
- **AND** 系统 SHALL 查询远程资产表中 `deletedAt IS NOT NULL` 的记录
- **AND** 系统 SHALL 合并本地和远程资产列表
- **AND** 系统 SHALL 按删除时间降序排序
- **AND** 系统 SHALL 按删除时间分组展示（类似时间线页面）

#### Scenario: 回收站过滤选项
- **WHEN** 用户选择"全部"过滤模式
- **THEN** 系统 SHALL 展示所有已删除的本地资产和远程资产

- **WHEN** 用户选择"仅本地"过滤模式
- **THEN** 系统 SHALL 仅展示已删除的本地资产
- **AND** 系统 SHALL 不展示已删除的远程资产

- **WHEN** 用户选择"仅远程"过滤模式
- **THEN** 系统 SHALL 仅展示已删除的远程资产
- **AND** 系统 SHALL 不展示已删除的本地资产

- **WHEN** 用户切换过滤模式
- **THEN** 系统 SHALL 通过过滤按钮提供过滤选项
- **AND** 系统 SHALL 支持循环切换（全部 → 仅本地 → 仅远程 → 全部）
- **AND** 系统 SHALL 实时更新过滤结果

#### Scenario: 回收站页面展示
- **WHEN** 用户进入回收站页面
- **THEN** 系统 SHALL 使用与照片页面相同的展示方式（时间线分组列表）
- **AND** 系统 SHALL 复用 `SelectableTimelineSliverList` 组件展示媒体网格
- **AND** 系统 SHALL 复用 `TimelineNormalAppBar` 和 `TimelineSelectionAppBar` 组件
- **AND** 系统 SHALL 在 AppBar 左侧显示过滤按钮
- **AND** 系统 SHALL 支持选择模式（长按或点击选择按钮进入）

#### Scenario: 回收站预览功能
- **WHEN** 用户点击回收站中的媒体资源
- **THEN** 系统 SHALL 导航到媒体查看器页面
- **AND** 系统 SHALL 传递回收站中的所有媒体资源 ID 列表
- **AND** 系统 SHALL 支持在查看器中浏览所有回收站资源

### Requirement: 回收站恢复功能

回收站页面 SHALL 支持恢复已删除的资源。本地资源恢复时将文件从回收站复制回系统相册，远程资源恢复时调用后端 API。

#### Scenario: 本地资源恢复
- **WHEN** 用户选择本地资源并点击恢复按钮
- **THEN** 系统 SHALL 从回收站复制文件回原始路径（`originalPath` 字段）
- **AND** 系统 SHALL 使用 photo_manager 将文件添加回系统相册（如需要）
- **AND** 系统 SHALL 删除回收站中的文件（`trashPath` 字段）
- **AND** 系统 SHALL 更新本地资产表：清空 `deletedAt`, `originalPath`, `trashPath` 字段，恢复 `path` 为原始路径
- **AND** 系统 SHALL 刷新回收站数据

#### Scenario: 远程资源恢复
- **WHEN** 用户选择远程资源并点击恢复按钮
- **THEN** 系统 SHALL 调用后端 API `POST /api/v1/media/:uuid/restore`
- **AND** 系统 SHALL 更新本地远程资产表的 `deletedAt` 字段为 `NULL`
- **AND** 系统 SHALL 刷新回收站数据
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

### Requirement: 回收站永久删除功能

回收站页面 SHALL 支持永久删除已删除的资源。本地资源永久删除时将删除回收站文件，远程资源永久删除时调用后端 API。

#### Scenario: 本地资源永久删除
- **WHEN** 用户选择本地资源并点击永久删除按钮
- **THEN** 系统 SHALL 显示确认对话框（警告永久删除无法恢复）
- **AND** 用户确认后，系统 SHALL 删除回收站中的文件（`trashPath` 字段）
- **AND** 系统 SHALL 从数据库删除记录（硬删除）
- **AND** 系统 SHALL 刷新回收站数据

#### Scenario: 远程资源永久删除
- **WHEN** 用户选择远程资源并点击永久删除按钮
- **THEN** 系统 SHALL 显示确认对话框（警告永久删除无法恢复）
- **AND** 用户确认后，系统 SHALL 调用后端 API `DELETE /api/v1/media/:uuid/purge`
- **AND** 系统 SHALL 从本地数据库删除远程资产记录（硬删除）
- **AND** 系统 SHALL 刷新回收站数据

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

### Requirement: 回收站选择模式

回收站页面 SHALL 支持选择模式，允许用户选择多个资源进行批量操作（恢复或永久删除）。

#### Scenario: 进入选择模式
- **WHEN** 用户长按回收站中的媒体资源
- **THEN** 系统 SHALL 进入选择模式
- **AND** 系统 SHALL 切换 AppBar 为选择模式 AppBar（显示选中数量和关闭按钮）
- **AND** 系统 SHALL 显示底部操作栏（恢复按钮、永久删除按钮）
- **AND** 系统 SHALL 自动选中被长按的资源

#### Scenario: 选择模式操作
- **WHEN** 用户在选择模式下点击媒体资源
- **THEN** 系统 SHALL 切换该资源的选中状态
- **AND** 系统 SHALL 更新底部操作栏的选中数量

#### Scenario: 选择模式退出
- **WHEN** 用户点击选择模式 AppBar 的关闭按钮
- **THEN** 系统 SHALL 退出选择模式
- **AND** 系统 SHALL 清除所有选中状态
- **AND** 系统 SHALL 切换 AppBar 为正常模式 AppBar
- **AND** 系统 SHALL 隐藏底部操作栏

