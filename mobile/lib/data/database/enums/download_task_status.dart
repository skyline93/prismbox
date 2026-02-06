// lib/data/database/enums/download_task_status.dart

/// 下载任务状态枚举
enum DownloadTaskStatus {
  /// 待处理（刚创建）
  pending,

  /// 已入队（等待执行）
  queued,

  /// 下载中
  downloading,

  /// 后处理中（写相册、删临时文件）
  processing,

  /// 已完成
  completed,

  /// 失败（可重试）
  failed,

  /// 永久失败
  permanentlyFailed,

  /// 已取消
  cancelled,
}
