import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:mobile/data/models/media/media_model.dart';

// 为了让 Drift 能够生成代码，需要这个 part 文件
part 'app_database.g.dart';

// ==========================================================================
// 1. 枚举定义 (Enums) - 提供了类型安全，避免了魔法字符串
// ==========================================================================

/// 媒体资产的同步状态 (对应 media_assets.sync_status)
/// 用于驱动 UI 的视觉状态
enum SyncStatus {
  localOnlyNotSelected, // 本地独有，未被选中
  uploading, // 上传中/等待上传
  synced, // 已同步
  cloudOnly, // 仅云端
  downloading, // 下载中
  error, // 同步出错
}

/// 同步任务的类型 (对应 sync_jobs.job_type)
enum JobType {
  upload, // 上传任务
  deleteCloud, // 删除云端副本任务
}

/// 同步任务的状态 (对应 sync_jobs.status)
enum JobStatus {
  pending, // 等待执行
  inProgress, // 正在执行
  failed, // 执行失败
}

// ==========================================================================
// 2. 表定义 (Tables) - 严格遵循 v2.1 文档的设计
// ==========================================================================

/// 核心数据表，存储所有媒体的元数据和状态
@DataClassName('MediaAsset')
class MediaAssets extends Table {
  // 自增主键
  IntColumn get id => integer().autoIncrement()();

  // photo_manager 提供的 ID，用于本地文件操作 (可空，云端资源无此ID)
  TextColumn get localId => text().unique().nullable()();

  // 服务器提供的 UUID，用于云端操作 (可空，本地资源上传前无此ID)
  TextColumn get cloudUuid => text().unique().nullable()();

  // 文件内容的 SHA256 哈希，用于去重
  TextColumn get contentHash => text().nullable()();

  // 核心状态，驱动UI展示
  TextColumn get syncStatus =>
      text().map(const EnumNameConverter(SyncStatus.values))();

  // 媒体类型 (IMAGE, VIDEO)
  TextColumn get assetType =>
      text().map(const EnumNameConverter(MediaType.values))();

  // 本地文件路径 (缓存，用于快速访问)
  TextColumn get filePath => text().nullable()();

  // 媒体元数据
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  IntColumn get durationSec => integer().nullable()(); // 视频时长(秒)

  // 媒体拍摄或创建时间 (用于排序)
  DateTimeColumn get createdAt => dateTime()();

  // 记录更新时间
  DateTimeColumn get updatedAt => dateTime()();
}

/// 任务队列，用于实现健壮的后台同步
@DataClassName('SyncJob')
class SyncJobs extends Table {
  // 任务 ID
  IntColumn get id => integer().autoIncrement()();

