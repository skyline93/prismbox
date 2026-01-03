## MODIFIED Requirements

### Requirement: 时间线数据合并和展示

时间线页面 SHALL 独立展示本地资产和远程资产，不进行自动关联去重。系统 SHALL 支持过滤选项，允许用户选择查看方式。

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

