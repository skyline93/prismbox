// lib/services/backup/upload_orchestrator.dart

import 'dart:async';
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/enums/asset_type.dart';
import 'package:prismbox/data/database/enums/upload_task_type.dart';
import 'package:prismbox/data/database/enums/upload_task_status.dart';
import 'package:prismbox/infrastructure/api/api_service.dart';
import 'package:prismbox/services/backup/models/live_photo_upload_metadata.dart';
import 'package:prismbox/services/backup/upload_task_state_machine.dart';
import 'package:prismbox/services/backup/upload_concurrency_controller.dart';
import 'package:prismbox/services/backup/upload_task_manager.dart';
import 'package:prismbox/services/backup/api_endpoint_validator.dart';
import 'package:prismbox/infrastructure/asset/asset_path_resolver.dart';
import 'package:prismbox/services/backup/file_metadata_extractor.dart';
import 'package:prismbox/services/backup/task_update_service.dart';
import 'package:prismbox/services/backup/error_handler.dart';
import 'package:prismbox/utils/cancellation_token.dart';
import 'package:prismbox/core/config/task_config.dart';

/// 上传结果
class UploadResult {
  final int successCount;
  final int failedCount;
  final List<UploadError> errors;
  final Map<String, String>? mediaUuids;

  UploadResult({
    required this.successCount,
    required this.failedCount,
    required this.errors,
    this.mediaUuids,
  });

  int get totalCount => successCount + failedCount;
  double get successRatio => totalCount > 0 ? successCount / totalCount : 0.0;
}

/// 上传错误
class UploadError {
  final String assetId;
  final String errorMessage;
  final ErrorType type;

  UploadError({
    required this.assetId,
    required this.errorMessage,
    required this.type,
  });
}

/// 错误类型
enum ErrorType {
  network, // 网络错误（可重试）
  authentication, // 认证错误（不可重试）
  server, // 服务器错误（5xx 可重试，4xx 不可重试）
  local, // 本地错误（文件不存在、权限不足等，不可重试）
  timeout, // 超时错误（可重试）
  cancelled, // 取消错误（不可重试）
}

/// 单任务执行结果（用于可扩展队列：返回派生任务与成功/失败）
class _SingleTaskResult {
  final List<UploadTaskEntityData> derived;
  final bool success;
  final UploadError? error;

  _SingleTaskResult({
    required this.derived,
    required this.success,
    this.error,
  });
}

/// 上传编排器：流程编排层
///
/// **职责边界明确**：
/// - ✅ **负责**：上传流程编排（去重、优先级、执行协调）
/// - ✅ **负责**：过滤已上传资产
/// - ❌ **不负责**：候选资源筛选（由 BackupCandidateSelector 负责）
/// - ❌ **不负责**：队列管理（由 UploadService 负责）
class UploadOrchestrator {
  final AppDatabase _database;
  final UploadTaskStateMachine _stateMachine;
  final ApiService _apiService;
  final UploadConcurrencyController _concurrencyController;
  final UploadTaskManager _uploadTaskManager;
  final ApiEndpointValidator _endpointValidator;
  final AssetPathResolver _pathResolver;
  final FileMetadataExtractor _metadataExtractor;
  final TaskUpdateService? _taskUpdateService; // 可选，用于更新任务信息
  final BackupErrorHandler _errorHandler; // 必需，用于统一错误处理
  final Logger _logger = Logger('UploadOrchestrator');

  // 上传端点配置
  static const String _uploadEndpoint = '/api/v1/media/upload-stream';

  /// 上传完成通知流控制器
  final _uploadCompleteController = StreamController<String>.broadcast();

  /// 上传完成通知流
  /// 当资产上传成功并更新数据库后，发出 assetId 通知
  /// 用于通知 UI 刷新上传状态图标
  Stream<String> get uploadCompleteStream => _uploadCompleteController.stream;

  UploadOrchestrator({
    required AppDatabase database,
    required UploadTaskStateMachine stateMachine,
    ApiService? apiService,
    UploadConcurrencyController? concurrencyController,
    UploadTaskManager? uploadTaskManager,
    ApiEndpointValidator? endpointValidator,
    required AssetPathResolver pathResolver,
    required FileMetadataExtractor metadataExtractor,
    required BackupErrorHandler errorHandler, // 必需，用于统一错误处理
    TaskUpdateService? taskUpdateService, // 可选，用于更新任务信息
  }) : _database = database,
       _stateMachine = stateMachine,
       _apiService = apiService ?? ApiService(),
       _concurrencyController =
           concurrencyController ?? UploadConcurrencyController(),
       _uploadTaskManager =
           uploadTaskManager ??
           UploadTaskManager(
             database: database,
             stateMachine: stateMachine,
             errorHandler: errorHandler, // 传递错误处理器
           ),
       _endpointValidator =
           endpointValidator ??
           ApiEndpointValidator(apiService: apiService ?? ApiService()),
       _pathResolver = pathResolver,
       _metadataExtractor = metadataExtractor,
       _errorHandler = errorHandler,
       _taskUpdateService = taskUpdateService;

