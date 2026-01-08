# Change: 添加收藏属性同步和展示

## Why

当前 PrismBox 在本地同步流程中未从系统相册读取照片的收藏（favorite）属性，导致：
1. 用户在系统相册中标记的收藏照片无法在 PrismBox 中体现
2. 照片上传到服务器时无法携带原始收藏状态
3. 用户无法通过缩略图直观识别哪些照片是收藏的

参考 Immich 的实现方案（参考 `docs/immich参考/架构详解/mobile-backup-module.md`：在备份时同步收藏状态），我们需要在本地同步时获取系统相册的收藏属性，存储到本地数据库，并在 UI 上展示。同时，在增量同步中也需要检测收藏状态变化，确保与系统相册保持同步。

## What Changes

- 在本地资产同步流程中，从系统相册读取收藏（favorite）属性
- 使用 Pigeon 创建原生平台桥接（iOS 和 Android），获取系统相册的收藏状态
- 在 `LocalSyncService._convertToEntity` 方法中调用原生 API 获取收藏状态
- 在时间线缩略图左下角添加收藏图标指示器
- 支持 iOS PHAsset.isFavorite 属性读取
- 支持 Android MediaStore.IS_FAVORITE 字段读取（仅 Android 11+）

## Impact

- **受影响的 specs**:
  - `local-asset-sync`: 添加收藏属性同步需求
  - `timeline-page`: 添加收藏图标展示需求
- **受影响的代码**:
  - `mobile/lib/features/local_sync/services/local_sync_service.dart`: 修改 `_convertToEntity` 方法
  - `mobile/pigeon/`: 新增 Pigeon 接口定义
  - `mobile/ios/Runner/Platform/`: 新增 iOS 原生实现
  - `mobile/android/app/src/main/kotlin/`: 新增 Android 原生实现
  - `mobile/lib/presentation/widgets/timeline/`: 新增收藏图标组件
- **性能影响**: 在同步时需要额外的原生调用获取收藏状态，建议使用批量 API 优化性能
- **兼容性**: Android 10 及以下版本无法获取收藏状态，默认为 false

