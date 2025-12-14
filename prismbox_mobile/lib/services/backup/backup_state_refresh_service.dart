// lib/services/backup/backup_state_refresh_service.dart

import 'dart:async';
import 'package:logging/logging.dart';
import 'package:prismbox/services/backup/providers/backup_state_provider.dart';

/// 备份状态刷新服务
/// 
/// **职责**：
/// - 管理状态刷新的定时器和刷新策略
/// - 处理定时器的生命周期（启动、停止、销毁）
/// - 提供刷新状态查询接口
/// - 处理异步调用和错误重试
/// 
/// **设计原则**：
/// - 单一职责：只负责定时器和刷新逻辑
/// - 可测试：可以独立测试，不依赖 Riverpod
/// - 可扩展：可以轻松添加新的刷新策略（如自适应频率、WebSocket等）
/// - 错误处理：正确处理异步调用和连续失败
class BackupStateRefreshService {
  Timer? _refreshTimer;
  String? _currentUserId;
  BackupStateNotifier? _notifier;
  bool _isRunning = false;
  bool _isDisposed = false;
  int _consecutiveFailures = 0;
  static const int maxConsecutiveFailures = 3;
  final Logger _logger = Logger('BackupStateRefreshService');
  
  /// 刷新间隔
  final Duration refreshInterval;
  
  /// 是否自动启动（在 start 时立即刷新一次）
  final bool autoRefreshOnStart;
  
  BackupStateRefreshService({
    this.refreshInterval = const Duration(seconds: 1),
    this.autoRefreshOnStart = true,
  });
  
  /// 开始刷新
  /// 
  /// [userId] 用户 ID
  /// [notifier] 备份状态 Notifier，用于触发刷新
  Future<void> start(String userId, BackupStateNotifier notifier) async {
    if (_isDisposed) {
      return;
    }
    
    // 如果已经在运行且用户 ID 相同，不需要重新启动
    if (_isRunning && _currentUserId == userId && _notifier == notifier) {
      return;
    }
    
    // 先停止旧的定时器
    stop();
    
    _currentUserId = userId;
    _notifier = notifier;
    _isRunning = true;
    _consecutiveFailures = 0;  // 重置失败计数
    
    // 立即刷新一次（如果启用）
    if (autoRefreshOnStart) {
      try {
        await _notifier?.refresh(userId);  // ✅ 使用 await 正确处理异步
        _consecutiveFailures = 0;  // 重置失败计数
      } catch (e, stackTrace) {
        _logger.warning(
          'Failed to refresh on start',
          e,
          stackTrace,
        );
        _consecutiveFailures++;
        // 如果首次刷新就失败，仍然启动定时器，让后续重试
      }
    }
    
    // 启动定时器
    _refreshTimer = Timer.periodic(refreshInterval, (_) async {
      if (!_isRunning || _isDisposed || _currentUserId == null || _notifier == null) {
        return;
      }
      
      try {
        await _notifier!.refresh(_currentUserId!);
        _consecutiveFailures = 0;  // 重置失败计数
      } catch (e, stackTrace) {
        _consecutiveFailures++;
        _logger.warning(
          'Failed to refresh (consecutive failures: $_consecutiveFailures)',
          e,
          stackTrace,
        );
        
        // 如果连续失败太多次，停止刷新
        if (_consecutiveFailures >= maxConsecutiveFailures) {
          _logger.severe(
            'Too many consecutive failures, stopping refresh',
          );
          stop();
        }
      }
    });
  }
  
  /// 停止刷新
  void stop() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _isRunning = false;
    // 注意：不清理 _currentUserId 和 _notifier，以便可以重新启动
  }
  
  /// 是否正在运行
  bool get isRunning => _isRunning && !_isDisposed;
  
  /// 当前用户 ID
  String? get currentUserId => _currentUserId;
  
  /// 连续失败次数
  int get consecutiveFailures => _consecutiveFailures;
  
  /// 销毁服务，清理所有资源
  void dispose() {
    if (_isDisposed) {
      return;
    }
    
    _isDisposed = true;
    stop();
    _currentUserId = null;
    _notifier = null;
    _consecutiveFailures = 0;
  }
}

