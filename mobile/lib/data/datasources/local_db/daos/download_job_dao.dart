// lib/data/datasources/local_db/daos/download_job_dao.dart

part of '../app_database.dart';

@DriftAccessor(tables: [DownloadJobs])
class DownloadJobDao extends DatabaseAccessor<AppDatabase>
    with _$DownloadJobDaoMixin {
  DownloadJobDao(super.db);

  Stream<List<DownloadJob>> watchAllJobs() => select(downloadJobs).watch();

  Future<void> insertJob(DownloadJobsCompanion job) {
    return into(downloadJobs).insert(job);
  }

  Future<int> updateJob(DownloadJobsCompanion job) {
    if (job.jobId.present) {
      return (update(
        downloadJobs,
      )..where((tbl) => tbl.jobId.equals(job.jobId.value))).write(job);
    } else {
      throw ArgumentError('jobId must be provided when updating a job.');
    }
  }

  Future<DownloadJob?> getJob(String jobId) {
    return (select(
      downloadJobs,
    )..where((tbl) => tbl.jobId.equals(jobId))).getSingleOrNull();
  }

  Future<DownloadJob?> getJobByTaskId(String taskId) {
    return (select(
      downloadJobs,
    )..where((tbl) => tbl.taskId.equals(taskId))).getSingleOrNull();
  }
}
