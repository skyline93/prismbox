// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MediaResponseImpl _$$MediaResponseImplFromJson(Map<String, dynamic> json) =>
    _$MediaResponseImpl(
      uuid: json['uuid'] as String,
      filename: json['filename'] as String,
      originalFilename: json['original_filename'] as String,
      itemType: json['item_type'] as String,
      hash: json['hash'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      mediaTakenAt: json['media_taken_at'] as String?,
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      downloadUrl: json['download_url'] as String,
      previewUrl: json['preview_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String,
    );

Map<String, dynamic> _$$MediaResponseImplToJson(_$MediaResponseImpl instance) =>
    <String, dynamic>{
      'uuid': instance.uuid,
      'filename': instance.filename,
      'original_filename': instance.originalFilename,
      'item_type': instance.itemType,
      'hash': instance.hash,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'media_taken_at': instance.mediaTakenAt,
      'width': instance.width,
      'height': instance.height,
      'download_url': instance.downloadUrl,
      'preview_url': instance.previewUrl,
      'thumbnail_url': instance.thumbnailUrl,
    };

_$CheckHashesRequestImpl _$$CheckHashesRequestImplFromJson(
        Map<String, dynamic> json) =>
    _$CheckHashesRequestImpl(
      hashes:
          (json['hashes'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$$CheckHashesRequestImplToJson(
        _$CheckHashesRequestImpl instance) =>
    <String, dynamic>{
      'hashes': instance.hashes,
    };

_$CheckHashesResponseImpl _$$CheckHashesResponseImplFromJson(
        Map<String, dynamic> json) =>
    _$CheckHashesResponseImpl(
      existingHashes: (json['existing_hashes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$CheckHashesResponseImplToJson(
        _$CheckHashesResponseImpl instance) =>
    <String, dynamic>{
      'existing_hashes': instance.existingHashes,
    };
