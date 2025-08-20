part of '../app_database.dart';

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
