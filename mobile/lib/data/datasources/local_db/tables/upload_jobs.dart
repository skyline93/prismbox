// lib/data/datasources/local_db/tables/upload_jobs.dart

import 'package:drift/drift.dart';
import 'package:mobile/core/enums.dart';


/// 用于在 Drift 表和 Dart 枚举之间转换的转换器
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
  TextColumn get uploadId => text().nullable()(); // 服务端返回的上传ID
  TextColumn get filePath => text()(); // 原始文件路径
  TextColumn get fileHash => text()(); // 完整文件的SHA256哈希
  IntColumn get totalSize => integer()(); // 文件总大小
  IntColumn get chunkSize => integer()(); // 分片大小
  IntColumn get totalChunks => integer()(); // 总分片数
  TextColumn get status =>
      text().map(const UploadJobStatusConverter())(); // 作业状态
  RealColumn get progress => real()(); // 整体上传进度 (0.0 to 1.0)
  DateTimeColumn get createdAt => dateTime()(); // 创建时间

  @override
  Set<Column> get primaryKey => {jobId};
}
