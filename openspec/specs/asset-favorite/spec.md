# asset-favorite Specification

## Purpose
TBD - created by archiving change add-media-viewer-favorite-action. Update Purpose after archive.
## Requirements
### Requirement: 资产收藏服务
系统 SHALL 提供资产收藏服务（AssetFavoriteService），用于管理媒体资源的收藏状态，包括设置和切换收藏状态。收藏操作仅更新 Prismbox 数据库，不修改系统相册。

#### Scenario: 服务类结构
- **WHEN** 使用 AssetFavoriteService
- **THEN** 服务类 SHALL 位于 `lib/services/asset/asset_favorite_service.dart`
- **AND** 类名 SHALL 为 `AssetFavoriteService`
- **AND** 服务 SHALL 依赖 `LocalAssetDao`（不依赖 `AssetNativeApi`）
- **AND** 服务 SHALL 提供 `toggleFavorite(String assetId)` 方法用于切换收藏状态
- **AND** 服务 SHALL 提供 `setFavorite(String assetId, bool isFavorite)` 方法用于设置收藏状态

#### Scenario: 切换收藏状态
- **WHEN** 调用 `toggleFavorite(assetId)` 方法
- **THEN** 服务 SHALL 首先从数据库获取当前收藏状态
- **AND** 服务 SHALL 计算新的收藏状态（取反）
- **AND** 服务 SHALL 直接更新数据库中的收藏状态
- **AND** 服务 SHALL 记录操作日志（成功或失败）
- **AND** 服务 SHALL 不调用原生 API 修改系统相册

#### Scenario: 设置收藏状态
- **WHEN** 调用 `setFavorite(assetId, isFavorite)` 方法
- **THEN** 服务 SHALL 直接更新数据库中的收藏状态
- **AND** 服务 SHALL 记录操作日志（成功或失败）
- **AND** 服务 SHALL 不调用原生 API 修改系统相册

#### Scenario: 错误处理
- **WHEN** 资产不存在（数据库查询返回 null）
- **THEN** 服务 SHALL 抛出异常，包含错误信息
- **AND** 服务 SHALL 记录错误日志
- **WHEN** 数据库更新失败
- **THEN** 服务 SHALL 抛出异常，包含错误信息
- **AND** 服务 SHALL 记录错误日志

