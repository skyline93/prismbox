// lib/features/backup/models/asset_upload_status.dart

/// 资产上传状态枚举
enum AssetUploadStatus {
  /// 未上传（仅本地数据）
  notUploaded,
  
  /// 上传中
  uploading,
  
  /// 已上传
  uploaded,
  
  /// 上传失败
  failed,
}

/// Live Photo 上传状态枚举（从视频任务 + 图片任务组合计算）
enum LivePhotoUploadState {
  /// 还没有任何与 Live Photo 相关的上传任务
  none,

  /// 正在上传视频（图片任务尚未开始）
  uploadingVideo,

  /// 视频已完成，正在上传图片
  uploadingPhoto,

  /// 仅视频已成功上传，图片尚未成功
  videoOnlyUploaded,

  /// 仅图片已成功上传（理论上少见，兼容异常场景）
  photoOnlyUploaded,

  /// 视频与图片均已成功上传
  bothUploaded,

  /// 视频上传失败（图片尚未成功）
  failedVideo,

  /// 图片上传失败（视频已成功或不存在）
  failedPhoto,

  /// 视频与图片都处于失败状态
  failedBoth,
}

/// 资产上传状态信息
class AssetUploadStatusInfo {
  /// 当前状态
  final AssetUploadStatus status;
  
  /// 上传进度（0.0 - 1.0），仅在上传中时有效
  final double? progress;
  
  /// 错误信息，仅在失败时有效
  final String? errorMessage;

  /// Live Photo 聚合上传状态（非 Live Photo 资产为 null）
  final LivePhotoUploadState? livePhotoState;
  
  const AssetUploadStatusInfo({
    required this.status,
    this.progress,
    this.errorMessage,
    this.livePhotoState,
  });
  
  /// 是否正在上传
  bool get isUploading => status == AssetUploadStatus.uploading;
  
  /// 是否已上传
  bool get isUploaded => status == AssetUploadStatus.uploaded;
  
  /// 是否上传失败
  bool get isFailed => status == AssetUploadStatus.failed;
  
  /// 是否未上传
  bool get isNotUploaded => status == AssetUploadStatus.notUploaded;
  
  /// 复制并更新
  AssetUploadStatusInfo copyWith({
    AssetUploadStatus? status,
    double? progress,
    String? errorMessage,
    LivePhotoUploadState? livePhotoState,
  }) {
    return AssetUploadStatusInfo(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
      livePhotoState: livePhotoState ?? this.livePhotoState,
    );
  }
}

