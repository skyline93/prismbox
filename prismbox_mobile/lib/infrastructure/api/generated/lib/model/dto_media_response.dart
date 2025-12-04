//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DtoMediaResponse {
  /// Returns a new [DtoMediaResponse] instance.
  DtoMediaResponse({
    this.backupStatus,
    this.createdAt,
    this.downloadUrl,
    this.fileSize,
    this.filename,
    this.hash,
    this.height,
    this.itemType,
    this.localPath,
    this.mediaTakenAt,
    this.mimeType,
    this.originalFilename,
    this.previewUrl,
    this.processingStatus,
    this.thumbnailUrl,
    this.updatedAt,
    this.userId,
    this.uuid,
    this.width,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? backupStatus;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? createdAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? downloadUrl;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? fileSize;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? filename;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? hash;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? height;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? itemType;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? localPath;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? mediaTakenAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? mimeType;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? originalFilename;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? previewUrl;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? processingStatus;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? thumbnailUrl;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? updatedAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? userId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? uuid;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? width;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DtoMediaResponse &&
    other.backupStatus == backupStatus &&
    other.createdAt == createdAt &&
    other.downloadUrl == downloadUrl &&
    other.fileSize == fileSize &&
    other.filename == filename &&
    other.hash == hash &&
    other.height == height &&
    other.itemType == itemType &&
    other.localPath == localPath &&
    other.mediaTakenAt == mediaTakenAt &&
    other.mimeType == mimeType &&
    other.originalFilename == originalFilename &&
    other.previewUrl == previewUrl &&
    other.processingStatus == processingStatus &&
    other.thumbnailUrl == thumbnailUrl &&
    other.updatedAt == updatedAt &&
    other.userId == userId &&
    other.uuid == uuid &&
    other.width == width;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (backupStatus == null ? 0 : backupStatus!.hashCode) +
    (createdAt == null ? 0 : createdAt!.hashCode) +
    (downloadUrl == null ? 0 : downloadUrl!.hashCode) +
    (fileSize == null ? 0 : fileSize!.hashCode) +
    (filename == null ? 0 : filename!.hashCode) +
    (hash == null ? 0 : hash!.hashCode) +
    (height == null ? 0 : height!.hashCode) +
    (itemType == null ? 0 : itemType!.hashCode) +
    (localPath == null ? 0 : localPath!.hashCode) +
    (mediaTakenAt == null ? 0 : mediaTakenAt!.hashCode) +
    (mimeType == null ? 0 : mimeType!.hashCode) +
    (originalFilename == null ? 0 : originalFilename!.hashCode) +
    (previewUrl == null ? 0 : previewUrl!.hashCode) +
    (processingStatus == null ? 0 : processingStatus!.hashCode) +
    (thumbnailUrl == null ? 0 : thumbnailUrl!.hashCode) +
    (updatedAt == null ? 0 : updatedAt!.hashCode) +
    (userId == null ? 0 : userId!.hashCode) +
    (uuid == null ? 0 : uuid!.hashCode) +
    (width == null ? 0 : width!.hashCode);

  @override
  String toString() => 'DtoMediaResponse[backupStatus=$backupStatus, createdAt=$createdAt, downloadUrl=$downloadUrl, fileSize=$fileSize, filename=$filename, hash=$hash, height=$height, itemType=$itemType, localPath=$localPath, mediaTakenAt=$mediaTakenAt, mimeType=$mimeType, originalFilename=$originalFilename, previewUrl=$previewUrl, processingStatus=$processingStatus, thumbnailUrl=$thumbnailUrl, updatedAt=$updatedAt, userId=$userId, uuid=$uuid, width=$width]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.backupStatus != null) {
      json[r'backup_status'] = this.backupStatus;
    } else {
      json[r'backup_status'] = null;
    }
    if (this.createdAt != null) {
      json[r'created_at'] = this.createdAt;
    } else {
      json[r'created_at'] = null;
    }
    if (this.downloadUrl != null) {
      json[r'download_url'] = this.downloadUrl;
    } else {
      json[r'download_url'] = null;
    }
    if (this.fileSize != null) {
      json[r'file_size'] = this.fileSize;
    } else {
      json[r'file_size'] = null;
    }
    if (this.filename != null) {
      json[r'filename'] = this.filename;
    } else {
      json[r'filename'] = null;
    }
    if (this.hash != null) {
      json[r'hash'] = this.hash;
    } else {
      json[r'hash'] = null;
    }
    if (this.height != null) {
      json[r'height'] = this.height;
    } else {
      json[r'height'] = null;
    }
    if (this.itemType != null) {
      json[r'item_type'] = this.itemType;
    } else {
      json[r'item_type'] = null;
    }
    if (this.localPath != null) {
      json[r'local_path'] = this.localPath;
    } else {
      json[r'local_path'] = null;
    }
    if (this.mediaTakenAt != null) {
      json[r'media_taken_at'] = this.mediaTakenAt;
    } else {
      json[r'media_taken_at'] = null;
    }
    if (this.mimeType != null) {
      json[r'mime_type'] = this.mimeType;
    } else {
      json[r'mime_type'] = null;
    }
    if (this.originalFilename != null) {
      json[r'original_filename'] = this.originalFilename;
    } else {
      json[r'original_filename'] = null;
    }
    if (this.previewUrl != null) {
      json[r'preview_url'] = this.previewUrl;
    } else {
      json[r'preview_url'] = null;
    }
    if (this.processingStatus != null) {
      json[r'processing_status'] = this.processingStatus;
    } else {
      json[r'processing_status'] = null;
    }
    if (this.thumbnailUrl != null) {
      json[r'thumbnail_url'] = this.thumbnailUrl;
    } else {
      json[r'thumbnail_url'] = null;
    }
    if (this.updatedAt != null) {
      json[r'updated_at'] = this.updatedAt;
    } else {
      json[r'updated_at'] = null;
    }
    if (this.userId != null) {
      json[r'user_id'] = this.userId;
    } else {
      json[r'user_id'] = null;
    }
    if (this.uuid != null) {
      json[r'uuid'] = this.uuid;
    } else {
      json[r'uuid'] = null;
    }
    if (this.width != null) {
      json[r'width'] = this.width;
    } else {
      json[r'width'] = null;
    }
    return json;
  }

  /// Returns a new [DtoMediaResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DtoMediaResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "DtoMediaResponse[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "DtoMediaResponse[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return DtoMediaResponse(
        backupStatus: mapValueOfType<String>(json, r'backup_status'),
        createdAt: mapValueOfType<String>(json, r'created_at'),
        downloadUrl: mapValueOfType<String>(json, r'download_url'),
        fileSize: mapValueOfType<int>(json, r'file_size'),
        filename: mapValueOfType<String>(json, r'filename'),
        hash: mapValueOfType<String>(json, r'hash'),
        height: mapValueOfType<int>(json, r'height'),
        itemType: mapValueOfType<String>(json, r'item_type'),
        localPath: mapValueOfType<String>(json, r'local_path'),
        mediaTakenAt: mapValueOfType<String>(json, r'media_taken_at'),
        mimeType: mapValueOfType<String>(json, r'mime_type'),
        originalFilename: mapValueOfType<String>(json, r'original_filename'),
        previewUrl: mapValueOfType<String>(json, r'preview_url'),
        processingStatus: mapValueOfType<String>(json, r'processing_status'),
        thumbnailUrl: mapValueOfType<String>(json, r'thumbnail_url'),
        updatedAt: mapValueOfType<String>(json, r'updated_at'),
        userId: mapValueOfType<int>(json, r'user_id'),
        uuid: mapValueOfType<String>(json, r'uuid'),
        width: mapValueOfType<int>(json, r'width'),
      );
    }
    return null;
  }

  static List<DtoMediaResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DtoMediaResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DtoMediaResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DtoMediaResponse> mapFromJson(dynamic json) {
    final map = <String, DtoMediaResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DtoMediaResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DtoMediaResponse-objects as value to a dart map
  static Map<String, List<DtoMediaResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DtoMediaResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DtoMediaResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

