## MODIFIED Requirements

### Requirement: 远程资产同步

系统 SHALL 提供远程资产同步功能，从服务器同步远程媒体资源到本地数据库。远程资产同步 SHALL 完全独立于本地资产同步，不进行任何关联。

#### Scenario: 流式同步
- **WHEN** 执行远程资产同步
- **THEN** 系统 SHALL 使用流式 API 从服务器获取资产列表
- **AND** 系统 SHALL 支持全量同步（reset=true）和增量同步（updatedAfter）
- **AND** 系统 SHALL 批量写入数据库（每批 100 个）
- **AND** 系统 SHALL 处理删除事件（软删除）
- **AND** 系统 SHALL 在增量同步时接收并处理 `asset_delete_v1` 事件
- **AND** 系统 SHALL 在收到删除事件后更新本地数据库的 `deletedAt` 字段

#### Scenario: 删除事件同步
- **WHEN** 服务器上有资产被软删除（deleted=true）
- **AND** 执行增量同步（updatedAfter 时间点之后）
- **THEN** 服务器 SHALL 查询在时间范围内被软删除的资产
- **AND** 服务器 SHALL 发送 `asset_delete_v1` 事件，包含已删除资产的ID列表
- **AND** 客户端 SHALL 收到删除事件后调用 `softDeleteAsset` 更新本地数据库
- **AND** 客户端 SHALL 设置 `deletedAt` 字段为当前时间

#### Scenario: 永久删除事件同步
- **WHEN** 服务器上有资产被永久删除（PurgeMedia）
- **AND** 该资产之前未被软删除（deleted=false）
- **THEN** 服务器 SHALL 在永久删除前发送 `asset_delete_v1` 事件
- **AND** 客户端 SHALL 收到删除事件后更新本地数据库
- **AND** 如果资产之前已被软删除（deleted=true），服务器 SHALL 不发送删除事件（其他设备应该已经收到）

#### Scenario: 独立于本地资产
- **WHEN** 执行远程资产同步
- **THEN** 系统 SHALL 不查询本地资产表
- **AND** 系统 SHALL 不进行 checksum 匹配
- **AND** 系统 SHALL 不建立远程-本地资产关联
- **AND** 远程资产 SHALL 包含服务器计算的 checksum（用于后端去重）

#### Scenario: 数据源选择
- **WHEN** 选择时间线数据源
- **THEN** 系统 SHALL 检查是否有远程资产
- **AND** 如果存在远程资产，系统 SHALL 使用数据库数据源（需要合并显示）
- **AND** 如果不存在远程资产，系统 SHALL 根据本地资产数量选择数据源

