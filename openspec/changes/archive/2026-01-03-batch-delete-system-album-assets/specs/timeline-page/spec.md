## MODIFIED Requirements

### Requirement: 时间线数据合并和展示

时间线页面 SHALL 独立展示本地资产和远程资产，不进行自动关联去重。系统 SHALL 支持过滤选项，允许用户选择查看方式。系统 SHALL 支持删除功能，根据当前过滤模式决定删除行为。

#### Scenario: 独立数据合并
- **WHEN** 获取时间线数据
- **THEN** 系统 SHALL 并行查询本地资产表和远程资产表
- **AND** 系统 SHALL 先添加所有远程资产（RemoteAsset）到列表
- **AND** 系统 SHALL 再添加所有本地资产（LocalAsset）到列表
- **AND** 系统 SHALL 不进行基于 checksum 的关联
- **AND** 系统 SHALL 不建立本地-远程资产关联
- **AND** 系统 SHALL 按创建时间降序排序

#### Scenario: 过滤选项支持
- **WHEN** 用户选择"全部"过滤模式
- **THEN** 系统 SHALL 仅展示本地媒体资源（LocalAsset）
- **AND** 系统 SHALL 包括已上传的本地媒体资源
- **AND** 系统 SHALL 包括上传失败的本地媒体资源
- **AND** 系统 SHALL 包括未上传的本地媒体资源
- **AND** 系统 SHALL 不展示远程媒体资源（RemoteAsset）

- **WHEN** 用户选择"已备份"过滤模式
- **THEN** 系统 SHALL 仅展示已上传过的本地媒体资源（LocalAsset）
- **AND** 系统 SHALL 判断已上传状态的依据为：本地资产表的 `isUploaded` 字段为 `true`
- **AND** 系统 SHALL 不展示未上传的本地媒体资源（`isUploaded == false`）
- **AND** 系统 SHALL 不展示远程媒体资源（RemoteAsset）
- **AND** 系统 SHALL 不查询上传任务表来判断上传状态

- **WHEN** 用户选择"未备份"过滤模式
- **THEN** 系统 SHALL 仅展示未上传的本地媒体资源（LocalAsset）
- **AND** 系统 SHALL 判断未上传状态的依据为：本地资产表的 `isUploaded` 字段为 `false`
- **AND** 系统 SHALL 不区分"从未上传"和"上传失败"两种情况（都视为未上传）
- **AND** 系统 SHALL 不展示已成功上传的本地媒体资源（`isUploaded == true`）
- **AND** 系统 SHALL 不展示远程媒体资源（RemoteAsset）
- **AND** 系统 SHALL 不查询上传任务表来判断上传状态

- **WHEN** 用户选择"仅云端"过滤模式
- **THEN** 系统 SHALL 仅展示远程服务端的媒体资源（RemoteAsset）
- **AND** 系统 SHALL 不展示本地媒体资源（LocalAsset）

- **WHEN** 用户切换过滤模式
- **THEN** 系统 SHALL 通过 `TimelineFilterButton` 组件提供过滤选项
- **AND** 系统 SHALL 支持循环切换（全部 → 已备份 → 未备份 → 仅云端 → 全部）
- **AND** 系统 SHALL 实时更新过滤结果

#### Scenario: 数据源选择
- **WHEN** 选择时间线数据源
- **THEN** 系统 SHALL 检查是否有远程资产
- **AND** 如果存在远程资产，系统 SHALL 使用数据库数据源（需要合并显示）
- **AND** 如果不存在远程资产，系统 SHALL 根据本地资产数量选择数据源（数据库或 photo_manager）

#### Scenario: 上传状态判断基于本地资产表
- **WHEN** 过滤本地资产时判断上传状态
- **THEN** 系统 SHALL 仅使用本地资产表的 `isUploaded` 字段判断上传状态
- **AND** 系统 SHALL 不查询上传任务表来判断上传状态
- **AND** 系统 SHALL 在创建 `LocalAsset` 实体时，从数据库实体中读取 `isUploaded` 字段并存储
- **AND** 系统 SHALL 在过滤时直接使用 `LocalAsset` 实体的 `isUploaded` 字段，无需额外查询

#### Scenario: 删除功能支持
- **WHEN** 用户在选择模式下选择资产并点击删除按钮
- **THEN** 系统 SHALL 根据当前过滤模式决定删除行为
- **AND** 如果当前过滤模式为"全部"、"已备份"或"未备份"，系统 SHALL 仅支持删除本地资源
- **AND** 如果当前过滤模式为"仅云端"，系统 SHALL 仅支持删除远程资源
- **AND** 系统 SHALL 在选择模式下显示删除按钮
- **AND** 系统 SHALL 在执行删除前显示确认对话框
- **AND** 系统 SHALL 在执行删除后刷新时间线数据

#### Scenario: 本地资源删除
- **WHEN** 用户在"全部"、"已备份"或"未备份"模式下删除本地资源
- **THEN** 系统 SHALL 执行本地资源软删除操作
- **AND** 系统 SHALL 将文件从系统相册复制到应用私有回收站空间
- **AND** 系统 SHALL 删除系统相册中的原文件
- **AND** 系统 SHALL 更新本地资产表的软删除字段（`deletedAt`, `originalPath`, `trashPath`）
- **AND** 系统 SHALL 不删除远程资产（如果存在对应的远程资产）

#### Scenario: 批量删除本地资产系统相册确认
- **WHEN** 用户批量删除多个本地资产
- **THEN** 系统 SHALL 先批量处理文件复制和数据库更新操作（不涉及系统相册删除）
- **AND** 系统 SHALL 收集所有成功处理的资产 ID
- **AND** 系统 SHALL 统一调用系统相册删除 API 删除所有资产
- **AND** 系统 SHALL 只弹出一次系统确认对话框
- **AND** 系统 SHALL 记录删除结果（成功和失败的资产 ID）
- **AND** 如果系统相册删除部分失败，系统 SHALL 记录失败的资产 ID（但文件已复制到回收站，可以从回收站恢复）

#### Scenario: 远程资源删除
- **WHEN** 用户在"仅云端"模式下删除远程资源
- **THEN** 系统 SHALL 调用后端 API 执行远程资源软删除
- **AND** 系统 SHALL 调用 `DELETE /api/v1/media/:uuid` 接口
- **AND** 系统 SHALL 更新本地远程资产表的 `deletedAt` 字段
- **AND** 系统 SHALL 不删除本地资产（如果存在对应的本地资产）

#### Scenario: 删除操作错误处理
- **WHEN** 删除操作失败
- **THEN** 系统 SHALL 显示错误提示
- **AND** 系统 SHALL 不更新数据库记录（如果文件操作失败）
- **AND** 系统 SHALL 允许用户重试删除操作