  /// 过滤已上传资产（基于 isUploaded 字段）
  ///
  /// **参数**：
  /// - [userId] - 用户 ID（必须，保留用于未来扩展）
  /// - [candidates] - 候选任务列表
  /// - [skipDeduplication] - 是否跳过去重（手动备份可选）
  ///
  /// **返回**：过滤后的任务列表
  ///
  /// **去重策略**：
  /// 1. 查询本地资产表中 isUploaded = true 的资产
  /// 2. 过滤掉这些资产对应的任务
  Future<List<UploadTaskEntityData>> filterUploadedAssets({
    required String userId,
    required List<UploadTaskEntityData> candidates,
    bool skipDeduplication = false,
  }) async {
    if (skipDeduplication) {
      _logger.info('Skipping deduplication for userId=$userId');
      return candidates;
    }

    if (candidates.isEmpty) {
      return candidates;
    }

    _logger.info(
      'Filtering uploaded assets: userId=$userId, '
      'candidates=${candidates.length}',
    );

    // 1. 批量查询本地资产，获取已上传的资产 ID 集合
    final assetIds = candidates.map((task) => task.assetId).toList();
    final localDao = _database.localAssetDao;
    final localAssetsMap = await localDao.getAssetsByIds(assetIds);
    
    final uploadedAssetIds = <String>{};
    for (final entry in localAssetsMap.entries) {
      if (entry.value.isUploaded) {
        uploadedAssetIds.add(entry.key);
      }
    }

    // 2. 过滤掉已上传的资产，并将被去重的任务标记为 completed
    final filtered = <UploadTaskEntityData>[];
    final duplicateTasks = <UploadTaskEntityData>[];

    for (final task in candidates) {
      final isUploadedAsset = uploadedAssetIds.contains(task.assetId);

      if (!isUploadedAsset) {
        // 资产未标记为已上传，任务直接进入待执行列表
        filtered.add(task);
        continue;
      }

      // 资产已标记为 isUploaded=true，根据任务类型（尤其是 Live Photo）做细粒度判断
      final lpMeta = task.livePhotoMetadata;
      final isLivePhoto = lpMeta != null && lpMeta.isLivePhoto;
      final isLivePhotoImageTask =
          isLivePhoto && lpMeta.part == LivePhotoTaskPart.image;

      if (isLivePhotoImageTask) {
        // Live Photo 图片任务：即便资产整体被标记为已上传，
        // 仍允许图片任务执行一次，以修复潜在的不一致状态（例如之前只上传了视频）。
        filtered.add(task);
        _logger.fine(
          'Keeping Live Photo image task despite asset isUploaded=true: '
          'taskId=${task.id}, assetId=${task.assetId}',
        );
      } else {
        _logger.fine(
          'Skipping uploaded asset: assetId=${task.assetId}',
        );
        duplicateTasks.add(task);
      }
    }

    // 3. 将被去重的任务标记为 completed（因为它们已经上传）
    if (duplicateTasks.isNotEmpty) {
      _logger.info(
        'Marking ${duplicateTasks.length} duplicate tasks as completed',
      );
      // 通过状态机批量更新重复任务为已完成
      for (final task in duplicateTasks) {
        try {
          await _stateMachine.transition(task, UploadTaskStatus.completed);
          // 状态机内部已记录详细日志，这里记录额外的上下文信息
          final fileName = task.localPath.split('/').last;
          _logger.info(
            'Marked duplicate task as completed: '
            'taskId=${task.id}, '
            'assetId=${task.assetId}, '
            'filename=$fileName',
          );
        } catch (e) {
          final fileName = task.localPath.split('/').last;
          _logger.warning(
            'Failed to mark duplicate task as completed: '
            'taskId=${task.id}, '
            'assetId=${task.assetId}, '
            'filename=$fileName, '
            'error=$e',
          );
        }
      }
    }

    _logger.info(
      'Filtered ${filtered.length} assets '
      '(from ${candidates.length} candidates, ${duplicateTasks.length} duplicates)',
    );

    return filtered;
  }

