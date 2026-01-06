// lib/data/database/enums/auto_backup_mode.dart

/// 自动备份模式枚举
enum AutoBackupMode {
  /// 所有未备份（all_unbacked）
  /// 备份所有未备份的媒体资源，基于 lastBackupTime 进行增量筛选
  allUnbacked,
  
  /// 选中相册（selected_albums）
  /// 仅备份 backupSelection = selected 的相册中的资产
  selectedAlbums,
  
  /// 时间段（time_range）
  /// 仅备份指定时间范围内的媒体资源
  timeRange,
}

