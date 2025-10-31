// lib/data/datasources/local_db/daos/post_job_dao.dart

part of '../app_database.dart';

@DriftAccessor(tables: [PostJobs])
class PostJobDao extends DatabaseAccessor<AppDatabase> with _$PostJobDaoMixin {
  PostJobDao(super.db);

  Future<void> insertJob(PostJobsCompanion job) => into(postJobs).insert(job);

  Future<void> updateStatus(String jobId, String status, {String? message}) {
    return (update(postJobs)..where((t) => t.jobId.equals(jobId))).write(
      PostJobsCompanion(
        status: Value(status),
        message: Value(message),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Stream<PostJob?> watchJob(String jobId) =>
      (select(postJobs)..where((t) => t.jobId.equals(jobId)))
          .watchSingleOrNull();

  Stream<List<PostJob>> watchJobsByGroup(String groupUuid) =>
      (select(postJobs)
            ..where((t) => t.groupUuid.equals(groupUuid))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Future<PostJob?> getJob(String jobId) =>
      (select(postJobs)..where((t) => t.jobId.equals(jobId))).getSingleOrNull();

  Future<void> deleteJob(String jobId) =>
      (delete(postJobs)..where((t) => t.jobId.equals(jobId))).go();
}

