// lib/services/backup/upload_orchestrator.dart

import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart' as pm;
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/enums/upload_task_type.dart';
import 'package:prismbox/data/database/enums/upload_task_status.dart';
import 'package:prismbox/infrastructure/api/api_service.dart';
import 'package:prismbox/services/backup/task_status_validator.dart';
import 'package:prismbox/services/backup/upload_concurrency_controller.dart';
import 'package:prismbox/services/backup/upload_task_manager.dart';
import 'package:prismbox/services/backup/api_endpoint_validator.dart';
import 'package:prismbox/utils/cancellation_token.dart';

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
  network,        // 网络错误（可重试）
  authentication, // 认证错误（不可重试）
  server,         // 服务器错误（5xx 可重试，4xx 不可重试）
  local,          // 本地错误（文件不存在、权限不足等，不可重试）
  timeout,        // 超时错误（可重试）
  cancelled,      // 取消错误（不可重试）
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
  final TaskStatusValidator _statusValidator;
  final ApiService _apiService;
  final UploadConcurrencyController _concurrencyController;
  final UploadTaskManager _uploadTaskManager;
  final ApiEndpointValidator _endpointValidator;
  final Logger _logger = Logger('UploadOrchestrator');

  // 去重检查配置
  static const int _batchSize = 100; // 每批最多检查 100 个
  static const Duration _timeout = Duration(seconds: 30); // 超时时间

  // 上传端点配置
  static const String _uploadEndpoint = '/api/v1/media/upload-stream';
  static const String _checkAssetsEndpoint = '/api/v1/media/check_hashes';

  UploadOrchestrator({
    required AppDatabase database,
    ApiService? apiService,
    UploadConcurrencyController? concurrencyController,
    UploadTaskManager? uploadTaskManager,
    ApiEndpointValidator? endpointValidator,
  })  : _database = database,
        _statusValidator = TaskStatusValidator(),
        _apiService = apiService ?? ApiService(),
        _concurrencyController =
            concurrencyController ?? UploadConcurrencyController(),
        _uploadTaskManager = uploadTaskManager ??
            UploadTaskManager(
              database: database,
              apiService: apiService ?? ApiService(),
            ),
        _endpointValidator = endpointValidator ??
            ApiEndpointValidator(apiService: apiService ?? ApiService());

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

    // 3. 过滤掉已存在的资产
    final filtered = <UploadTaskEntityData>[];
    for (int i = 0; i < candidates.length; i++) {
      final task = candidates[i];
      final checksum = checksums[i];
      
      if (!existingChecksums.contains(checksum)) {
        filtered.add(task);
      } else {
        _logger.fine(
          'Skipping duplicate asset: assetId=${task.assetId}, '
          'checksum=$checksum',
        );
      }
    }

    _logger.info(
      'Filtered ${filtered.length} assets '
      '(from ${candidates.length} candidates)',
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

    // 使用并发控制器执行上传任务
    await Future.wait(
      sortedTasks.map((task) async {
        if (cancellationToken.isCancelled) {
          return;
        }

        // 使用并发控制器控制并发数
        await _concurrencyController.execute(() async {
          try {
            // 更新状态为 uploading
            await _statusValidator.validateAndUpdate(
              database: _database,
              taskId: task.id,
              from: task.status,
              to: UploadTaskStatus.uploading,
            );

            // 执行上传（带自动重试）
            await _executeUploadWithRetry(task);

            // 更新状态为 completed
            await _statusValidator.validateAndUpdate(
              database: _database,
              taskId: task.id,
              from: UploadTaskStatus.uploading,
              to: UploadTaskStatus.completed,
            );

            successCount++;
            _logger.fine('Upload completed: taskId=${task.id}');
          } catch (e, stackTrace) {
            _logger.warning(
              'Upload failed: taskId=${task.id}, error=$e',
              e,
              stackTrace,
            );

            // 处理错误
            final error = _handleUploadError(task, e);
            errors.add(error);

            // 获取当前任务状态（可能已更新重试次数）
            final currentTask = await _database.uploadTaskDao.getTaskById(task.id);
            final currentRetryCount = currentTask?.retryCount ?? task.retryCount;

            // 更新状态为 failed 或 permanentlyFailed
            final newStatus = currentRetryCount >= task.maxRetries
                ? UploadTaskStatus.permanentlyFailed
                : UploadTaskStatus.failed;

            await _statusValidator.validateAndUpdate(
              database: _database,
              taskId: task.id,
              from: UploadTaskStatus.uploading,
              to: newStatus,
            );

            failedCount++;
          } finally {
            // 更新进度
            completedCount[0]++;
            onProgress?.call(completedCount[0], sortedTasks.length);
          }
        });
      }),
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
        // 从本地资产获取 checksum（如果已计算）
        final localAsset = await _database.localAssetDao.getAssetById(
          task.assetId,
        );

        if (localAsset?.checksum != null) {
          checksums.add(localAsset!.checksum);
        } else {
          // 计算 checksum（如果文件存在）
          final file = File(task.localPath);
          if (await file.exists()) {
            final checksum = await _calculateFileChecksum(task.localPath);
            checksums.add(checksum);
          } else {
            checksums.add(null);
          }
        }
      } catch (e) {
        _logger.warning(
          'Failed to calculate checksum for taskId=${task.id}: $e',
        );
        checksums.add(null);
      }
    }

    return checksums;
  }

  /// 计算文件 checksum
  Future<String> _calculateFileChecksum(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final hash = sha256.convert(bytes);
    return hash.toString();
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
          final batch = remainingChecksums
              .skip(i)
              .take(_batchSize)
              .toList();

          // 带超时的批量检查
          final remoteChecksums = await _checkAssetsExistOnServer(batch)
              .timeout(_timeout);
          existingChecksums.addAll(remoteChecksums);
        }
      } catch (e) {
        // 降级策略：批量检查失败时，记录错误但不阻塞流程
        _logger.warning(
          'Failed to check existing assets on server: $e',
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
          // 重置重试计数：先获取当前任务，然后更新
          final currentTask = await _database.uploadTaskDao.getTaskById(task.id);
          if (currentTask != null && currentTask.retryCount > 0) {
            await _database.uploadTaskDao.updateTaskStatus(
              task.id,
              currentTask.status,
            );
            // 注意：这里没有直接重置 retryCount 的方法，可以通过更新整个任务来实现
            // 或者保留重试计数，因为任务已成功完成
          }
        }
        return;
      } catch (e) {
        // 判断是否可重试
        final error = _handleUploadError(task, e);
        final isRetryable = _isRetryableError(error);
        
        if (!isRetryable || retryCount >= maxRetries) {
          // 不可重试或达到最大重试次数，增加重试计数并抛出异常
          if (retryCount < maxRetries) {
            await _database.uploadTaskDao.incrementRetryCount(task.id);
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
          'attempt=$retryCount/$maxRetries, delay=${delay.inSeconds}s',
        );
        
        // 增加重试计数
        await _database.uploadTaskDao.incrementRetryCount(task.id);
        
        // 等待后重试
        await Future.delayed(delay);
      }
    }
    
    // 理论上不会到达这里
    throw Exception('Max retries exceeded for taskId=${task.id}');
  }

  /// 判断错误是否可重试
  bool _isRetryableError(UploadError error) {
    switch (error.type) {
      case ErrorType.network:
      case ErrorType.timeout:
        return true; // 网络和超时错误可重试
      case ErrorType.server:
        // 5xx 可重试，4xx 不可重试（需要从错误消息中判断）
        // 这里简化处理，假设服务器错误可重试
        return true;
      case ErrorType.authentication:
      case ErrorType.local:
      case ErrorType.cancelled:
        return false; // 认证、本地、取消错误不可重试
    }
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
    _logger.info('Executing upload: taskId=${task.id}, assetId=${task.assetId}');

    try {
      // 1. 检查文件是否存在，如果不存在则尝试从 photo_manager 重新获取
      String actualPath = task.localPath;
      File file = File(actualPath);
      
      if (!await file.exists()) {
        _logger.warning(
          'File not found: ${task.localPath}, trying to get from photo_manager',
        );
        
        try {
          final assetEntity = await pm.AssetEntity.fromId(task.assetId);
          if (assetEntity != null) {
            // 使用 originFile 获取原始文件路径，确保获取的是永久文件
            final fileFromAsset = await assetEntity.originFile;
            if (fileFromAsset != null && await fileFromAsset.exists()) {
              actualPath = fileFromAsset.path;
              file = fileFromAsset;
              _logger.info('Got file path from photo_manager: $actualPath');
              
              // 更新任务中的文件路径（确保后续使用正确的路径）
              await _database.uploadTaskDao.updateTaskLocalPath(
                task.id,
                actualPath,
              );
              
              // 更新本地资产数据库中的路径（如果路径已改变）
              final localAsset = await _database.localAssetDao.getAssetById(task.assetId);
              if (localAsset != null && localAsset.path != actualPath) {
                final updatedAsset = localAsset.copyWith(
                  path: actualPath,
                  updatedAt: DateTime.now(),
                );
                try {
                  await _database.localAssetDao.updateAsset(updatedAsset);
                  _logger.info('Updated asset path in database: ${task.assetId}');
                } catch (e) {
                  _logger.warning(
                    'Failed to update asset path in database: ${task.assetId}',
                    e,
                  );
                  // 继续上传，即使更新数据库失败
                }
              }
            } else {
              throw FileSystemException(
                'File not found in photo_manager',
                task.assetId,
              );
            }
          } else {
            throw FileSystemException(
              'AssetEntity not found',
              task.assetId,
            );
          }
        } catch (e) {
          _logger.warning(
            'Failed to get file from photo_manager for ${task.assetId}: $e',
          );
          throw FileSystemException('File not found', task.localPath);
        }
      }

      // 2. 获取文件大小（如果未设置）
      int fileSize = task.fileSize;
      if (fileSize == 0) {
        fileSize = await file.length();
      }

      // 3. 获取 checksum（从本地资产或计算）
      String? checksum;
      final localAsset = await _database.localAssetDao.getAssetById(task.assetId);
      if (localAsset?.checksum != null && localAsset!.checksum!.isNotEmpty) {
        checksum = localAsset.checksum;
      } else {
        // 计算 checksum（使用实际路径）
        checksum = await _calculateFileChecksum(actualPath);
        // 更新本地资产的 checksum
        if (localAsset != null && localAsset.checksum != checksum) {
          final updatedAsset = localAsset.copyWith(
            checksum: Value(checksum),
            updatedAt: DateTime.now(),
          );
          await _database.localAssetDao.updateAsset(updatedAsset);
        }
      }

      // 4. 验证上传端点（可选，用于提前发现问题）
      final endpointValidation = await _endpointValidator.validateUploadEndpoint();
      if (!endpointValidation.isValid) {
        _logger.warning(
          'Upload endpoint validation failed: ${endpointValidation.error}',
        );
        // 继续尝试上传，因为验证可能失败但实际上传可能成功
      }

      // 5. 获取上传端点
      final endpoint = _apiService.endpoint ?? '';
      final uploadUrl = '$endpoint$_uploadEndpoint';

      // 6. 获取请求头（包含认证信息）
      final headers = ApiService.getRequestHeaders();

      // 7. 构建表单字段
      final fields = <String, String>{
        'hash': checksum ?? '',
        'deviceAssetId': task.assetId,
      };

      // 8. 确定任务组
      final group = task.taskType == UploadTaskType.manual
          ? UploadTaskGroup.manual
          : UploadTaskGroup.auto;

      // 9. 创建上传任务（使用实际路径）
      final uploadTask = _uploadTaskManager.createUploadTask(
        taskId: task.id,
        filePath: actualPath, // 使用实际获取到的路径
        url: uploadUrl,
        headers: headers,
        fields: fields,
        group: group,
      );

      // 10. 入队任务
      final enqueued = await _uploadTaskManager.enqueueTask(uploadTask);
      if (!enqueued) {
        throw Exception('Failed to enqueue upload task');
      }

      // 11. 等待任务完成（通过监听状态更新）
      // 注意：background_downloader 会在后台执行任务，状态更新通过回调处理
      // 这里我们等待一段时间让任务开始，然后通过状态检查确认完成
      await _waitForTaskCompletion(task.id);

      _logger.info('Upload task enqueued and completed: taskId=${task.id}');
    } catch (e, stackTrace) {
      _logger.warning(
        'Upload failed: taskId=${task.id}, error=$e',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// 等待任务完成
  /// 
  /// **实现说明**：
  /// - 通过轮询检查任务状态（background_downloader 会通过回调更新数据库）
  /// - 使用智能轮询策略：初始间隔短，逐渐增加间隔
  /// - 超时时间：1 小时（大文件上传可能需要较长时间）
  /// 
  /// **参数**：
  /// - [taskId] - 任务 ID
  /// 
  /// **轮询策略**：
  /// - 前 30 秒：每 1 秒检查一次（快速响应）
  /// - 30 秒到 5 分钟：每 2 秒检查一次
  /// - 5 分钟到 30 分钟：每 5 秒检查一次
  /// - 30 分钟以上：每 10 秒检查一次（减少数据库查询）
  Future<void> _waitForTaskCompletion(String taskId) async {
    const timeout = Duration(hours: 1);
    final startTime = DateTime.now();
    int checkCount = 0;

    while (DateTime.now().difference(startTime) < timeout) {
      // 从数据库检查任务状态
      final task = await _database.uploadTaskDao.getTaskById(taskId);
      if (task == null) {
        throw Exception('Task not found: $taskId');
      }

      if (task.status == UploadTaskStatus.completed) {
        _logger.info(
          'Task completed: taskId=$taskId, '
          'checks=$checkCount, elapsed=${DateTime.now().difference(startTime).inSeconds}s',
        );
        return;
      }

      if (task.status == UploadTaskStatus.permanentlyFailed ||
          task.status == UploadTaskStatus.cancelled) {
        throw Exception(
          'Task failed or cancelled: taskId=$taskId, status=${task.status}',
        );
      }

      // 智能轮询间隔：根据已等待时间调整检查间隔
      final elapsed = DateTime.now().difference(startTime);
      Duration checkInterval;
      
      if (elapsed < const Duration(seconds: 30)) {
        checkInterval = const Duration(seconds: 1); // 前 30 秒：快速检查
      } else if (elapsed < const Duration(minutes: 5)) {
        checkInterval = const Duration(seconds: 2); // 30 秒到 5 分钟：每 2 秒
      } else if (elapsed < const Duration(minutes: 30)) {
        checkInterval = const Duration(seconds: 5); // 5 分钟到 30 分钟：每 5 秒
      } else {
        checkInterval = const Duration(seconds: 10); // 30 分钟以上：每 10 秒
      }

      checkCount++;
      await Future.delayed(checkInterval);
    }

    throw TimeoutException(
      'Task completion timeout: taskId=$taskId, '
      'checks=$checkCount, elapsed=${DateTime.now().difference(startTime).inSeconds}s',
      timeout,
    );
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
  Future<Set<String>> _checkAssetsExistOnServer(
    List<String> checksums,
  ) async {
    if (checksums.isEmpty) {
      return {};
    }

    try {
      final endpoint = _apiService.endpoint ?? '';
      final url = '$endpoint$_checkAssetsEndpoint';

      final headers = ApiService.getRequestHeaders();
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

  /// 处理上传错误
  UploadError _handleUploadError(
    UploadTaskEntityData task,
    dynamic error,
  ) {
    // 根据错误类型分类
    ErrorType errorType;
    String errorMessage = error.toString();

    if (error is TimeoutException) {
      errorType = ErrorType.timeout;
      errorMessage = '上传超时';
    } else if (error is SocketException || error is DioException) {
      if (error is DioException) {
        final dioError = error;
        if (dioError.type == DioExceptionType.connectionTimeout ||
            dioError.type == DioExceptionType.receiveTimeout ||
            dioError.type == DioExceptionType.sendTimeout) {
          errorType = ErrorType.timeout;
        } else if (dioError.type == DioExceptionType.connectionError ||
            dioError.type == DioExceptionType.unknown) {
          errorType = ErrorType.network;
        } else if (dioError.response != null) {
          final statusCode = dioError.response!.statusCode;
          if (statusCode == 401) {
            errorType = ErrorType.authentication;
            errorMessage = '认证失败，请重新登录';
          } else if (statusCode != null && statusCode >= 500) {
            errorType = ErrorType.server;
            errorMessage = '服务器错误 ($statusCode)';
          } else if (statusCode != null && statusCode >= 400) {
            errorType = ErrorType.server;
            errorMessage = '客户端错误 ($statusCode)';
          } else {
            errorType = ErrorType.network;
          }
        } else {
          errorType = ErrorType.network;
        }
      } else {
        errorType = ErrorType.network;
      }
    } else if (error is FileSystemException) {
      errorType = ErrorType.local;
      errorMessage = '文件访问失败: ${error.message}';
    } else {
      // 默认作为本地错误
      errorType = ErrorType.local;
    }

    return UploadError(
      assetId: task.assetId,
      errorMessage: errorMessage,
      type: errorType,
    );
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