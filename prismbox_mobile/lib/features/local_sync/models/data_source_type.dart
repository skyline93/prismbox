// lib/features/local_sync/models/data_source_type.dart

/// 数据源类型
enum DataSourceType {
  /// 数据库数据源（优先使用）
  database,
  
  /// photo_manager 数据源（快速路径）
  photoManager,
}

