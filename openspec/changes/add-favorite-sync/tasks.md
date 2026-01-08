# 实现任务清单

## 1. 原生平台桥接

- [x] 1.1 在 `pigeon/asset_native_api.dart` 中定义 Pigeon 接口
  - [x] 1.1.1 定义 `AssetMetadata` 数据类（包含 id, isFavorite 等字段）
  - [x] 1.1.2 定义 `AssetNativeApi` 接口（包含 `getIsFavorite` 和 `getAssetMetadata` 方法）
- [x] 1.2 生成 Pigeon 代码（iOS Swift、Android Kotlin、Dart）
- [x] 1.3 实现 iOS 原生层（`ios/Runner/Assets/AssetNativeApiImpl.swift`）
  - [x] 1.3.1 实现 `getIsFavorite` 方法（通过 PHAsset.isFavorite）
  - [x] 1.3.2 实现 `getAssetMetadata` 批量获取方法
  - [x] 1.3.3 添加错误处理（资产不存在等情况）
- [x] 1.4 实现 Android 原生层（`android/app/src/main/kotlin/app/prismbox/assets/AssetNativeApiImpl.kt`）
  - [x] 1.4.1 检测 Android 版本（仅支持 Android 11+）
  - [x] 1.4.2 实现 `getIsFavorite` 方法（查询 MediaStore.IS_FAVORITE）
  - [x] 1.4.3 实现 `getAssetMetadata` 批量获取方法
  - [x] 1.4.4 添加错误处理和降级逻辑（Android 10- 返回 false）
- [x] 1.5 注册原生 API 实现到 Flutter 引擎

## 2. 本地同步服务更新

- [x] 2.1 修改 `LocalSyncService` 类（`lib/features/local_sync/services/local_sync_service.dart`）
  - [x] 2.1.1 注入 `AssetNativeApi` 依赖
  - [x] 2.1.2 修改 `_convertToEntity` 方法，调用 `getIsFavorite` 获取收藏状态
  - [x] 2.1.3 添加异常处理（获取失败时默认为 false）
  - [x] 2.1.4 添加日志记录
- [x] 2.2 优化性能：实现批量获取收藏状态的逻辑
  - [x] 2.2.1 创建 `_batchGetFavoriteStatus` 方法
  - [x] 2.2.2 使用 `getAssetMetadata` 批量获取元数据
  - [x] 2.2.3 映射元数据到对应资产
- [x] 2.3 更新 Provider 注册（使用默认构造函数，无需修改）

## 3. UI 展示组件

- [x] 3.1 创建收藏图标组件（`lib/presentation/widgets/media/favorite_indicator.dart`）
  - [x] 3.1.1 定义 `FavoriteIndicator` 组件（StatelessWidget）
  - [x] 3.1.2 接收 `isFavorite` 参数
  - [x] 3.1.3 在左下角显示心形图标（仅当 isFavorite 为 true 时）
  - [x] 3.1.4 添加半透明背景和阴影，确保图标在任何背景下可见
  - [x] 3.1.5 提供 `const` 构造函数
- [x] 3.2 更新时间线缩略图组件，集成收藏指示器
  - [x] 3.2.1 在缩略图 Stack 中添加 `FavoriteIndicator` 层
  - [x] 3.2.2 传递 `asset.isFavorite` 参数
  - [x] 3.2.3 确保图标位于左下角且不影响其他 UI 元素
- [x] 3.3 确保组件符合性能优化要求（const 构造函数、避免不必要的重建）

## 4. 文档和注释

- [x] 4.1 在 `AssetNativeApi` 接口中添加中文注释，说明方法用途和参数
- [x] 4.2 在 `LocalSyncService` 中添加中文注释，说明收藏状态获取逻辑
- [x] 4.3 在 `FavoriteIndicator` 组件中添加中文注释

