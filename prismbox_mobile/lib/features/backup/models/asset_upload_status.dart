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

/// 资产上传状态信息
class AssetUploadStatusInfo {
  /// 当前状态
  final AssetUploadStatus status;
  
  /// 上传进度（0.0 - 1.0），仅在上传中时有效
  final double? progress;
  
  /// 错误信息，仅在失败时有效
  final String? errorMessage;
  
  const AssetUploadStatusInfo({
    required this.status,
    this.progress,
    this.errorMessage,
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
  }) {
    return AssetUploadStatusInfo(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

