// lib/data/datasources/app_database.dart

import 'dart:io';
import 'dart:developer';
import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:mobile/data/models/media/media_model.dart';
// import 'package:injectable/injectable.dart';
import 'package:drift/isolate.dart';

part 'app_database.g.dart';

enum SyncStatus {
  localOnlyNotSelected,
  uploading,
  synced,
  cloudOnly,
  downloading,
  error,
}

enum JobType {
  upload,
  deleteCloud,
  downloadOriginal,
  downloadThumbnail,
  syncCloudChanges,
  processCloudCreate,
  processCloudDelete,
}

enum JobStatus { pending, inProgress, failed }

enum NetworkConstraint { any, wifiOnly }

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
  IntColumn get assetId => integer().nullable().references(
    MediaAssets,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get jobType =>
      text().map(const EnumNameConverter(JobType.values))();
  TextColumn get status =>
      text().map(const EnumNameConverter(JobStatus.values))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get errorMessage => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get relatedCloudUuid => text().nullable()();

  // ADDED: Priority for the job. Higher value means higher priority.
  IntColumn get priority => integer().withDefault(const Constant(0))();

  // ADDED: Network constraint for job execution.
  TextColumn get networkConstraint => text()
      .map(const EnumNameConverter(NetworkConstraint.values))
      .withDefault(Constant(NetworkConstraint.any.name))();
}

@DataClassName('UserSetting')
class UserSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

// @lazySingleton
@DriftDatabase(
  tables: [MediaAssets, SyncJobs, UserSettings],
  daos: [MediaAssetDao, SyncJobDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 4;

  static DatabaseConnection _openConnection() {
    // 1. 创建一个 Future，它将异步地执行所有设置并返回一个 DatabaseConnection
    final future = Future<DatabaseConnection>(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbPath = p.join(dbFolder.path, 'media_library.sqlite');
      log("==========> dbPath: $dbPath");
      final file = File(dbPath);

      // 2. 创建底层的执行器 (QueryExecutor)
      final executor = NativeDatabase(
        file,
        setup: (database) {
          database.execute('PRAGMA journal_mode = WAL;');
          database.execute('PRAGMA synchronous = NORMAL;');
          database.execute('PRAGMA cache_size = 10000;');
          database.execute('PRAGMA temp_store = memory;');
          database.execute('PRAGMA mmap_size = 268435456;');
        },
      );

      // 3. 将执行器包装在 DatabaseConnection 中并返回。
      //    这是我之前所有回答中都遗漏的关键步骤。
      return DatabaseConnection.fromExecutor(executor);
    });

    // 4. 将这个类型完全正确的 Future<DatabaseConnection> 传递给 delayed 构造函数
    return DatabaseConnection.delayed(future);
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // Handles migration from version 1 to 2
      if (from < 2) {
        await m.addColumn(mediaAssets, mediaAssets.fileName);
      }
      // Handles migration from version 2 to 3
      if (from < 3) {
        await m.addColumn(syncJobs, syncJobs.priority);
        await m.addColumn(syncJobs, syncJobs.networkConstraint);
      }
      if (from < 4) {}
    },
  );
}

DriftIsolate? _driftIsolate;
Future<DriftIsolate>? _isolateFuture;

Future<DriftIsolate> _getIsolate() async {
  if (_driftIsolate != null) return _driftIsolate!;
  if (_isolateFuture != null) return _isolateFuture!;

  final completer = Completer<DriftIsolate>();
  _isolateFuture = completer.future;

  final isolate = await DriftIsolate.spawn(() => AppDatabase._openConnection());

  _driftIsolate = isolate;
  completer.complete(isolate);
  _isolateFuture = null;

  return isolate;
}

