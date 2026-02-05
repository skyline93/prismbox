// lib/services/backup/backup_service.dart

import 'dart:async';
import 'package:logging/logging.dart';
import 'package:prismbox/config/app_config.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/enums/upload_task_type.dart';
import 'package:prismbox/data/database/enums/auto_backup_mode.dart';
import 'package:prismbox/data/database/enums/asset_type.dart';
import 'package:prismbox/infrastructure/api/api_service.dart';
import 'package:prismbox/services/backup/backup_query_builder.dart';
import 'package:prismbox/services/backup/backup_candidate_selector.dart';
import 'package:prismbox/services/backup/upload_service.dart';
import 'package:prismbox/services/backup/backup_config_validator.dart';
import 'package:prismbox/services/backup/task_factory.dart';
import 'package:prismbox/utils/cancellation_token.dart';
import 'package:prismbox/core/storage/store_service.dart';
import 'package:prismbox/core/storage/store_key.dart';

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
  final BackupConfigValidator _configValidator;
  final ApiService _apiService;
  final TaskFactory _taskFactory;
  final Logger _logger = Logger('BackupService');

  // 上传端点配置
  static const String _uploadEndpoint = '/api/v1/media/upload-stream';

  BackupService({
    required AppDatabase database,
    required UploadService uploadService,
    required BackupCandidateSelector candidateSelector,
    ApiService? apiService,
    required TaskFactory taskFactory,
  }) : _database = database,
       _uploadService = uploadService,
       _candidateSelector = candidateSelector,
       _configValidator = BackupConfigValidator(),
       _apiService = apiService ?? ApiService(),
       _taskFactory = taskFactory;

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
    final endpoint = _apiService.endpoint ?? ApiConfig.apiEndpoint;
    final remotePath = '$endpoint$_uploadEndpoint';

    final tasks = await _taskFactory.createTasks(
      assets: assets,
      userId: userId,
      remotePath: remotePath,
      taskType: UploadTaskType.manual,
      priority: 1, // 手动备份高优先级
    );

    // 3. 添加上传任务到队列（自动进行冲突检测）
    await _uploadService.addTasks(tasks);

    _logger.info('Created ${tasks.length} manual backup tasks');

    // 4. 乐观更新：立即将任务状态更新为 queued（已入队）
    // 这样UI可以立即显示上传中的状态，提供即时反馈
    await _uploadService.optimisticallyUpdateTasksToQueued(tasks);

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

    // 0. 检查触发频率（避免频繁触发）
    final storeService = StoreService();
    final lastTriggerTime = storeService.get<DateTime?>(
      StoreKey.lastAutoBackupTriggerTime,
      null,
    );
    
    if (lastTriggerTime != null) {
      final timeSinceLastTrigger = DateTime.now().difference(lastTriggerTime);
      if (timeSinceLastTrigger.inMinutes < 5) {
        _logger.info(
          'Auto backup triggered too frequently, '
          'last trigger was ${timeSinceLastTrigger.inMinutes} minutes ago. '
          'Skipping this trigger.',
        );
        return;
      }
    }
    
    // 更新最后触发时间
    await storeService.put(
      StoreKey.lastAutoBackupTriggerTime,
      DateTime.now(),
    );

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

    // 3.1 针对 Live Photo 做候选集归一化：
    //     - 对于 Live Photo，仅保留「主图」资产（image + livePhotoVideoId 非空）作为候选；
    //     - 排除被任何主图引用的「视频资产」，避免后续为同一 Live Photo 创建重复任务。
    final livePhotoVideoIds = <String>{};
    for (final asset in candidates) {
      if (asset.type == AssetType.image &&
          asset.livePhotoVideoId != null &&
          asset.livePhotoVideoId!.isNotEmpty) {
        livePhotoVideoIds.add(asset.livePhotoVideoId!);
      }
    }

    final normalizedCandidates = <LocalAssetEntityData>[];
    for (final asset in candidates) {
      final isLivePhotoVideo = asset.type == AssetType.video &&
          livePhotoVideoIds.contains(asset.id);

      // 仅保留：非 Live Photo 资产 + Live Photo 主图资产
      if (!isLivePhotoVideo) {
        normalizedCandidates.add(asset);
      }

      if (isLivePhotoVideo) {
        _logger.fine(
          'Skip Live Photo video candidate because it will be uploaded via its '
          'paired image asset: videoAssetId=${asset.id}',
        );
      }
    }

    _logger.info(
      'Normalized auto-backup candidates: '
      'original=${candidates.length}, normalized=${normalizedCandidates.length}',
    );

    // 4. 创建上传任务（正常优先级，auto 类型）
    final endpoint = _apiService.endpoint ?? ApiConfig.apiEndpoint;
    final remotePath = '$endpoint$_uploadEndpoint';

    final tasks = await _taskFactory.createTasks(
      assets: normalizedCandidates,
      userId: userId,
      remotePath: remotePath,
      taskType: UploadTaskType.auto,
      priority: 5, // 自动备份正常优先级
    );

    // 5. 添加上传任务到队列
    await _uploadService.addTasks(tasks);

    _logger.info('Created ${tasks.length} auto backup tasks');

    // 6. 乐观更新：立即将任务状态更新为 queued（已入队）
    // 这样UI可以立即显示上传中的状态，提供即时反馈
    await _uploadService.optimisticallyUpdateTasksToQueued(tasks);

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
    
    // 3. 统计信息（基于 isUploaded 字段）
    int total = candidates.length;
    int backupCount = candidates.where((asset) => asset.isUploaded).length;
    int remainder = total - backupCount;
    int processing = 0; // 处理中数量（不再需要，因为不再计算 checksum）
    
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
