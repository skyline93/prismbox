// lib/services/backup/backup_service.dart

import 'dart:async';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart' as pm;
import 'package:prismbox/config/app_config.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/enums/upload_task_type.dart';
import 'package:prismbox/data/database/enums/upload_task_status.dart';
import 'package:prismbox/data/database/enums/auto_backup_mode.dart';
import 'package:prismbox/infrastructure/api/api_service.dart';
import 'package:prismbox/services/backup/backup_query_builder.dart';
import 'package:prismbox/services/backup/backup_candidate_selector.dart';
import 'package:prismbox/services/backup/upload_service.dart';
import 'package:prismbox/services/backup/backup_config_validator.dart';
import 'package:prismbox/features/local_sync/services/local_sync_service.dart';
import 'package:prismbox/utils/cancellation_token.dart';

/// 备份状态
class BackupStatus {
  final bool enabled;
  final DateTime? lastBackupTime;
  final AutoBackupMode mode;
  final DateTime? timeRangeStart;
  final DateTime? timeRangeEnd;

  BackupStatus({
    required this.enabled,
    this.lastBackupTime,
    required this.mode,
    this.timeRangeStart,
    this.timeRangeEnd,
  });
}

/// 备份统计信息
class BackupCounts {
  /// 总数量（所有需要备份的照片）
  final int total;
  
  /// 已备份数量（已上传到服务器）
  final int backupCount;
  
  /// 剩余数量（还需要备份）
  final int remainder;
  
  /// 处理中数量（正在准备/哈希计算中）
  final int processing;
  
  BackupCounts({
    required this.total,
    required this.backupCount,
    required this.remainder,
    required this.processing,
  });
  
  /// 进度百分比（0.0 - 1.0）
  double get progress {
    if (total == 0) return 0.0;
    return backupCount / total;
  }
  
  /// 是否已完成备份
  bool get isCompleted => remainder == 0 && processing == 0;
}

/// 备份服务：业务编排层
///
/// **职责**：
/// - 备份业务编排（手动/自动触发、配置管理）
/// - 协调备份流程的启动和状态管理
/// - 与本地媒体同步模块协调获取资产数据
///
/// **职责边界**：
/// - ✅ **负责**：备份业务编排、配置管理、触发备份流程
/// - ❌ **不负责**：上传队列管理（由 UploadService 负责）
/// - ❌ **不负责**：候选资源筛选（由 BackupCandidateSelector 负责）
/// - ❌ **不负责**：上传流程编排（由 UploadOrchestrator 负责）
class BackupService {
  final AppDatabase _database;
  final UploadService _uploadService;
  final BackupCandidateSelector _candidateSelector;
  final LocalSyncService _localSyncService;
  final BackupConfigValidator _configValidator;
  final ApiService _apiService;
  final Logger _logger = Logger('BackupService');

  // 上传端点配置
  static const String _uploadEndpoint = '/api/v1/media/upload-stream';

  BackupService({
    required AppDatabase database,
    required UploadService uploadService,
    required BackupCandidateSelector candidateSelector,
    required LocalSyncService localSyncService,
    ApiService? apiService,
  }) : _database = database,
       _uploadService = uploadService,
       _candidateSelector = candidateSelector,
       _localSyncService = localSyncService,
       _configValidator = BackupConfigValidator(),
       _apiService = apiService ?? ApiService();

