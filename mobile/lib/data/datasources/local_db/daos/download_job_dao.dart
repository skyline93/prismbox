// lib/data/datasources/local_db/daos/download_job_dao.dart

part of '../app_database.dart';

@DriftAccessor(tables: [DownloadJobs])
class DownloadJobDao extends DatabaseAccessor<AppDatabase>
    with _$DownloadJobDaoMixin {
  DownloadJobDao(super.db);

  /// 监听所有下载任务的变化
  Stream<List<DownloadJob>> watchAllJobs() => select(downloadJobs).watch();

  /// 插入一个新的下载任务
  Future<void> insertJob(DownloadJobsCompanion job) {
    return into(downloadJobs).insert(job);
  }

  /// 更新一个下载任务
  /// 它会根据主键 [jobId] 匹配并更新记录
  // [修改开始]
  Future<int> updateJob(DownloadJobsCompanion job) {
    // 确保 companion 包含有效的 jobId
    if (job.jobId.present) {
      return (update(
        downloadJobs,
      )..where((tbl) => tbl.jobId.equals(job.jobId.value))).write(job);
    } else {
      // 在更新操作中，jobId 是必须的
      throw ArgumentError('jobId must be provided when updating a job.');
    }
  }
  // [修改结束]

  /// 根据 jobId 获取一个具体的下载任务
  Future<DownloadJob?> getJob(String jobId) {
    return (select(
      downloadJobs,
    )..where((tbl) => tbl.jobId.equals(jobId))).getSingleOrNull();
  }

  /// 根据 background_downloader 的 taskId 获取一个下载任务
  Future<DownloadJob?> getJobByTaskId(String taskId) {
    return (select(
      downloadJobs,
    )..where((tbl) => tbl.taskId.equals(taskId))).getSingleOrNull();
  }
}