  /// 编排上传流程
  ///
  /// **参数**：
  /// - [userId] - 用户 ID（必须）
  /// - [tasks] - 上传任务列表
  /// - [cancellationToken] - 取消令牌
  /// - [taskType] - 任务类型（用于决定是否更新 lastBackupTime）
  ///
  /// **返回**：UploadResult（上传结果）
  ///
  /// **执行流程**：
  /// 1. 按优先级排序任务
  /// 2. 可扩展队列 + 循环调度：每批最多 6 个并发，Live Photo 视频完成后派生图片任务并加入同一轮队列
  /// 3. 更新进度和状态
  /// 4. 处理错误和重试（指数退避策略）
  /// 5. 根据成功比例更新 lastBackupTime（仅自动备份）
  Future<UploadResult> orchestrateUpload({
    required String userId,
    required List<UploadTaskEntityData> tasks,
    required CancellationToken cancellationToken,
    required UploadTaskType taskType,
    void Function(int current, int total)? onProgress,
  }) async {
    if (tasks.isEmpty) {
      return UploadResult(successCount: 0, failedCount: 0, errors: []);
    }

    _logger.info(
      'Orchestrating upload: userId=$userId, tasks=${tasks.length}, '
      'taskType=$taskType',
    );

    // 1. 按优先级排序任务
    final sortedTasks = _sortTasksByPriority(tasks);

    // 2. 可扩展队列 + 循环调度：支持 Live Photo 视频完成后派生图片任务并在同一轮执行
    int successCount = 0;
    int failedCount = 0;
    final errors = <UploadError>[];
    final mediaUuids = <String, String>{};
    final queue = List<UploadTaskEntityData>.from(sortedTasks);

    _logger.info(
      'Starting upload orchestration: initialTasks=${queue.length}',
    );

    while (queue.isNotEmpty && !cancellationToken.isCancelled) {
      final batchSize = queue.length > 6 ? 6 : queue.length;
      final batch = queue.take(batchSize).toList();
      for (var i = 0; i < batchSize; i++) {
        queue.removeAt(0);
      }

      final results = await Future.wait(
        batch.map((task) async {
          _logger.fine('Waiting for concurrency slot: taskId=${task.id}');
          return _concurrencyController.execute(() async {
            final fileName = task.localPath.split('/').last;
            final taskLpMeta = task.livePhotoMetadata;
            _logger.info(
              'Acquired concurrency slot: taskId=${task.id}, '
              'assetId=${task.assetId}, filename=$fileName',
            );
            if (taskLpMeta != null) {
              _logger.info(
                '[LivePhoto] Orchestrator: task has livePhotoMetadata '
                'part=${taskLpMeta.part.name}, isLivePhoto=${taskLpMeta.isLivePhoto}, '
                'localAssetId=${taskLpMeta.localAssetId}',
              );
            }
            return _executeSingleTaskAndReturnDerived(task, cancellationToken);
          });
        }),
      );

      for (var i = 0; i < batch.length; i++) {
        final task = batch[i];
        final result = results[i];
        if (result.success) {
          successCount++;
          queue.addAll(result.derived);
          try {
            final completedTask =
                await _database.uploadTaskDao.getTaskById(task.id);
            if (completedTask?.status == UploadTaskStatus.completed) {
              final uuid = completedTask!.mediaUuid;
              if (uuid != null && uuid.isNotEmpty) {
                mediaUuids[task.id] = uuid;
              }
            }
          } catch (e) {
            _logger.warning(
              'Failed to read media UUID for task: taskId=${task.id}, error=$e',
            );
          }
          final fileName = task.localPath.split('/').last;
          _logger.info(
            'Upload completed successfully: '
            'taskId=${task.id}, assetId=${task.assetId}, filename=$fileName',
          );
        } else {
          failedCount++;
          if (result.error != null) {
            errors.add(result.error!);
          }
        }
      }

      final completed = successCount + failedCount;
      final total = completed + queue.length;
      onProgress?.call(completed, total);
      _logger.fine(
        'Batch finished: completed=$completed, remaining=${queue.length}',
      );
    }

    if (cancellationToken.isCancelled) {
      _logger.warning('Upload cancelled during orchestration');
    }

    _logger.info(
      'Upload orchestration finished: success=$successCount, failed=$failedCount',
    );

    // 3. 根据成功比例更新 lastBackupTime（仅自动备份）
    final totalRan = successCount + failedCount;
    if (taskType == UploadTaskType.auto && totalRan > 0) {
      await _updateLastBackupTime(
        userId: userId,
        successCount: successCount,
        totalCount: totalRan,
      );
    }

    final result = UploadResult(
      successCount: successCount,
      failedCount: failedCount,
      errors: errors,
      mediaUuids: mediaUuids.isNotEmpty ? mediaUuids : null,
    );

    _logger.info(
      'Upload orchestration completed: userId=$userId, '
      'success=$successCount, failed=$failedCount, '
      'mediaUuidsCount=${mediaUuids.length}',
    );

    return result;
  }


