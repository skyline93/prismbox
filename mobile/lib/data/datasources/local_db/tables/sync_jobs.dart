// lib/data/datasources/local_db/tables/sync_jobs.dart

import 'package:drift/drift.dart';
import '../enums.dart';
import 'media_assets.dart';

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
  IntColumn get priority => integer().withDefault(const Constant(0))();
  TextColumn get networkConstraint => text()
      .map(const EnumNameConverter(NetworkConstraint.values))
      .withDefault(Constant(NetworkConstraint.any.name))();

  TextColumn get payload => text().withDefault(const Constant('{}'))();
}
