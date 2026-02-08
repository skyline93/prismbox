// lib/data/database/app_database.dart

import 'package:drift/drift.dart';
import 'package:prismbox/data/database/tables/user_entity.dart';
import 'package:prismbox/data/database/tables/local_asset_entity.dart';
import 'package:prismbox/data/database/tables/remote_asset_entity.dart';
import 'package:prismbox/data/database/tables/local_album_entity.dart';
import 'package:prismbox/data/database/tables/remote_album_entity.dart';
import 'package:prismbox/data/database/tables/album_asset_entity.dart';
import 'package:prismbox/data/database/tables/local_album_asset_entity.dart';
import 'package:prismbox/data/database/tables/store_entity.dart';
import 'package:prismbox/data/database/tables/backup_status_entity.dart';
import 'package:prismbox/data/database/tables/upload_task_entity.dart';
import 'package:prismbox/data/database/tables/download_task_entity.dart';
import 'package:prismbox/data/database/tables/sync_checkpoint_entity.dart';
import 'package:prismbox/data/database/tables/album_session_entity.dart';
import 'package:prismbox/data/database/tables/retry_task_entity.dart';
import 'package:prismbox/data/database/tables/post_task_entity.dart';
import 'package:prismbox/data/database/daos/user_dao.dart';
import 'package:prismbox/data/database/daos/local_asset_dao.dart';
import 'package:prismbox/data/database/daos/remote_asset_dao.dart';
import 'package:prismbox/data/database/daos/album_dao.dart';
import 'package:prismbox/data/database/daos/backup_status_dao.dart';
import 'package:prismbox/data/database/daos/upload_task_dao.dart';
import 'package:prismbox/data/database/daos/download_task_dao.dart';
import 'package:prismbox/data/database/daos/sync_checkpoint_dao.dart';
import 'package:prismbox/data/database/daos/retry_task_dao.dart';
import 'package:prismbox/data/database/daos/post_task_dao.dart';
import 'package:prismbox/data/database/exceptions/database_exception.dart';
// 导入枚举类型，供生成的代码使用
import 'package:prismbox/data/database/enums/asset_type.dart';
import 'package:prismbox/data/database/enums/asset_visibility.dart';
import 'package:prismbox/data/database/enums/backup_selection.dart';
import 'package:prismbox/data/database/enums/album_order.dart';
import 'package:prismbox/data/database/enums/album_type.dart';
import 'package:prismbox/data/database/enums/migration_status.dart';
import 'package:prismbox/data/database/enums/upload_task_type.dart';
import 'package:prismbox/data/database/enums/upload_task_status.dart';
import 'package:prismbox/data/database/enums/download_task_status.dart';
import 'package:prismbox/data/database/enums/media_download_source_type.dart';
import 'package:prismbox/data/database/enums/auto_backup_mode.dart';
import 'package:prismbox/data/database/enums/post_task_status.dart';

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
    LocalAlbumAssetEntity,
    AlbumSessionEntity,
    RetryTaskEntity,
    StoreEntity,
    BackupStatusEntity,
    UploadTaskEntity,
    DownloadTaskEntity,
    SyncCheckpointEntity,
    PostTaskEntity,
  ],
  daos: [
    UserDao,
    LocalAssetDao,
    RemoteAssetDao,
    AlbumDao,
    BackupStatusDao,
    UploadTaskDao,
    DownloadTaskDao,
    SyncCheckpointDao,
    RetryTaskDao,
    PostTaskDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 17;

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
      case 3:
        // 添加备份相关表
        await m.createTable(backupStatusEntity);
        await m.createTable(uploadTaskEntity);
        break;
      case 4:
        // 添加同步检查点表
        await m.createTable(syncCheckpointEntity);
        break;
      case 5:
        // 为同步检查点表添加 lastSyncTime 字段
        await m.addColumn(
          syncCheckpointEntity,
          syncCheckpointEntity.lastSyncTime,
        );
        break;
      case 6:
        // 加密空间功能：添加新字段和表
        // 为远程相册表添加加密相关字段
        await m.database.customStatement('''
          ALTER TABLE remote_album_entity 
          ADD COLUMN is_encrypted INTEGER NOT NULL DEFAULT 0;
        ''');
        await m.database.customStatement('''
          ALTER TABLE remote_album_entity 
          ADD COLUMN album_type INTEGER NOT NULL DEFAULT 0;
        ''');
        // 为本地相册表添加加密相关字段
        await m.database.customStatement('''
          ALTER TABLE local_album_entity 
          ADD COLUMN is_encrypted INTEGER NOT NULL DEFAULT 0;
        ''');
        await m.database.customStatement('''
          ALTER TABLE local_album_entity 
          ADD COLUMN album_type INTEGER NOT NULL DEFAULT 0;
        ''');
        // 为本地资产表添加私有空间相关字段
        await m.database.customStatement('''
          ALTER TABLE local_asset_entity 
          ADD COLUMN is_in_private_space INTEGER NOT NULL DEFAULT 0;
        ''');
        await m.database.customStatement('''
          ALTER TABLE local_asset_entity 
          ADD COLUMN migration_status INTEGER NOT NULL DEFAULT 0;
        ''');
        // 创建相册会话令牌表
        await m.database.customStatement('''
          CREATE TABLE IF NOT EXISTS album_session_entity (
            id TEXT NOT NULL PRIMARY KEY,
            album_id TEXT NOT NULL,
            session_token TEXT NOT NULL,
            expires_at INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            FOREIGN KEY (album_id) REFERENCES remote_album_entity (id) ON DELETE CASCADE
          );
        ''');
        break;
      case 7:
        // 创建本地相册-资产关联表
        await m.createTable(localAlbumAssetEntity);
        break;
      case 8:
        // 创建重试任务表
        await m.createTable(retryTaskEntity);
        break;
      case 9:
        // 本地资源与远程资源完全解耦：添加 isUploaded 字段，移除 checksum 字段
        // 注意：SQLite 不支持直接删除列，使用表重建方式
        // 1. 添加 isUploaded 字段（临时，用于迁移）
        await m.database.customStatement('''
          ALTER TABLE local_asset_entity 
          ADD COLUMN is_uploaded INTEGER NOT NULL DEFAULT 0;
        ''');
        // 2. 创建新表（不包含 checksum 字段）
        await m.database.customStatement('''
          CREATE TABLE local_asset_entity_new (
            id TEXT NOT NULL PRIMARY KEY,
            is_uploaded INTEGER NOT NULL DEFAULT 0,
            path TEXT NOT NULL,
            is_favorite INTEGER NOT NULL DEFAULT 0,
            orientation INTEGER NOT NULL DEFAULT 0,
            is_in_private_space INTEGER NOT NULL DEFAULT 0,
            migration_status INTEGER NOT NULL DEFAULT 0,
            name TEXT NOT NULL,
            type INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            width INTEGER,
            height INTEGER,
            duration_in_seconds INTEGER
          );
        ''');
        // 3. 复制数据（忽略 checksum 字段，isUploaded 设为 0）
        await m.database.customStatement('''
          INSERT INTO local_asset_entity_new (
            id, is_uploaded, path, is_favorite, orientation, 
            is_in_private_space, migration_status, name, type, 
            created_at, updated_at, width, height, duration_in_seconds
          )
          SELECT 
            id, 0, path, is_favorite, orientation, 
            is_in_private_space, migration_status, name, type, 
            created_at, updated_at, width, height, duration_in_seconds
          FROM local_asset_entity;
        ''');
        // 4. 删除旧表和索引
        await m.database.customStatement('''
          DROP INDEX IF EXISTS idx_local_asset_checksum;
        ''');
        await m.database.customStatement('''
          DROP TABLE local_asset_entity;
        ''');
        // 5. 重命名新表
        await m.database.customStatement('''
          ALTER TABLE local_asset_entity_new RENAME TO 
          local_asset_entity;
        ''');
        break;
      case 10:
        // 添加回收站相关字段到本地资产表
        await m.database.customStatement('''
          ALTER TABLE local_asset_entity 
          ADD COLUMN deleted_at INTEGER;
        ''');
        await m.database.customStatement('''
          ALTER TABLE local_asset_entity 
          ADD COLUMN original_path TEXT;
        ''');
        await m.database.customStatement('''
          ALTER TABLE local_asset_entity 
          ADD COLUMN trash_path TEXT;
        ''');
        break;
      case 11:
        // 添加帖子任务表
        await m.createTable(postTaskEntity);
        break;
      case 12:
        // 为帖子任务表添加 mediaAssetIds 字段
        // 检查列是否存在（使用 PRAGMA table_info 查询表结构）
        final result = await m.database.customSelect(
          'PRAGMA table_info(post_task_entity)',
          readsFrom: {},
        ).get();
        
        final columnExists = result.any((row) => 
          row.data['name'] == 'media_asset_ids'
        );
        
        if (!columnExists) {
          // 列不存在，添加列
          await m.database.customStatement('''
            ALTER TABLE post_task_entity 
            ADD COLUMN media_asset_ids TEXT;
          ''');
        }
        break;
      case 13:
        // 为上传任务表添加 mediaUuid 字段
        // 检查列是否存在（使用 PRAGMA table_info 查询表结构）
        final uploadTaskResult = await m.database.customSelect(
          'PRAGMA table_info(upload_task_entity)',
          readsFrom: {},
        ).get();
        
        final mediaUuidColumnExists = uploadTaskResult.any((row) => 
          row.data['name'] == 'media_uuid'
        );
        
        if (!mediaUuidColumnExists) {
          // 列不存在，添加列
          await m.database.customStatement('''
            ALTER TABLE upload_task_entity 
            ADD COLUMN media_uuid TEXT;
          ''');
        }
        break;
      case 14:
        // 本地 Live Photo 支持：为 local_asset_entity 添加 live_photo_video_id
        await m.addColumn(
          localAssetEntity,
          localAssetEntity.livePhotoVideoId,
        );
        break;
      case 15:
        // 媒体下载：新增下载任务表
        await m.createTable(downloadTaskEntity);
        break;
      case 16:
        // 媒体详细信息：文件大小、拍摄位置、设备、EXIF 参数
        await m.addColumn(
          localAssetEntity,
          localAssetEntity.fileSize,
        );
        await m.addColumn(
          localAssetEntity,
          localAssetEntity.latitude,
        );
        await m.addColumn(
          localAssetEntity,
          localAssetEntity.longitude,
        );
        await m.addColumn(
          localAssetEntity,
          localAssetEntity.deviceMake,
        );
        await m.addColumn(
          localAssetEntity,
          localAssetEntity.deviceModel,
        );
        await m.addColumn(
          localAssetEntity,
          localAssetEntity.exifExposureTime,
        );
        await m.addColumn(
          localAssetEntity,
          localAssetEntity.exifFNumber,
        );
        await m.addColumn(
          localAssetEntity,
          localAssetEntity.exifIso,
        );
        await m.addColumn(
          localAssetEntity,
          localAssetEntity.exifFocalLength,
        );
        break;
      case 17:
        // 远程资产媒体详情：与本地一致，便于仅远程媒体在预览中展示详情
        await m.addColumn(
          remoteAssetEntity,
          remoteAssetEntity.fileSize,
        );
        await m.addColumn(
          remoteAssetEntity,
          remoteAssetEntity.latitude,
        );
        await m.addColumn(
          remoteAssetEntity,
          remoteAssetEntity.longitude,
        );
        await m.addColumn(
          remoteAssetEntity,
          remoteAssetEntity.deviceMake,
        );
        await m.addColumn(
          remoteAssetEntity,
          remoteAssetEntity.deviceModel,
        );
        await m.addColumn(
          remoteAssetEntity,
          remoteAssetEntity.exifExposureTime,
        );
        await m.addColumn(
          remoteAssetEntity,
          remoteAssetEntity.exifFNumber,
        );
        await m.addColumn(
          remoteAssetEntity,
          remoteAssetEntity.exifIso,
        );
        await m.addColumn(
          remoteAssetEntity,
          remoteAssetEntity.exifFocalLength,
        );
        break;
      default:
        throw ArgumentError('未知的数据库版本: $version');
    }
  }
}
