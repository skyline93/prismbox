// lib/features/local_sync/services/sync_coordinator.dart

import 'dart:async';
import 'package:logging/logging.dart';
import 'package:prismbox/core/config/sync_config.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/features/local_sync/models/sync_result.dart';
import 'package:prismbox/features/local_sync/models/sync_status.dart';
import 'package:prismbox/features/local_sync/services/data_source_selector.dart';
import 'package:prismbox/features/local_sync/services/local_sync_service.dart';
import 'package:prismbox/utils/async_mutex.dart';

/// 同步协调器
/// 
/// **职责**：
/// - 协调后台本地同步任务，不阻塞 UI
/// - 管理同步状态
/// - 支持自动同步和手动同步
/// - 协调数据源切换
class SyncCoordinator {
  final LocalSyncService _syncService;
  final AppDatabase _database;
  final Logger _logger = Logger('SyncCoordinator');
  
  /// 同步状态流控制器
  final _statusController = StreamController<SyncStatusInfo>.broadcast();
  
  /// 数据源切换通知流控制器
  final _dataSourceSwitchController = StreamController<bool>.broadcast();
  
  /// 同步互斥锁（确保顺序执行）
  final AsyncMutex _syncMutex = AsyncMutex();
  
  /// 最后同步时间
  DateTime? _lastSyncedAt;
  
  /// 最后触发时间（用于去重）
  DateTime? _lastTriggerTime;

  SyncCoordinator({
    required LocalSyncService syncService,
    required AppDatabase database,
  })  : _syncService = syncService,
        _database = database;

  /// 同步状态流
  Stream<SyncStatusInfo> get statusStream => _statusController.stream;

  /// 数据源切换通知流
  /// 当同步完成后，如果数据库数据可用，会发出 true 通知
  Stream<bool> get dataSourceSwitchStream => _dataSourceSwitchController.stream;

  /// 当前状态
  SyncStatusInfo _currentStatus = const SyncStatusInfo();
  SyncStatusInfo get currentStatus => _currentStatus;

  /// 应用启动时自动同步（延迟执行）
  void startAutoSyncOnLaunch() {
    _logger.info('计划延迟自动同步（${SyncConfig.startDelay.inSeconds}秒后）');
    Future.delayed(SyncConfig.startDelay, () {
      _checkAndSyncLocal();
    });
  }

  /// 应用恢复时检查并同步
  void checkAndSyncOnResume() {
    _logger.info('应用恢复，检查数据新鲜度');
    _checkAndSyncLocal();
  }

  /// 手动触发同步
  /// 
  /// [full] 是否全量同步
  Future<SyncResult> syncManually({bool full = false}) async {
    // 如果有任务正在运行，取消它
    if (_syncMutex.enqueued > 0) {
      _logger.warning('同步任务正在进行中，取消当前任务');
      cancel();
      // 注意：AsyncMutex 会自动处理等待，新任务会等待当前任务完成后再执行
      // 即使当前任务被取消，AsyncMutex 也会等待它完成（或失败）后再执行新任务
    }

    return await _sync(full: full);
  }

  /// 统一的本地同步触发入口（带去重）
  Future<void> _checkAndSyncLocal({bool force = false}) async {
    // 去重：如果最近已触发，跳过
    if (!force && _lastTriggerTime != null) {
      final timeSinceLastTrigger = DateTime.now().difference(_lastTriggerTime!);
      if (timeSinceLastTrigger < SyncConfig.triggerDebounce) {
        _logger.info('最近已触发同步，跳过（去重）');
        return;
      }
    }
    
    _lastTriggerTime = DateTime.now();
    
    try {
      // 检查数据新鲜度
      final isFresh = _lastSyncedAt != null &&
          DateTime.now().difference(_lastSyncedAt!) < SyncConfig.localFreshnessThreshold;

      if (isFresh) {
        _logger.info('数据新鲜，跳过同步');
        return;
      }

      // 执行增量同步
      await _sync(full: false);
    } catch (e) {
      _logger.warning('自动同步失败', e);
    }
  }

  /// 执行同步（使用 AsyncMutex 保证顺序执行）
  Future<SyncResult> _sync({bool full = false}) async {
    return await _syncMutex.run(() async {
      try {
        return await _doSync(full: full);
      } catch (e, stackTrace) {
        _logger.severe('同步执行异常', e, stackTrace);
        return SyncResult.failure(e.toString());
      }
    });
  }

  /// 执行同步任务
  Future<SyncResult> _doSync({bool full = false}) async {
    try {
      _updateStatus(
        SyncStatus.syncing,
        current: 0,
        total: 0,
      );
      
      final result = await _syncService.syncLocal(
        full: full,
        onProgress: (current, total) {
          _updateStatus(
            SyncStatus.syncing,
            current: current,
            total: total,
          );
        },
      );

      if (result.success) {
        _lastSyncedAt = DateTime.now();
        _updateStatus(
          SyncStatus.success,
          current: result.total,
          total: result.total,
          lastSyncedAt: _lastSyncedAt,
        );
        _logger.info('同步成功: $result');
        
        // 同步成功后，检查是否需要切换到数据库数据源
        await _checkAndSwitchDataSource();
      } else {
        _updateStatus(
          SyncStatus.error,
          current: 0,
          total: 0,
          error: result.error,
        );
        _logger.warning('同步失败: ${result.error}');
      }

      return result;
    } catch (e, stackTrace) {
      _logger.severe('同步异常', e, stackTrace);
      _updateStatus(
        SyncStatus.error,
        current: 0,
        total: 0,
        error: e.toString(),
      );
      return SyncResult.failure(e.toString());
    }
  }

  /// 更新状态
  void _updateStatus(
    SyncStatus status, {
    int? current,
    int? total,
    String? error,
    DateTime? lastSyncedAt,
  }) {
    _currentStatus = SyncStatusInfo(
      status: status,
      current: current ?? _currentStatus.current,
      total: total ?? _currentStatus.total,
      error: error ?? _currentStatus.error,
      lastSyncedAt: lastSyncedAt ?? _currentStatus.lastSyncedAt,
    );
    _statusController.add(_currentStatus);
  }

  /// 取消同步
  void cancel() {
    _syncService.cancel();
    _updateStatus(SyncStatus.idle);
  }

  /// 检查并切换数据源
  /// 如果数据库资产数量达到阈值，通知切换到数据库数据源
  Future<void> _checkAndSwitchDataSource() async {
    try {
      final selector = DataSourceSelector(database: _database);
      final assetCount = await selector.getDatabaseAssetCount();
      final threshold = selector.threshold;
      final isDatabaseAvailable = await selector.isDatabaseAvailable();
      
      _logger.info('检查数据源切换：数据库资产数量=$assetCount, 阈值=$threshold, 可用=$isDatabaseAvailable');
      
      if (isDatabaseAvailable) {
        _logger.info('✅ 数据库数据可用（资产数量=$assetCount > 阈值=$threshold），通知切换到数据库数据源');
        _dataSourceSwitchController.add(true);
      } else {
        _logger.info('数据库数据不足（资产数量=$assetCount ≤ 阈值=$threshold），保持使用 photo_manager 数据源');
      }
    } catch (e) {
      _logger.warning('检查数据源切换失败', e);
    }
  }

  /// 释放资源
  void dispose() {
    cancel();
    _statusController.close();
    _dataSourceSwitchController.close();
  }
}

