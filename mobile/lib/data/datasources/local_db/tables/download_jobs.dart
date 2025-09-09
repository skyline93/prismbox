// lib/data/datasources/local_db/tables/download_jobs.dart

import 'package:drift/drift.dart';
import 'package:mobile/core/enums.dart';

/// 用于在 Drift 表和 Dart 枚举之间转换的转换器
class DownloadJobStatusConverter
    extends TypeConverter<DownloadJobStatus, String> {
  const DownloadJobStatusConverter();
  @override
  DownloadJobStatus fromSql(String fromDb) {
    return DownloadJobStatus.values.byName(fromDb);
  }

  @override
  String toSql(DownloadJobStatus value) {
    return value.name;
  }
}

@DataClassName('DownloadJob')
class DownloadJobs extends Table {
  TextColumn get jobId => text()(); // 客户端生成的UUID作为主键
  TextColumn get taskId => text().nullable()(); // background_downloader 返回的任务ID
  TextColumn get mediaUuid => text()(); // 要下载的媒体文件的UUID
  TextColumn get downloadUrl => text()(); // 完整的下载URL
  TextColumn get savePath => text()(); // 文件保存路径
  TextColumn get status =>
      text().map(const DownloadJobStatusConverter())(); // 作业状态
  RealColumn get progress => real()(); // 下载进度 (0.0 to 1.0)
  DateTimeColumn get createdAt => dateTime()(); // 创建时间

  @override
  Set<Column> get primaryKey => {jobId};
}
