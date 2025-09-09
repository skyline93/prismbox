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

  /// 更新一个上传任务
  /// 它会根据主键 [jobId] 匹配并更新记录
  Future<bool> updateJob(UploadJobsCompanion job) {
    return update(uploadJobs).replace(job);
  }

  /// 根据 jobId 获取一个具体的上传任务
  Future<UploadJob?> getJob(String jobId) {
    return (select(
      uploadJobs,
    )..where((tbl) => tbl.jobId.equals(jobId))).getSingleOrNull();
  }

  /// 根据服务端返回的 uploadId 获取一个上传任务
  Future<UploadJob?> getJobByUploadId(String uploadId) {
    return (select(
      uploadJobs,
    )..where((tbl) => tbl.uploadId.equals(uploadId))).getSingleOrNull();
  }
}
