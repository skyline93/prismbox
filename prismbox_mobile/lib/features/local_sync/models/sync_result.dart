// lib/features/local_sync/models/sync_result.dart

/// 同步结果
class SyncResult {
  /// 新增的资产数量
  final int added;
  
  /// 更新的资产数量
  final int updated;
  
  /// 删除的资产数量
  final int deleted;
  
  /// 总处理的资产数量
  int get total => added + updated + deleted;
  
  /// 是否成功
  final bool success;
  
  /// 错误信息（如果失败）
  final String? error;

  const SyncResult({
    this.added = 0,
    this.updated = 0,
    this.deleted = 0,
    this.success = true,
    this.error,
  });

  /// 创建成功结果
  factory SyncResult.success({
    int added = 0,
    int updated = 0,
    int deleted = 0,
  }) {
    return SyncResult(
      added: added,
      updated: updated,
      deleted: deleted,
      success: true,
    );
  }

  /// 创建失败结果
  factory SyncResult.failure(String error) {
    return SyncResult(
      success: false,
      error: error,
    );
  }

  @override
  String toString() {
    if (!success) {
      return 'SyncResult(failed: $error)';
    }
    return 'SyncResult(added: $added, updated: $updated, deleted: $deleted)';
  }
}

