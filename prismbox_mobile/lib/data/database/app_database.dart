// lib/data/database/app_database.dart

import 'package:drift/drift.dart';
import 'package:prismbox/data/database/tables/user_entity.dart';
import 'package:prismbox/data/database/tables/local_asset_entity.dart';
import 'package:prismbox/data/database/tables/remote_asset_entity.dart';
import 'package:prismbox/data/database/tables/local_album_entity.dart';
import 'package:prismbox/data/database/tables/remote_album_entity.dart';
import 'package:prismbox/data/database/tables/album_asset_entity.dart';
import 'package:prismbox/data/database/tables/store_entity.dart';
import 'package:prismbox/data/database/daos/user_dao.dart';
import 'package:prismbox/data/database/daos/local_asset_dao.dart';
import 'package:prismbox/data/database/daos/remote_asset_dao.dart';
import 'package:prismbox/data/database/daos/album_dao.dart';
import 'package:prismbox/data/database/exceptions/database_exception.dart';
// 导入枚举类型，供生成的代码使用
import 'package:prismbox/data/database/enums/asset_type.dart';
import 'package:prismbox/data/database/enums/asset_visibility.dart';
import 'package:prismbox/data/database/enums/backup_selection.dart';
import 'package:prismbox/data/database/enums/album_order.dart';

part 'app_database.g.dart';

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
    StoreEntity,
  ],
  daos: [UserDao, LocalAssetDao, RemoteAssetDao, AlbumDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // 创建部分唯一索引（新语法不支持 WHERE 子句，需要手动创建）
        await m.database.customStatement('''
          CREATE UNIQUE INDEX IF NOT EXISTS UQ_remote_assets_owner_checksum
          ON remote_asset_entity (owner_id, checksum)
          WHERE (library_id IS NULL);
        ''');
        await m.database.customStatement('''
          CREATE UNIQUE INDEX IF NOT EXISTS UQ_remote_assets_owner_library_checksum
          ON remote_asset_entity (owner_id, library_id, checksum)
          WHERE (library_id IS NOT NULL);
        ''');
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // 逐步升级
        try {
          for (int version = from + 1; version <= to; version++) {
            await _migrateToVersion(m, version);
          }
        } catch (e, stackTrace) {
          // 迁移失败时抛出 DatabaseException
          throw DatabaseException(
            type: DatabaseErrorType.migrationFailed,
            message:
                '数据库迁移失败: 从版本 $from 升级到版本 $to 时出错\n错误信息: $e\n堆栈跟踪: $stackTrace',
            originalError: e,
          );
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
        // 添加Store表
        await m.createTable(storeEntity);
        break;
      // ... 其他版本迁移
      default:
        throw ArgumentError('未知的数据库版本: $version');
    }
  }
}
