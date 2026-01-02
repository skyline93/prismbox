## ADDED Requirements

### Requirement: 本地资产同步

系统 SHALL 提供本地资产同步功能，扫描设备媒体库并同步到本地数据库。本地资产同步 SHALL 完全独立于远程资产同步，不进行任何关联。

#### Scenario: 全量同步
- **WHEN** 执行全量同步（首次同步或数据库为空）
- **THEN** 系统 SHALL 扫描所有系统相册资产
- **AND** 系统 SHALL 批量写入数据库（每批 100 个）
- **AND** 系统 SHALL 检测已删除的资产并更新数据库
- **AND** 系统 SHALL 不计算文件 hash（checksum）

#### Scenario: 增量同步
- **WHEN** 执行增量同步（数据库已有数据）
- **THEN** 系统 SHALL 只处理新增/修改/删除的资产
- **AND** 系统 SHALL 通过修改时间快速判断，避免全量对比
- **AND** 系统 SHALL 不计算文件 hash（checksum）

#### Scenario: 上传状态标识
- **WHEN** 同步本地资产到数据库
- **THEN** 系统 SHALL 为每个本地资产维护 `isUploaded` 字段
- **AND** `isUploaded` 字段 SHALL 默认为 `false`
- **AND** `isUploaded` 字段 SHALL 仅在上传成功时更新为 `true`

#### Scenario: 独立于远程资产
- **WHEN** 执行本地资产同步
- **THEN** 系统 SHALL 不查询远程资产表
- **AND** 系统 SHALL 不进行 checksum 匹配
- **AND** 系统 SHALL 不建立本地-远程资产关联

