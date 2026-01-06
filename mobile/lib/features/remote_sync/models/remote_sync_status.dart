// lib/features/remote_sync/models/remote_sync_status.dart

import 'package:prismbox/features/remote_sync/models/remote_sync_result.dart';

/// 远程同步状态信息
class RemoteSyncStatusInfo {
  /// 是否正在同步
  final bool isSyncing;

  /// 最后同步时间
  final DateTime? lastSyncTime;

  /// 同步结果
  final RemoteSyncResult? lastResult;

  RemoteSyncStatusInfo({
    this.isSyncing = false,
    this.lastSyncTime,
    this.lastResult,
  });

  /// 是否成功
  bool get isSuccess => lastResult?.isSuccess ?? false;

  /// 是否有错误
  bool get hasError => lastResult?.errors.isNotEmpty ?? false;

  /// 复制并更新
  RemoteSyncStatusInfo copyWith({
    bool? isSyncing,
    DateTime? lastSyncTime,
    RemoteSyncResult? lastResult,
  }) {
    return RemoteSyncStatusInfo(
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastResult: lastResult ?? this.lastResult,
    );
  }
}

