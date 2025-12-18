// lib/features/remote_sync/services/remote_sync_coordinator.dart

import 'dart:async';
import 'package:logging/logging.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/daos/remote_asset_dao.dart';
import 'package:prismbox/features/remote_sync/models/remote_sync_result.dart';
import 'package:prismbox/features/remote_sync/models/remote_sync_status.dart';
import 'package:prismbox/features/remote_sync/services/checkpoint_store.dart';
import 'package:prismbox/features/remote_sync/services/remote_sync_service.dart';
import 'package:synchronized/synchronized.dart';

/// 远程同步协调器
/// 负责协调后台同步任务，管理同步状态
class RemoteSyncCoordinator {
  final RemoteSyncService _syncService;
  final AppDatabase _database;
  final CheckpointStore _checkpointStore;
  final Logger _logger = Logger('RemoteSyncCoordinator');
  
  /// 同步状态流控制器
  final _statusController = StreamController<RemoteSyncStatusInfo>.broadcast();
  
  /// 远程同步完成通知流控制器
  final _remoteSyncCompleteController = StreamController<RemoteSyncResult>.broadcast();
  
  /// 同步锁（确保同一时间只有一个同步任务）
  final _syncLock = Lock();
  
  /// 当前同步状态
  RemoteSyncStatusInfo _currentStatus = RemoteSyncStatusInfo();
  
  /// 数据新鲜度阈值（30分钟）
  static const Duration _dataFreshnessThreshold = Duration(minutes: 30);

  RemoteSyncCoordinator({
    required RemoteSyncService syncService,
    required AppDatabase database,
    required CheckpointStore checkpointStore,
  })  : _syncService = syncService,
        _database = database,
        _checkpointStore = checkpointStore;

  /// 同步状态流
  Stream<RemoteSyncStatusInfo> get statusStream => _statusController.stream;

  /// 远程同步完成通知流
  /// 当远程同步完成后，会发出通知，包含同步结果
  Stream<RemoteSyncResult> get remoteSyncCompleteStream => _remoteSyncCompleteController.stream;

  /// 获取当前同步状态
  RemoteSyncStatusInfo get currentStatus => _currentStatus;

  /// 应用启动时自动同步（延迟执行）
  void startAutoSyncOnLaunch({String? userId}) {
    _logger.info('计划延迟自动同步（2秒后）');
    Future.delayed(const Duration(seconds: 2), () {
      if (userId != null) {
        _checkAndSync(userId: userId);
      }
    });
  }

  /// 应用恢复时检查并同步
  void checkAndSyncOnResume({String? userId}) {
    _logger.info('应用恢复，检查数据新鲜度');
    if (userId != null) {
      _checkAndSync(userId: userId);
    }
  }

  /// 手动触发同步
  /// 
  /// [userId] 用户 ID
  /// [full] 是否全量同步
  Future<RemoteSyncResult> syncManually({
    required String userId,
    bool full = false,
  }) async {
    return await _sync(userId: userId, full: full, force: true);
  }

  /// 统一的同步触发入口
  Future<void> _checkAndSync({
    required String userId,
    bool force = false,
  }) async {
    // 检查数据新鲜度
    final isFresh = await _isDataFresh(userId);
    if (isFresh && !force) {
      _logger.info('数据新鲜，跳过同步');
      return;
    }

    // 执行增量同步
    await _sync(userId: userId, full: false, force: force);
  }

  /// 检查数据是否新鲜
  Future<bool> _isDataFresh(String userId) async {
    try {
      final remoteDao = RemoteAssetDao(_database);
      final assets = await remoteDao.getUserAssets(userId);
      
      if (assets.isEmpty) {
        // 如果没有数据，需要全量同步
        return false;
      }

      // 检查最后同步时间
      final checkpoint = await _checkpointStore.getCheckpoint(userId, 'assets_v1');
      if (checkpoint == null) {
        // 没有 checkpoint，需要同步
        return false;
      }

      // 检查是否有最近更新的资产
      final now = DateTime.now();
      final recentAssets = assets.where((asset) {
        final timeSinceUpdate = now.difference(asset.updatedAt);
        return timeSinceUpdate < _dataFreshnessThreshold;
      });

      // 如果有最近更新的资产，数据可能不新鲜
      return recentAssets.isEmpty;
    } catch (e, stackTrace) {
      _logger.warning('检查数据新鲜度失败', e, stackTrace);
      // 出错时认为数据不新鲜，触发同步
      return false;
    }
  }

