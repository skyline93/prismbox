// lib/features/remote_sync/services/remote_sync_coordinator.dart

import 'dart:async';
import 'package:logging/logging.dart';
import 'package:prismbox/core/config/sync_config.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/daos/remote_asset_dao.dart';
import 'package:prismbox/features/remote_sync/models/remote_sync_result.dart';
import 'package:prismbox/features/remote_sync/models/remote_sync_status.dart';
import 'package:prismbox/features/remote_sync/services/checkpoint_store.dart';
import 'package:prismbox/features/remote_sync/services/remote_sync_service.dart';
import 'package:prismbox/utils/async_mutex.dart';

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
  final _remoteSyncCompleteController =
      StreamController<RemoteSyncResult>.broadcast();

  /// 同步互斥锁（确保同一时间只有一个同步任务）
  final AsyncMutex _syncMutex = AsyncMutex();

  /// 当前同步状态
  RemoteSyncStatusInfo _currentStatus = RemoteSyncStatusInfo();

  /// 定时轮询定时器
  Timer? _pollingTimer;

  /// 当前轮询的用户 ID
  String? _pollingUserId;

  RemoteSyncCoordinator({
    required RemoteSyncService syncService,
    required AppDatabase database,
    required CheckpointStore checkpointStore,
  }) : _syncService = syncService,
       _database = database,
       _checkpointStore = checkpointStore;

  /// 同步状态流
  Stream<RemoteSyncStatusInfo> get statusStream => _statusController.stream;

  /// 远程同步完成通知流
  /// 当远程同步完成后，会发出通知，包含同步结果
  Stream<RemoteSyncResult> get remoteSyncCompleteStream =>
      _remoteSyncCompleteController.stream;

  /// 获取当前同步状态
  RemoteSyncStatusInfo get currentStatus => _currentStatus;

  /// 应用启动时自动同步（延迟执行）
  void startAutoSyncOnLaunch({String? userId}) {
    _logger.info('计划延迟自动同步（${SyncConfig.startDelay.inSeconds}秒后）');
    Future.delayed(SyncConfig.startDelay, () {
      if (userId != null) {
        _checkAndSyncRemote(userId: userId);
        // 启动定时轮询
        startPolling(userId: userId);
      }
    });
  }

  /// 应用恢复时检查并同步
  void checkAndSyncOnResume({String? userId}) {
    _logger.info('应用恢复，检查数据新鲜度');
    if (userId != null) {
      _checkAndSyncRemote(userId: userId);
      // 确保定时轮询正在运行
      if (_pollingTimer == null || _pollingUserId != userId) {
        startPolling(userId: userId);
      }
    }
  }

  /// 启动定时轮询
  ///
  /// [userId] 用户 ID
  /// [interval] 轮询间隔（默认使用 SyncConfig.remotePollingInterval）
  void startPolling({required String userId, Duration? interval}) {
    // 如果已经在轮询相同的用户，不需要重新启动
    if (_pollingTimer != null && _pollingUserId == userId) {
      _logger.fine('定时轮询已在运行: userId=$userId');
      return;
    }

    // 停止旧的轮询
    stopPolling();

    _pollingUserId = userId;
    final effectiveInterval = interval ?? SyncConfig.remotePollingInterval;

    final intervalSeconds = effectiveInterval.inSeconds;
    final intervalDisplay = intervalSeconds >= 60
        ? '${intervalSeconds ~/ 60}分钟'
        : '$intervalSeconds秒';
    _logger.info('启动定时轮询: userId=$userId, interval=$intervalDisplay');

    _pollingTimer = Timer.periodic(effectiveInterval, (_) {
      _logger.fine('定时轮询触发: userId=$userId');
      _checkAndSyncRemote(userId: userId);
    });
  }

  /// 停止定时轮询
  void stopPolling() {
    if (_pollingTimer != null) {
      _logger.info('停止定时轮询: userId=$_pollingUserId');
      _pollingTimer?.cancel();
      _pollingTimer = null;
      _pollingUserId = null;
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

  /// 统一的远程同步触发入口
  Future<void> _checkAndSyncRemote({
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
  ///
  /// **修复**：使用最后同步时间而不是本地资产更新时间
  /// 这样可以正确检测服务器上的新资产（其他设备上传的）
  Future<bool> _isDataFresh(String userId) async {
    try {
      // 1. 检查是否有 checkpoint（表示曾经同步过）
      final checkpoint = await _checkpointStore.getCheckpoint(
        userId,
        'assets_v1',
      );
      if (checkpoint == null) {
        // 没有 checkpoint，需要同步
        _logger.fine('没有 checkpoint，需要同步');
        return false;
      }

      // 2. 检查最后同步时间（从状态中获取）
      final lastSyncTime = _currentStatus.lastSyncTime;
      if (lastSyncTime == null) {
        // 没有最后同步时间，需要同步
        _logger.fine('没有最后同步时间，需要同步');
        return false;
      }

      // 3. 检查距离最后同步时间是否超过阈值
      final now = DateTime.now();
      final timeSinceLastSync = now.difference(lastSyncTime);
      final isFresh = timeSinceLastSync < SyncConfig.remoteFreshnessThreshold;

      if (isFresh) {
        _logger.fine(
          '数据新鲜，距离最后同步时间: ${timeSinceLastSync.inMinutes}分钟 '
          '(阈值: ${SyncConfig.remoteFreshnessThreshold.inMinutes}分钟)',
        );
      } else {
        _logger.fine(
          '数据不新鲜，距离最后同步时间: ${timeSinceLastSync.inMinutes}分钟 '
          '(阈值: ${SyncConfig.remoteFreshnessThreshold.inMinutes}分钟)',
        );
      }

      return isFresh;
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
    // 使用 AsyncMutex 确保同一时间只有一个同步任务
    return await _syncMutex.run(() async {
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
        final localCheckpoint = await _checkpointStore.getCheckpoint(
          userId,
          'assets_v1',
        );

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
        // **修复**：使用真正的最后同步时间，而不是当前时间减去阈值
        DateTime? updatedAfter;
        if (!shouldReset) {
          // 优先级1：使用状态中保存的最后同步时间（最快，但应用重启后会丢失）
          final lastSyncTime = _currentStatus.lastSyncTime;
          if (lastSyncTime != null) {
            updatedAfter = lastSyncTime;
            _logger.fine('使用状态中的最后同步时间: $lastSyncTime');
          } else {
            // 优先级2：从 checkpoint 的 lastSyncTime 获取（持久化，最可靠）
            final persistedSyncTime = await _checkpointStore.getLastSyncTime(
              userId,
              'assets_v1',
            );
            if (persistedSyncTime != null) {
              updatedAfter = persistedSyncTime;
              _logger.fine('使用持久化的最后同步时间: $updatedAfter');
            } else {
              // 最后备选：使用当前时间减去阈值（临时方案）
              updatedAfter = DateTime.now().subtract(SyncConfig.remoteFreshnessThreshold);
              _logger.warning('无法获取最后同步时间，使用临时方案: $updatedAfter');
            }
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

        // 记录同步完成时间
        final syncTime = DateTime.now();

        // 更新状态：同步完成
        _updateStatus(
          isSyncing: false,
          lastSyncTime: syncTime,
          lastResult: result,
        );

        // 保存同步时间到 checkpoint（如果同步成功）
        if (result.isSuccess) {
          final checkpoint = await _checkpointStore.getCheckpoint(
            userId,
            'assets_v1',
          );
          if (checkpoint != null) {
            // 更新 checkpoint 的 lastSyncTime
            await _checkpointStore.setCheckpointWithSyncTime(
              userId,
              'assets_v1',
              checkpoint,
              syncTime,
            );
            _logger.fine('已保存同步时间到 checkpoint: $syncTime');
          }
        }

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
        _updateStatus(isSyncing: false, lastResult: errorResult);

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
    stopPolling();
    _statusController.close();
    _remoteSyncCompleteController.close();
    cancel();
  }
}
