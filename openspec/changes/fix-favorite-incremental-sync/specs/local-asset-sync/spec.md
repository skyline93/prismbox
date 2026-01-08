# local-asset-sync Specification Delta

## MODIFIED Requirements

### Requirement: 增量同步

系统 SHALL 提供增量同步功能，只处理新增/修改/删除的资产，通过修改时间快速判断，避免全量对比。

#### Scenario: 增量同步（修改前）
- **WHEN** 执行增量同步（数据库已有数据）
- **THEN** 系统 SHALL 只处理新增/修改/删除的资产
- **AND** 系统 SHALL 通过修改时间快速判断，避免全量对比
- **AND** 系统 SHALL 不计算文件 hash（checksum）

#### Scenario: 增量同步（修改后）
- **WHEN** 执行增量同步（数据库已有数据）
- **THEN** 系统 SHALL 只处理新增/修改/删除的资产
- **AND** 系统 SHALL 通过修改时间快速判断，避免全量对比
- **AND** 系统 SHALL 检查所有已存在资产的收藏状态是否变化
- **AND** 系统 SHALL 如果收藏状态变化，即使修改时间没有变化，也要更新数据库
- **AND** 系统 SHALL 使用批量 API 获取收藏状态，优化性能
- **AND** 系统 SHALL 不计算文件 hash（checksum）

#### Scenario: 检测收藏状态变化
- **WHEN** 执行增量同步
- **AND** 数据库中已存在某个资产
- **AND** 该资产的 `modifiedDateTime` 没有变化
- **AND** 系统相册中该资产的收藏状态与数据库中的不同
- **THEN** 系统 SHALL 检测到收藏状态变化
- **AND** 系统 SHALL 更新数据库中的 `isFavorite` 字段
- **AND** 系统 SHALL 将该资产添加到更新列表

#### Scenario: 批量获取收藏状态
- **WHEN** 执行增量同步
- **AND** 需要检查已存在资产的收藏状态
- **THEN** 系统 SHALL 使用批量 API（`getAssetMetadata`）获取收藏状态
- **AND** 系统 SHALL 每批处理最多 100 个资产
- **AND** 系统 SHALL 如果批量获取失败，跳过收藏状态检查（不影响其他同步逻辑）

