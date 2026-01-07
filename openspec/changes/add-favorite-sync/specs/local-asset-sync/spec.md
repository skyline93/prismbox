## ADDED Requirements

### Requirement: 收藏属性同步

系统 SHALL 在本地资产同步流程中从系统相册读取收藏（favorite）属性，并存储到本地数据库。收藏属性的获取 SHALL 通过原生平台 API 实现，支持 iOS 和 Android 平台。

#### Scenario: iOS 平台获取收藏状态

- **WHEN** 在 iOS 平台执行本地资产同步
- **THEN** 系统 SHALL 通过 PHAsset.isFavorite 属性获取每个资产的收藏状态
- **AND** 系统 SHALL 将收藏状态存储到 LocalAssetEntityData 的 isFavorite 字段
- **AND** 获取失败时系统 SHALL 记录警告日志并默认为 false

#### Scenario: Android 平台获取收藏状态

- **WHEN** 在 Android 平台执行本地资产同步
- **THEN** 系统 SHALL 检测 Android 版本是否为 11 (API 30) 及以上
- **AND** 如果版本支持，系统 SHALL 通过 MediaStore.MediaColumns.IS_FAVORITE 字段查询收藏状态
- **AND** 如果版本不支持（Android 10-），系统 SHALL 默认返回 false
- **AND** 系统 SHALL 将收藏状态存储到 LocalAssetEntityData 的 isFavorite 字段
- **AND** 获取失败时系统 SHALL 记录警告日志并默认为 false

#### Scenario: 原生平台桥接

- **WHEN** 需要获取资产的收藏状态
- **THEN** 系统 SHALL 通过 Pigeon 定义的 AssetNativeApi 接口与原生平台通信
- **AND** 接口 SHALL 提供 getIsFavorite(String assetId) 方法获取单个资产收藏状态
- **AND** 接口 SHALL 提供 getAssetMetadata(List<String> assetIds) 方法批量获取资产元数据（包含收藏状态）
- **AND** 原生实现 SHALL 返回布尔值表示收藏状态
- **AND** 原生实现 SHALL 处理资产不存在等异常情况

#### Scenario: 同步流程集成

- **WHEN** LocalSyncService 执行 _convertToEntity 方法转换资产
- **THEN** 系统 SHALL 调用 AssetNativeApi.getIsFavorite 获取收藏状态
- **AND** 系统 SHALL 将获取的收藏状态赋值给 LocalAssetEntityData.isFavorite 字段
- **AND** 系统 SHALL 在获取失败时默认设为 false 并继续处理
- **AND** 系统 SHALL 记录日志便于调试和监控

#### Scenario: 增量同步中的收藏状态变化检测

- **WHEN** 执行增量同步
- **THEN** 系统 SHALL 为新增或修改的资产获取最新的收藏状态
- **AND** 如果资产的收藏状态与数据库中的不一致，系统 SHALL 更新数据库
- **AND** 系统 SHALL 在日志中记录收藏状态的变化

#### Scenario: 性能优化（批量查询）

- **WHEN** 需要获取多个资产的收藏状态
- **THEN** 系统可选地 SHALL 使用 getAssetMetadata 批量查询接口
- **AND** 批量查询 SHALL 减少跨平台调用次数（每批最多 100 个资产）
- **AND** 系统 SHALL 将批量查询结果映射到对应的资产
- **AND** 性能优化 SHALL 不改变功能语义

#### Scenario: 错误处理

- **WHEN** 获取收藏状态时发生错误（如资产不存在、权限不足）
- **THEN** 系统 SHALL 记录警告日志包含错误信息和资产 ID
- **AND** 系统 SHALL 默认该资产的收藏状态为 false
- **AND** 系统 SHALL 继续处理其他资产，不中断同步流程