  /// 启动手动备份
  ///
  /// **参数**：
  /// - [userId] - 用户 ID（必须）
  /// - [assetIds] - 要备份的资产 ID 列表
  /// - [skipDeduplication] - 是否跳过去重（默认 false）
  ///
  /// **执行流程**：
  /// 1. 验证用户和资产
  /// 2. 创建上传任务（高优先级）
  /// 3. 添加上传任务到队列
  Future<void> startManualBackup({
    required String userId,
    required List<String> assetIds,
    bool skipDeduplication = false,
  }) async {
    _logger.info(
      'Starting manual backup: userId=$userId, '
      'assetIds=${assetIds.length}, skipDeduplication=$skipDeduplication',
    );

    if (assetIds.isEmpty) {
      _logger.warning('No assets to backup');
      return;
    }

    // 1. 获取本地资产
    final dao = _database.localAssetDao;
    final assets = <LocalAssetEntityData>[];

    for (final assetId in assetIds) {
      final asset = await dao.getAssetById(assetId);
      if (asset != null) {
        assets.add(asset);
      } else {
        _logger.warning('Asset not found: assetId=$assetId');
      }
    }

    if (assets.isEmpty) {
      _logger.warning('No valid assets to backup');
      return;
    }

    // 2. 创建上传任务（高优先级，manual 类型）
    final tasks = <UploadTaskEntityData>[];
    final endpoint = _apiService.endpoint ?? ApiConfig.apiEndpoint;
    final remotePath = '$endpoint$_uploadEndpoint';

    for (final asset in assets) {
      // 获取文件路径和大小
      String? actualPath = asset.path;
      int fileSize = 0;

      try {
        final file = File(asset.path);
        if (await file.exists()) {
          fileSize = await file.length();
        } else {
          // 文件不存在，尝试通过 photo_manager 重新获取
          _logger.warning(
            'File not found: ${asset.path}, trying to get from photo_manager',
          );
          try {
            final assetEntity = await pm.AssetEntity.fromId(asset.id);
            if (assetEntity != null) {
              // 使用 originFile 获取原始文件路径，确保获取的是永久文件
              final fileFromAsset = await assetEntity.originFile;
              if (fileFromAsset != null && await fileFromAsset.exists()) {
                actualPath = fileFromAsset.path;
                fileSize = await fileFromAsset.length();
                _logger.info('Got file path from photo_manager: $actualPath');
              } else {
                _logger.warning('File not found in photo_manager: ${asset.id}');
                continue; // 跳过不存在的文件
              }
            } else {
              _logger.warning('AssetEntity not found: ${asset.id}');
              continue; // 跳过找不到的资产
            }
          } catch (e) {
            _logger.warning(
              'Failed to get file from photo_manager for ${asset.id}: $e',
            );
            continue; // 跳过无法获取的文件
          }
        }
      } catch (e) {
        _logger.warning('Failed to get file size for ${asset.path}: $e');
        // 继续创建任务，fileSize 为 0，后续上传时会重新获取
      }

      // 确保有有效的文件路径
      if (actualPath == null || actualPath.isEmpty) {
        _logger.warning('No valid file path for asset: ${asset.id}');
        continue;
      }

      final task = UploadTaskEntityData(
        id: 'manual_${asset.id}_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        assetId: asset.id,
        localPath: actualPath, // 使用实际获取到的路径
        remotePath: remotePath,
        fileSize: fileSize,
        taskType: UploadTaskType.manual,
        priority: 1, // 手动备份高优先级
        status: UploadTaskStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        errorMessage: null,
        uploadedAt: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        progress: 0,
      );
      tasks.add(task);
    }

    // 3. 添加上传任务到队列（自动进行冲突检测）
    await _uploadService.addTasks(tasks);

    _logger.info('Created ${tasks.length} manual backup tasks');

    // 4. 对于手动备份，无论批量大小，都应该立即开始上传编排（异步）
    // 因为这是用户主动触发的操作，需要立即反馈
    // 任务入队后由 background_downloader 的原生层自动处理，不阻塞UI
    if (tasks.isNotEmpty) {
      _logger.info(
        'Starting manual backup upload orchestration: ${tasks.length} tasks',
      );

      // 异步执行上传编排，不阻塞UI
      // 任务入队后立即返回，实际执行由 background_downloader 的原生层处理
      unawaited(
        _uploadService
            .startUpload(
              userId: userId,
              cancellationToken: CancellationToken(),
              onProgress: (current, total) {
                _logger.fine(
                  'Manual backup progress: $current/$total '
                  '(${(current / total * 100).toStringAsFixed(1)}%)',
                );
              },
            )
            .then((result) {
              _logger.info(
                'Manual backup upload orchestration completed: '
                'success=${result.successCount}, failed=${result.failedCount}',
              );
            })
            .catchError((e, stackTrace) {
              _logger.warning(
                'Failed to start manual backup upload orchestration: $e',
                e,
                stackTrace,
              );
              // 即使编排失败，任务已在队列中，background_downloader 会处理
            }),
      );
    }
  }