  /// 执行同步
  Future<RemoteSyncResult> _sync({
    required String userId,
    bool full = false,
    bool force = false,
  }) async {
    // 使用锁确保同一时间只有一个同步任务
    return await _syncLock.synchronized(() async {
      // 检查是否正在同步
      if (_currentStatus.isSyncing) {
        _logger.info('同步已在进行中，跳过');
        return _currentStatus.lastResult ?? 
            RemoteSyncResult(duration: Duration.zero);
      }

      // 更新状态：开始同步
      _updateStatus(isSyncing: true);

      try {
        // 检测是否是重新安装场景
        // 如果本地数据库为空（没有远程资产），但设备ID可能对应服务端的检查点
        // 这种情况下应该强制全量同步（reset=true）
        final remoteDao = RemoteAssetDao(_database);
        final localAssets = await remoteDao.getUserAssets(userId);
        final localCheckpoint = await _checkpointStore.getCheckpoint(userId, 'assets_v1');
        
        // 如果是首次安装（本地没有数据且没有检查点），强制全量同步
        // 这样可以确保即使服务端有检查点，也会被清除并重新同步所有数据
        final isFirstInstall = localAssets.isEmpty && localCheckpoint == null;
        
        // 如果用户明确要求全量同步，或者检测到首次安装，使用 reset=true
        final shouldReset = full || isFirstInstall;
        
        if (isFirstInstall) {
          _logger.info('检测到首次安装（本地无数据且无检查点），强制全量同步');
        }

        _logger.info('开始${shouldReset ? '全量' : '增量'}同步: userId=$userId');

        // 获取上次同步时间（用于增量同步）
        DateTime? updatedAfter;
        if (!shouldReset) {
          final checkpoint = await _checkpointStore.getCheckpoint(userId, 'assets_v1');
          if (checkpoint != null) {
            // 如果有 checkpoint，使用增量同步
            // 注意：这里简化处理，实际应该从 checkpoint 解析时间戳
            // 暂时使用当前时间减去阈值作为增量同步起点
            updatedAfter = DateTime.now().subtract(_dataFreshnessThreshold);
          }
        }

        // 执行同步
        final result = await _syncService.syncRemoteStream(
          userId: userId,
          reset: shouldReset, // 使用 shouldReset 而不是 full
          updatedAfter: updatedAfter,
          onProgress: (current, total) {
            _logger.fine('同步进度: $current${total > 0 ? '/$total' : ''}');
          },
        );

        // 更新状态：同步完成
        _updateStatus(
          isSyncing: false,
          lastSyncTime: DateTime.now(),
          lastResult: result,
        );

        _logger.info('同步完成: $result');
        
        // 发送远程同步完成通知
        if (!_remoteSyncCompleteController.isClosed) {
          _remoteSyncCompleteController.add(result);
        }
        
        return result;
      } catch (e, stackTrace) {
        _logger.severe('同步失败', e, stackTrace);
        
        // 更新状态：同步失败
        final errorResult = RemoteSyncResult(
          errors: [e.toString()],
          duration: Duration.zero,
        );
        _updateStatus(
          isSyncing: false,
          lastResult: errorResult,
        );
        
        return errorResult;
      }
    });
  }

  /// 更新同步状态
  void _updateStatus({
    bool? isSyncing,
    DateTime? lastSyncTime,
    RemoteSyncResult? lastResult,
  }) {
    _currentStatus = _currentStatus.copyWith(
      isSyncing: isSyncing ?? _currentStatus.isSyncing,
      lastSyncTime: lastSyncTime ?? _currentStatus.lastSyncTime,
      lastResult: lastResult ?? _currentStatus.lastResult,
    );
    _statusController.add(_currentStatus);
  }

  /// 取消同步
  void cancel() {
    _syncService.cancel();
    _updateStatus(isSyncing: false);
    _logger.info('同步已取消');
  }

  /// 释放资源
  void dispose() {
    _statusController.close();
    _remoteSyncCompleteController.close();
    cancel();
  }
}

