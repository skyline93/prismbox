// lib/providers/transfer_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:mobile/services/transfer/transfer_manager.dart';
import 'package:mobile/services/transfer/upload_orchestrator.dart';

part 'transfer_providers.g.dart';

@Riverpod(keepAlive: true)
TransferManager transferManager(TransferManagerRef ref) {
  return getIt<TransferManager>();
}

@riverpod
DownloadJobDao downloadJobDao(DownloadJobDaoRef ref) {
  return getIt<AppDatabase>().downloadJobDao;
}

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

final uploadOrchestratorProvider = Provider((ref) {
  return UploadOrchestrator();
});