  /// 启动自动备份
  ///
  /// **参数**：
  /// - [userId] - 用户 ID（必须）
  ///
  /// **执行流程**：
  /// 1. 检查全局开关和用户开关
  /// 2. 检查网络条件（WiFi 要求等）
  /// 3. 根据 autoBackupMode 筛选候选资源
  /// 4. 创建上传任务
  /// 5. 调用 UploadService 执行上传
  Future<void> startAutoBackup(String userId) async {
    _logger.info('Starting auto backup: userId=$userId');

    // 1. 获取备份配置
    final backupStatus = await BackupQueryBuilder(
      _database,
    ).withUserId(userId).getBackupStatus();

    if (backupStatus == null || !backupStatus.enabled) {
      _logger.info('Auto backup is disabled for userId=$userId');
      return;
    }

    // 2. 验证配置
    final validation = await _configValidator.validate(_database, userId);
    if (!validation.isValid) {
      _logger.warning(
        'Invalid backup config for userId=$userId: ${validation.errors}',
      );
      return;
    }

    // 3. 根据 autoBackupMode 筛选候选资源
    List<LocalAssetEntityData> candidates;

    switch (backupStatus.autoBackupMode) {
      case AutoBackupMode.allUnbacked:
        candidates = await _candidateSelector.selectAllUnbacked(
          userId: userId,
          lastBackupTime: backupStatus.lastBackupTime,
        );
        break;

      case AutoBackupMode.selectedAlbums:
        candidates = await _candidateSelector.selectSelectedAlbums(
          userId: userId,
          timeRangeStart: backupStatus.timeRangeStart,
          timeRangeEnd: backupStatus.timeRangeEnd,
        );
        break;

      case AutoBackupMode.timeRange:
        if (backupStatus.timeRangeStart == null ||
            backupStatus.timeRangeEnd == null) {
          _logger.warning(
            'Time range mode requires timeRangeStart and timeRangeEnd',
          );
          return;
        }
        candidates = await _candidateSelector.selectTimeRange(
          userId: userId,
          timeRangeStart: backupStatus.timeRangeStart!,
          timeRangeEnd: backupStatus.timeRangeEnd!,
        );
        break;
    }

    if (candidates.isEmpty) {
      _logger.info('No candidates for auto backup');
      return;
    }

    _logger.info('Found ${candidates.length} candidates for auto backup');

    // 4. 创建上传任务（正常优先级，auto 类型）
    final tasks = <UploadTaskEntityData>[];
    final endpoint = _apiService.endpoint ?? ApiConfig.apiEndpoint;
    final remotePath = '$endpoint$_uploadEndpoint';

    for (final asset in candidates) {
      // 获取文件路径和大小
      String? actualPath = asset.path;
      int fileSize = 0;

      try {
        final file = File(asset.path);
        if (await file.exists()) {
          fileSize = await file.length();
        } else {
          // 文件不存在，尝试通过 photo_manager 重新获取
          _logger.warning(
            'File not found: ${asset.path}, trying to get from photo_manager',
          );
          try {
            final assetEntity = await pm.AssetEntity.fromId(asset.id);
            if (assetEntity != null) {
              // 使用 originFile 获取原始文件路径，确保获取的是永久文件
              final fileFromAsset = await assetEntity.originFile;
              if (fileFromAsset != null && await fileFromAsset.exists()) {
                actualPath = fileFromAsset.path;
                fileSize = await fileFromAsset.length();
                _logger.info('Got file path from photo_manager: $actualPath');

                // 更新本地资产数据库中的路径（如果路径已改变）
                if (actualPath != asset.path) {
                  final updatedAsset = asset.copyWith(
                    path: actualPath,
                    updatedAt: DateTime.now(),
                  );
                  try {
                    await _database.localAssetDao.updateAsset(updatedAsset);
                    _logger.info('Updated asset path in database: ${asset.id}');
                  } catch (e) {
                    _logger.warning(
                      'Failed to update asset path in database: ${asset.id}',
                      e,
                    );
                    // 继续创建任务，即使更新数据库失败
                  }
                }
              } else {
                _logger.warning('File not found in photo_manager: ${asset.id}');
                continue; // 跳过不存在的文件
              }
            } else {
              _logger.warning('AssetEntity not found: ${asset.id}');
              continue; // 跳过找不到的资产
            }
          } catch (e) {
            _logger.warning(
              'Failed to get file from photo_manager for ${asset.id}: $e',
            );
            continue; // 跳过无法获取的文件
          }
        }
      } catch (e) {
        _logger.warning('Failed to get file size for ${asset.path}: $e');
        // 继续创建任务，fileSize 为 0，后续上传时会重新获取
      }

      // 确保有有效的文件路径
      if (actualPath == null || actualPath.isEmpty) {
        _logger.warning('No valid file path for asset: ${asset.id}');
        continue;
      }

      final task = UploadTaskEntityData(
        id: 'auto_${asset.id}_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        assetId: asset.id,
        localPath: actualPath, // 使用实际获取到的路径
        remotePath: remotePath,
        fileSize: fileSize,
        taskType: UploadTaskType.auto,
        priority: 5, // 自动备份正常优先级
        status: UploadTaskStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        errorMessage: null,
        uploadedAt: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        progress: 0,
      );
      tasks.add(task);
    }

    // 5. 添加上传任务到队列
    await _uploadService.addTasks(tasks);

    _logger.info('Created ${tasks.length} auto backup tasks');

    // 6. 启动上传（可选，也可以由后台任务触发）
    // await _uploadService.startUpload(
    //   userId: userId,
    //   cancellationToken: CancellationToken(),
    // );
  }

