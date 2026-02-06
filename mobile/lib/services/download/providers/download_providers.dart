// lib/services/download/providers/download_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:prismbox/services/download/download_orchestrator.dart';
import 'package:prismbox/services/download/download_save_to_album.dart';
import 'package:prismbox/services/download/download_service.dart';
import 'package:prismbox/services/download/download_task_manager.dart';
import 'package:prismbox/services/download/download_task_state_machine.dart';
import 'package:prismbox/providers/infrastructure/database_provider.dart' as infra;

part 'download_providers.g.dart';

/// DownloadSaveToAlbum Provider
@riverpod
DownloadSaveToAlbum downloadSaveToAlbum(DownloadSaveToAlbumRef ref) {
  return DownloadSaveToAlbum();
}

/// DownloadTaskStateMachine Provider
@riverpod
Future<DownloadTaskStateMachine> downloadTaskStateMachine(
  DownloadTaskStateMachineRef ref,
) async {
  final database = await ref.watch(infra.databaseProvider.future);
  return DownloadTaskStateMachine(database: database);
}

/// DownloadTaskManager Provider
@riverpod
Future<DownloadTaskManager> downloadTaskManager(
  DownloadTaskManagerRef ref,
) async {
  final database = await ref.watch(infra.databaseProvider.future);
  final stateMachine = await ref.watch(downloadTaskStateMachineProvider.future);
  final saveToAlbum = ref.watch(downloadSaveToAlbumProvider);
  final manager = DownloadTaskManager(
    database: database,
    stateMachine: stateMachine,
    saveToAlbum: saveToAlbum,
  );
  await manager.initialize();
  return manager;
}

/// DownloadOrchestrator Provider
@riverpod
Future<DownloadOrchestrator> downloadOrchestrator(
  DownloadOrchestratorRef ref,
) async {
  final database = await ref.watch(infra.databaseProvider.future);
  final taskManager = await ref.watch(downloadTaskManagerProvider.future);
  return DownloadOrchestrator(
    database: database,
    taskManager: taskManager,
  );
}

/// DownloadService Provider
@riverpod
Future<DownloadService> downloadService(DownloadServiceRef ref) async {
  final database = await ref.watch(infra.databaseProvider.future);
  final orchestrator = await ref.watch(downloadOrchestratorProvider.future);
  return DownloadService(
    database: database,
    orchestrator: orchestrator,
  );
}
