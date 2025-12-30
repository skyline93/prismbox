// lib/data/database/enums/migration_status.dart

/// 迁移状态枚举
/// 用于跟踪资产迁移到私有空间或移回系统相册的操作状态
enum MigrationStatus {
  /// 初始状态，无操作进行
  none,
  
  /// 操作进行中（迁移到私有空间或移回系统相册）
  pending,
  
  /// 操作成功完成
  success,
  
  /// 操作失败，需要重试或清理
  failed,
}