  /// 获取备份状态
  ///
  /// **参数**：
  /// - [userId] - 用户 ID（必须）
  ///
  /// **返回**：BackupStatus（备份状态）
  Future<BackupStatus?> getBackupStatus(String userId) async {
    final entity = await BackupQueryBuilder(
      _database,
    ).withUserId(userId).getBackupStatus();

    if (entity == null) {
      return null;
    }

    return BackupStatus(
      enabled: entity.enabled,
      lastBackupTime: entity.lastBackupTime,
      mode: entity.autoBackupMode,
      timeRangeStart: entity.timeRangeStart,
      timeRangeEnd: entity.timeRangeEnd,
    );
  }

  /// 获取备份统计信息
  /// 
  /// **参数**：
  /// - [userId] - 用户 ID（必须）
  /// 
  /// **返回**：BackupCounts（备份统计信息）
  /// 
  /// **实现逻辑**：
  /// 1. 获取备份配置
  /// 2. 根据备份模式筛选需要备份的资产
  /// 3. 通过 SQL 查询统计信息（总数、已备份数、剩余数、处理中数）
  /// 4. 返回 BackupCounts
  /// 
  /// **注意**：当前实现简化版本，不依赖本地相册资产关联表
  /// 后续可以根据实际数据结构优化查询
  Future<BackupCounts> getBackupCounts(String userId) async {
    // 1. 获取备份配置
    final backupStatus = await BackupQueryBuilder(_database)
        .withUserId(userId)
        .getBackupStatus();
    
    if (backupStatus == null || !backupStatus.enabled) {
      return BackupCounts(
        total: 0,
        backupCount: 0,
        remainder: 0,
        processing: 0,
      );
    }
    
    // 2. 根据备份模式获取候选资产
    List<LocalAssetEntityData> candidates;
    switch (backupStatus.autoBackupMode) {
      case AutoBackupMode.allUnbacked:
        candidates = await _candidateSelector.selectAllUnbacked(
          userId: userId,
          lastBackupTime: backupStatus.lastBackupTime,
        );
        break;
      case AutoBackupMode.selectedAlbums:
        candidates = await _candidateSelector.selectSelectedAlbums(
          userId: userId,
          timeRangeStart: backupStatus.timeRangeStart,
          timeRangeEnd: backupStatus.timeRangeEnd,
        );
        break;
      case AutoBackupMode.timeRange:
        if (backupStatus.timeRangeStart == null ||
            backupStatus.timeRangeEnd == null) {
          return BackupCounts(
            total: 0,
            backupCount: 0,
            remainder: 0,
            processing: 0,
          );
        }
        candidates = await _candidateSelector.selectTimeRange(
          userId: userId,
          timeRangeStart: backupStatus.timeRangeStart!,
          timeRangeEnd: backupStatus.timeRangeEnd!,
        );
        break;
    }
    
    if (candidates.isEmpty) {
      return BackupCounts(
        total: 0,
        backupCount: 0,
        remainder: 0,
        processing: 0,
      );
    }
    
    // 3. 统计信息
    int total = candidates.length;
    int processing = 0;
    int backupCount = 0;
    
    // 获取所有候选资产的 checksum
    final candidateChecksums = candidates
        .where((asset) => asset.checksum != null)
        .map((asset) => asset.checksum!)
        .toSet();
    
    // 查询已备份的资产（通过 checksum 匹配）
    if (candidateChecksums.isNotEmpty) {
      final remoteAssets = await (_database.select(_database.remoteAssetEntity)
            ..where((t) =>
                t.ownerId.equals(userId) &
                t.checksum.isIn(candidateChecksums)))
          .get();
      
      backupCount = remoteAssets.length;
    }
    
    // 统计处理中的资产（checksum 为 null）
    processing = candidates.where((asset) => asset.checksum == null).length;
    
    // 剩余数量 = 总数 - 已备份数
    final remainder = total - backupCount;
    
    return BackupCounts(
      total: total,
      backupCount: backupCount,
      remainder: remainder,
      processing: processing,
    );
  }

  /// 更新备份配置
  ///
  /// **参数**：
  /// - [userId] - 用户 ID（必须）
  /// - [config] - 备份配置
  ///
  /// **职责**：
  /// - 验证配置
  /// - 保存配置到数据库
  Future<void> updateBackupConfig(
    String userId,
    BackupStatusEntityCompanion config,
  ) async {
    _logger.info('Updating backup config: userId=$userId');

    // 1. 验证配置
    final existing = await BackupQueryBuilder(
      _database,
    ).withUserId(userId).getBackupStatus();

    if (existing != null) {
      final validation = await _configValidator.validate(_database, userId);
      if (!validation.isValid) {
        throw ArgumentError(
          'Invalid backup config: ${validation.errors.join(", ")}',
        );
      }
    }

    // 2. 保存配置
    final dao = _database.backupStatusDao;
    await dao.updateBackupConfig(userId, config);

    _logger.info('Backup config updated successfully');
  }
}
