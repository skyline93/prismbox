// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$backupQueryBuilderHash() =>
    r'3fc45e81fd4bb1727064fa46e1913839ddb74f58';

/// BackupQueryBuilder Provider
///
/// Copied from [backupQueryBuilder].
@ProviderFor(backupQueryBuilder)
final backupQueryBuilderProvider =
    AutoDisposeFutureProvider<BackupQueryBuilder>.internal(
  backupQueryBuilder,
  name: r'backupQueryBuilderProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$backupQueryBuilderHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef BackupQueryBuilderRef
    = AutoDisposeFutureProviderRef<BackupQueryBuilder>;
String _$taskConflictResolverHash() =>
    r'fd7b4bdf2eab742988afee71f13380c3fdf95e33';

/// TaskConflictResolver Provider
///
/// Copied from [taskConflictResolver].
@ProviderFor(taskConflictResolver)
final taskConflictResolverProvider =
    AutoDisposeFutureProvider<TaskConflictResolver>.internal(
  taskConflictResolver,
  name: r'taskConflictResolverProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$taskConflictResolverHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TaskConflictResolverRef
    = AutoDisposeFutureProviderRef<TaskConflictResolver>;
String _$backupCandidateSelectorHash() =>
    r'2900165d51243d5aa9aeb82355a0e5c894cc76a3';

/// BackupCandidateSelector Provider
///
/// Copied from [backupCandidateSelector].
@ProviderFor(backupCandidateSelector)
final backupCandidateSelectorProvider =
    AutoDisposeFutureProvider<BackupCandidateSelector>.internal(
  backupCandidateSelector,
  name: r'backupCandidateSelectorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$backupCandidateSelectorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef BackupCandidateSelectorRef
    = AutoDisposeFutureProviderRef<BackupCandidateSelector>;
String _$assetSyncServiceHash() => r'8e1b80fefce37f9a9280d816b8bbb620aa961d71';

/// AssetSyncService Provider
///
/// 向后兼容：委托给新的同步模块 Provider
///
/// Copied from [assetSyncService].
@ProviderFor(assetSyncService)
final assetSyncServiceProvider =
    AutoDisposeFutureProvider<AssetSyncService>.internal(
  assetSyncService,
  name: r'assetSyncServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$assetSyncServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AssetSyncServiceRef = AutoDisposeFutureProviderRef<AssetSyncService>;
String _$uploadOrchestratorHash() =>
    r'874e86fe6134ca476c335a16ae9a2c0b8b3ca200';

/// UploadOrchestrator Provider
///
/// 使用 keepAlive: true 确保全局单例，这样所有组件共享同一个实例
/// 确保上传完成通知流能够正确工作
///
/// Copied from [uploadOrchestrator].
@ProviderFor(uploadOrchestrator)
final uploadOrchestratorProvider = FutureProvider<UploadOrchestrator>.internal(
  uploadOrchestrator,
  name: r'uploadOrchestratorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$uploadOrchestratorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef UploadOrchestratorRef = FutureProviderRef<UploadOrchestrator>;
String _$uploadServiceHash() => r'9c47055749c9f3a01bc7e2c7082ef9086892bde8';

/// UploadService Provider
///
/// Copied from [uploadService].
@ProviderFor(uploadService)
final uploadServiceProvider = AutoDisposeFutureProvider<UploadService>.internal(
  uploadService,
  name: r'uploadServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$uploadServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef UploadServiceRef = AutoDisposeFutureProviderRef<UploadService>;
String _$backupConfigValidatorHash() =>
    r'14a004982f9dc1b7994836afe5360ea05f411334';

/// BackupConfigValidator Provider
///
/// Copied from [backupConfigValidator].
@ProviderFor(backupConfigValidator)
final backupConfigValidatorProvider =
    AutoDisposeProvider<BackupConfigValidator>.internal(
  backupConfigValidator,
  name: r'backupConfigValidatorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$backupConfigValidatorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef BackupConfigValidatorRef
    = AutoDisposeProviderRef<BackupConfigValidator>;
String _$fileMetadataExtractorHash() =>
    r'87f8a3e587d3a5daa8acc66cda22a695ed7f2624';

/// FileMetadataExtractor Provider
///
/// Copied from [fileMetadataExtractor].
@ProviderFor(fileMetadataExtractor)
final fileMetadataExtractorProvider =
    AutoDisposeProvider<FileMetadataExtractor>.internal(
  fileMetadataExtractor,
  name: r'fileMetadataExtractorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$fileMetadataExtractorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FileMetadataExtractorRef
    = AutoDisposeProviderRef<FileMetadataExtractor>;
String _$assetPathResolverHash() => r'34790b6143b52a38555373aee88f219c57ae49b1';

/// AssetPathResolver Provider
///
/// Copied from [assetPathResolver].
@ProviderFor(assetPathResolver)
final assetPathResolverProvider =
    AutoDisposeFutureProvider<AssetPathResolver>.internal(
  assetPathResolver,
  name: r'assetPathResolverProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$assetPathResolverHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AssetPathResolverRef = AutoDisposeFutureProviderRef<AssetPathResolver>;
String _$taskFactoryHash() => r'10e4901397311091c4f034b5b4fa1a55e8cd628f';

/// TaskFactory Provider
///
/// Copied from [taskFactory].
@ProviderFor(taskFactory)
final taskFactoryProvider = AutoDisposeFutureProvider<TaskFactory>.internal(
  taskFactory,
  name: r'taskFactoryProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$taskFactoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TaskFactoryRef = AutoDisposeFutureProviderRef<TaskFactory>;
String _$uploadTaskStateMachineHash() =>
    r'795053592cf9dd6a161ba577f05866498881f794';

/// UploadTaskStateMachine Provider
///
/// Copied from [uploadTaskStateMachine].
@ProviderFor(uploadTaskStateMachine)
final uploadTaskStateMachineProvider =
    AutoDisposeFutureProvider<UploadTaskStateMachine>.internal(
  uploadTaskStateMachine,
  name: r'uploadTaskStateMachineProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$uploadTaskStateMachineHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef UploadTaskStateMachineRef
    = AutoDisposeFutureProviderRef<UploadTaskStateMachine>;
String _$backupServiceHash() => r'7528f7ab4d669294bfae51d76a3b687c3f59ca22';

/// BackupService Provider
///
/// Copied from [backupService].
@ProviderFor(backupService)
final backupServiceProvider = AutoDisposeFutureProvider<BackupService>.internal(
  backupService,
  name: r'backupServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$backupServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef BackupServiceRef = AutoDisposeFutureProviderRef<BackupService>;
String _$uploadTaskManagerHash() => r'81d2d9ad4597e5c2097d6f1c31176dcc945e9cac';

/// UploadTaskManager Provider
///
/// Copied from [uploadTaskManager].
@ProviderFor(uploadTaskManager)
final uploadTaskManagerProvider =
    AutoDisposeFutureProvider<UploadTaskManager>.internal(
  uploadTaskManager,
  name: r'uploadTaskManagerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$uploadTaskManagerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef UploadTaskManagerRef = AutoDisposeFutureProviderRef<UploadTaskManager>;
String _$backupErrorHandlerHash() =>
    r'2bc30406ffa6a64a0a3070afb0b642adbce5ce3a';

/// BackupErrorHandler Provider
///
/// Copied from [backupErrorHandler].
@ProviderFor(backupErrorHandler)
final backupErrorHandlerProvider =
    AutoDisposeProvider<BackupErrorHandler>.internal(
  backupErrorHandler,
  name: r'backupErrorHandlerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$backupErrorHandlerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef BackupErrorHandlerRef = AutoDisposeProviderRef<BackupErrorHandler>;
String _$autoRecoveryManagerHash() =>
    r'd50e36f28c62c5cb8c04ab5c9a57601522498ea4';

/// AutoRecoveryManager Provider
///
/// Copied from [autoRecoveryManager].
@ProviderFor(autoRecoveryManager)
final autoRecoveryManagerProvider =
    AutoDisposeFutureProvider<AutoRecoveryManager>.internal(
  autoRecoveryManager,
  name: r'autoRecoveryManagerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$autoRecoveryManagerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AutoRecoveryManagerRef
    = AutoDisposeFutureProviderRef<AutoRecoveryManager>;
String _$networkOptimizerHash() => r'69f41d347e750d168ce47a113464b25c6cc784fc';

/// NetworkOptimizer Provider
///
/// Copied from [networkOptimizer].
@ProviderFor(networkOptimizer)
final networkOptimizerProvider = AutoDisposeProvider<NetworkOptimizer>.internal(
  networkOptimizer,
  name: r'networkOptimizerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$networkOptimizerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef NetworkOptimizerRef = AutoDisposeProviderRef<NetworkOptimizer>;
String _$resourceManagerHash() => r'af23b016dbe9eaeeffa7c444584bfcdd5c1d185e';

/// ResourceManager Provider
///
/// Copied from [resourceManager].
@ProviderFor(resourceManager)
final resourceManagerProvider =
    AutoDisposeFutureProvider<ResourceManager>.internal(
  resourceManager,
  name: r'resourceManagerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$resourceManagerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ResourceManagerRef = AutoDisposeFutureProviderRef<ResourceManager>;
String _$queueSizeManagerHash() => r'34c07b2d6442f0349fa82f83433bde5668247b51';

/// QueueSizeManager Provider
///
/// Copied from [queueSizeManager].
@ProviderFor(queueSizeManager)
final queueSizeManagerProvider =
    AutoDisposeFutureProvider<QueueSizeManager>.internal(
  queueSizeManager,
  name: r'queueSizeManagerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$queueSizeManagerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef QueueSizeManagerRef = AutoDisposeFutureProviderRef<QueueSizeManager>;
String _$taskCleanupSchedulerHash() =>
    r'102c6943fb32c4bf3587f5941440362d72414220';

/// TaskCleanupScheduler Provider
///
/// Copied from [taskCleanupScheduler].
@ProviderFor(taskCleanupScheduler)
final taskCleanupSchedulerProvider =
    AutoDisposeFutureProvider<TaskCleanupScheduler>.internal(
  taskCleanupScheduler,
  name: r'taskCleanupSchedulerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$taskCleanupSchedulerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TaskCleanupSchedulerRef
    = AutoDisposeFutureProviderRef<TaskCleanupScheduler>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
