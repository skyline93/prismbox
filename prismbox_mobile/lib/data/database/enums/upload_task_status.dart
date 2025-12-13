// lib/data/database/enums/upload_task_status.dart

/// 上传任务状态枚举
enum UploadTaskStatus {
  /// 待上传
  pending,
  
  /// 上传中
  uploading,
  
  /// 已暂停
  paused,
  
  /// 已完成
  completed,
  
  /// 失败（可重试）
  failed,
  
  /// 永久失败（达到最大重试次数）
  permanentlyFailed,
  
  /// 已取消
  cancelled,
}

