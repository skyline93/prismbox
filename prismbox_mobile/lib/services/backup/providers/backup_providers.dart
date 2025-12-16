// lib/services/backup/providers/backup_providers.dart

import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:prismbox/services/backup/backup_query_builder.dart';
import 'package:prismbox/services/backup/task_conflict_resolver.dart';
import 'package:prismbox/services/backup/backup_candidate_selector.dart';
import 'package:prismbox/services/backup/upload_orchestrator.dart';
import 'package:prismbox/services/backup/upload_service.dart';
import 'package:prismbox/services/backup/upload_concurrency_controller.dart';
import 'package:prismbox/services/backup/upload_task_manager.dart';
import 'package:prismbox/services/backup/backup_config_validator.dart';
import 'package:prismbox/services/backup/backup_service.dart';
import 'package:prismbox/services/backup/background_sync_manager.dart';
import 'package:prismbox/services/backup/error_handler.dart';
import 'package:prismbox/services/backup/auto_recovery_manager.dart';
import 'package:prismbox/services/backup/network_optimizer.dart';
import 'package:prismbox/services/backup/resource_manager.dart';
import 'package:prismbox/services/backup/queue_size_manager.dart';
import 'package:prismbox/services/backup/task_cleanup_scheduler.dart';
import 'package:prismbox/services/backup/task_factory.dart';
import 'package:prismbox/services/backup/asset_path_resolver.dart';
import 'package:prismbox/services/backup/file_metadata_extractor.dart';
import 'package:prismbox/services/backup/upload_task_state_machine.dart';
import 'package:prismbox/features/local_sync/providers/local_sync_providers.dart';
import 'package:prismbox/providers/infrastructure/database_provider.dart' as infra;
import 'package:prismbox/providers/infrastructure/api_service_provider.dart' as infra;

part 'backup_providers.g.dart';

/// BackupQueryBuilder Provider
@riverpod
Future<BackupQueryBuilder> backupQueryBuilder(BackupQueryBuilderRef ref) async {
  final database = await ref.watch(infra.databaseProvider.future);
  return BackupQueryBuilder(database);
}

/// TaskConflictResolver Provider
@riverpod
Future<TaskConflictResolver> taskConflictResolver(
  TaskConflictResolverRef ref,
) async {
  final database = await ref.watch(infra.databaseProvider.future);
  final stateMachine = await ref.watch(uploadTaskStateMachineProvider.future);
  return TaskConflictResolver(
    database: database,
    stateMachine: stateMachine,
  );
}

/// BackupCandidateSelector Provider
@riverpod
Future<BackupCandidateSelector> backupCandidateSelector(
  BackupCandidateSelectorRef ref,
) async {
  final database = await ref.watch(infra.databaseProvider.future);
  return BackupCandidateSelector(
    database: database,
  );
}

/// UploadOrchestrator Provider
/// 
/// 使用 keepAlive: true 确保全局单例，这样所有组件共享同一个实例
/// 确保上传完成通知流能够正确工作
@Riverpod(keepAlive: true)
Future<UploadOrchestrator> uploadOrchestrator(
  UploadOrchestratorRef ref,
) async {
  final database = await ref.watch(infra.databaseProvider.future);
  final apiService = ref.watch(infra.apiServiceProvider);
  final uploadTaskManager = await ref.watch(uploadTaskManagerProvider.future);
  final stateMachine = await ref.watch(uploadTaskStateMachineProvider.future);
  final concurrencyController = UploadConcurrencyController();
  final pathResolver = await ref.watch(assetPathResolverProvider.future);
  final metadataExtractor = ref.watch(fileMetadataExtractorProvider);
  return UploadOrchestrator(
    database: database,
    stateMachine: stateMachine,
    apiService: apiService,
    concurrencyController: concurrencyController,
    uploadTaskManager: uploadTaskManager,
    pathResolver: pathResolver,
    metadataExtractor: metadataExtractor,
  );
}

/// UploadService Provider
@riverpod
Future<UploadService> uploadService(UploadServiceRef ref) async {
  final database = await ref.watch(infra.databaseProvider.future);
  final orchestrator = await ref.watch(uploadOrchestratorProvider.future);
  final conflictResolver = await ref.watch(taskConflictResolverProvider.future);
  final stateMachine = await ref.watch(uploadTaskStateMachineProvider.future);
  return UploadService(
    database: database,
    orchestrator: orchestrator,
    conflictResolver: conflictResolver,
    stateMachine: stateMachine,
  );
}

/// BackupConfigValidator Provider
@riverpod
BackupConfigValidator backupConfigValidator(BackupConfigValidatorRef ref) {
  return BackupConfigValidator();
}

/// FileMetadataExtractor Provider
@riverpod
FileMetadataExtractor fileMetadataExtractor(FileMetadataExtractorRef ref) {
  return FileMetadataExtractor();
}

/// AssetPathResolver Provider
@riverpod
Future<AssetPathResolver> assetPathResolver(AssetPathResolverRef ref) async {
  final database = await ref.watch(infra.databaseProvider.future);
  return AssetPathResolver(database: database);
}

