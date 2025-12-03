# 数据库模块实现说明

## 概述

本目录包含 PrismBox 移动端数据库模块的完整实现，使用 Drift (SQLite) 作为底层存储引擎。

## 文件结构

```
lib/data/database/
├── enums/                          # 枚举类型定义
│   ├── asset_type.dart
│   ├── asset_visibility.dart
│   ├── backup_selection.dart
│   └── album_order.dart
├── tables/                         # 表定义
│   ├── mixins/                     # Mixin 定义
│   │   ├── asset_entity_mixin.dart
│   │   └── drift_defaults_mixin.dart
│   ├── user_entity.dart
│   ├── local_asset_entity.dart
│   ├── remote_asset_entity.dart
│   ├── local_album_entity.dart
│   ├── remote_album_entity.dart
│   └── album_asset_entity.dart
├── daos/                           # 数据访问对象
│   ├── local_asset_dao.dart
│   ├── remote_asset_dao.dart
│   └── album_dao.dart
├── exceptions/                     # 异常定义
│   └── database_exception.dart
├── connection.dart                 # 数据库连接管理
├── app_database.dart               # 数据库主文件
└── README.md                       # 本文件
```

## 依赖配置

在 `pubspec.yaml` 中添加以下依赖：

```yaml
dependencies:
  flutter:
    sdk: flutter
  drift: ^2.11.0
  sqlite3_flutter_libs: ^0.5.18
  path_provider: ^2.1.1
  path: ^1.8.3

dev_dependencies:
  drift_dev: ^2.11.0
  build_runner: ^2.4.11
```

## 代码生成

在实现代码后，需要运行代码生成：

```bash
cd prismbox_mobile

# 安装依赖
flutter pub get

# 生成数据库代码
flutter pub run build_runner build --delete-conflicting-outputs

# 监听模式（开发时使用）
flutter pub run build_runner watch --delete-conflicting-outputs
```

## 使用示例

### 初始化数据库

```dart
import 'package:prismbox/data/database/connection.dart';

// 获取数据库实例
final database = await DatabaseConnection.getInstance();
```

### 使用 DAO

```dart
// 获取本地资产
final localAssets = await database.localAssetDao.getAllAssets();

// 插入资产
await database.localAssetDao.insertAsset(asset);

// 查询远程资产
final remoteAssets = await database.remoteAssetDao.getUserAssets(userId);

// 流式查询（监听变化）
database.localAssetDao.watchAssets().listen((assets) {
  print('资产数量: ${assets.length}');
});
```

### 事务操作

```dart
await database.transaction(() async {
  await database.localAssetDao.insertAsset(asset1);
  await database.localAssetDao.insertAsset(asset2);
  // 如果任何操作失败，整个事务会回滚
});
```

### 批量操作

```dart
// 批量插入
await database.localAssetDao.insertAssets(assets);
```

## 核心特性

1. **类型安全**：使用 Drift 的代码生成机制，提供编译时类型检查
2. **跨 Isolate 支持**：支持在多个 Dart Isolate 中共享数据库连接
3. **WAL 模式**：使用 WAL 模式提升并发性能
4. **外键约束**：完整的外键约束保证数据一致性
5. **软删除**：远程资产支持软删除机制
6. **索引优化**：为常用查询字段创建索引

## 表结构说明

### 本地资产表 (LocalAssetEntity)
- 存储设备上的原始媒体文件信息
- 通过 `checksum` 与远程资产关联

### 远程资产表 (RemoteAssetEntity)
- 存储从服务器同步的资产信息
- 支持软删除（通过 `deletedAt` 字段）
- 支持多库场景（通过 `libraryId` 字段）

### 相册表 (LocalAlbumEntity / RemoteAlbumEntity)
- 本地相册：存储设备上的相册信息
- 远程相册：存储服务器端的相册信息

### 相册-资产关联表 (AlbumAssetEntity)
- 多对多关系表
- 支持一个资产属于多个相册

## 注意事项

1. **包名配置**：确保 `pubspec.yaml` 中的 `name` 字段为 `prismbox`
2. **代码生成**：每次修改表定义后，需要重新运行代码生成
3. **迁移**：数据库结构变更时，需要更新 `schemaVersion` 并实现迁移逻辑
4. **跨 Isolate**：确保所有 Isolate 使用相同的数据库文件路径

## 后续工作

1. 添加更多查询方法（如分页查询、排序查询）
2. 实现数据迁移机制（版本化升级）
3. 添加单元测试
4. 性能优化（索引优化、查询优化）