  /// 在编排层为 Live Photo 视频任务完成后创建并插入对应的图片上传任务，
  /// 供同一轮队列调度。返回新创建的图片任务（供加入队列），失败或无需创建时返回 null。
  ///
  /// 归属编排器以便派生任务能在同一轮备份中被调度。
  Future<UploadTaskEntityData?> _createLivePhotoImageTaskForOrchestration({
    required UploadTaskEntityData completedTask,
    required LivePhotoUploadMetadata metadata,
  }) async {
    final imageLocalAssetId = metadata.localAssetId;
    final remoteVideoId = completedTask.mediaUuid;

    if (remoteVideoId == null || remoteVideoId.isEmpty) {
      _logger.warning(
        'Live Photo video completed but mediaUuid is missing, '
        'skip creating image task: videoTaskId=${completedTask.id}, '
        'imageAssetId=$imageLocalAssetId',
      );
      return null;
    }

    try {
      final imageAsset = await _database.localAssetDao.getAssetById(
        imageLocalAssetId,
      );
      if (imageAsset == null) {
        _logger.warning(
          'Live Photo image asset not found, skip creating image task: '
          'imageAssetId=$imageLocalAssetId, videoTaskId=${completedTask.id}',
        );
        return null;
      }

      final imageTaskId =
          'auto_livephoto_image_${imageLocalAssetId}_${DateTime.now().millisecondsSinceEpoch}';

      final imageTask = UploadTaskEntityData(
        id: imageTaskId,
        userId: completedTask.userId,
        assetId: imageLocalAssetId,
        localPath: imageAsset.path,
        remotePath: completedTask.remotePath,
        mediaUuid: null,
        fileSize: completedTask.fileSize,
        taskType: completedTask.taskType,
        priority: (completedTask.priority > 1)
            ? completedTask.priority - 1
            : completedTask.priority,
        status: UploadTaskStatus.pending,
        retryCount: 0,
        maxRetries: completedTask.maxRetries,
        errorMessage: null,
        uploadedAt: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        progress: 0,
        livePhotoMetadataJson: LivePhotoUploadMetadata(
          localAssetId: imageLocalAssetId,
          isLivePhoto: true,
          part: LivePhotoTaskPart.image,
          remoteVideoId: remoteVideoId,
        ).toJsonString(),
      );

      await _database.uploadTaskDao.insertTask(imageTask);

      _logger.info(
        '[LivePhoto] Orchestrator: created derived image task: '
        'videoTaskId=${completedTask.id}, imageTaskId=$imageTaskId, '
        'imageAssetId=$imageLocalAssetId, remoteVideoId=$remoteVideoId',
      );
      return imageTask;
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to create Live Photo image task in orchestrator: '
        'videoTaskId=${completedTask.id}, imageAssetId=$imageLocalAssetId, '
        'error=$e',
        e,
        stackTrace,
      );
      return null;
    }
  }

  /// 执行单个上传任务，并在 Live Photo 视频任务成功时同步创建派生图片任务。
  /// 返回 [_SingleTaskResult]：成功时可能带 derived 列表，失败时带 error。
  /// 用于可扩展队列：主循环可将 derived 加入队列在同一轮中调度。
  Future<_SingleTaskResult> _executeSingleTaskAndReturnDerived(
    UploadTaskEntityData task,
    CancellationToken cancellationToken,
  ) async {
    if (cancellationToken.isCancelled) {
      return _SingleTaskResult(
        derived: [],
        success: false,
        error: UploadError(
          assetId: task.assetId,
          errorMessage: 'Upload cancelled',
          type: ErrorType.cancelled,
        ),
      );
    }

    try {
      await _executeUploadWithRetry(task);

      final completedTask =
          await _database.uploadTaskDao.getTaskById(task.id);
      if (completedTask?.status != UploadTaskStatus.completed) {
        return _SingleTaskResult(derived: [], success: true);
      }

      final metadata = completedTask!.livePhotoMetadata;
      final bool isLpVideoComplete = metadata != null &&
          metadata.isLivePhoto &&
          metadata.part == LivePhotoTaskPart.video &&
          (completedTask.mediaUuid ?? '').isNotEmpty;

      if (!isLpVideoComplete) {
        return _SingleTaskResult(derived: [], success: true);
      }

      final derivedTask = await _createLivePhotoImageTaskForOrchestration(
        completedTask: completedTask,
        metadata: metadata,
      );
      final derived =
          derivedTask != null ? [derivedTask] : <UploadTaskEntityData>[];

      return _SingleTaskResult(derived: derived, success: true);
    } catch (e, stackTrace) {
      final fileName = task.localPath.split('/').last;
      _logger.warning(
        'Upload error in single-task execution: '
        'taskId=${task.id}, assetId=${task.assetId}, filename=$fileName, error=$e',
        e,
        stackTrace,
      );

      final backupError = _errorHandler.handleError(
        e,
        context: 'upload_orchestration',
      );

      await _errorHandler.handleUploadError(backupError, task);

      try {
        final currentTask = await _database.uploadTaskDao.getTaskById(task.id);
        if (currentTask != null) {
          final isFinalStatus =
              currentTask.status == UploadTaskStatus.failed ||
              currentTask.status == UploadTaskStatus.permanentlyFailed ||
              currentTask.status == UploadTaskStatus.cancelled;

          if (!isFinalStatus) {
            final newStatus = backupError.isRetryable
                ? (currentTask.retryCount >= task.maxRetries
                    ? UploadTaskStatus.permanentlyFailed
                    : UploadTaskStatus.failed)
                : UploadTaskStatus.permanentlyFailed;

            await _stateMachine.transition(
              currentTask,
              newStatus,
              errorMessage: backupError.message,
            );
          }
        }
      } catch (stateError, stateStackTrace) {
        _logger.warning(
          'Failed to update task status after error: '
          'taskId=${task.id}, error=$stateError',
          stateError,
          stateStackTrace,
        );
      }

      return _SingleTaskResult(
        derived: [],
        success: false,
        error: UploadError(
          assetId: task.assetId,
          errorMessage: backupError.message,
          type: _mapBackupErrorTypeToErrorType(backupError.type),
        ),
      );
    }
  }

  /// 按优先级排序任务
  List<UploadTaskEntityData> _sortTasksByPriority(
    List<UploadTaskEntityData> tasks,
  ) {
    // 优先级排序规则：
    // 1. 任务类型优先：手动备份优先于自动备份
    // 2. Live Photo 图片任务优先于其他任务
    // 3. 优先级字段：数字越小优先级越高
    // 4. 文件大小：小文件优先（可选）
    // 5. 创建时间：早创建的任务优先

    final sorted = List<UploadTaskEntityData>.from(tasks);
    sorted.sort((a, b) {
      // 1. 任务类型优先
      if (a.taskType != b.taskType) {
        return a.taskType == UploadTaskType.manual ? -1 : 1;
      }

      // 2. Live Photo 图片任务优先
      final aMeta = a.livePhotoMetadata;
      final bMeta = b.livePhotoMetadata;
      final aIsLivePhotoImage =
          aMeta != null && aMeta.isLivePhoto && aMeta.part == LivePhotoTaskPart.image;
      final bIsLivePhotoImage =
          bMeta != null && bMeta.isLivePhoto && bMeta.part == LivePhotoTaskPart.image;

      if (aIsLivePhotoImage != bIsLivePhotoImage) {
        // true 优先
        return aIsLivePhotoImage ? -1 : 1;
      }

      // 3. 优先级字段
      final priorityDiff = a.priority.compareTo(b.priority);
      if (priorityDiff != 0) {
        return priorityDiff;
      }

      // 4. 文件大小（小文件优先）
      final sizeDiff = a.fileSize.compareTo(b.fileSize);
      if (sizeDiff != 0) {
        return sizeDiff;
      }

      // 5. 创建时间
      return a.createdAt.compareTo(b.createdAt);
    });

    return sorted;
  }

  /// 当本次上传为 Live Photo 图片任务且任务元数据中已有远程视频 UUID 时，
  /// 向 [fields] 写入 [live_photo_video_id]，供上传请求携带。
  /// 用于后台上传派生任务及前台上传成对逻辑，确保服务端能建立图片→视频关联。
  /// 对测试可见，便于单测覆盖。
  static void applyLivePhotoVideoIdToFields(
    UploadTaskEntityData task,
    bool isImageAsset,
    Map<String, String> fields,
  ) {
    final lpMeta = task.livePhotoMetadata;
    if (!isImageAsset ||
        lpMeta == null ||
        !lpMeta.isLivePhoto ||
        lpMeta.part != LivePhotoTaskPart.image ||
        lpMeta.remoteVideoId == null ||
        lpMeta.remoteVideoId!.isEmpty) {
      return;
    }
    fields['live_photo_video_id'] = lpMeta.remoteVideoId!;
  }

  /// 执行上传（带自动重试）
  ///
  /// **实现说明**：
  /// - 使用指数退避策略自动重试
  /// - 最大重试次数：3 次
  /// - 重试间隔：1秒、2秒、4秒
  ///
  /// **重试策略**：
  /// - 可重试错误：网络错误、超时错误、5xx 服务器错误
  /// - 不可重试错误：认证错误、4xx 客户端错误、本地文件错误
  Future<void> _executeUploadWithRetry(UploadTaskEntityData task) async {
    int retryCount = 0;
    const maxRetries = 3;
    const baseDelay = Duration(seconds: 1);

    while (retryCount <= maxRetries) {
      try {
        await _executeUpload(task);
        // 上传成功，清除重试计数（如果之前有重试）
        if (retryCount > 0) {
          // 注意：重试计数不需要重置，因为任务已成功完成
          // 状态机已经处理了状态转换，不需要额外的更新
        }
        return;
      } catch (e) {
        // 使用统一的错误处理器
        final backupError = _errorHandler.handleError(
          e,
          context: 'upload_with_retry',
        );

        // 判断是否可重试
        final isRetryable = backupError.isRetryable;

        if (!isRetryable || retryCount >= maxRetries) {
          // 不可重试或达到最大重试次数，增加重试计数并抛出异常
          if (retryCount < maxRetries) {
            // 优先使用 TaskUpdateService，如果没有则直接操作数据库（降级处理）
            if (_taskUpdateService != null) {
              await _taskUpdateService.incrementRetryCount(task.id);
            } else {
              // 降级处理：直接操作数据库（避免循环依赖）
              await _database.uploadTaskDao.incrementRetryCount(task.id);
            }
          }
          rethrow;
        }

        // 可重试，等待后重试
        retryCount++;
        final delay = Duration(
          milliseconds: baseDelay.inMilliseconds * (1 << (retryCount - 1)),
        ); // 指数退避：1秒、2秒、4秒

        _logger.info(
          'Upload failed, retrying: taskId=${task.id}, '
          'attempt=$retryCount/$maxRetries, delay=${delay.inSeconds}s, '
          'errorType=${backupError.type}, isRetryable=$isRetryable',
        );

        // 增加重试计数
        // 优先使用 TaskUpdateService，如果没有则直接操作数据库（降级处理）
        if (_taskUpdateService != null) {
          await _taskUpdateService.incrementRetryCount(task.id);
        } else {
          // 降级处理：直接操作数据库（避免循环依赖）
          await _database.uploadTaskDao.incrementRetryCount(task.id);
        }

        // 等待后重试
        await Future.delayed(delay);
      }
    }

    // 理论上不会到达这里
    throw Exception('Max retries exceeded for taskId=${task.id}');
  }

  /// 执行上传（使用 background_downloader）
  ///
  /// **实现说明**：
  /// - 使用 background_downloader 实现上传逻辑
  /// - 支持后台运行、断点续传
  ///
  /// **上传流程**：
  /// 1. 检查文件是否存在
  /// 2. 读取文件并计算 checksum（如果未计算）
  /// 3. 验证上传端点
  /// 4. 创建 UploadTask 并入队
  /// 5. 等待任务完成
  Future<void> _executeUpload(UploadTaskEntityData task) async {
    _logger.info(
      'Executing upload: taskId=${task.id}, assetId=${task.assetId}',
    );

    try {
      // 1. 确定实际上传的资产与路径（Live Photo 视频任务上传视频文件，其余按 task.assetId）
      final LocalAssetEntityData assetForUpload;
      final String actualPath;

      final lpMeta = task.livePhotoMetadata;
      _logger.info(
        '[LivePhoto] _executeUpload: taskId=${task.id}, '
        'livePhotoMetadataJson=${task.livePhotoMetadataJson == null || task.livePhotoMetadataJson!.isEmpty ? "null_or_empty" : "present(len=${task.livePhotoMetadataJson!.length})"}, '
        'parsed part=${lpMeta?.part.name ?? "null"}, isLivePhoto=${lpMeta?.isLivePhoto ?? false}',
      );

      if (lpMeta != null &&
          lpMeta.isLivePhoto &&
          lpMeta.part == LivePhotoTaskPart.video) {
        _logger.info(
          '[LivePhoto] _executeUpload: using VIDEO branch (Live Photo video task)',
        );
        // Live Photo 视频任务：主图与视频由同一 AssetEntity 提供，用主图资产 + 子类型接口取视频路径
        final imageAsset = await _database.localAssetDao.getAssetById(
          task.assetId,
        );
        if (imageAsset == null) {
          throw Exception(
            'Live Photo image asset not found: ${task.assetId}',
          );
        }
        final resolvedVideoPath =
            await _pathResolver.resolveLivePhotoVideoPath(imageAsset);
        if (resolvedVideoPath == null || resolvedVideoPath.isEmpty) {
          throw FileSystemException(
            'Live Photo video file not found for asset: ${task.assetId}',
            task.localPath,
          );
        }
        actualPath = resolvedVideoPath;
        assetForUpload = imageAsset;
        _logger.info(
          '[LivePhoto] _executeUpload: VIDEO branch resolved (same AssetEntity), '
          'actualPathTail=${actualPath.split("/").last}, assetForUpload.type=${assetForUpload.type.name}',
        );
      } else {
        _logger.info(
          '[LivePhoto] _executeUpload: using NON-VIDEO branch '
          '(image task or non-LivePhoto), assetId=${task.assetId}',
        );
        final localAsset = await _database.localAssetDao.getAssetById(
          task.assetId,
        );
        if (localAsset == null) {
          throw Exception('Local asset not found: ${task.assetId}');
        }
        final resolved =
            await _pathResolver.resolveAssetPath(localAsset);
        if (resolved == null || resolved.isEmpty) {
          throw FileSystemException('File not found', task.localPath);
        }
        actualPath = resolved;
        assetForUpload = localAsset;
        _logger.info(
          '[LivePhoto] _executeUpload: NON-VIDEO branch resolved, '
          'actualPathTail=${actualPath.split("/").last}, '
          'assetForUpload.type=${assetForUpload.type.name}',
        );
      }

      // 3. 更新任务中的文件路径（如果路径已改变）
      // 优先使用 TaskUpdateService，如果没有则直接操作数据库（降级处理）
      if (actualPath != task.localPath) {
        if (_taskUpdateService != null) {
          await _taskUpdateService.updateTaskLocalPath(
            taskId: task.id,
            localPath: actualPath,
          );
        } else {
          // 降级处理：直接操作数据库（避免循环依赖）
          await _database.uploadTaskDao.updateTaskLocalPath(
            task.id,
            actualPath,
          );
        }
      }

      // 4. 使用 FileMetadataExtractor 获取文件大小（如果未设置）
      int fileSize = task.fileSize;
      if (fileSize == 0) {
        fileSize = await _metadataExtractor.extractFileSize(actualPath);
      }

      // 5. 验证上传端点（可选，用于提前发现问题）
      final endpointValidation = await _endpointValidator
          .validateUploadEndpoint();
      if (!endpointValidation.isValid) {
        _logger.warning(
          'Upload endpoint validation failed: ${endpointValidation.error}',
        );
        // 继续尝试上传，因为验证可能失败但实际上传可能成功
      }

      // 6. 获取上传端点
      final endpoint = _apiService.endpoint ?? '';
      final uploadUrl = '$endpoint$_uploadEndpoint';

      // 7. 获取请求头（包含认证信息和设备信息）
      final headers = await ApiService.getRequestHeaders();

      // 8. 构建表单字段（后端 API 要求的格式，使用 assetForUpload 以支持 Live Photo 视频任务）
      // Live Photo 视频任务时 assetForUpload 为主图资产，需显式传 item_type=video
      String itemType;
      if (lpMeta != null &&
          lpMeta.isLivePhoto &&
          lpMeta.part == LivePhotoTaskPart.video) {
        itemType = 'video';
      } else {
        switch (assetForUpload.type) {
          case AssetType.image:
            itemType = 'image';
            break;
          case AssetType.video:
            itemType = 'video';
            break;
          default:
            itemType = 'image';
            _logger.warning(
              'Unknown asset type: ${assetForUpload.type}, defaulting to image',
            );
        }
      }

      const uuid = Uuid();
      final cloudUuid = uuid.v4();
      final mediaTakenAt =
          assetForUpload.createdAt.toUtc().toIso8601String();

      final fields = <String, String>{
        'item_type': itemType,
        'cloud_uuid': cloudUuid,
        'original_filename': assetForUpload.name,
        'media_taken_at': mediaTakenAt,
      };

      applyLivePhotoVideoIdToFields(
        task,
        assetForUpload.type == AssetType.image,
        fields,
      );
      _logger.info(
        '[LivePhoto] _executeUpload: request built: item_type=$itemType, '
        'has_live_photo_video_id=${fields.containsKey("live_photo_video_id")}, '
        'original_filename=${assetForUpload.name}',
      );
      if (fields.containsKey('live_photo_video_id')) {
        _logger.fine(
          'Live Photo image upload: attaching live_photo_video_id for assetId=${assetForUpload.id}',
        );
      }

      // 9. 确定任务组
      final group = task.taskType == UploadTaskType.manual
          ? UploadTaskGroup.manual
          : UploadTaskGroup.auto;

      // 10. 创建上传任务（使用实际路径）
      final uploadTask = _uploadTaskManager.createUploadTask(
        taskId: task.id,
        filePath: actualPath, // 使用实际获取到的路径
        url: uploadUrl,
        headers: headers,
        fields: fields,
        group: group,
      );

      // 11. 入队任务
      final enqueued = await _uploadTaskManager.enqueueTask(uploadTask);
      if (!enqueued) {
        throw Exception('Failed to enqueue upload task');
      }

      _logger.info('Upload task enqueued: taskId=${task.id}');

      // 12. 等待任务完成（通过轮询数据库状态）
      // 注意：background_downloader 会在后台执行任务，状态更新通过回调处理
      // 我们需要等待任务真正完成，而不是只等待入队
      await _waitForTaskCompletion(task.id);
    } catch (e, stackTrace) {
      // 使用统一的错误处理器
      final backupError = _errorHandler.handleError(
        e,
        context: 'execute_upload',
      );

      _logger.warning(
        'Upload failed: taskId=${task.id}, '
        'errorType=${backupError.type}, errorMessage=${backupError.message}',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// 等待任务完成（通过轮询数据库状态）
  ///
  /// **参数**：
  /// - [taskId] - 任务 ID
  ///
  /// **实现说明**：
  /// - 轮询数据库中的任务状态
  /// - 当状态变为 completed、failed 或 permanentlyFailed 时返回
  /// - 设置超时机制（默认 10 分钟），避免无限等待
  /// - 如果任务失败，抛出异常
  Future<void> _waitForTaskCompletion(String taskId) async {
    final pollInterval = TaskConfig.pollInterval;
    final timeout = TaskConfig.taskCompletionTimeout;
    final startTime = DateTime.now();
    int pollCount = 0;

    _logger.fine('Waiting for task completion: taskId=$taskId');

    while (true) {
      // 检查超时
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed > timeout) {
        _logger.warning(
          'Task completion timeout: taskId=$taskId, '
          'elapsed=${elapsed.inSeconds}s',
        );
        throw TimeoutException(
          'Upload task timeout after ${timeout.inMinutes} minutes',
          timeout,
        );
      }

      // 查询任务状态
      final task = await _database.uploadTaskDao.getTaskById(taskId);
      if (task == null) {
        _logger.warning('Task not found: taskId=$taskId');
        throw Exception('Task not found: $taskId');
      }

      pollCount++;
      if (pollCount % 10 == 0) {
        // 每10次轮询记录一次日志
        _logger.fine(
          'Task still in progress: taskId=$taskId, '
          'status=${task.status}, elapsed=${elapsed.inSeconds}s',
        );
      }

      // 检查任务状态
      switch (task.status) {
        case UploadTaskStatus.completed:
          _logger.fine(
            'Task completed: taskId=$taskId, '
            'elapsed=${elapsed.inSeconds}s, polls=$pollCount',
          );
          
          // 等待 UUID 存储完成（最多等待 1 秒，每次 100ms）
          String? mediaUuid = task.mediaUuid;
          if (mediaUuid == null || mediaUuid.isEmpty) {
            _logger.fine(
              'Media UUID not yet stored, waiting for it: taskId=$taskId',
            );
            const maxRetries = 10;
            const retryInterval = Duration(milliseconds: 100);
            
            for (int i = 0; i < maxRetries; i++) {
              await Future.delayed(retryInterval);
              final updatedTask = await _database.uploadTaskDao.getTaskById(taskId);
              if (updatedTask != null) {
                mediaUuid = updatedTask.mediaUuid;
                if (mediaUuid != null && mediaUuid.isNotEmpty) {
                  _logger.fine(
                    'Media UUID found after waiting: taskId=$taskId, '
                    'attempt=${i + 1}/$maxRetries, mediaUuid=$mediaUuid',
                  );
                  break;
                }
              }
            }
            
            if (mediaUuid == null || mediaUuid.isEmpty) {
              _logger.warning(
                'Media UUID not available after waiting: taskId=$taskId, '
                'elapsed=${elapsed.inSeconds}s',
              );
              throw Exception(
                'Media UUID not available for completed task: $taskId',
              );
            }
          }
          
          // 任务成功完成，视任务类型决定是否更新本地资产的 isUploaded = true
          // 语义约定：
          // - 非 Live Photo 任务：单一媒体文件，完成即视为已上传
          // - Live Photo 视频任务：仅完成视频部分，不更新 isUploaded
          // - Live Photo 图片任务：在已有关联远程视频 UUID 时，视为整套 Live Photo 完成，更新 isUploaded
          final effectiveAssetId = task.assetId;
          final lpMeta = task.livePhotoMetadata;
          var shouldMarkUploaded = false;

          if (lpMeta == null || !lpMeta.isLivePhoto) {
            // 普通资产，完成即视为已上传
            shouldMarkUploaded = true;
          } else {
            switch (lpMeta.part) {
              case LivePhotoTaskPart.video:
                // 仅完成 Live Photo 视频，不标记整体已上传
                shouldMarkUploaded = false;
                break;
              case LivePhotoTaskPart.image:
                // 图片任务完成，通常意味着整套 Live Photo 已经可用
                // 若需要更严格判断，可在此检查是否已有 remoteVideoId
                shouldMarkUploaded = true;
                break;
            }
          }

          if (shouldMarkUploaded) {
            await _updateLocalAssetUploadedStatus(effectiveAssetId, true);
            _logger.info(
              'Task completed: assetId=$effectiveAssetId, '
              'isUploaded updated to true',
            );
            _uploadCompleteController.add(effectiveAssetId);
          } else {
            _logger.info(
              'Task completed without marking isUploaded: '
              'taskId=$taskId, assetId=$effectiveAssetId',
            );
            _uploadCompleteController.add(effectiveAssetId);
          }

          return; // 任务成功完成

        case UploadTaskStatus.failed:
        case UploadTaskStatus.permanentlyFailed:
          _logger.warning(
            'Task failed: taskId=$taskId, status=${task.status}, '
            'error=${task.errorMessage}, elapsed=${elapsed.inSeconds}s',
          );
          throw Exception(
            'Upload task failed: ${task.errorMessage ?? "Unknown error"}',
          );

        case UploadTaskStatus.cancelled:
          _logger.warning(
            'Task cancelled: taskId=$taskId, elapsed=${elapsed.inSeconds}s',
          );
          throw Exception('Upload task cancelled');

        case UploadTaskStatus.pending:
        case UploadTaskStatus.queued:
        case UploadTaskStatus.uploading:
        case UploadTaskStatus.paused:
          // 任务还在进行中，继续等待
          await Future.delayed(pollInterval);
          break;
      }
    }
  }

  /// 更新本地资产的上传状态
  /// 
  /// **参数**：
  /// - [assetId] - 本地资产 ID
  /// - [isUploaded] - 是否已上传
  /// 
  /// **注意**：此方法需要数据库代码生成后才能使用 isUploaded 字段
  Future<void> _updateLocalAssetUploadedStatus(
    String assetId,
    bool isUploaded,
  ) async {
    try {
      final localDao = _database.localAssetDao;
      final localAsset = await localDao.getAssetById(assetId);
      if (localAsset == null) {
        _logger.warning(
          'Local asset not found: assetId=$assetId, '
          'cannot update isUploaded status',
        );
        return;
      }

      // 如果状态已经是目标状态，跳过更新
      if (localAsset.isUploaded == isUploaded) {
        return;
      }

      // 更新资产的上传状态
      final updatedAsset = localAsset.copyWith(
        isUploaded: isUploaded,
        updatedAt: DateTime.now(),
      );
      await localDao.updateAsset(updatedAsset);

      _logger.info(
        'Updated local asset isUploaded status: '
        'assetId=$assetId, isUploaded=$isUploaded',
      );
    } catch (e, stackTrace) {
      // 记录错误但不阻塞上传流程
      _logger.warning(
        'Failed to update local asset isUploaded status: '
        'assetId=$assetId, error=$e',
        e,
        stackTrace,
      );
    }
  }

  /// 映射 BackupErrorType 到 ErrorType（用于返回 UploadError）
  ErrorType _mapBackupErrorTypeToErrorType(BackupErrorType type) {
    switch (type) {
      case BackupErrorType.network:
        return ErrorType.network;
      case BackupErrorType.authentication:
        return ErrorType.authentication;
      case BackupErrorType.server:
        return ErrorType.server;
      case BackupErrorType.local:
      case BackupErrorType.fileNotFound:
        return ErrorType.local;
      case BackupErrorType.timeout:
        return ErrorType.timeout;
      case BackupErrorType.cancelled:
        return ErrorType.cancelled;
      default:
        return ErrorType.local;
    }
  }

  /// 更新最后备份时间（根据成功比例决定是否更新）
  ///
  /// **更新策略**：
  /// - 全部成功：立即更新
  /// - 部分成功且成功比例 ≥ 80%：更新（避免少量失败阻塞增量同步）
  /// - 部分成功且成功比例 < 80%：不更新（避免跳过大量失败任务）
  /// - 全部失败：不更新
  ///
  /// **注意**：此方法仅由自动备份调用，手动备份不更新 lastBackupTime
  Future<void> _updateLastBackupTime({
    required String userId,
    required int successCount,
    required int totalCount,
  }) async {
    if (totalCount == 0) {
      return; // 没有任务，不更新
    }

    // 计算成功比例
    final successRatio = successCount / totalCount;

    // 更新策略
    if (successCount == totalCount || successRatio >= 0.8) {
      final dao = _database.backupStatusDao;
      await dao.updateLastBackupTime(userId, DateTime.now());
      _logger.info(
        'Updated lastBackupTime for userId=$userId, '
        'successRatio=$successRatio',
      );
    } else {
      _logger.info(
        'Skipping lastBackupTime update for userId=$userId, '
        'successRatio=$successRatio',
      );
    }
  }
}