Future<AppDatabase> connect() async {
  final isolate = await _getIsolate();
  final connection = await isolate.connect();
  return AppDatabase(connection);
}

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

  Future<void> updateAsset(MediaAssetsCompanion companion) {
    return (update(
      mediaAssets,
    )..where((tbl) => tbl.id.equals(companion.id.value))).write(companion);
  }

  Future<void> updateAssetStatus(int assetId, SyncStatus status) {
    return (update(mediaAssets)..where((tbl) => tbl.id.equals(assetId))).write(
      MediaAssetsCompanion(syncStatus: Value(status)),
    );
  }

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
          assetId: Value(id),
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
            assetId: Value(assetToDelete.id),
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

  Future<void> applyCloudChanges({
    required List<MediaAssetsCompanion> toUpsert,
    required List<String> uuidsToDelete,
  }) async {
    log("开始应用云端变更，执行非破坏性合并...", name: 'MediaAssetDao');
    log(
      "待处理: ${toUpsert.length} 条, 待删除: ${uuidsToDelete.length} 条。",
      name: 'MediaAssetDao',
    );

    return transaction(() async {
      if (uuidsToDelete.isNotEmpty) {
        await (delete(
          mediaAssets,
        )..where((tbl) => tbl.cloudUuid.isIn(uuidsToDelete))).go();
        log("成功删除了 ${uuidsToDelete.length} 条云端指定的记录。", name: 'MediaAssetDao');
      }

      if (toUpsert.isNotEmpty) {
        int newInserts = 0;
        int skippedUpdates = 0;

        for (final companion in toUpsert) {
          final cloudUuidValue = companion.cloudUuid.value;

          if (cloudUuidValue != null && cloudUuidValue.isNotEmpty) {
            final existingAsset =
                await (select(mediaAssets)
                      ..where((tbl) => tbl.cloudUuid.equals(cloudUuidValue)))
                    .getSingleOrNull();

            if (existingAsset == null) {
              await into(
                mediaAssets,
              ).insert(companion, mode: InsertMode.insertOrIgnore);
              newInserts++;
            } else {
              skippedUpdates++;
            }
          } else {
            log("警告: 跳过一个没有有效 cloudUuid 的云端资产。", name: 'MediaAssetDao');
          }
        }
        log(
          "处理完成：新增 $newInserts 条云端记录，跳过 $skippedUpdates 条已有记录的更新。",
          name: 'MediaAssetDao',
        );
      }
    });
  }
}

@DriftAccessor(tables: [SyncJobs])
class SyncJobDao extends DatabaseAccessor<AppDatabase> with _$SyncJobDaoMixin {
  SyncJobDao(super.db);

  Future<List<SyncJob>> getPendingJobs() => (select(
    syncJobs,
  )..where((tbl) => tbl.status.equalsValue(JobStatus.pending))).get();

  Future<SyncJob?> getNextPendingJob() {
    final query = select(syncJobs)
      ..where((tbl) => tbl.status.equalsValue(JobStatus.pending))
      ..orderBy([
        (tbl) =>
            OrderingTerm(expression: tbl.priority, mode: OrderingMode.desc),
        (tbl) =>
            OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.asc),
      ])
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<void> updateJobStatus(
    int jobId,
    JobStatus status, {
    String? errorMessage,
  }) {
    final companion = SyncJobsCompanion(
      status: Value(status),
      errorMessage: errorMessage != null
          ? Value(errorMessage)
          : const Value.absent(),
    );
    return (update(
      syncJobs,
    )..where((tbl) => tbl.id.equals(jobId))).write(companion);
  }

  Future<int> resetStaleJobs() {
    final staleTime = DateTime.now().subtract(const Duration(minutes: 30));
    final query = update(syncJobs)
      ..where(
        (tbl) =>
            tbl.status.equalsValue(JobStatus.inProgress) &
            tbl.createdAt.isSmallerThanValue(staleTime),
      );
    return query.write(
      const SyncJobsCompanion(status: Value(JobStatus.pending)),
    );
  }

  Future<void> updateJob(int jobId, SyncJobsCompanion updates) =>
      (update(syncJobs)..where((tbl) => tbl.id.equals(jobId))).write(updates);

  Future<void> deleteJob(int jobId) =>
      (delete(syncJobs)..where((tbl) => tbl.id.equals(jobId))).go();
}
