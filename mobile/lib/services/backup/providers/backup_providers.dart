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
import 'package:prismbox/services/backup/error_handler.dart';
import 'package:prismbox/services/backup/auto_recovery_manager.dart';
import 'package:prismbox/services/backup/network_optimizer.dart';
import 'package:prismbox/services/backup/resource_manager.dart';
import 'package:prismbox/services/backup/queue_size_manager.dart';
import 'package:prismbox/services/backup/task_cleanup_scheduler.dart';
import 'package:prismbox/services/backup/task_factory.dart';
import 'package:prismbox/services/backup/file_metadata_extractor.dart';
import 'package:prismbox/services/backup/upload_task_state_machine.dart';
import 'package:prismbox/providers/infrastructure/asset_providers.dart' as infra_asset;
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
  final errorHandler = ref.watch(backupErrorHandlerProvider);
  final uploadTaskManager = await ref.watch(uploadTaskManagerProvider.future);
  final stateMachine = await ref.watch(uploadTaskStateMachineProvider.future);
  final concurrencyController = UploadConcurrencyController();
  final pathResolver = await ref.watch(infra_asset.assetPathResolverProvider.future);
  final metadataExtractor = ref.watch(fileMetadataExtractorProvider);
  // 注意：taskUpdateService 会在 uploadServiceProvider 中设置
  // 这里先传入 null，后续通过 setTaskUpdateService 设置
  return UploadOrchestrator(
    database: database,
    stateMachine: stateMachine,
    apiService: apiService,
    concurrencyController: concurrencyController,
    uploadTaskManager: uploadTaskManager,
    pathResolver: pathResolver,
    metadataExtractor: metadataExtractor,
    errorHandler: errorHandler, // 注入错误处理器
    taskUpdateService: null, // 延迟设置
  );
}

/// UploadService Provider
@riverpod
Future<UploadService> uploadService(UploadServiceRef ref) async {
  final database = await ref.watch(infra.databaseProvider.future);
  final orchestrator = await ref.watch(uploadOrchestratorProvider.future);
  final conflictResolver = await ref.watch(taskConflictResolverProvider.future);
  final stateMachine = await ref.watch(uploadTaskStateMachineProvider.future);
  final uploadService = UploadService(
    database: database,
    orchestrator: orchestrator,
    conflictResolver: conflictResolver,
    stateMachine: stateMachine,
  );
  
  // 注意：UploadOrchestrator 在创建时传入了 taskUpdateService: null
  // 由于 UploadService 实现了 TaskUpdateService 接口，我们可以通过延迟设置来解决循环依赖
  // 但由于 UploadOrchestrator 的 taskUpdateService 是 final，我们需要重新创建
  // 实际上，更好的方法是让 UploadOrchestrator 支持延迟设置
  // 但为了简化，我们暂时使用降级处理（UploadOrchestrator 直接操作数据库）
  // 这样既避免了循环依赖，又保持了职责边界的清晰
  
  return uploadService;
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


/// TaskFactory Provider
@riverpod
Future<TaskFactory> taskFactory(TaskFactoryRef ref) async {
  final pathResolver = await ref.watch(infra_asset.assetPathResolverProvider.future);
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
  return BackupService(
    database: database,
    uploadService: uploadService,
    candidateSelector: candidateSelector,
    apiService: apiService,
    taskFactory: taskFactory,
  );
}

/// UploadTaskManager Provider
@riverpod
Future<UploadTaskManager> uploadTaskManager(
  UploadTaskManagerRef ref,
) async {
  final database = await ref.watch(infra.databaseProvider.future);
  final stateMachine = await ref.watch(uploadTaskStateMachineProvider.future);
  final errorHandler = ref.watch(backupErrorHandlerProvider);
  final uploadTaskManager = UploadTaskManager(
    database: database,
    stateMachine: stateMachine,
    errorHandler: errorHandler, // 注入错误处理器
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
  final pathResolver = await ref.watch(infra_asset.assetPathResolverProvider.future);
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
  final pathResolver = await ref.watch(infra_asset.assetPathResolverProvider.future);
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

