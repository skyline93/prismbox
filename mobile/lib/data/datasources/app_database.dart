// lib/data/datasources/app_database.dart

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:mobile/data/models/media/media_model.dart';

part 'app_database.g.dart';

// --- Enums ---
enum SyncStatus {
  localOnlyNotSelected,
  uploading,
  synced,
  cloudOnly,
  downloading,
  error,
}

enum JobType { upload, deleteCloud }

enum JobStatus { pending, inProgress, failed }

// --- Tables ---
@DataClassName('MediaAsset')
class MediaAssets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get localId => text().unique().nullable()();
  TextColumn get cloudUuid => text().unique().nullable()();
  TextColumn get contentHash => text().nullable()();
  TextColumn get syncStatus =>
      text().map(const EnumNameConverter(SyncStatus.values))();
  TextColumn get assetType =>
      text().map(const EnumNameConverter(MediaType.values))();
  TextColumn get filePath => text().nullable()();
  // [新增] 存储原始文件名，用于下载时保持文件类型
  TextColumn get fileName => text().nullable()();
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  IntColumn get durationSec => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

@DataClassName('SyncJob')
class SyncJobs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get assetId =>
      integer().references(MediaAssets, #id, onDelete: KeyAction.cascade)();
  TextColumn get jobType =>
      text().map(const EnumNameConverter(JobType.values))();
  TextColumn get status =>
      text().map(const EnumNameConverter(JobStatus.values))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get errorMessage => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get relatedCloudUuid => text().nullable()();
}

@DataClassName('UserSetting')
class UserSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

// --- Database Class ---
@DriftDatabase(
  tables: [MediaAssets, SyncJobs, UserSettings],
  daos: [MediaAssetDao, SyncJobDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2; // 版本号保持为2

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(mediaAssets, mediaAssets.fileName);
      }
    },
  );
}