  // 关联的 media_assets.id
  IntColumn get assetId =>
      integer().references(MediaAssets, #id, onDelete: KeyAction.cascade)();

  // 任务类型 (UPLOAD, DELETE_CLOUD, ...)
  TextColumn get jobType =>
      text().map(const EnumNameConverter(JobType.values))();

  // 任务状态 (PENDING, IN_PROGRESS, FAILED)
  TextColumn get status =>
      text().map(const EnumNameConverter(JobStatus.values))();

  // 重试次数
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  // 失败信息
  TextColumn get errorMessage => text().nullable()();

  // 任务创建时间
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  // 在执行乐观删除时，可能需要暂存 cloudUuid
  TextColumn get relatedCloudUuid => text().nullable()();
}

/// 用户设置表
@DataClassName('UserSetting')
class UserSettings extends Table {
  // 设置项的键 (e.g., 'backup_mode')
  TextColumn get key => text()();
  // 设置项的值 (e.g., 'AUTO', 'MANUAL')
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

// ==========================================================================
// 3. 数据库主类和数据访问对象 (DAOs)
// ==========================================================================

@DriftDatabase(
  tables: [MediaAssets, SyncJobs, UserSettings],
  daos: [MediaAssetDao, SyncJobDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

// --- MediaAsset DAO ---
@DriftAccessor(tables: [MediaAssets, SyncJobs])
class MediaAssetDao extends DatabaseAccessor<AppDatabase>
    with _$MediaAssetDaoMixin {
  // -- FIX: 使用 super 参数简化构造函数 --
  MediaAssetDao(super.db);

  /// 监听所有媒体资源的变化，用于驱动UI实时更新
  Stream<List<MediaAsset>> watchAllMediaAssets() => select(mediaAssets).watch();

  /// 插入单个媒体资源
  Future<int> insertMediaAsset(MediaAssetsCompanion entity) =>
      into(mediaAssets).insert(entity);

  /// 批量插入从云端拉取的媒体元数据
  Future<void> bulkInsertCloudMedia(List<MediaAssetsCompanion> assets) async {
    await batch((batch) {
      batch.insertAll(mediaAssets, assets, mode: InsertMode.insertOrIgnore);
    });
  }

  /// [核心事务] 场景 5.2：用户在“手动模式”下备份照片
  /// 1. 更新 media_assets 的状态为 'uploading'
  /// 2. 在 sync_jobs 表中创建 'UPLOAD' 任务
  Future<void> markAsPendingBackup(List<int> assetIds) async {
    return transaction(() async {
      // 步骤 1: 更新状态。这里使用默认构造函数，需要 Value()
      final query = update(mediaAssets)..where((tbl) => tbl.id.isIn(assetIds));
      await query.write(
        const MediaAssetsCompanion(syncStatus: Value(SyncStatus.uploading)),
      );

      // 步骤 2: 创建任务。
      // -- FIX: 使用 .insert() 工厂构造函数，直接传递原始值，不使用 Value() --
      final jobs = assetIds.map(
        (id) => SyncJobsCompanion.insert(
          assetId: id, // 直接使用 int id
          jobType: JobType.upload,
          status: JobStatus.pending,
        ),
      );
      await batch((batch) {
        batch.insertAll(syncJobs, jobs);
      });
    });
  }

  /// [核心事务] 场景 5.3：用户从 App 中删除一张已同步的照片
  /// 1. 从 media_assets 表中乐观删除记录，UI立即响应
  /// 2. 在 sync_jobs 表中创建 'DELETE_CLOUD' 任务，由后台服务处理
  Future<void> performOptimisticDelete(MediaAsset assetToDelete) async {
    return transaction(() async {
      // 步骤 1: 乐观删除
      await (delete(
        mediaAssets,
      )..where((tbl) => tbl.id.equals(assetToDelete.id))).go();

      // 步骤 2: 创建云端删除任务
      // 只有当资源真正存在于云端时才创建删除任务
      if (assetToDelete.cloudUuid != null) {
        // -- FIX: 使用 .insert() 工厂构造函数，直接传递原始值，不使用 Value() --
        await into(syncJobs).insert(
          SyncJobsCompanion.insert(
            assetId: assetToDelete.id, // 直接使用 int
            relatedCloudUuid: Value(assetToDelete.cloudUuid), // 必须保存 cloudUuid
            jobType: JobType.deleteCloud,
            status: JobStatus.pending,
          ),
        );
      }
    });
  }

  /// [核心事务] 批量更新或插入从云端拉取的媒体数据
  ///
  /// 使用 "upsert" 逻辑:
  /// - 如果云端 `cloudUuid` 对应的记录已存在，则更新它。
  /// - 如果不存在，则插入新记录。
  ///
  /// @param cloudAssets 从 RemoteMediaSource 获取并转换好的数据。
  Future<void> bulkUpsertCloudMedia(
    List<MediaAssetsCompanion> cloudAssets,
  ) async {
    if (cloudAssets.isEmpty) {
      return;
    }

    print("开始将 ${cloudAssets.length} 条云端记录写入本地数据库...");

    // 使用事务确保操作的原子性，要么全部成功，要么全部失败。
    await transaction(() async {
      for (final asset in cloudAssets) {
        // Drift 提供了 insertOnConflictUpdate，完美实现了 Upsert 功能。
        // 我们基于 cloudUuid 这个唯一键进行冲突判断。
        await into(mediaAssets).insertOnConflictUpdate(asset);
      }
    });

    print("云端记录写入数据库完成。");
  }

  /// [核心事务] 将从云端获取的变更原子化地应用到本地数据库。
  ///
  /// 此方法在一个事务中执行所有操作，以保证数据的一致性。
  ///
  /// @param toUpsert 需要创建或更新的媒体列表。
  /// @param uuidsToDelete 需要删除的媒体的 cloudUuid 列表。
  Future<void> applyCloudChanges({
    required List<MediaAssetsCompanion> toUpsert,
    required List<String> uuidsToDelete,
  }) async {
    print("开始应用云端变更到本地数据库...");
    print("待更新/插入: ${toUpsert.length} 条, 待删除: ${uuidsToDelete.length} 条。");

    // 使用事务确保所有操作要么全部成功，要么全部失败回滚。
    return transaction(() async {
      // 1. 处理删除操作
      if (uuidsToDelete.isNotEmpty) {
        await (delete(
          mediaAssets,
        )..where((tbl) => tbl.cloudUuid.isIn(uuidsToDelete))).go();
        print("成功删除了 ${uuidsToDelete.length} 条云端指定的记录。");
      }

      // 2. 处理创建/更新操作
      if (toUpsert.isNotEmpty) {
        // 使用批量操作提升性能
        await batch((batch) {
          // insertOnConflictUpdate 是 Drift 实现 "Upsert" 的绝佳方式。
          // 它会根据主键或唯一键（这里我们依赖 cloudUuid）来判断是插入新行还是更新旧行。
          batch.insertAll(
            mediaAssets,
            toUpsert,
            mode: InsertMode.insertOrReplace,
          );
        });
        print("成功创建/更新了 ${toUpsert.length} 条记录。");
      }
    });
  }
}

// --- SyncJob DAO ---
@DriftAccessor(tables: [SyncJobs])
class SyncJobDao extends DatabaseAccessor<AppDatabase> with _$SyncJobDaoMixin {
  // -- FIX: 使用 super 参数简化构造函数 --
  SyncJobDao(super.db);

  /// 获取所有待处理的任务，供后台服务拉取
  Future<List<SyncJob>> getPendingJobs() => (select(
    syncJobs,
  )..where((tbl) => tbl.status.equalsValue(JobStatus.pending))).get();

  /// 更新任务（例如，失败后增加重试次数）。这里使用默认构造函数，需要 Value()
  Future<void> updateJob(int jobId, SyncJobsCompanion updates) =>
      (update(syncJobs)..where((tbl) => tbl.id.equals(jobId))).write(updates);

  /// 删除已成功完成的任务
  Future<void> deleteJob(int jobId) =>
      (delete(syncJobs)..where((tbl) => tbl.id.equals(jobId))).go();
}

/// 打开数据库连接的辅助函数
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'media_library.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
