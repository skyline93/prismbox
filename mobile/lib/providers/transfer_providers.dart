// lib/providers/transfer_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mobile/core/service_locator.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:mobile/services/transfer/transfer_manager.dart';

part 'transfer_providers.g.dart';

// Provider for the TransferService singleton
// [注意] transfer_providers.g.dart 中 transferService 名称应为 transferManager
@Riverpod(keepAlive: true)
TransferManager transferManager(TransferManagerRef ref) {
  return getIt<TransferManager>();
}

// Provider for the DownloadJobDao
@riverpod
DownloadJobDao downloadJobDao(DownloadJobDaoRef ref) {
  return getIt<AppDatabase>().downloadJobDao;
}

// [任务 3.2] StreamProvider, 监听所有下载任务
@riverpod
Stream<List<DownloadJob>> downloadJobs(DownloadJobsRef ref) {
  final dao = ref.watch(downloadJobDaoProvider);
  return dao.watchAllJobs();
}

@riverpod
UploadJobDao uploadJobDao(UploadJobDaoRef ref) {
  return getIt<AppDatabase>().uploadJobDao;
}

@riverpod
Stream<List<UploadJob>> uploadJobs(UploadJobsRef ref) {
  final dao = ref.watch(uploadJobDaoProvider);
  return dao.watchAllJobs();
}
