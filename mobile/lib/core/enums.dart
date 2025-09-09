// lib/core/enums.dart

import 'package:freezed_annotation/freezed_annotation.dart';

enum SyncStatus {
  localOnlyNotSelected,
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
  downloadOriginal,
  downloadThumbnail,
  syncCloudChanges,
  processCloudCreate,
  processCloudDelete,
}

enum JobStatus { pending, inProgress, failed }

enum NetworkConstraint { any, wifiOnly }

enum AlbumSource { local, remote }

/// 媒体类型枚举
enum MediaType {
  @JsonValue('IMAGE')
  image,
  @JsonValue('VIDEO')
  video,
}

/// 处理状态枚举
enum ProcessingStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('COMPLETED')
  completed,
  @JsonValue('FAILED')
  failed,
}

/// 下载任务的状态枚举
enum DownloadJobStatus {
  pending, // 待处理
  running, // 下载中
  paused, // 已暂停
  success, // 成功
  failed, // 失败
  canceled, downloading, // 已取消
}

/// 上传任务的状态枚举
enum UploadJobStatus {
  pending, // 待处理
  initiating, // 初始化中 (调用 /initiate)
  uploading, // 正在上传分片
  completing, // 正在合并 (调用 /complete)
  success, // 成功
  failed, // 失败
}