// --- MediaAsset DAO ---
@DriftAccessor(tables: [MediaAssets, SyncJobs])
class MediaAssetDao extends DatabaseAccessor<AppDatabase>
    with _$MediaAssetDaoMixin {
  MediaAssetDao(super.db);

  Stream<List<MediaAsset>> watchAllMediaAssets() => select(mediaAssets).watch();

  Future<int> insertMediaAsset(MediaAssetsCompanion entity) =>
      into(mediaAssets).insert(entity);

  Future<void> bulkInsertCloudMedia(List<MediaAssetsCompanion> assets) async {
    await batch((batch) {
      batch.insertAll(mediaAssets, assets, mode: InsertMode.insertOrIgnore);
    });
  }

  /// [新增] 更新单个媒体资源。
  /// 用于上传/下载成功后，更新多个字段。
  Future<void> updateAsset(MediaAssetsCompanion companion) {
    return (update(
      mediaAssets,
    )..where((tbl) => tbl.id.equals(companion.id.value))).write(companion);
  }

  /// [新增] 仅更新单个媒体资源的状态。
  /// 用于快速更新UI（如开始上传/下载时）。
  Future<void> updateAssetStatus(int assetId, SyncStatus status) {
    return (update(mediaAssets)..where((tbl) => tbl.id.equals(assetId))).write(
      MediaAssetsCompanion(syncStatus: Value(status)),
    );
  }

  // [新增] 专门用于首次同步时，清空所有非本地的数据
  Future<void> deleteAllCloudRelatedAssets() {
    return (delete(mediaAssets)..where(
          (tbl) =>
              tbl.syncStatus.isNotValue(SyncStatus.localOnlyNotSelected.name),
        ))
        .go();
  }

  Future<void> markAsPendingBackup(List<int> assetIds) async {
    return transaction(() async {
      final query = update(mediaAssets)..where((tbl) => tbl.id.isIn(assetIds));
      await query.write(
        const MediaAssetsCompanion(syncStatus: Value(SyncStatus.uploading)),
      );
      final jobs = assetIds.map(
        (id) => SyncJobsCompanion.insert(
          assetId: id,
          jobType: JobType.upload,
          status: JobStatus.pending,
        ),
      );
      await batch((batch) => batch.insertAll(syncJobs, jobs));
    });
  }

  Future<void> performOptimisticDelete(MediaAsset assetToDelete) async {
    return transaction(() async {
      await (delete(
        mediaAssets,
      )..where((tbl) => tbl.id.equals(assetToDelete.id))).go();
      if (assetToDelete.cloudUuid != null) {
        await into(syncJobs).insert(
          SyncJobsCompanion.insert(
            assetId: assetToDelete.id,
            relatedCloudUuid: Value(assetToDelete.cloudUuid),
            jobType: JobType.deleteCloud,
            status: JobStatus.pending,
          ),
        );
      }
    });
  }

  Future<void> bulkUpsertCloudMedia(
    List<MediaAssetsCompanion> cloudAssets,
  ) async {
    if (cloudAssets.isEmpty) return;
    await transaction(() async {
      for (final asset in cloudAssets) {
        await into(mediaAssets).insertOnConflictUpdate(asset);
      }
    });
  }

  /// [核心修正] 重写 applyCloudChanges 以实现非破坏性合并并处理可空性
  Future<void> applyCloudChanges({
    required List<MediaAssetsCompanion> toUpsert,
    required List<String> uuidsToDelete,
  }) async {
    print("开始应用云端变更，执行非破坏性合并...");
    print("待处理: ${toUpsert.length} 条, 待删除: ${uuidsToDelete.length} 条。");

    return transaction(() async {
      // 步骤 1: 处理删除，这部分逻辑是正确的
      if (uuidsToDelete.isNotEmpty) {
        await (delete(
          mediaAssets,
        )..where((tbl) => tbl.cloudUuid.isIn(uuidsToDelete))).go();
        print("成功删除了 ${uuidsToDelete.length} 条云端指定的记录。");
      }

      // 步骤 2: [新逻辑] 处理更新和插入
      if (toUpsert.isNotEmpty) {
        int newInserts = 0;
        int skippedUpdates = 0;

        for (final companion in toUpsert) {
          // [修正] 从 companion 中安全地获取 cloudUuid
          final cloudUuidValue = companion.cloudUuid.value;

          // [修正] 在使用之前，必须检查 cloudUuid 是否为 null
          if (cloudUuidValue != null && cloudUuidValue.isNotEmpty) {
            // 现在 cloudUuidValue 是一个已知的、非空的 String
            final existingAsset =
                await (select(mediaAssets)..where(
                      (tbl) => tbl.cloudUuid.equals(cloudUuidValue),
                    )) // <-- 这里不再报错
                    .getSingleOrNull();

            if (existingAsset == null) {
              // [场景A] 本地不存在该记录：这是一个全新的、仅云端的媒体。
              await into(
                mediaAssets,
              ).insert(companion, mode: InsertMode.insertOrIgnore);
              newInserts++;
            } else {
              // [场景B] 本地已存在该记录：保护本地状态，跳过更新。
              skippedUpdates++;
            }
          } else {
            // 如果从云端来的数据没有 cloudUuid，我们跳过它，因为它无法被唯一标识。
            print("警告: 跳过一个没有有效 cloudUuid 的云端资产。");
          }
        }
        print("处理完成：新增 $newInserts 条云端记录，跳过 $skippedUpdates 条已有记录的更新。");
      }
    });
  }
}

// --- SyncJob DAO ---
@DriftAccessor(tables: [SyncJobs])
class SyncJobDao extends DatabaseAccessor<AppDatabase> with _$SyncJobDaoMixin {
  SyncJobDao(super.db);
  Future<List<SyncJob>> getPendingJobs() => (select(
    syncJobs,
  )..where((tbl) => tbl.status.equalsValue(JobStatus.pending))).get();
  Future<void> updateJob(int jobId, SyncJobsCompanion updates) =>
      (update(syncJobs)..where((tbl) => tbl.id.equals(jobId))).write(updates);
  Future<void> deleteJob(int jobId) =>
      (delete(syncJobs)..where((tbl) => tbl.id.equals(jobId))).go();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'media_library.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
