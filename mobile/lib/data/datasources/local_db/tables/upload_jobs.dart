// lib/data/datasources/local_db/tables/upload_jobs.dart

import 'package:drift/drift.dart';
import 'package:mobile/core/enums.dart';

class UploadJobStatusConverter extends TypeConverter<UploadJobStatus, String> {
  const UploadJobStatusConverter();
  @override
  UploadJobStatus fromSql(String fromDb) {
    return UploadJobStatus.values.byName(fromDb);
  }

  @override
  String toSql(UploadJobStatus value) {
    return value.name;
  }
}

@DataClassName('UploadJob')
class UploadJobs extends Table {
  TextColumn get jobId => text()(); // 客户端生成的UUID作为主键
  TextColumn get filePath => text()(); // 原始文件路径
  TextColumn get fileHash => text()(); // 完整文件的SHA256哈希
  IntColumn get totalSize => integer()(); // 文件总大小
  TextColumn get status =>
      text().map(const UploadJobStatusConverter())(); // 作业状态
  RealColumn get progress => real()(); // 整体上传进度 (0.0 to 1.0)
  DateTimeColumn get createdAt => dateTime()(); // 创建时间

  @override
  Set<Column> get primaryKey => {jobId};
}
