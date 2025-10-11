// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MediaDetailImpl _$$MediaDetailImplFromJson(Map<String, dynamic> json) =>
    _$MediaDetailImpl(
      id: (json['id'] as num).toInt(),
      uuid: json['uuid'] as String,
      filename: json['filename'] as String,
      originalFilename: json['originalFilename'] as String,
      itemType: $enumDecode(_$MediaTypeEnumMap, json['itemType']),
      mimeType: json['mimeType'] as String,
      fileSize: (json['fileSize'] as num).toInt(),
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      mediaTakenAt: json['mediaTakenAt'] as String?,
      cameraMake: json['cameraMake'] as String?,
      cameraModel: json['cameraModel'] as String?,
      aperture: json['aperture'] as String?,
      shutterSpeed: json['shutterSpeed'] as String?,
      iso: (json['iso'] as num?)?.toInt(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      hash: json['hash'] as String,
      processingStatus:
          $enumDecode(_$ProcessingStatusEnumMap, json['processingStatus']),
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
      userID: (json['userID'] as num).toInt(),
    );

Map<String, dynamic> _$$MediaDetailImplToJson(_$MediaDetailImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'uuid': instance.uuid,
      'filename': instance.filename,
      'originalFilename': instance.originalFilename,
      'itemType': _$MediaTypeEnumMap[instance.itemType]!,
      'mimeType': instance.mimeType,
      'fileSize': instance.fileSize,
      'width': instance.width,
      'height': instance.height,
      'mediaTakenAt': instance.mediaTakenAt,
      'cameraMake': instance.cameraMake,
      'cameraModel': instance.cameraModel,
      'aperture': instance.aperture,
      'shutterSpeed': instance.shutterSpeed,
      'iso': instance.iso,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'hash': instance.hash,
      'processingStatus': _$ProcessingStatusEnumMap[instance.processingStatus]!,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'userID': instance.userID,
    };

const _$MediaTypeEnumMap = {
  MediaType.image: 'image',
  MediaType.video: 'video',
};

const _$ProcessingStatusEnumMap = {
  ProcessingStatus.pending: 'PENDING',
  ProcessingStatus.completed: 'COMPLETED',
  ProcessingStatus.failed: 'FAILED',
};

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

_$MediaListResponseImpl _$$MediaListResponseImplFromJson(
        Map<String, dynamic> json) =>
    _$MediaListResponseImpl(
      data: (json['data'] as List<dynamic>)
          .map((e) => MediaResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
    );

Map<String, dynamic> _$$MediaListResponseImplToJson(
        _$MediaListResponseImpl instance) =>
    <String, dynamic>{
      'data': instance.data,
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
    };

_$CheckHashesResponseImpl _$$CheckHashesResponseImplFromJson(
        Map<String, dynamic> json) =>
    _$CheckHashesResponseImpl(
      existingHashes: (json['existingHashes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$CheckHashesResponseImplToJson(
        _$CheckHashesResponseImpl instance) =>
    <String, dynamic>{
      'existingHashes': instance.existingHashes,
    };

_$MediaChangesResponseImpl _$$MediaChangesResponseImplFromJson(
        Map<String, dynamic> json) =>
    _$MediaChangesResponseImpl(
      created: (json['created'] as List<dynamic>)
          .map((e) => MediaResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      updated: (json['updated'] as List<dynamic>)
          .map((e) => MediaResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      deleted:
          (json['deleted'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$$MediaChangesResponseImplToJson(
        _$MediaChangesResponseImpl instance) =>
    <String, dynamic>{
      'created': instance.created,
      'updated': instance.updated,
      'deleted': instance.deleted,
    };
