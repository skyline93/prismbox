// lib/data/database/app_database.dart

import 'package:drift/drift.dart';
import 'package:prismbox/data/database/tables/user_entity.dart';
import 'package:prismbox/data/database/tables/local_asset_entity.dart';
import 'package:prismbox/data/database/tables/remote_asset_entity.dart';
import 'package:prismbox/data/database/tables/local_album_entity.dart';
import 'package:prismbox/data/database/tables/remote_album_entity.dart';
import 'package:prismbox/data/database/tables/album_asset_entity.dart';
import 'package:prismbox/data/database/daos/local_asset_dao.dart';
import 'package:prismbox/data/database/daos/remote_asset_dao.dart';
import 'package:prismbox/data/database/daos/album_dao.dart';

part '../../../../prismbox_mobile.bak/lib/data/database/app_database.g.dart';

/// 应用数据库主文件
/// 管理数据库连接、表定义、DAO 和迁移
@DriftDatabase(
  tables: [
    UserEntity,
    LocalAssetEntity,
    RemoteAssetEntity,
    LocalAlbumEntity,
    RemoteAlbumEntity,
    AlbumAssetEntity,
  ],
  daos: [
    LocalAssetDao,
    RemoteAssetDao,
    AlbumDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.connection);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // 逐步升级
        for (int version = from + 1; version <= to; version++) {
          await _migrateToVersion(m, version);
        }
      },
      beforeOpen: (details) async {
        // 打开前检查
        if (details.wasCreated) {
          // 新数据库初始化
        } else if (details.hadUpgrade) {
          // 升级后处理
        }
      },
    );
  }

  /// 迁移到指定版本
  Future<void> _migrateToVersion(Migrator m, int version) async {
    switch (version) {
      case 2:
        // 未来版本的迁移逻辑
        break;
      // ... 其他版本迁移
      default:
        throw ArgumentError('未知的数据库版本: $version');
    }
  }
}

