// lib/features/remote_sync/models/remote_sync_result.dart

/// 远程同步结果
class RemoteSyncResult {
  /// 新增的资产数量
  final int addedCount;

  /// 更新的资产数量
  final int updatedCount;

  /// 删除的资产数量
  final int deletedCount;

  /// 错误列表
  final List<String> errors;

  /// 同步耗时
  final Duration duration;

  /// 总处理的资产数量
  int get total => addedCount + updatedCount + deletedCount;

  /// 是否成功
  bool get isSuccess => errors.isEmpty;

  RemoteSyncResult({
    this.addedCount = 0,
    this.updatedCount = 0,
    this.deletedCount = 0,
    this.errors = const [],
    required this.duration,
  });

  /// 复制并更新
  RemoteSyncResult copyWith({
    int? addedCount,
    int? updatedCount,
    int? deletedCount,
    List<String>? errors,
    Duration? duration,
  }) {
    return RemoteSyncResult(
      addedCount: addedCount ?? this.addedCount,
      updatedCount: updatedCount ?? this.updatedCount,
      deletedCount: deletedCount ?? this.deletedCount,
      errors: errors ?? this.errors,
      duration: duration ?? this.duration,
    );
  }

  @override
  String toString() {
    return 'RemoteSyncResult(added: $addedCount, updated: $updatedCount, '
        'deleted: $deletedCount, errors: ${errors.length}, '
        'duration: ${duration.inSeconds}s)';
  }
}

