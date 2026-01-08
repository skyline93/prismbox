# Change: 修复增量同步中收藏状态变化检测

## Why

当前增量同步逻辑只检查资产的 `modifiedDateTime` 来判断是否需要更新。但是，当用户在系统相册中改变收藏状态时，`modifiedDateTime` 通常不会改变（因为收藏是元数据属性，不是文件本身的修改）。

这导致：
1. 用户在系统相册中添加/移除收藏后，PrismBox 中的收藏状态不会更新
2. 需要执行全量同步才能检测到收藏状态变化
3. 用户体验差，无法及时看到收藏状态的变化

参考 Immich 的实现方案，我们需要在增量同步中检查收藏状态变化，确保与系统相册保持同步。

## What Changes

- 修改增量同步逻辑，在检查 `modifiedDateTime` 的同时，也检查收藏状态是否变化
- 对于已存在的资产，即使 `modifiedDateTime` 没有变化，也要比较数据库中的 `isFavorite` 和系统相册中的 `isFavorite`
- 如果收藏状态不同，即使 `modifiedDateTime` 没有变化，也要更新数据库
- 优化性能：批量获取收藏状态，避免逐个调用原生 API

## Impact

- **受影响的 specs**:
  - `local-asset-sync`: 修改增量同步需求，添加收藏状态变化检测
- **受影响的代码**:
  - `mobile/lib/features/local_sync/services/local_sync_service.dart`: 修改 `_incrementalSync` 方法
- **性能影响**: 增量同步时需要为所有已存在的资产检查收藏状态，但使用批量 API 可以最小化性能影响
- **兼容性**: 无影响，向后兼容

