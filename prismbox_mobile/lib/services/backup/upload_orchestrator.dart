// lib/services/backup/upload_orchestrator.dart

import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/enums/asset_type.dart';
import 'package:prismbox/data/database/enums/upload_task_type.dart';
import 'package:prismbox/data/database/enums/upload_task_status.dart';
import 'package:prismbox/infrastructure/api/api_service.dart';
import 'package:prismbox/services/backup/upload_task_state_machine.dart';
import 'package:prismbox/services/backup/upload_concurrency_controller.dart';
import 'package:prismbox/services/backup/upload_task_manager.dart';
import 'package:prismbox/services/backup/api_endpoint_validator.dart';
import 'package:prismbox/infrastructure/asset/asset_path_resolver.dart';
import 'package:prismbox/services/backup/file_metadata_extractor.dart';
import 'package:prismbox/infrastructure/asset/checksum_service.dart';
import 'package:prismbox/services/backup/task_update_service.dart';
import 'package:prismbox/services/backup/error_handler.dart';
import 'package:prismbox/utils/cancellation_token.dart';
import 'package:prismbox/core/config/task_config.dart';

/// 上传结果
class UploadResult {
  final int successCount;
  final int failedCount;
  final List<UploadError> errors;

  UploadResult({
    required this.successCount,
    required this.failedCount,
    required this.errors,
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
  final ChecksumService _checksumService;
  final TaskUpdateService? _taskUpdateService; // 可选，用于更新任务信息
  final BackupErrorHandler _errorHandler; // 必需，用于统一错误处理
  final Logger _logger = Logger('UploadOrchestrator');

  // 去重检查配置
  static const int _batchSize = 100; // 每批最多检查 100 个
  static const Duration _timeout = Duration(seconds: 30); // 超时时间

  // 上传端点配置
  static const String _uploadEndpoint = '/api/v1/media/upload-stream';
  static const String _checkAssetsEndpoint = '/api/v1/media/check_hashes';

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
    required ChecksumService checksumService,
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
       _checksumService = checksumService,
       _errorHandler = errorHandler,
       _taskUpdateService = taskUpdateService;

  /// 过滤已上传资产（支持分批检查和降级策略）
  ///
  /// **参数**：
  /// - [userId] - 用户 ID（必须）
  /// - [candidates] - 候选任务列表
  /// - [skipDeduplication] - 是否跳过去重（手动备份可选）
  ///
  /// **返回**：过滤后的任务列表
  ///
  /// **去重策略**：
  /// 1. 优先检查本地数据库（remote_asset_entity）
  /// 2. 检查服务器（分批检查，支持超时和降级）
  /// 3. 过滤掉已存在的资产
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

    // 1. 获取所有候选任务的 checksum
    final checksums = await _calculateChecksums(candidates);

    // 2. 批量检查已存在资产
    final existingChecksums = await _checkExistingAssets(
      userId: userId,
      checksums: checksums,
    );

    // 3. 过滤掉已存在的资产，并将被去重的任务标记为 completed
    final filtered = <UploadTaskEntityData>[];
    final duplicateTasks = <UploadTaskEntityData>[];
    // 创建任务到 checksum 的映射，用于后续日志记录
    final taskChecksumMap = <String, String?>{};

    for (int i = 0; i < candidates.length; i++) {
      final task = candidates[i];
      final checksum = checksums[i];
      taskChecksumMap[task.id] = checksum;

      if (!existingChecksums.contains(checksum)) {
        filtered.add(task);
      } else {
        _logger.fine(
          'Skipping duplicate asset: assetId=${task.assetId}, '
          'checksum=$checksum',
        );
        duplicateTasks.add(task);
      }
    }

    // 4. 将被去重的任务标记为 completed（因为它们已经存在于服务器上）
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
          final checksum = taskChecksumMap[task.id];
          _logger.info(
            'Marked duplicate task as completed: '
            'taskId=${task.id}, '
            'assetId=${task.assetId}, '
            'filename=$fileName, '
            'checksum=$checksum',
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
  /// 2. 并发执行上传任务（最大 6 个并发）
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

    // 2. 并发执行上传（最大 6 个并发）
    int successCount = 0;
    int failedCount = 0;
    final errors = <UploadError>[];
    final completedCount = <int>[0]; // 使用列表包装以便在闭包中修改

    _logger.info(
      'Starting upload orchestration: totalTasks=${sortedTasks.length}',
    );

    // 使用并发控制器执行上传任务
    await Future.wait(
      sortedTasks.map((task) async {
        if (cancellationToken.isCancelled) {
          _logger.warning('Upload cancelled, skipping task: taskId=${task.id}');
          return;
        }

        _logger.fine('Waiting for concurrency slot: taskId=${task.id}');

        // 使用并发控制器控制并发数
        await _concurrencyController.execute(() async {
          final fileName = task.localPath.split('/').last;
          _logger.info(
            'Acquired concurrency slot: taskId=${task.id}, '
            'assetId=${task.assetId}, filename=$fileName',
          );
          try {
            // 执行上传（带自动重试）
            // 注意：
            // 1. 状态更新由 background_downloader 的状态回调驱动（单一数据源原则）
            // 2. background_downloader 会依次报告：enqueued -> running -> complete
            // 3. UploadTaskManager 的回调会将它们映射为：queued -> uploading -> completed
            // 4. 不在入队前提前更新状态，避免状态冲突
            await _executeUploadWithRetry(task);

            // 验证任务状态（应该已经被 UploadTaskManager 更新为 completed）
            final completedTask = await _database.uploadTaskDao.getTaskById(
              task.id,
            );
            if (completedTask?.status != UploadTaskStatus.completed) {
              final fileName = task.localPath.split('/').last;
              _logger.warning(
                'Task status mismatch after completion: '
                'taskId=${task.id}, '
                'assetId=${task.assetId}, '
                'filename=$fileName, '
                'expected=completed, actual=${completedTask?.status}',
              );
            }

            successCount++;
            final fileName = task.localPath.split('/').last;
            _logger.info(
              'Upload completed successfully: '
              'taskId=${task.id}, '
              'assetId=${task.assetId}, '
              'filename=$fileName',
            );
          } catch (e, stackTrace) {
            final fileName = task.localPath.split('/').last;
            _logger.warning(
              'Upload error in orchestration: '
              'taskId=${task.id}, '
              'assetId=${task.assetId}, '
              'filename=$fileName, '
              'error=$e',
            );
            _logger.warning(
              'Upload failed: taskId=${task.id}, assetId=${task.assetId}, filename=$fileName, error=$e',
              e,
              stackTrace,
            );

            // 使用统一的错误处理器
            final backupError = _errorHandler.handleError(
              e,
              context: 'upload_orchestration',
            );

            // 处理上传错误
            await _errorHandler.handleUploadError(backupError, task);

            // 获取当前任务状态（UploadTaskManager 的回调可能已经更新了状态）
            // 注意：正常情况下，background_downloader 会通过回调更新状态
            // 但如果异常发生在入队之前，或者回调未触发，需要手动更新状态
            try {
              final currentTask = await _database.uploadTaskDao.getTaskById(
                task.id,
              );
              if (currentTask != null) {
                // 如果状态已经是最终状态（failed、permanentlyFailed、cancelled），不需要再次更新
                final isFinalStatus =
                    currentTask.status == UploadTaskStatus.failed ||
                    currentTask.status == UploadTaskStatus.permanentlyFailed ||
                    currentTask.status == UploadTaskStatus.cancelled;

                if (!isFinalStatus) {
                  // 状态还未更新，手动更新（异常情况下的兜底处理）
                  final newStatus = backupError.isRetryable
                      ? (currentTask.retryCount >= task.maxRetries
                            ? UploadTaskStatus.permanentlyFailed
                            : UploadTaskStatus.failed)
                      : UploadTaskStatus.permanentlyFailed;

                  // 通过状态机更新状态
                  await _stateMachine.transition(
                    currentTask,
                    newStatus,
                    errorMessage: backupError.message,
                  );
                }
              }
            } catch (stateError, stateStackTrace) {
              // 状态更新失败，记录错误但不抛出异常，避免影响其他任务
              _logger.warning(
                'Failed to update task status after error: '
                'taskId=${task.id}, error=$stateError',
                stateError,
                stateStackTrace,
              );
            }

            // 添加错误到错误列表（用于返回）
            errors.add(
              UploadError(
                assetId: task.assetId,
                errorMessage: backupError.message,
                type: _mapBackupErrorTypeToErrorType(backupError.type),
              ),
            );

            failedCount++;
          } finally {
            // 更新进度
            completedCount[0]++;
            onProgress?.call(completedCount[0], sortedTasks.length);
            _logger.fine(
              'Task finished: taskId=${task.id}, '
              'completed=${completedCount[0]}/${sortedTasks.length}',
            );
          }
        });
      }),
    );

    _logger.info(
      'Upload orchestration finished: totalTasks=${sortedTasks.length}, '
      'success=$successCount, failed=$failedCount',
    );

    // 3. 根据成功比例更新 lastBackupTime（仅自动备份）
    if (taskType == UploadTaskType.auto) {
      await _updateLastBackupTime(
        userId: userId,
        successCount: successCount,
        totalCount: sortedTasks.length,
      );
    }

    final result = UploadResult(
      successCount: successCount,
      failedCount: failedCount,
      errors: errors,
    );

    _logger.info(
      'Upload orchestration completed: userId=$userId, '
      'success=$successCount, failed=$failedCount',
    );

    return result;
  }

  /// 计算任务的 checksum
  Future<List<String?>> _calculateChecksums(
    List<UploadTaskEntityData> tasks,
  ) async {
    final checksums = <String?>[];

    for (final task in tasks) {
      try {
        // 使用 ChecksumService 获取或计算 checksum
        final checksum = await _checksumService.getOrCalculateChecksum(
          assetId: task.assetId,
          filePath: task.localPath,
        );
        checksums.add(checksum);
      } catch (e) {
        _logger.warning(
          'Failed to calculate checksum for taskId=${task.id}: $e',
        );
        checksums.add(null);
      }
    }

    return checksums;
  }

  /// 批量检查已存在资产
  Future<Set<String>> _checkExistingAssets({
    required String userId,
    required List<String?> checksums,
  }) async {
    final existingChecksums = <String>{};

    // 过滤掉 null checksum
    final validChecksums = checksums
        .where((c) => c != null)
        .cast<String>()
        .toList();

    if (validChecksums.isEmpty) {
      return existingChecksums;
    }

    // 1. 优先检查本地数据库（remote_asset_entity）
    var query = _database.select(_database.remoteAssetEntity)
      ..where((t) => t.checksum.isIn(validChecksums))
      ..where((t) => t.ownerId.equals(userId));

    final localChecksums = await query.get();

    final localSet = localChecksums
        .map((a) => a.checksum)
        .where((c) => c.isNotEmpty)
        .toSet();
    existingChecksums.addAll(localSet);

    // 2. 检查服务器（分批检查，支持超时和降级）
    final remainingChecksums = validChecksums
        .where((c) => !existingChecksums.contains(c))
        .toList();

    if (remainingChecksums.isNotEmpty) {
      try {
        // 分批检查
        for (int i = 0; i < remainingChecksums.length; i += _batchSize) {
          final batch = remainingChecksums.skip(i).take(_batchSize).toList();

          // 带超时的批量检查
          final remoteChecksums = await _checkAssetsExistOnServer(
            batch,
          ).timeout(_timeout);
          existingChecksums.addAll(remoteChecksums);
        }
      } catch (e) {
        // 使用统一的错误处理器
        final backupError = _errorHandler.handleError(
          e,
          context: 'check_assets_exist_on_server',
        );

        // 降级策略：批量检查失败时，记录错误但不阻塞流程
        _logger.warning(
          'Failed to check existing assets on server: '
          'errorType=${backupError.type}, errorMessage=${backupError.message}',
        );
        // 可以选择跳过去重或逐个检查（根据配置决定）
      }
    }

    return existingChecksums;
  }

  /// 按优先级排序任务
  List<UploadTaskEntityData> _sortTasksByPriority(
    List<UploadTaskEntityData> tasks,
  ) {
    // 优先级排序规则：
    // 1. 任务类型优先：手动备份优先于自动备份
    // 2. 优先级字段：数字越小优先级越高
    // 3. 文件类型：图片优先于视频
    // 4. 文件大小：小文件优先（可选）
    // 5. 创建时间：早创建的任务优先

    final sorted = List<UploadTaskEntityData>.from(tasks);
    sorted.sort((a, b) {
      // 1. 任务类型优先
      if (a.taskType != b.taskType) {
        return a.taskType == UploadTaskType.manual ? -1 : 1;
      }

      // 2. 优先级字段
      final priorityDiff = a.priority.compareTo(b.priority);
      if (priorityDiff != 0) {
        return priorityDiff;
      }

      // 3. 文件类型（需要从 localAsset 获取，这里简化处理）
      // TODO: 从 localAsset 获取 type 进行比较

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
      // 1. 获取本地资产信息（必需，用于路径解析和构建上传表单字段）
      final localAsset = await _database.localAssetDao.getAssetById(
        task.assetId,
      );
      if (localAsset == null) {
        throw Exception('Local asset not found: ${task.assetId}');
      }

      // 2. 使用 AssetPathResolver 解析文件路径（如果不存在则尝试从 photo_manager 重新获取）
      final actualPath = await _pathResolver.resolveAssetPath(localAsset);
      if (actualPath == null) {
        throw FileSystemException('File not found', task.localPath);
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

      // 4. 获取或计算 checksum（使用 ChecksumService）
      final checksum = await _checksumService.getOrCalculateChecksum(
        assetId: task.assetId,
        filePath: actualPath,
      );

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

      // 8. 构建表单字段（后端 API 要求的格式）
      // 转换 AssetType 为后端期望的 item_type
      String itemType;
      switch (localAsset.type) {
        case AssetType.image:
          itemType = 'image';
          break;
        case AssetType.video:
          itemType = 'video';
          break;
        default:
          itemType = 'image'; // 默认处理为图片
          _logger.warning(
            'Unknown asset type: ${localAsset.type}, defaulting to image',
          );
      }

      // 生成 cloud_uuid（客户端生成的 UUID）
      const uuid = Uuid();
      final cloudUuid = uuid.v4();

      // 格式化 media_taken_at（RFC3339 格式，UTC 时间）
      final mediaTakenAt = localAsset.createdAt.toUtc().toIso8601String();

      final fields = <String, String>{
        'hash': checksum ?? '',
        'item_type': itemType,
        'cloud_uuid': cloudUuid,
        'original_filename': localAsset.name,
        'media_taken_at': mediaTakenAt,
      };

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
          // 任务成功完成，发出上传完成通知
          // 注意：不再立即同步资产，由同步模块定时处理
          _logger.info(
            'Task completed: assetId=${task.assetId}, '
            'sync will be handled by sync module',
          );
          _uploadCompleteController.add(task.assetId);
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

  /// 批量检查服务器上已存在的资产
  ///
  /// **参数**：
  /// - [checksums] - checksum 列表
  ///
  /// **返回**：已存在的 checksum 集合
  ///
  /// **API 格式**：
  /// - 请求：POST /api/v1/media/check_hashes
  /// - 请求体：{ "hashes": ["hash1", "hash2", ...] }
  /// - 响应：{ "existing_hashes": ["hash1", "hash3", ...], "missing_hashes": [...], ... }
  Future<Set<String>> _checkAssetsExistOnServer(List<String> checksums) async {
    if (checksums.isEmpty) {
      return {};
    }

    try {
      final endpoint = _apiService.endpoint ?? '';
      final url = '$endpoint$_checkAssetsEndpoint';

      final headers = await ApiService.getRequestHeaders();
      headers['Content-Type'] = 'application/json';

      final response = await _apiService.dio.post(
        url,
        data: {'hashes': checksums},
        options: Options(headers: headers),
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        // 响应拦截器已经提取了 data 字段，所以 response.data 直接是业务数据
        final data = response.data as Map<String, dynamic>?;
        if (data != null) {
          final existing = data['existing_hashes'] as List<dynamic>?;
          if (existing != null) {
            return existing.cast<String>().toSet();
          }
        }
      }

      return {};
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to check assets exist on server: $e',
        e,
        stackTrace,
      );
      // 降级策略：返回空集合，允许继续上传
      return {};
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
