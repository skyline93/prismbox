// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'media_model.freezed.dart';
part 'media_model.g.dart';

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
    @JsonKey(name: 'download_url') required String downloadUrl,
    @JsonKey(name: 'preview_url') required String previewUrl,
    @JsonKey(name: 'thumbnail_url') required String thumbnailUrl,
  }) = _MediaResponse;

  factory MediaResponse.fromJson(Map<String, dynamic> json) =>
      _$MediaResponseFromJson(json);
}

@freezed
class CheckHashesRequest with _$CheckHashesRequest {
  const factory CheckHashesRequest({required List<String> hashes}) =
      _CheckHashesRequest;

  factory CheckHashesRequest.fromJson(Map<String, dynamic> json) =>
      _$CheckHashesRequestFromJson(json);
}

@freezed
class CheckHashesResponse with _$CheckHashesResponse {
  const factory CheckHashesResponse({
    @JsonKey(name: 'existing_hashes') required List<String> existingHashes,
  }) = _CheckHashesResponse;

  factory CheckHashesResponse.fromJson(Map<String, dynamic> json) =>
      _$CheckHashesResponseFromJson(json);
}
