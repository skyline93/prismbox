// lib/features/local_sync/services/sync_coordinator.dart

import 'dart:async';
import 'package:logging/logging.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/features/local_sync/models/sync_result.dart';
import 'package:prismbox/features/local_sync/models/sync_status.dart';
import 'package:prismbox/features/local_sync/services/data_source_selector.dart';
import 'package:prismbox/features/local_sync/services/local_sync_service.dart';

/// 同步协调器
/// 协调后台同步任务，不阻塞 UI
class SyncCoordinator {
  final LocalSyncService _syncService;
  final AppDatabase _database;
  final Logger _logger = Logger('SyncCoordinator');
  
  /// 同步状态流控制器
  final _statusController = StreamController<SyncStatusInfo>.broadcast();
  
  /// 数据源切换通知流控制器
  final _dataSourceSwitchController = StreamController<bool>.broadcast();
  
  /// 当前同步任务
  Future<SyncResult>? _currentSyncTask;
  
  /// 最后同步时间
  DateTime? _lastSyncedAt;
  
  /// 数据新鲜度阈值（1小时）
  static const Duration _freshnessThreshold = Duration(hours: 1);
  
  /// 启动延迟（2秒）
  static const Duration _startDelay = Duration(seconds: 2);

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
    _logger.info('计划延迟自动同步（${_startDelay.inSeconds}秒后）');
    Future.delayed(_startDelay, () {
      _checkAndSync();
    });
  }

  /// 应用恢复时检查并同步
  void checkAndSyncOnResume() {
    _logger.info('应用恢复，检查数据新鲜度');
    _checkAndSync();
  }

  /// 手动触发同步
  /// 
  /// [full] 是否全量同步
  Future<SyncResult> syncManually({bool full = false}) async {
    if (_currentSyncTask != null) {
      _logger.warning('同步任务正在进行中，取消当前任务');
      _syncService.cancel();
      await _currentSyncTask;
    }

    return await _sync(full: full);
  }

  /// 检查并同步
  Future<void> _checkAndSync() async {
    try {
      // 检查数据新鲜度
      final isFresh = _lastSyncedAt != null &&
          DateTime.now().difference(_lastSyncedAt!) < _freshnessThreshold;

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

  /// 执行同步
  Future<SyncResult> _sync({bool full = false}) async {
    if (_currentSyncTask != null) {
      _logger.warning('同步任务正在进行中');
      return await _currentSyncTask!;
    }

    _currentSyncTask = _doSync(full: full);
    final result = await _currentSyncTask!;
    _currentSyncTask = null;
    return result;
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
      final isDatabaseAvailable = await selector.isDatabaseAvailable();
      
      if (isDatabaseAvailable) {
        _logger.info('数据库数据可用，通知切换到数据库数据源');
        _dataSourceSwitchController.add(true);
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

