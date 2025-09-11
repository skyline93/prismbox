// lib/data/datasources/local_db/daos/upload_job_dao.dart

part of '../app_database.dart';

@DriftAccessor(tables: [UploadJobs])
class UploadJobDao extends DatabaseAccessor<AppDatabase>
    with _$UploadJobDaoMixin {
  UploadJobDao(super.db);

  /// 监听所有上传任务的变化
  Stream<List<UploadJob>> watchAllJobs() => select(uploadJobs).watch();

  /// 插入一个新的上传任务
  Future<void> insertJob(UploadJobsCompanion job) {
    return into(uploadJobs).insert(job);
  }

  /// 更新一个上传任务的部分字段。
  /// 它会根据 [job] 中的主键 [jobId] 匹配记录，并只更新 [job] 中有值的字段。
  Future<void> updateJob(UploadJobsCompanion job) {
    if (job.jobId.present) {
      return (update(
        uploadJobs,
      )..where((tbl) => tbl.jobId.equals(job.jobId.value))).write(job);
    } else {
      // 在更新操作中，jobId 是必须的
      throw ArgumentError('jobId must be provided when updating a job.');
    }
  }

  /// 根据 jobId 获取一个具体的上传任务
  Future<UploadJob?> getJob(String jobId) {
    return (select(
      uploadJobs,
    )..where((tbl) => tbl.jobId.equals(jobId))).getSingleOrNull();
  }
}
