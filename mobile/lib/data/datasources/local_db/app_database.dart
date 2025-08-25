// lib/data/datasources/app_database.dart

import 'dart:developer';
import 'dart:async';

import 'package:drift/drift.dart';
import 'package:mobile/data/models/media/media_model.dart';
import 'package:mobile/data/datasources/local_db/enums.dart';
import 'package:mobile/data/datasources/local_db/tables/media_assets.dart';
import 'package:mobile/data/datasources/local_db/tables/sync_jobs.dart';
import 'package:mobile/data/datasources/local_db/tables/user_settings.dart';
import 'package:mobile/data/datasources/local_db/tables/albums.dart';

part 'daos/media_asset_dao.dart';
part 'daos/sync_job_dao.dart';
part 'daos/album_dao.dart';
part 'daos/user_settings_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [MediaAssets, SyncJobs, UserSettings, Albums],
  daos: [MediaAssetDao, SyncJobDao, AlbumDao, UserSettingDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 5;

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
      if (from < 5) {
        await m.createTable(albums);
      }
    },
  );
}
