import 'dart:convert';

import 'package:prismbox/data/database/app_database.dart';

/// Live Photo 任务子类型。
///
/// - [video]：上传 Live Photo 的视频部分；
/// - [image]：上传 Live Photo 的图片部分。
enum LivePhotoTaskPart {
  video,
  image,
}

/// 与 `UploadTaskEntity.livePhotoMetadataJson` 对应的 Live Photo 任务元数据。
///
/// 该结构用于在上传任务层面显式建模「Live Photo = 视频任务 + 图片任务」：
/// - 通过 [localAssetId] 关联本地资产；
/// - 通过 [isLivePhoto] 标记该任务是否属于 Live Photo；
/// - 通过 [part] 区分当前任务是「视频」还是「图片」子任务；
/// - 通过 [remoteVideoId] 记录已上传的视频资产远程 ID（仅在视频任务完成后填充）。
class LivePhotoUploadMetadata {
  const LivePhotoUploadMetadata({
    required this.localAssetId,
    required this.isLivePhoto,
    required this.part,
    this.remoteVideoId,
  });

  /// 本地资产 ID（与 `UploadTaskEntity.assetId` 一致，用于从任务恢复上下文）。
  final String localAssetId;

  /// 是否为 Live Photo 相关任务。
  final bool isLivePhoto;

  /// 当前子任务类型：视频 / 图片。
  final LivePhotoTaskPart part;

  /// 已上传的视频资产远程 ID（仅在视频任务完成后可用）。
  final String? remoteVideoId;

  LivePhotoUploadMetadata copyWith({
    String? localAssetId,
    bool? isLivePhoto,
    LivePhotoTaskPart? part,
    String? remoteVideoId,
  }) {
    return LivePhotoUploadMetadata(
      localAssetId: localAssetId ?? this.localAssetId,
      isLivePhoto: isLivePhoto ?? this.isLivePhoto,
      part: part ?? this.part,
      remoteVideoId: remoteVideoId ?? this.remoteVideoId,
    );
  }

  /// 将元数据转换为可序列化的 Map。
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'localAssetId': localAssetId,
      'isLivePhoto': isLivePhoto,
      'part': part.name,
      if (remoteVideoId != null) 'remoteVideoId': remoteVideoId,
    };
  }

  /// 从 Map 反序列化元数据。
  factory LivePhotoUploadMetadata.fromJson(Map<String, dynamic> json) {
    final partString = json['part'] as String?;

    final part = switch (partString) {
      'video' => LivePhotoTaskPart.video,
      'image' => LivePhotoTaskPart.image,
      _ => LivePhotoTaskPart.image,
    };

    return LivePhotoUploadMetadata(
      localAssetId: json['localAssetId'] as String? ?? '',
      isLivePhoto: json['isLivePhoto'] as bool? ?? false,
      part: part,
      remoteVideoId: json['remoteVideoId'] as String?,
    );
  }

  /// 序列化为 JSON 字符串，便于存入 `UploadTaskEntity.livePhotoMetadataJson`。
  String toJsonString() => jsonEncode(toJson());

  /// 从 JSON 字符串解析元数据。
  static LivePhotoUploadMetadata? fromJsonString(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }

    try {
      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) {
        return LivePhotoUploadMetadata.fromJson(decoded);
      }
      if (decoded is Map) {
        return LivePhotoUploadMetadata.fromJson(
          decoded.map(
            (key, value) => MapEntry(key.toString(), value),
          ),
        );
      }
    } catch (_) {
      // 解析失败时不抛出异常，避免影响上传流程，仅返回 null。
      return null;
    }

    return null;
  }
}

/// 为 `UploadTaskEntityData` 提供 Live Photo 元数据的便捷访问方法。
extension UploadTaskEntityLivePhotoMetadataX on UploadTaskEntityData {
  /// 从 `livePhotoMetadataJson` 解析出的 Live Photo 元数据。
  LivePhotoUploadMetadata? get livePhotoMetadata =>
      LivePhotoUploadMetadata.fromJsonString(this.livePhotoMetadataJson);

  /// 当前任务是否携带 Live Photo 元数据。
  bool get hasLivePhotoMetadata => livePhotoMetadata != null;
}

