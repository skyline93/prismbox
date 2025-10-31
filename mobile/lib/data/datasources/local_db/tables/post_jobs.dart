// lib/data/datasources/local_db/tables/post_jobs.dart

import 'package:drift/drift.dart';

@DataClassName('PostJob')
class PostJobs extends Table {
  TextColumn get jobId => text()();
  TextColumn get groupUuid => text()();
  TextColumn get content => text().withDefault(const Constant(''))();
  TextColumn get status => text()(); // queued|preparing|waiting_uploads|creating_post|success|failed
  TextColumn get message => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {jobId};
}

