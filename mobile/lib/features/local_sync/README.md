# 本地媒体同步模块

## 模块概述

本地媒体同步模块是 PrismBox 移动端的核心功能模块，负责：
1. 本地媒体库同步：将系统相册的媒体资源同步到本地数据库
2. 数据获取：提供 BaseAsset 数据列表，支持从数据库或 photo_manager 获取
3. 智能数据源切换：根据数据可用性自动选择最优数据源
4. 上传状态标识：清晰标识媒体资源的上传状态
5. 后台同步协调：在后台执行同步任务，不阻塞用户浏览

## 目录结构

```
lib/features/local_sync/
├── models/                    # 数据模型
│   ├── sync_result.dart       # 同步结果
│   ├── sync_status.dart       # 同步状态
│   └── data_source_type.dart  # 数据源类型
├── exceptions/                 # 异常类
│   └── sync_exception.dart    # 同步异常
├── services/                   # 服务层
│   ├── local_sync_service.dart           # 本地同步服务
│   ├── timeline_provider_service.dart    # 时间线数据提供者
│   ├── sync_coordinator.dart             # 同步协调器
│   └── data_source_selector.dart         # 数据源选择器
└── providers/                  # Riverpod Providers
    ├── local_sync_providers.dart  # 服务 Providers
    └── timeline_provider.dart    # 时间线数据 Provider
```

## 核心组件

### 1. LocalSyncService（本地同步服务）
- 负责扫描系统相册并同步到数据库
- 支持全量同步和增量同步
- 分批处理，避免内存溢出
- 支持取消操作

### 2. TimelineProviderService（时间线数据提供者）
- 提供时间线数据（BaseAsset 列表）
- 支持双数据源（数据库和 photo_manager）
- 根据数据可用性自动选择最优数据源

### 3. SyncCoordinator（同步协调器）
- 协调后台同步任务
- 管理同步状态
- 不阻塞 UI 线程
- 支持自动同步和手动同步

### 4. DataSourceSelector（数据源选择器）
- 检查数据库数据可用性
- 决定使用哪个数据源
- 支持手动切换数据源

## 使用示例

### 获取时间线数据

```dart
final timelineAssets = ref.watch(timelineAssetsProvider);
```

### 手动触发同步

```dart
final coordinator = ref.read(syncCoordinatorProvider);
final result = await coordinator.syncManually(full: false);
```

### 监听同步状态

```dart
final syncStatus = ref.watch(syncStatusProvider);
syncStatus.whenData((status) {
  print('同步状态: ${status.status}');
  print('进度: ${status.progress}');
});
```

## 注意事项

1. **代码生成**：运行 `flutter pub run build_runner build --delete-conflicting-outputs` 生成 Provider 代码
2. **权限**：需要相册访问权限
3. **性能**：大批量数据同步在后台执行，不阻塞 UI
4. **数据源切换**：数据库数据充足时自动切换到数据库数据源

## 后续工作

1. 实现 checksum 计算和关联验证
2. 实现媒体库变化监听（Android MediaObserver、iOS PHPhotoLibraryChangeObserver）
3. 实现定期自动同步（WorkManager、BGTaskScheduler）
4. 实现查询结果缓存
5. 完善错误处理和重试机制

