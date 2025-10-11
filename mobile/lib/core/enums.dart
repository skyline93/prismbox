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
  image,
  video; // Dart 3 中枚举成员末尾可以用分号

  /// 从字符串解析，如果找不到匹配项则返回 null
  static MediaType? fromString(String value) {
    for (final type in MediaType.values) {
      if (type.name == value) {
        return type;
      }
    }
    return null;
  }

  /// 从字符串解析，如果找不到匹配项则抛出异常
  static MediaType fromStringStrict(String value) {
    return MediaType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => throw ArgumentError('"$value" 不是一个有效的 MediaType'),
    );
  }
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
  // [阶段三 新增]: 用于表示任务因网络限制而等待
  waitingForWifi,
}
