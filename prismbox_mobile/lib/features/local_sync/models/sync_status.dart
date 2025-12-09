// lib/features/local_sync/models/sync_status.dart

/// 同步状态
enum SyncStatus {
  /// 空闲（未同步）
  idle,
  
  /// 同步中
  syncing,
  
  /// 同步成功
  success,
  
  /// 同步失败
  error,
}

/// 同步状态信息
class SyncStatusInfo {
  /// 当前状态
  final SyncStatus status;
  
  /// 当前进度（已处理数量）
  final int current;
  
  /// 总数量
  final int total;
  
  /// 错误信息（如果失败）
  final String? error;
  
  /// 最后同步时间
  final DateTime? lastSyncedAt;

  const SyncStatusInfo({
    this.status = SyncStatus.idle,
    this.current = 0,
    this.total = 0,
    this.error,
    this.lastSyncedAt,
  });

  /// 进度百分比（0.0 - 1.0）
  double get progress {
    if (total == 0) return 0.0;
    return current / total;
  }

  /// 是否正在同步
  bool get isSyncing => status == SyncStatus.syncing;

  /// 是否成功
  bool get isSuccess => status == SyncStatus.success;

  /// 是否失败
  bool get isError => status == SyncStatus.error;

  /// 复制并更新
  SyncStatusInfo copyWith({
    SyncStatus? status,
    int? current,
    int? total,
    String? error,
    DateTime? lastSyncedAt,
  }) {
    return SyncStatusInfo(
      status: status ?? this.status,
      current: current ?? this.current,
      total: total ?? this.total,
      error: error ?? this.error,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

