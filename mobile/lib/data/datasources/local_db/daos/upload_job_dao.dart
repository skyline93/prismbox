// lib/data/datasources/local_db/daos/upload_job_dao.dart

part of '../app_database.dart';

@DriftAccessor(tables: [UploadJobs])
class UploadJobDao extends DatabaseAccessor<AppDatabase>
    with _$UploadJobDaoMixin {
  UploadJobDao(super.db);

  Stream<List<UploadJob>> watchAllJobs() => select(uploadJobs).watch();

  Future<void> insertJob(UploadJobsCompanion job) {
    return into(uploadJobs).insert(job);
  }

  Future<void> updateJob(UploadJobsCompanion job) {
    if (job.jobId.present) {
      return (update(
        uploadJobs,
      )..where((tbl) => tbl.jobId.equals(job.jobId.value))).write(job);
    } else {
      throw ArgumentError('jobId must be provided when updating a job.');
    }
  }

  Future<UploadJob?> getJob(String jobId) {
    return (select(
      uploadJobs,
    )..where((tbl) => tbl.jobId.equals(jobId))).getSingleOrNull();
  }
}
