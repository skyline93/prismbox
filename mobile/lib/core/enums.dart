// lib/core/enums.dart

import 'package:freezed_annotation/freezed_annotation.dart';

enum LifecycleState { active, trashed }

enum SyncStatus {
  localOnly,
  uploading,
  synced,
  cloudOnly,
  downloading,
  error,
  uploadFailed,
  downloadFailed,
}

enum JobType {
  upload,
  deleteCloud,
  downloadThumbnail,
  syncCloudChanges,
  processCloudCreate,
  processCloudDelete,
}

enum JobStatus { pending, inProgress, failed }

enum NetworkConstraint { any, wifiOnly }

enum AlbumSource { local, remote }

enum MediaType {
  @JsonValue('IMAGE')
  image,
  @JsonValue('VIDEO')
  video,
}

enum ProcessingStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('COMPLETED')
  completed,
  @JsonValue('FAILED')
  failed,
}

enum DownloadJobStatus {
  pending, // 待处理
  running, // 下载中
  paused, // 已暂停
  success, // 成功
  failed, // 失败
  canceled,
  downloading, // 已取消
}

enum UploadJobStatus {
  pending, // 待处理
  initiating, // 初始化中 (调用 /initiate)
  uploading, // 正在上传分片
  completing, // 正在合并 (调用 /complete)
  success, // 成功
  failed, // 失败
}