/// TaskFactory Provider
@riverpod
Future<TaskFactory> taskFactory(TaskFactoryRef ref) async {
  final pathResolver = await ref.watch(assetPathResolverProvider.future);
  final metadataExtractor = ref.watch(fileMetadataExtractorProvider);
  return TaskFactory(
    pathResolver: pathResolver,
    metadataExtractor: metadataExtractor,
  );
}

/// UploadTaskStateMachine Provider
@riverpod
Future<UploadTaskStateMachine> uploadTaskStateMachine(
  UploadTaskStateMachineRef ref,
) async {
  final database = await ref.watch(infra.databaseProvider.future);
  return UploadTaskStateMachine(database: database);
}

/// BackupService Provider
@riverpod
Future<BackupService> backupService(BackupServiceRef ref) async {
  final database = await ref.watch(infra.databaseProvider.future);
  final uploadService = await ref.watch(uploadServiceProvider.future);
  final candidateSelector = await ref.watch(backupCandidateSelectorProvider.future);
  final apiService = ref.watch(infra.apiServiceProvider);
  final taskFactory = await ref.watch(taskFactoryProvider.future);
  final stateMachine = await ref.watch(uploadTaskStateMachineProvider.future);
  return BackupService(
    database: database,
    uploadService: uploadService,
    candidateSelector: candidateSelector,
    apiService: apiService,
    taskFactory: taskFactory,
    stateMachine: stateMachine,
  );
}

/// BackgroundSyncManager Provider
@riverpod
Future<BackgroundSyncManager> backgroundSyncManager(
  BackgroundSyncManagerRef ref,
) async {
  final database = await ref.watch(infra.databaseProvider.future);
  final localSyncService = await ref.watch(localSyncServiceProvider.future);
  final apiService = ref.watch(infra.apiServiceProvider);
  final pathResolver = await ref.watch(assetPathResolverProvider.future);
  return BackgroundSyncManager(
    database: database,
    localSyncService: localSyncService,
    apiService: apiService,
    pathResolver: pathResolver,
  );
}

/// UploadTaskManager Provider
@riverpod
Future<UploadTaskManager> uploadTaskManager(
  UploadTaskManagerRef ref,
) async {
  final database = await ref.watch(infra.databaseProvider.future);
  final stateMachine = await ref.watch(uploadTaskStateMachineProvider.future);
  final uploadTaskManager = UploadTaskManager(
    database: database,
    stateMachine: stateMachine,
  );
  
  // 初始化 UploadTaskManager（注册回调和配置）
  await uploadTaskManager.initialize(
    onStatusChange: (taskId, status) {
      // 状态更新回调（UploadTaskManager 会自动更新数据库）
      final logger = Logger('UploadTaskManager');
      logger.fine('Upload task status changed: taskId=$taskId, status=$status');
    },
    onProgress: (taskId, progress) {
      // 进度更新回调（UploadTaskManager 会自动更新数据库）
      final logger = Logger('UploadTaskManager');
      logger.fine('Upload task progress: taskId=$taskId, progress=$progress');
    },
  );
  
  return uploadTaskManager;
}

/// BackupErrorHandler Provider
@riverpod
BackupErrorHandler backupErrorHandler(BackupErrorHandlerRef ref) {
  return BackupErrorHandler();
}

/// AutoRecoveryManager Provider
@riverpod
Future<AutoRecoveryManager> autoRecoveryManager(
  AutoRecoveryManagerRef ref,
) async {
  final database = await ref.watch(infra.databaseProvider.future);
  final pathResolver = await ref.watch(assetPathResolverProvider.future);
  final stateMachine = await ref.watch(uploadTaskStateMachineProvider.future);
  return AutoRecoveryManager(
    database: database,
    pathResolver: pathResolver,
    stateMachine: stateMachine,
  );
}

/// NetworkOptimizer Provider
@riverpod
NetworkOptimizer networkOptimizer(NetworkOptimizerRef ref) {
  final apiService = ref.watch(infra.apiServiceProvider);
  return NetworkOptimizer(apiService: apiService);
}

/// ResourceManager Provider
@riverpod
Future<ResourceManager> resourceManager(ResourceManagerRef ref) async {
  final database = await ref.watch(infra.databaseProvider.future);
  final pathResolver = await ref.watch(assetPathResolverProvider.future);
  return ResourceManager(
    database: database,
    pathResolver: pathResolver,
  );
}

/// QueueSizeManager Provider
@riverpod
Future<QueueSizeManager> queueSizeManager(QueueSizeManagerRef ref) async {
  final database = await ref.watch(infra.databaseProvider.future);
  return QueueSizeManager(database: database);
}

/// TaskCleanupScheduler Provider
@riverpod
Future<TaskCleanupScheduler> taskCleanupScheduler(
  TaskCleanupSchedulerRef ref,
) async {
  final database = await ref.watch(infra.databaseProvider.future);
  final resourceManager = await ref.watch(resourceManagerProvider.future);
  return TaskCleanupScheduler(
    database: database,
    resourceManager: resourceManager,
  );
}

