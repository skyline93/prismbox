// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $MediaAssetsTable extends MediaAssets
    with TableInfo<$MediaAssetsTable, MediaAsset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaAssetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
      'uuid', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _filenameMeta =
      const VerificationMeta('filename');
  @override
  late final GeneratedColumn<String> filename = GeneratedColumn<String>(
      'filename', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _originalFilenameMeta =
      const VerificationMeta('originalFilename');
  @override
  late final GeneratedColumn<String> originalFilename = GeneratedColumn<String>(
      'original_filename', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _itemTypeMeta =
      const VerificationMeta('itemType');
  @override
  late final GeneratedColumn<String> itemType = GeneratedColumn<String>(
      'item_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _hashMeta = const VerificationMeta('hash');
  @override
  late final GeneratedColumn<String> hash = GeneratedColumn<String>(
      'hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mediaTakenAtMeta =
      const VerificationMeta('mediaTakenAt');
  @override
  late final GeneratedColumn<String> mediaTakenAt = GeneratedColumn<String>(
      'media_taken_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _thumbnailUrlMeta =
      const VerificationMeta('thumbnailUrl');
  @override
  late final GeneratedColumn<String> thumbnailUrl = GeneratedColumn<String>(
      'thumbnail_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _previewUrlMeta =
      const VerificationMeta('previewUrl');
  @override
  late final GeneratedColumn<String> previewUrl = GeneratedColumn<String>(
      'preview_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _downloadUrlMeta =
      const VerificationMeta('downloadUrl');
  @override
  late final GeneratedColumn<String> downloadUrl = GeneratedColumn<String>(
      'download_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        uuid,
        filename,
        originalFilename,
        itemType,
        hash,
        createdAt,
        updatedAt,
        mediaTakenAt,
        thumbnailUrl,
        previewUrl,
        downloadUrl
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_assets';
  @override
  VerificationContext validateIntegrity(Insertable<MediaAsset> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uuid')) {
      context.handle(
          _uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    }
    if (data.containsKey('filename')) {
      context.handle(_filenameMeta,
          filename.isAcceptableOrUnknown(data['filename']!, _filenameMeta));
    }
    if (data.containsKey('original_filename')) {
      context.handle(
          _originalFilenameMeta,
          originalFilename.isAcceptableOrUnknown(
              data['original_filename']!, _originalFilenameMeta));
    } else if (isInserting) {
      context.missing(_originalFilenameMeta);
    }
    if (data.containsKey('item_type')) {
      context.handle(_itemTypeMeta,
          itemType.isAcceptableOrUnknown(data['item_type']!, _itemTypeMeta));
    } else if (isInserting) {
      context.missing(_itemTypeMeta);
    }
    if (data.containsKey('hash')) {
      context.handle(
          _hashMeta, hash.isAcceptableOrUnknown(data['hash']!, _hashMeta));
    } else if (isInserting) {
      context.missing(_hashMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('media_taken_at')) {
      context.handle(
          _mediaTakenAtMeta,
          mediaTakenAt.isAcceptableOrUnknown(
              data['media_taken_at']!, _mediaTakenAtMeta));
    }
    if (data.containsKey('thumbnail_url')) {
      context.handle(
          _thumbnailUrlMeta,
          thumbnailUrl.isAcceptableOrUnknown(
              data['thumbnail_url']!, _thumbnailUrlMeta));
    } else if (isInserting) {
      context.missing(_thumbnailUrlMeta);
    }
    if (data.containsKey('preview_url')) {
      context.handle(
          _previewUrlMeta,
          previewUrl.isAcceptableOrUnknown(
              data['preview_url']!, _previewUrlMeta));
    } else if (isInserting) {
      context.missing(_previewUrlMeta);
    }
    if (data.containsKey('download_url')) {
      context.handle(
          _downloadUrlMeta,
          downloadUrl.isAcceptableOrUnknown(
              data['download_url']!, _downloadUrlMeta));
    } else if (isInserting) {
      context.missing(_downloadUrlMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  MediaAsset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaAsset(
      uuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uuid']),
      filename: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}filename']),
      originalFilename: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}original_filename'])!,
      itemType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_type'])!,
      hash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hash'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
      mediaTakenAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_taken_at']),
      thumbnailUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}thumbnail_url'])!,
      previewUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}preview_url'])!,
      downloadUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}download_url'])!,
    );
  }

  @override
  $MediaAssetsTable createAlias(String alias) {
    return $MediaAssetsTable(attachedDatabase, alias);
  }
}

class MediaAsset extends DataClass implements Insertable<MediaAsset> {
  final String? uuid;
  final String? filename;
  final String originalFilename;
  final String itemType;
  final String hash;
  final String createdAt;
  final String updatedAt;
  final String? mediaTakenAt;
  final String thumbnailUrl;
  final String previewUrl;
  final String downloadUrl;
  const MediaAsset(
      {this.uuid,
      this.filename,
      required this.originalFilename,
      required this.itemType,
      required this.hash,
      required this.createdAt,
      required this.updatedAt,
      this.mediaTakenAt,
      required this.thumbnailUrl,
      required this.previewUrl,
      required this.downloadUrl});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || uuid != null) {
      map['uuid'] = Variable<String>(uuid);
    }
    if (!nullToAbsent || filename != null) {
      map['filename'] = Variable<String>(filename);
    }
    map['original_filename'] = Variable<String>(originalFilename);
    map['item_type'] = Variable<String>(itemType);
    map['hash'] = Variable<String>(hash);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || mediaTakenAt != null) {
      map['media_taken_at'] = Variable<String>(mediaTakenAt);
    }
    map['thumbnail_url'] = Variable<String>(thumbnailUrl);
    map['preview_url'] = Variable<String>(previewUrl);
    map['download_url'] = Variable<String>(downloadUrl);
    return map;
  }

  MediaAssetsCompanion toCompanion(bool nullToAbsent) {
    return MediaAssetsCompanion(
      uuid: uuid == null && nullToAbsent ? const Value.absent() : Value(uuid),
      filename: filename == null && nullToAbsent
          ? const Value.absent()
          : Value(filename),
      originalFilename: Value(originalFilename),
      itemType: Value(itemType),
      hash: Value(hash),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      mediaTakenAt: mediaTakenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaTakenAt),
      thumbnailUrl: Value(thumbnailUrl),
      previewUrl: Value(previewUrl),
      downloadUrl: Value(downloadUrl),
    );
  }

  factory MediaAsset.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaAsset(
      uuid: serializer.fromJson<String?>(json['uuid']),
      filename: serializer.fromJson<String?>(json['filename']),
      originalFilename: serializer.fromJson<String>(json['originalFilename']),
      itemType: serializer.fromJson<String>(json['itemType']),
      hash: serializer.fromJson<String>(json['hash']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      mediaTakenAt: serializer.fromJson<String?>(json['mediaTakenAt']),
      thumbnailUrl: serializer.fromJson<String>(json['thumbnailUrl']),
      previewUrl: serializer.fromJson<String>(json['previewUrl']),
      downloadUrl: serializer.fromJson<String>(json['downloadUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<String?>(uuid),
      'filename': serializer.toJson<String?>(filename),
      'originalFilename': serializer.toJson<String>(originalFilename),
      'itemType': serializer.toJson<String>(itemType),
      'hash': serializer.toJson<String>(hash),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'mediaTakenAt': serializer.toJson<String?>(mediaTakenAt),
      'thumbnailUrl': serializer.toJson<String>(thumbnailUrl),
      'previewUrl': serializer.toJson<String>(previewUrl),
      'downloadUrl': serializer.toJson<String>(downloadUrl),
    };
  }

  MediaAsset copyWith(
          {Value<String?> uuid = const Value.absent(),
          Value<String?> filename = const Value.absent(),
          String? originalFilename,
          String? itemType,
          String? hash,
          String? createdAt,
          String? updatedAt,
          Value<String?> mediaTakenAt = const Value.absent(),
          String? thumbnailUrl,
          String? previewUrl,
          String? downloadUrl}) =>
      MediaAsset(
        uuid: uuid.present ? uuid.value : this.uuid,
        filename: filename.present ? filename.value : this.filename,
        originalFilename: originalFilename ?? this.originalFilename,
        itemType: itemType ?? this.itemType,
        hash: hash ?? this.hash,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        mediaTakenAt:
            mediaTakenAt.present ? mediaTakenAt.value : this.mediaTakenAt,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        previewUrl: previewUrl ?? this.previewUrl,
        downloadUrl: downloadUrl ?? this.downloadUrl,
      );
  MediaAsset copyWithCompanion(MediaAssetsCompanion data) {
    return MediaAsset(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      filename: data.filename.present ? data.filename.value : this.filename,
      originalFilename: data.originalFilename.present
          ? data.originalFilename.value
          : this.originalFilename,
      itemType: data.itemType.present ? data.itemType.value : this.itemType,
      hash: data.hash.present ? data.hash.value : this.hash,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      mediaTakenAt: data.mediaTakenAt.present
          ? data.mediaTakenAt.value
          : this.mediaTakenAt,
      thumbnailUrl: data.thumbnailUrl.present
          ? data.thumbnailUrl.value
          : this.thumbnailUrl,
      previewUrl:
          data.previewUrl.present ? data.previewUrl.value : this.previewUrl,
      downloadUrl:
          data.downloadUrl.present ? data.downloadUrl.value : this.downloadUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaAsset(')
          ..write('uuid: $uuid, ')
          ..write('filename: $filename, ')
          ..write('originalFilename: $originalFilename, ')
          ..write('itemType: $itemType, ')
          ..write('hash: $hash, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('mediaTakenAt: $mediaTakenAt, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('previewUrl: $previewUrl, ')
          ..write('downloadUrl: $downloadUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      uuid,
      filename,
      originalFilename,
      itemType,
      hash,
      createdAt,
      updatedAt,
      mediaTakenAt,
      thumbnailUrl,
      previewUrl,
      downloadUrl);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaAsset &&
          other.uuid == this.uuid &&
          other.filename == this.filename &&
          other.originalFilename == this.originalFilename &&
          other.itemType == this.itemType &&
          other.hash == this.hash &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.mediaTakenAt == this.mediaTakenAt &&
          other.thumbnailUrl == this.thumbnailUrl &&
          other.previewUrl == this.previewUrl &&
          other.downloadUrl == this.downloadUrl);
}

class MediaAssetsCompanion extends UpdateCompanion<MediaAsset> {
  final Value<String?> uuid;
  final Value<String?> filename;
  final Value<String> originalFilename;
  final Value<String> itemType;
  final Value<String> hash;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String?> mediaTakenAt;
  final Value<String> thumbnailUrl;
  final Value<String> previewUrl;
  final Value<String> downloadUrl;
  final Value<int> rowid;
  const MediaAssetsCompanion({
    this.uuid = const Value.absent(),
    this.filename = const Value.absent(),
    this.originalFilename = const Value.absent(),
    this.itemType = const Value.absent(),
    this.hash = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.mediaTakenAt = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.previewUrl = const Value.absent(),
    this.downloadUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediaAssetsCompanion.insert({
    this.uuid = const Value.absent(),
    this.filename = const Value.absent(),
    required String originalFilename,
    required String itemType,
    required String hash,
    required String createdAt,
    required String updatedAt,
    this.mediaTakenAt = const Value.absent(),
    required String thumbnailUrl,
    required String previewUrl,
    required String downloadUrl,
    this.rowid = const Value.absent(),
  })  : originalFilename = Value(originalFilename),
        itemType = Value(itemType),
        hash = Value(hash),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        thumbnailUrl = Value(thumbnailUrl),
        previewUrl = Value(previewUrl),
        downloadUrl = Value(downloadUrl);
  static Insertable<MediaAsset> custom({
    Expression<String>? uuid,
    Expression<String>? filename,
    Expression<String>? originalFilename,
    Expression<String>? itemType,
    Expression<String>? hash,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? mediaTakenAt,
    Expression<String>? thumbnailUrl,
    Expression<String>? previewUrl,
    Expression<String>? downloadUrl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (filename != null) 'filename': filename,
      if (originalFilename != null) 'original_filename': originalFilename,
      if (itemType != null) 'item_type': itemType,
      if (hash != null) 'hash': hash,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (mediaTakenAt != null) 'media_taken_at': mediaTakenAt,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (previewUrl != null) 'preview_url': previewUrl,
      if (downloadUrl != null) 'download_url': downloadUrl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MediaAssetsCompanion copyWith(
      {Value<String?>? uuid,
      Value<String?>? filename,
      Value<String>? originalFilename,
      Value<String>? itemType,
      Value<String>? hash,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<String?>? mediaTakenAt,
      Value<String>? thumbnailUrl,
      Value<String>? previewUrl,
      Value<String>? downloadUrl,
      Value<int>? rowid}) {
    return MediaAssetsCompanion(
      uuid: uuid ?? this.uuid,
      filename: filename ?? this.filename,
      originalFilename: originalFilename ?? this.originalFilename,
      itemType: itemType ?? this.itemType,
      hash: hash ?? this.hash,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      mediaTakenAt: mediaTakenAt ?? this.mediaTakenAt,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      previewUrl: previewUrl ?? this.previewUrl,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (filename.present) {
      map['filename'] = Variable<String>(filename.value);
    }
    if (originalFilename.present) {
      map['original_filename'] = Variable<String>(originalFilename.value);
    }
    if (itemType.present) {
      map['item_type'] = Variable<String>(itemType.value);
    }
    if (hash.present) {
      map['hash'] = Variable<String>(hash.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (mediaTakenAt.present) {
      map['media_taken_at'] = Variable<String>(mediaTakenAt.value);
    }
    if (thumbnailUrl.present) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl.value);
    }
    if (previewUrl.present) {
      map['preview_url'] = Variable<String>(previewUrl.value);
    }
    if (downloadUrl.present) {
      map['download_url'] = Variable<String>(downloadUrl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaAssetsCompanion(')
          ..write('uuid: $uuid, ')
          ..write('filename: $filename, ')
          ..write('originalFilename: $originalFilename, ')
          ..write('itemType: $itemType, ')
          ..write('hash: $hash, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('mediaTakenAt: $mediaTakenAt, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('previewUrl: $previewUrl, ')
          ..write('downloadUrl: $downloadUrl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserSettingsTable extends UserSettings
    with TableInfo<$UserSettingsTable, UserSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_settings';
  @override
  VerificationContext validateIntegrity(Insertable<UserSetting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  UserSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserSetting(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $UserSettingsTable createAlias(String alias) {
    return $UserSettingsTable(attachedDatabase, alias);
  }
}

class UserSetting extends DataClass implements Insertable<UserSetting> {
  final String key;
  final String value;
  const UserSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  UserSettingsCompanion toCompanion(bool nullToAbsent) {
    return UserSettingsCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory UserSetting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  UserSetting copyWith({String? key, String? value}) => UserSetting(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  UserSetting copyWithCompanion(UserSettingsCompanion data) {
    return UserSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class UserSettingsCompanion extends UpdateCompanion<UserSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const UserSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<UserSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserSettingsCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return UserSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MediaAssetsTable mediaAssets = $MediaAssetsTable(this);
  late final $UserSettingsTable userSettings = $UserSettingsTable(this);
  late final MediaAssetDao mediaAssetDao = MediaAssetDao(this as AppDatabase);
  late final UserSettingDao userSettingDao =
      UserSettingDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [mediaAssets, userSettings];
}

typedef $$MediaAssetsTableCreateCompanionBuilder = MediaAssetsCompanion
    Function({
  Value<String?> uuid,
  Value<String?> filename,
  required String originalFilename,
  required String itemType,
  required String hash,
  required String createdAt,
  required String updatedAt,
  Value<String?> mediaTakenAt,
  required String thumbnailUrl,
  required String previewUrl,
  required String downloadUrl,
  Value<int> rowid,
});
typedef $$MediaAssetsTableUpdateCompanionBuilder = MediaAssetsCompanion
    Function({
  Value<String?> uuid,
  Value<String?> filename,
  Value<String> originalFilename,
  Value<String> itemType,
  Value<String> hash,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<String?> mediaTakenAt,
  Value<String> thumbnailUrl,
  Value<String> previewUrl,
  Value<String> downloadUrl,
  Value<int> rowid,
});

class $$MediaAssetsTableFilterComposer
    extends Composer<_$AppDatabase, $MediaAssetsTable> {
  $$MediaAssetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filename => $composableBuilder(
      column: $table.filename, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get originalFilename => $composableBuilder(
      column: $table.originalFilename,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemType => $composableBuilder(
      column: $table.itemType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hash => $composableBuilder(
      column: $table.hash, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mediaTakenAt => $composableBuilder(
      column: $table.mediaTakenAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get thumbnailUrl => $composableBuilder(
      column: $table.thumbnailUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get previewUrl => $composableBuilder(
      column: $table.previewUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get downloadUrl => $composableBuilder(
      column: $table.downloadUrl, builder: (column) => ColumnFilters(column));
}

class $$MediaAssetsTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaAssetsTable> {
  $$MediaAssetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filename => $composableBuilder(
      column: $table.filename, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get originalFilename => $composableBuilder(
      column: $table.originalFilename,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemType => $composableBuilder(
      column: $table.itemType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hash => $composableBuilder(
      column: $table.hash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mediaTakenAt => $composableBuilder(
      column: $table.mediaTakenAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get thumbnailUrl => $composableBuilder(
      column: $table.thumbnailUrl,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get previewUrl => $composableBuilder(
      column: $table.previewUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get downloadUrl => $composableBuilder(
      column: $table.downloadUrl, builder: (column) => ColumnOrderings(column));
}

class $$MediaAssetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaAssetsTable> {
  $$MediaAssetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get filename =>
      $composableBuilder(column: $table.filename, builder: (column) => column);

  GeneratedColumn<String> get originalFilename => $composableBuilder(
      column: $table.originalFilename, builder: (column) => column);

  GeneratedColumn<String> get itemType =>
      $composableBuilder(column: $table.itemType, builder: (column) => column);

  GeneratedColumn<String> get hash =>
      $composableBuilder(column: $table.hash, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get mediaTakenAt => $composableBuilder(
      column: $table.mediaTakenAt, builder: (column) => column);

  GeneratedColumn<String> get thumbnailUrl => $composableBuilder(
      column: $table.thumbnailUrl, builder: (column) => column);

  GeneratedColumn<String> get previewUrl => $composableBuilder(
      column: $table.previewUrl, builder: (column) => column);

  GeneratedColumn<String> get downloadUrl => $composableBuilder(
      column: $table.downloadUrl, builder: (column) => column);
}

class $$MediaAssetsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MediaAssetsTable,
    MediaAsset,
    $$MediaAssetsTableFilterComposer,
    $$MediaAssetsTableOrderingComposer,
    $$MediaAssetsTableAnnotationComposer,
    $$MediaAssetsTableCreateCompanionBuilder,
    $$MediaAssetsTableUpdateCompanionBuilder,
    (MediaAsset, BaseReferences<_$AppDatabase, $MediaAssetsTable, MediaAsset>),
    MediaAsset,
    PrefetchHooks Function()> {
  $$MediaAssetsTableTableManager(_$AppDatabase db, $MediaAssetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaAssetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaAssetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaAssetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String?> uuid = const Value.absent(),
            Value<String?> filename = const Value.absent(),
            Value<String> originalFilename = const Value.absent(),
            Value<String> itemType = const Value.absent(),
            Value<String> hash = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<String?> mediaTakenAt = const Value.absent(),
            Value<String> thumbnailUrl = const Value.absent(),
            Value<String> previewUrl = const Value.absent(),
            Value<String> downloadUrl = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MediaAssetsCompanion(
            uuid: uuid,
            filename: filename,
            originalFilename: originalFilename,
            itemType: itemType,
            hash: hash,
            createdAt: createdAt,
            updatedAt: updatedAt,
            mediaTakenAt: mediaTakenAt,
            thumbnailUrl: thumbnailUrl,
            previewUrl: previewUrl,
            downloadUrl: downloadUrl,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String?> uuid = const Value.absent(),
            Value<String?> filename = const Value.absent(),
            required String originalFilename,
            required String itemType,
            required String hash,
            required String createdAt,
            required String updatedAt,
            Value<String?> mediaTakenAt = const Value.absent(),
            required String thumbnailUrl,
            required String previewUrl,
            required String downloadUrl,
            Value<int> rowid = const Value.absent(),
          }) =>
              MediaAssetsCompanion.insert(
            uuid: uuid,
            filename: filename,
            originalFilename: originalFilename,
            itemType: itemType,
            hash: hash,
            createdAt: createdAt,
            updatedAt: updatedAt,
            mediaTakenAt: mediaTakenAt,
            thumbnailUrl: thumbnailUrl,
            previewUrl: previewUrl,
            downloadUrl: downloadUrl,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MediaAssetsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MediaAssetsTable,
    MediaAsset,
    $$MediaAssetsTableFilterComposer,
    $$MediaAssetsTableOrderingComposer,
    $$MediaAssetsTableAnnotationComposer,
    $$MediaAssetsTableCreateCompanionBuilder,
    $$MediaAssetsTableUpdateCompanionBuilder,
    (MediaAsset, BaseReferences<_$AppDatabase, $MediaAssetsTable, MediaAsset>),
    MediaAsset,
    PrefetchHooks Function()>;
typedef $$UserSettingsTableCreateCompanionBuilder = UserSettingsCompanion
    Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$UserSettingsTableUpdateCompanionBuilder = UserSettingsCompanion
    Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$UserSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $UserSettingsTable> {
  $$UserSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$UserSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserSettingsTable> {
  $$UserSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$UserSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserSettingsTable> {
  $$UserSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$UserSettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserSettingsTable,
    UserSetting,
    $$UserSettingsTableFilterComposer,
    $$UserSettingsTableOrderingComposer,
    $$UserSettingsTableAnnotationComposer,
    $$UserSettingsTableCreateCompanionBuilder,
    $$UserSettingsTableUpdateCompanionBuilder,
    (
      UserSetting,
      BaseReferences<_$AppDatabase, $UserSettingsTable, UserSetting>
    ),
    UserSetting,
    PrefetchHooks Function()> {
  $$UserSettingsTableTableManager(_$AppDatabase db, $UserSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserSettingsCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              UserSettingsCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UserSettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UserSettingsTable,
    UserSetting,
    $$UserSettingsTableFilterComposer,
    $$UserSettingsTableOrderingComposer,
    $$UserSettingsTableAnnotationComposer,
    $$UserSettingsTableCreateCompanionBuilder,
    $$UserSettingsTableUpdateCompanionBuilder,
    (
      UserSetting,
      BaseReferences<_$AppDatabase, $UserSettingsTable, UserSetting>
    ),
    UserSetting,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MediaAssetsTableTableManager get mediaAssets =>
      $$MediaAssetsTableTableManager(_db, _db.mediaAssets);
  $$UserSettingsTableTableManager get userSettings =>
      $$UserSettingsTableTableManager(_db, _db.userSettings);
}

mixin _$MediaAssetDaoMixin on DatabaseAccessor<AppDatabase> {
  $MediaAssetsTable get mediaAssets => attachedDatabase.mediaAssets;
}
mixin _$UserSettingDaoMixin on DatabaseAccessor<AppDatabase> {
  $UserSettingsTable get userSettings => attachedDatabase.userSettings;
}
