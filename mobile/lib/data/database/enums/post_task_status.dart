// lib/data/database/enums/post_task_status.dart

/// 帖子任务状态枚举
enum PostTaskStatus {
  /// 待处理（刚创建）
  pending,
  
  /// 上传媒体中
  uploadingMedia,
  
  /// 媒体上传完成
  mediaUploaded,
  
  /// 创建帖子中
  creatingPost,
  
  /// 已完成
  completed,
  
  /// 失败
  failed,
}

