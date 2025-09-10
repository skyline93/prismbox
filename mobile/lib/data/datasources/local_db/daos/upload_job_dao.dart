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
  Future<int> updateJob(UploadJobsCompanion job) {
    // 使用 (update()..where()).write() 来执行部分更新
    // 这只会更新 job 中被明确设置的字段
    return (update(
      uploadJobs,
    )..where((tbl) => tbl.jobId.equals(job.jobId.value))).write(job);
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
