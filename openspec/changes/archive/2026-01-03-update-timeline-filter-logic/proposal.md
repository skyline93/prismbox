# Change: 重构照片页面过滤功能

## Why

当前照片页面的过滤功能实现不符合用户需求。现有实现基于资产类型（LocalAsset/RemoteAsset）进行简单过滤，无法准确反映本地资产的上传状态（已上传、上传失败、未上传）。用户需要更精确的过滤选项来管理本地媒体资源和远程媒体资源。

## What Changes

- **MODIFIED**: 重构时间线页面过滤逻辑，基于上传状态而非资产类型进行过滤
- **MODIFIED**: "全部"模式仅展示本地媒体资源（包括已上传和未上传的本地媒体资源）
- **MODIFIED**: "已备份"模式仅展示已上传过的本地媒体资源（`isUploaded == true`）
- **MODIFIED**: "未备份"模式仅展示未上传的本地媒体资源（`isUploaded == false`，不区分从未上传和上传失败）
- **MODIFIED**: "仅云端"模式仅展示远程服务端的媒体资源（保持不变）

## Impact

- **Affected specs**: `timeline-page`
- **Affected code**: 
  - `prismbox_mobile/lib/domain/entities/local_asset.dart` - 添加 `isUploaded` 字段
  - `prismbox_mobile/lib/features/local_sync/providers/timeline_provider.dart` - 过滤逻辑实现
  - `prismbox_mobile/lib/providers/photo_filter/photo_filter_provider.dart` - 过滤模式定义（可能需要更新注释）
  - `prismbox_mobile/lib/features/local_sync/services/timeline_provider_service.dart` - 数据获取服务（创建 LocalAsset 时传递 isUploaded）

## Breaking Changes

无。此变更仅修改过滤逻辑，不改变 API 或数据结构。

