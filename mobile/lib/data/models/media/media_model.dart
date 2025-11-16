// lib/data/models/media/media_model.dart

// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mobile/core/enums.dart';

part 'media_model.freezed.dart';
part 'media_model.g.dart';

@freezed
class MediaDetail with _$MediaDetail {
  const factory MediaDetail({
    required int id,
    required String uuid,
    required String filename,
    required String originalFilename,
    required MediaType itemType,
    required String mimeType,
    required int fileSize,
    int? width,
    int? height,
    String? mediaTakenAt,
    String? cameraMake,
    String? cameraModel,
    String? aperture,
    String? shutterSpeed,
    int? iso,
    double? latitude,
    double? longitude,
    required String hash,
    required ProcessingStatus processingStatus,
    required String createdAt,
    required String updatedAt,
    required int userID,
  }) = _MediaDetail;

  factory MediaDetail.fromJson(Map<String, dynamic> json) =>
      _$MediaDetailFromJson(json);
}

@freezed
class MediaResponse with _$MediaResponse {
  const factory MediaResponse({
    required String uuid,
    required String filename,
    @JsonKey(name: 'original_filename') required String originalFilename,
    @JsonKey(name: 'item_type') required String itemType,
    @JsonKey(name: 'hash') required String hash,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
    @JsonKey(name: 'media_taken_at') String? mediaTakenAt,
    required int width,
    required int height,
    @JsonKey(name: 'download_url') String? downloadUrl,
    @JsonKey(name: 'preview_url') String? previewUrl,
    @JsonKey(name: 'thumbnail_url') String? thumbnailUrl,
  }) = _MediaResponse;

  factory MediaResponse.fromJson(Map<String, dynamic> json) =>
      _$MediaResponseFromJson(json);
}

/// 媒体分页响应
@freezed
class MediaListResponse with _$MediaListResponse {
  const factory MediaListResponse({
    required List<MediaResponse> data,
    required int total,
    required int page,
    required int limit,
  }) = _MediaListResponse;

  factory MediaListResponse.fromJson(Map<String, dynamic> json) =>
      _$MediaListResponseFromJson(json);
}

@freezed
class CheckHashesRequest with _$CheckHashesRequest {
  const factory CheckHashesRequest({required List<String> hashes}) =
      _CheckHashesRequest;
}

@freezed
class CheckHashesResponse with _$CheckHashesResponse {
  const factory CheckHashesResponse({required List<String> existingHashes}) =
      _CheckHashesResponse;

  factory CheckHashesResponse.fromJson(Map<String, dynamic> json) =>
      _$CheckHashesResponseFromJson(json);
}

@freezed
class MediaChangesResponse with _$MediaChangesResponse {
  const factory MediaChangesResponse({
    required List<MediaResponse> created,
    required List<MediaResponse> updated,
    required List<String> deleted,
  }) = _MediaChangesResponse;

  factory MediaChangesResponse.fromJson(Map<String, dynamic> json) =>
      _$MediaChangesResponseFromJson(json);
}

/// API通用响应格式
@immutable
class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;

  // 构造函数
  const ApiResponse({required this.code, required this.message, this.data});

  // fromJson 工厂构造函数
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return ApiResponse<T>(
      code: json['code'] as int,
      message: json['message'] as String,
      // 只有当 'data' 字段存在且不为 null 时才进行转换
      data: json['data'] != null ? fromJsonT(json['data']) : null,
    );
  }

  // copyWith 方法
  ApiResponse<T> copyWith({int? code, String? message, T? data}) {
    return ApiResponse<T>(
      code: code ?? this.code,
      message: message ?? this.message,
      data: data ?? this.data,
    );
  }

  // toString 方法，方便调试时打印信息
  @override
  String toString() {
    return 'ApiResponse<T>(code: $code, message: $message, data: $data)';
  }

  // == 操作符重写，用于比较两个 ApiResponse 实例是否相等
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ApiResponse<T> &&
        other.code == code &&
        other.message == message &&
        other.data == data;
  }

  // hashCode 的重写，与 == 保持一致
  @override
  int get hashCode => code.hashCode ^ message.hashCode ^ data.hashCode;
}
