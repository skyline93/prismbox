// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $MediaAssetsTable extends MediaAssets
    with TableInfo<$MediaAssetsTable, MediaAsset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaAssetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
      'local_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _cloudUuidMeta =
      const VerificationMeta('cloudUuid');
  @override
  late final GeneratedColumn<String> cloudUuid = GeneratedColumn<String>(
      'cloud_uuid', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _contentHashMeta =
      const VerificationMeta('contentHash');
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
      'content_hash', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumnWithTypeConverter<SyncStatus, String> syncStatus =
      GeneratedColumn<String>('sync_status', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<SyncStatus>($MediaAssetsTable.$convertersyncStatus);
  static const VerificationMeta _assetTypeMeta =
      const VerificationMeta('assetType');
  @override
  late final GeneratedColumnWithTypeConverter<MediaType, String> assetType =
      GeneratedColumn<String>('asset_type', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<MediaType>($MediaAssetsTable.$converterassetType);
  static const VerificationMeta _filePathMeta =
      const VerificationMeta('filePath');
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
      'file_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fileNameMeta =
      const VerificationMeta('fileName');
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
      'file_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
      'width', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
      'height', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _durationSecMeta =
      const VerificationMeta('durationSec');
  @override
  late final GeneratedColumn<int> durationSec = GeneratedColumn<int>(
      'duration_sec', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        localId,
        cloudUuid,
        contentHash,
        syncStatus,
        assetType,
        filePath,
        fileName,
        width,
        height,
        durationSec,
        createdAt,
        updatedAt
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
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    }
    if (data.containsKey('cloud_uuid')) {
      context.handle(_cloudUuidMeta,
          cloudUuid.isAcceptableOrUnknown(data['cloud_uuid']!, _cloudUuidMeta));
    }
    if (data.containsKey('content_hash')) {
      context.handle(
          _contentHashMeta,
          contentHash.isAcceptableOrUnknown(
              data['content_hash']!, _contentHashMeta));
    }
    context.handle(_syncStatusMeta, const VerificationResult.success());
    context.handle(_assetTypeMeta, const VerificationResult.success());
    if (data.containsKey('file_path')) {
      context.handle(_filePathMeta,
          filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta));
    }
    if (data.containsKey('file_name')) {
      context.handle(_fileNameMeta,
          fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta));
    }
    if (data.containsKey('width')) {
      context.handle(
          _widthMeta, width.isAcceptableOrUnknown(data['width']!, _widthMeta));
    }
    if (data.containsKey('height')) {
      context.handle(_heightMeta,
          height.isAcceptableOrUnknown(data['height']!, _heightMeta));
    }
    if (data.containsKey('duration_sec')) {
      context.handle(
          _durationSecMeta,
          durationSec.isAcceptableOrUnknown(
              data['duration_sec']!, _durationSecMeta));
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MediaAsset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaAsset(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_id']),
      cloudUuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cloud_uuid']),
      contentHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_hash']),
      syncStatus: $MediaAssetsTable.$convertersyncStatus.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}sync_status'])!),
      assetType: $MediaAssetsTable.$converterassetType.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}asset_type'])!),
      filePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_path']),
      fileName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_name']),
      width: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}width']),
      height: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}height']),
      durationSec: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_sec']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $MediaAssetsTable createAlias(String alias) {
    return $MediaAssetsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncStatus, String, String> $convertersyncStatus =
      const EnumNameConverter(SyncStatus.values);
  static JsonTypeConverter2<MediaType, String, String> $converterassetType =
      const EnumNameConverter(MediaType.values);
}

class MediaAsset extends DataClass implements Insertable<MediaAsset> {
  final int id;
  final String? localId;
  final String? cloudUuid;
  final String? contentHash;
  final SyncStatus syncStatus;
  final MediaType assetType;
  final String? filePath;
  final String? fileName;
  final int? width;
  final int? height;
  final int? durationSec;
  final DateTime createdAt;
  final DateTime updatedAt;
  const MediaAsset(
      {required this.id,
      this.localId,
      this.cloudUuid,
      this.contentHash,
      required this.syncStatus,
      required this.assetType,
      this.filePath,
      this.fileName,
      this.width,
      this.height,
      this.durationSec,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || localId != null) {
      map['local_id'] = Variable<String>(localId);
    }
    if (!nullToAbsent || cloudUuid != null) {
      map['cloud_uuid'] = Variable<String>(cloudUuid);
    }
    if (!nullToAbsent || contentHash != null) {
      map['content_hash'] = Variable<String>(contentHash);
    }
    {
      map['sync_status'] = Variable<String>(
          $MediaAssetsTable.$convertersyncStatus.toSql(syncStatus));
    }
    {
      map['asset_type'] = Variable<String>(
          $MediaAssetsTable.$converterassetType.toSql(assetType));
    }
    if (!nullToAbsent || filePath != null) {
      map['file_path'] = Variable<String>(filePath);
    }
    if (!nullToAbsent || fileName != null) {
      map['file_name'] = Variable<String>(fileName);
    }
    if (!nullToAbsent || width != null) {
      map['width'] = Variable<int>(width);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int>(height);
    }
    if (!nullToAbsent || durationSec != null) {
      map['duration_sec'] = Variable<int>(durationSec);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MediaAssetsCompanion toCompanion(bool nullToAbsent) {
    return MediaAssetsCompanion(
      id: Value(id),
      localId: localId == null && nullToAbsent
          ? const Value.absent()
          : Value(localId),
      cloudUuid: cloudUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudUuid),
      contentHash: contentHash == null && nullToAbsent
          ? const Value.absent()
          : Value(contentHash),
      syncStatus: Value(syncStatus),
      assetType: Value(assetType),
      filePath: filePath == null && nullToAbsent
          ? const Value.absent()
          : Value(filePath),
      fileName: fileName == null && nullToAbsent
          ? const Value.absent()
          : Value(fileName),
      width:
          width == null && nullToAbsent ? const Value.absent() : Value(width),
      height:
          height == null && nullToAbsent ? const Value.absent() : Value(height),
      durationSec: durationSec == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSec),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory MediaAsset.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaAsset(
      id: serializer.fromJson<int>(json['id']),
      localId: serializer.fromJson<String?>(json['localId']),
      cloudUuid: serializer.fromJson<String?>(json['cloudUuid']),
      contentHash: serializer.fromJson<String?>(json['contentHash']),
      syncStatus: $MediaAssetsTable.$convertersyncStatus
          .fromJson(serializer.fromJson<String>(json['syncStatus'])),
      assetType: $MediaAssetsTable.$converterassetType
          .fromJson(serializer.fromJson<String>(json['assetType'])),
      filePath: serializer.fromJson<String?>(json['filePath']),
      fileName: serializer.fromJson<String?>(json['fileName']),
      width: serializer.fromJson<int?>(json['width']),
      height: serializer.fromJson<int?>(json['height']),
      durationSec: serializer.fromJson<int?>(json['durationSec']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'localId': serializer.toJson<String?>(localId),
      'cloudUuid': serializer.toJson<String?>(cloudUuid),
      'contentHash': serializer.toJson<String?>(contentHash),
      'syncStatus': serializer.toJson<String>(
          $MediaAssetsTable.$convertersyncStatus.toJson(syncStatus)),
      'assetType': serializer.toJson<String>(
          $MediaAssetsTable.$converterassetType.toJson(assetType)),
      'filePath': serializer.toJson<String?>(filePath),
      'fileName': serializer.toJson<String?>(fileName),
      'width': serializer.toJson<int?>(width),
      'height': serializer.toJson<int?>(height),
      'durationSec': serializer.toJson<int?>(durationSec),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MediaAsset copyWith(
          {int? id,
          Value<String?> localId = const Value.absent(),
          Value<String?> cloudUuid = const Value.absent(),
          Value<String?> contentHash = const Value.absent(),
          SyncStatus? syncStatus,
          MediaType? assetType,
          Value<String?> filePath = const Value.absent(),
          Value<String?> fileName = const Value.absent(),
          Value<int?> width = const Value.absent(),
          Value<int?> height = const Value.absent(),
          Value<int?> durationSec = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      MediaAsset(
        id: id ?? this.id,
        localId: localId.present ? localId.value : this.localId,
        cloudUuid: cloudUuid.present ? cloudUuid.value : this.cloudUuid,
        contentHash: contentHash.present ? contentHash.value : this.contentHash,
        syncStatus: syncStatus ?? this.syncStatus,
        assetType: assetType ?? this.assetType,
        filePath: filePath.present ? filePath.value : this.filePath,
        fileName: fileName.present ? fileName.value : this.fileName,
        width: width.present ? width.value : this.width,
        height: height.present ? height.value : this.height,
        durationSec: durationSec.present ? durationSec.value : this.durationSec,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  MediaAsset copyWithCompanion(MediaAssetsCompanion data) {
    return MediaAsset(
      id: data.id.present ? data.id.value : this.id,
      localId: data.localId.present ? data.localId.value : this.localId,
      cloudUuid: data.cloudUuid.present ? data.cloudUuid.value : this.cloudUuid,
      contentHash:
          data.contentHash.present ? data.contentHash.value : this.contentHash,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      assetType: data.assetType.present ? data.assetType.value : this.assetType,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      durationSec:
          data.durationSec.present ? data.durationSec.value : this.durationSec,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaAsset(')
          ..write('id: $id, ')
          ..write('localId: $localId, ')
          ..write('cloudUuid: $cloudUuid, ')
          ..write('contentHash: $contentHash, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('assetType: $assetType, ')
          ..write('filePath: $filePath, ')
          ..write('fileName: $fileName, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('durationSec: $durationSec, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      localId,
      cloudUuid,
      contentHash,
      syncStatus,
      assetType,
      filePath,
      fileName,
      width,
      height,
      durationSec,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaAsset &&
          other.id == this.id &&
          other.localId == this.localId &&
          other.cloudUuid == this.cloudUuid &&
          other.contentHash == this.contentHash &&
          other.syncStatus == this.syncStatus &&
          other.assetType == this.assetType &&
          other.filePath == this.filePath &&
          other.fileName == this.fileName &&
          other.width == this.width &&
          other.height == this.height &&
          other.durationSec == this.durationSec &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MediaAssetsCompanion extends UpdateCompanion<MediaAsset> {
  final Value<int> id;
  final Value<String?> localId;
  final Value<String?> cloudUuid;
  final Value<String?> contentHash;
  final Value<SyncStatus> syncStatus;
  final Value<MediaType> assetType;
  final Value<String?> filePath;
  final Value<String?> fileName;
  final Value<int?> width;
  final Value<int?> height;
  final Value<int?> durationSec;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const MediaAssetsCompanion({
    this.id = const Value.absent(),
    this.localId = const Value.absent(),
    this.cloudUuid = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.assetType = const Value.absent(),
    this.filePath = const Value.absent(),
    this.fileName = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  MediaAssetsCompanion.insert({
    this.id = const Value.absent(),
    this.localId = const Value.absent(),
    this.cloudUuid = const Value.absent(),
    this.contentHash = const Value.absent(),
    required SyncStatus syncStatus,
    required MediaType assetType,
    this.filePath = const Value.absent(),
    this.fileName = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.durationSec = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  })  : syncStatus = Value(syncStatus),
        assetType = Value(assetType),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<MediaAsset> custom({
    Expression<int>? id,
    Expression<String>? localId,
    Expression<String>? cloudUuid,
    Expression<String>? contentHash,
    Expression<String>? syncStatus,
    Expression<String>? assetType,
    Expression<String>? filePath,
    Expression<String>? fileName,
    Expression<int>? width,
    Expression<int>? height,
    Expression<int>? durationSec,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (localId != null) 'local_id': localId,
      if (cloudUuid != null) 'cloud_uuid': cloudUuid,
      if (contentHash != null) 'content_hash': contentHash,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (assetType != null) 'asset_type': assetType,
      if (filePath != null) 'file_path': filePath,
      if (fileName != null) 'file_name': fileName,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (durationSec != null) 'duration_sec': durationSec,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  MediaAssetsCompanion copyWith(
      {Value<int>? id,
      Value<String?>? localId,
      Value<String?>? cloudUuid,
      Value<String?>? contentHash,
      Value<SyncStatus>? syncStatus,
      Value<MediaType>? assetType,
      Value<String?>? filePath,
      Value<String?>? fileName,
      Value<int?>? width,
      Value<int?>? height,
      Value<int?>? durationSec,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return MediaAssetsCompanion(
      id: id ?? this.id,
      localId: localId ?? this.localId,
      cloudUuid: cloudUuid ?? this.cloudUuid,
      contentHash: contentHash ?? this.contentHash,
      syncStatus: syncStatus ?? this.syncStatus,
      assetType: assetType ?? this.assetType,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      width: width ?? this.width,
      height: height ?? this.height,
      durationSec: durationSec ?? this.durationSec,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (cloudUuid.present) {
      map['cloud_uuid'] = Variable<String>(cloudUuid.value);
    }
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(
          $MediaAssetsTable.$convertersyncStatus.toSql(syncStatus.value));
    }
    if (assetType.present) {
      map['asset_type'] = Variable<String>(
          $MediaAssetsTable.$converterassetType.toSql(assetType.value));
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (durationSec.present) {
      map['duration_sec'] = Variable<int>(durationSec.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaAssetsCompanion(')
          ..write('id: $id, ')
          ..write('localId: $localId, ')
          ..write('cloudUuid: $cloudUuid, ')
          ..write('contentHash: $contentHash, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('assetType: $assetType, ')
          ..write('filePath: $filePath, ')
          ..write('fileName: $fileName, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('durationSec: $durationSec, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SyncJobsTable extends SyncJobs with TableInfo<$SyncJobsTable, SyncJob> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncJobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _assetIdMeta =
      const VerificationMeta('assetId');
  @override
  late final GeneratedColumn<int> assetId = GeneratedColumn<int>(
      'asset_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES media_assets (id) ON DELETE CASCADE'));
  static const VerificationMeta _jobTypeMeta =
      const VerificationMeta('jobType');
  @override
  late final GeneratedColumnWithTypeConverter<JobType, String> jobType =
      GeneratedColumn<String>('job_type', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<JobType>($SyncJobsTable.$converterjobType);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumnWithTypeConverter<JobStatus, String> status =
      GeneratedColumn<String>('status', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<JobStatus>($SyncJobsTable.$converterstatus);
  static const VerificationMeta _attemptsMeta =
      const VerificationMeta('attempts');
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
      'attempts', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _errorMessageMeta =
      const VerificationMeta('errorMessage');
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
      'error_message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _relatedCloudUuidMeta =
      const VerificationMeta('relatedCloudUuid');
  @override
  late final GeneratedColumn<String> relatedCloudUuid = GeneratedColumn<String>(
      'related_cloud_uuid', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
      'priority', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _networkConstraintMeta =
      const VerificationMeta('networkConstraint');
  @override
  late final GeneratedColumnWithTypeConverter<NetworkConstraint, String>
      networkConstraint = GeneratedColumn<String>(
              'network_constraint', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: Constant(NetworkConstraint.any.name))
          .withConverter<NetworkConstraint>(
              $SyncJobsTable.$converternetworkConstraint);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        assetId,
        jobType,
        status,
        attempts,
        errorMessage,
        createdAt,
        relatedCloudUuid,
        priority,
        networkConstraint
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_jobs';
  @override
  VerificationContext validateIntegrity(Insertable<SyncJob> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('asset_id')) {
      context.handle(_assetIdMeta,
          assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta));
    }
    context.handle(_jobTypeMeta, const VerificationResult.success());
    context.handle(_statusMeta, const VerificationResult.success());
    if (data.containsKey('attempts')) {
      context.handle(_attemptsMeta,
          attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta));
    }
    if (data.containsKey('error_message')) {
      context.handle(
          _errorMessageMeta,
          errorMessage.isAcceptableOrUnknown(
              data['error_message']!, _errorMessageMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('related_cloud_uuid')) {
      context.handle(
          _relatedCloudUuidMeta,
          relatedCloudUuid.isAcceptableOrUnknown(
              data['related_cloud_uuid']!, _relatedCloudUuidMeta));
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    }
    context.handle(_networkConstraintMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncJob map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncJob(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      assetId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}asset_id']),
      jobType: $SyncJobsTable.$converterjobType.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}job_type'])!),
      status: $SyncJobsTable.$converterstatus.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!),
      attempts: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempts'])!,
      errorMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error_message']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      relatedCloudUuid: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}related_cloud_uuid']),
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}priority'])!,
      networkConstraint: $SyncJobsTable.$converternetworkConstraint.fromSql(
          attachedDatabase.typeMapping.read(DriftSqlType.string,
              data['${effectivePrefix}network_constraint'])!),
    );
  }

  @override
  $SyncJobsTable createAlias(String alias) {
    return $SyncJobsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<JobType, String, String> $converterjobType =
      const EnumNameConverter(JobType.values);
  static JsonTypeConverter2<JobStatus, String, String> $converterstatus =
      const EnumNameConverter(JobStatus.values);
  static JsonTypeConverter2<NetworkConstraint, String, String>
      $converternetworkConstraint =
      const EnumNameConverter(NetworkConstraint.values);
}

class SyncJob extends DataClass implements Insertable<SyncJob> {
  final int id;
  final int? assetId;
  final JobType jobType;
  final JobStatus status;
  final int attempts;
  final String? errorMessage;
  final DateTime createdAt;
  final String? relatedCloudUuid;
  final int priority;
  final NetworkConstraint networkConstraint;
  const SyncJob(
      {required this.id,
      this.assetId,
      required this.jobType,
      required this.status,
      required this.attempts,
      this.errorMessage,
      required this.createdAt,
      this.relatedCloudUuid,
      required this.priority,
      required this.networkConstraint});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || assetId != null) {
      map['asset_id'] = Variable<int>(assetId);
    }
    {
      map['job_type'] =
          Variable<String>($SyncJobsTable.$converterjobType.toSql(jobType));
    }
    {
      map['status'] =
          Variable<String>($SyncJobsTable.$converterstatus.toSql(status));
    }
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || relatedCloudUuid != null) {
      map['related_cloud_uuid'] = Variable<String>(relatedCloudUuid);
    }
    map['priority'] = Variable<int>(priority);
    {
      map['network_constraint'] = Variable<String>(
          $SyncJobsTable.$converternetworkConstraint.toSql(networkConstraint));
    }
    return map;
  }

  SyncJobsCompanion toCompanion(bool nullToAbsent) {
    return SyncJobsCompanion(
      id: Value(id),
      assetId: assetId == null && nullToAbsent
          ? const Value.absent()
          : Value(assetId),
      jobType: Value(jobType),
      status: Value(status),
      attempts: Value(attempts),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      createdAt: Value(createdAt),
      relatedCloudUuid: relatedCloudUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(relatedCloudUuid),
      priority: Value(priority),
      networkConstraint: Value(networkConstraint),
    );
  }

  factory SyncJob.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncJob(
      id: serializer.fromJson<int>(json['id']),
      assetId: serializer.fromJson<int?>(json['assetId']),
      jobType: $SyncJobsTable.$converterjobType
          .fromJson(serializer.fromJson<String>(json['jobType'])),
      status: $SyncJobsTable.$converterstatus
          .fromJson(serializer.fromJson<String>(json['status'])),
      attempts: serializer.fromJson<int>(json['attempts']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      relatedCloudUuid: serializer.fromJson<String?>(json['relatedCloudUuid']),
      priority: serializer.fromJson<int>(json['priority']),
      networkConstraint: $SyncJobsTable.$converternetworkConstraint
          .fromJson(serializer.fromJson<String>(json['networkConstraint'])),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'assetId': serializer.toJson<int?>(assetId),
      'jobType': serializer
          .toJson<String>($SyncJobsTable.$converterjobType.toJson(jobType)),
      'status': serializer
          .toJson<String>($SyncJobsTable.$converterstatus.toJson(status)),
      'attempts': serializer.toJson<int>(attempts),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'relatedCloudUuid': serializer.toJson<String?>(relatedCloudUuid),
      'priority': serializer.toJson<int>(priority),
      'networkConstraint': serializer.toJson<String>(
          $SyncJobsTable.$converternetworkConstraint.toJson(networkConstraint)),
    };
  }

  SyncJob copyWith(
          {int? id,
          Value<int?> assetId = const Value.absent(),
          JobType? jobType,
          JobStatus? status,
          int? attempts,
          Value<String?> errorMessage = const Value.absent(),
          DateTime? createdAt,
          Value<String?> relatedCloudUuid = const Value.absent(),
          int? priority,
          NetworkConstraint? networkConstraint}) =>
      SyncJob(
        id: id ?? this.id,
        assetId: assetId.present ? assetId.value : this.assetId,
        jobType: jobType ?? this.jobType,
        status: status ?? this.status,
        attempts: attempts ?? this.attempts,
        errorMessage:
            errorMessage.present ? errorMessage.value : this.errorMessage,
        createdAt: createdAt ?? this.createdAt,
        relatedCloudUuid: relatedCloudUuid.present
            ? relatedCloudUuid.value
            : this.relatedCloudUuid,
        priority: priority ?? this.priority,
        networkConstraint: networkConstraint ?? this.networkConstraint,
      );
  SyncJob copyWithCompanion(SyncJobsCompanion data) {
    return SyncJob(
      id: data.id.present ? data.id.value : this.id,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      jobType: data.jobType.present ? data.jobType.value : this.jobType,
      status: data.status.present ? data.status.value : this.status,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      relatedCloudUuid: data.relatedCloudUuid.present
          ? data.relatedCloudUuid.value
          : this.relatedCloudUuid,
      priority: data.priority.present ? data.priority.value : this.priority,
      networkConstraint: data.networkConstraint.present
          ? data.networkConstraint.value
          : this.networkConstraint,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncJob(')
          ..write('id: $id, ')
          ..write('assetId: $assetId, ')
          ..write('jobType: $jobType, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('relatedCloudUuid: $relatedCloudUuid, ')
          ..write('priority: $priority, ')
          ..write('networkConstraint: $networkConstraint')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, assetId, jobType, status, attempts,
      errorMessage, createdAt, relatedCloudUuid, priority, networkConstraint);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncJob &&
          other.id == this.id &&
          other.assetId == this.assetId &&
          other.jobType == this.jobType &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.errorMessage == this.errorMessage &&
          other.createdAt == this.createdAt &&
          other.relatedCloudUuid == this.relatedCloudUuid &&
          other.priority == this.priority &&
          other.networkConstraint == this.networkConstraint);
}

class SyncJobsCompanion extends UpdateCompanion<SyncJob> {
  final Value<int> id;
  final Value<int?> assetId;
  final Value<JobType> jobType;
  final Value<JobStatus> status;
  final Value<int> attempts;
  final Value<String?> errorMessage;
  final Value<DateTime> createdAt;
  final Value<String?> relatedCloudUuid;
  final Value<int> priority;
  final Value<NetworkConstraint> networkConstraint;
  const SyncJobsCompanion({
    this.id = const Value.absent(),
    this.assetId = const Value.absent(),
    this.jobType = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.relatedCloudUuid = const Value.absent(),
    this.priority = const Value.absent(),
    this.networkConstraint = const Value.absent(),
  });
  SyncJobsCompanion.insert({
    this.id = const Value.absent(),
    this.assetId = const Value.absent(),
    required JobType jobType,
    required JobStatus status,
    this.attempts = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.relatedCloudUuid = const Value.absent(),
    this.priority = const Value.absent(),
    this.networkConstraint = const Value.absent(),
  })  : jobType = Value(jobType),
        status = Value(status);
  static Insertable<SyncJob> custom({
    Expression<int>? id,
    Expression<int>? assetId,
    Expression<String>? jobType,
    Expression<String>? status,
    Expression<int>? attempts,
    Expression<String>? errorMessage,
    Expression<DateTime>? createdAt,
    Expression<String>? relatedCloudUuid,
    Expression<int>? priority,
    Expression<String>? networkConstraint,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (assetId != null) 'asset_id': assetId,
      if (jobType != null) 'job_type': jobType,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (errorMessage != null) 'error_message': errorMessage,
      if (createdAt != null) 'created_at': createdAt,
      if (relatedCloudUuid != null) 'related_cloud_uuid': relatedCloudUuid,
      if (priority != null) 'priority': priority,
      if (networkConstraint != null) 'network_constraint': networkConstraint,
    });
  }

  SyncJobsCompanion copyWith(
      {Value<int>? id,
      Value<int?>? assetId,
      Value<JobType>? jobType,
      Value<JobStatus>? status,
      Value<int>? attempts,
      Value<String?>? errorMessage,
      Value<DateTime>? createdAt,
      Value<String?>? relatedCloudUuid,
      Value<int>? priority,
      Value<NetworkConstraint>? networkConstraint}) {
    return SyncJobsCompanion(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      jobType: jobType ?? this.jobType,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      relatedCloudUuid: relatedCloudUuid ?? this.relatedCloudUuid,
      priority: priority ?? this.priority,
      networkConstraint: networkConstraint ?? this.networkConstraint,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<int>(assetId.value);
    }
    if (jobType.present) {
      map['job_type'] = Variable<String>(
          $SyncJobsTable.$converterjobType.toSql(jobType.value));
    }
    if (status.present) {
      map['status'] =
          Variable<String>($SyncJobsTable.$converterstatus.toSql(status.value));
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (relatedCloudUuid.present) {
      map['related_cloud_uuid'] = Variable<String>(relatedCloudUuid.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (networkConstraint.present) {
      map['network_constraint'] = Variable<String>($SyncJobsTable
          .$converternetworkConstraint
          .toSql(networkConstraint.value));
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncJobsCompanion(')
          ..write('id: $id, ')
          ..write('assetId: $assetId, ')
          ..write('jobType: $jobType, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('relatedCloudUuid: $relatedCloudUuid, ')
          ..write('priority: $priority, ')
          ..write('networkConstraint: $networkConstraint')
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

class $AlbumsTable extends Albums with TableInfo<$AlbumsTable, Album> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlbumsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _assetCountMeta =
      const VerificationMeta('assetCount');
  @override
  late final GeneratedColumn<int> assetCount = GeneratedColumn<int>(
      'asset_count', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumnWithTypeConverter<AlbumSource, int> source =
      GeneratedColumn<int>('source', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<AlbumSource>($AlbumsTable.$convertersource);
  static const VerificationMeta _thumbnailIdMeta =
      const VerificationMeta('thumbnailId');
  @override
  late final GeneratedColumn<String> thumbnailId = GeneratedColumn<String>(
      'thumbnail_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, assetCount, source, thumbnailId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'albums';
  @override
  VerificationContext validateIntegrity(Insertable<Album> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('asset_count')) {
      context.handle(
          _assetCountMeta,
          assetCount.isAcceptableOrUnknown(
              data['asset_count']!, _assetCountMeta));
    } else if (isInserting) {
      context.missing(_assetCountMeta);
    }
    context.handle(_sourceMeta, const VerificationResult.success());
    if (data.containsKey('thumbnail_id')) {
      context.handle(
          _thumbnailIdMeta,
          thumbnailId.isAcceptableOrUnknown(
              data['thumbnail_id']!, _thumbnailIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Album map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Album(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      assetCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}asset_count'])!,
      source: $AlbumsTable.$convertersource.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}source'])!),
      thumbnailId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}thumbnail_id']),
    );
  }

  @override
  $AlbumsTable createAlias(String alias) {
    return $AlbumsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AlbumSource, int, int> $convertersource =
      const EnumIndexConverter<AlbumSource>(AlbumSource.values);
}

class Album extends DataClass implements Insertable<Album> {
  /// 相册ID (主键, 文本类型)
  final String id;

  /// 相册名称
  final String name;

  /// 相册包含的媒体数量
  final int assetCount;

  /// 相册来源 (本地或云端)
  final AlbumSource source;

  /// 封面媒体的ID (可空)
  final String? thumbnailId;
  const Album(
      {required this.id,
      required this.name,
      required this.assetCount,
      required this.source,
      this.thumbnailId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['asset_count'] = Variable<int>(assetCount);
    {
      map['source'] =
          Variable<int>($AlbumsTable.$convertersource.toSql(source));
    }
    if (!nullToAbsent || thumbnailId != null) {
      map['thumbnail_id'] = Variable<String>(thumbnailId);
    }
    return map;
  }

  AlbumsCompanion toCompanion(bool nullToAbsent) {
    return AlbumsCompanion(
      id: Value(id),
      name: Value(name),
      assetCount: Value(assetCount),
      source: Value(source),
      thumbnailId: thumbnailId == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailId),
    );
  }

  factory Album.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Album(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      assetCount: serializer.fromJson<int>(json['assetCount']),
      source: $AlbumsTable.$convertersource
          .fromJson(serializer.fromJson<int>(json['source'])),
      thumbnailId: serializer.fromJson<String?>(json['thumbnailId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'assetCount': serializer.toJson<int>(assetCount),
      'source':
          serializer.toJson<int>($AlbumsTable.$convertersource.toJson(source)),
      'thumbnailId': serializer.toJson<String?>(thumbnailId),
    };
  }

  Album copyWith(
          {String? id,
          String? name,
          int? assetCount,
          AlbumSource? source,
          Value<String?> thumbnailId = const Value.absent()}) =>
      Album(
        id: id ?? this.id,
        name: name ?? this.name,
        assetCount: assetCount ?? this.assetCount,
        source: source ?? this.source,
        thumbnailId: thumbnailId.present ? thumbnailId.value : this.thumbnailId,
      );
  Album copyWithCompanion(AlbumsCompanion data) {
    return Album(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      assetCount:
          data.assetCount.present ? data.assetCount.value : this.assetCount,
      source: data.source.present ? data.source.value : this.source,
      thumbnailId:
          data.thumbnailId.present ? data.thumbnailId.value : this.thumbnailId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Album(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('assetCount: $assetCount, ')
          ..write('source: $source, ')
          ..write('thumbnailId: $thumbnailId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, assetCount, source, thumbnailId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Album &&
          other.id == this.id &&
          other.name == this.name &&
          other.assetCount == this.assetCount &&
          other.source == this.source &&
          other.thumbnailId == this.thumbnailId);
}

class AlbumsCompanion extends UpdateCompanion<Album> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> assetCount;
  final Value<AlbumSource> source;
  final Value<String?> thumbnailId;
  final Value<int> rowid;
  const AlbumsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.assetCount = const Value.absent(),
    this.source = const Value.absent(),
    this.thumbnailId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AlbumsCompanion.insert({
    required String id,
    required String name,
    required int assetCount,
    required AlbumSource source,
    this.thumbnailId = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        assetCount = Value(assetCount),
        source = Value(source);
  static Insertable<Album> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? assetCount,
    Expression<int>? source,
    Expression<String>? thumbnailId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (assetCount != null) 'asset_count': assetCount,
      if (source != null) 'source': source,
      if (thumbnailId != null) 'thumbnail_id': thumbnailId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AlbumsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<int>? assetCount,
      Value<AlbumSource>? source,
      Value<String?>? thumbnailId,
      Value<int>? rowid}) {
    return AlbumsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      assetCount: assetCount ?? this.assetCount,
      source: source ?? this.source,
      thumbnailId: thumbnailId ?? this.thumbnailId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (assetCount.present) {
      map['asset_count'] = Variable<int>(assetCount.value);
    }
    if (source.present) {
      map['source'] =
          Variable<int>($AlbumsTable.$convertersource.toSql(source.value));
    }
    if (thumbnailId.present) {
      map['thumbnail_id'] = Variable<String>(thumbnailId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlbumsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('assetCount: $assetCount, ')
          ..write('source: $source, ')
          ..write('thumbnailId: $thumbnailId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MediaAssetsTable mediaAssets = $MediaAssetsTable(this);
  late final $SyncJobsTable syncJobs = $SyncJobsTable(this);
  late final $UserSettingsTable userSettings = $UserSettingsTable(this);
  late final $AlbumsTable albums = $AlbumsTable(this);
  late final MediaAssetDao mediaAssetDao = MediaAssetDao(this as AppDatabase);
  late final SyncJobDao syncJobDao = SyncJobDao(this as AppDatabase);
  late final AlbumDao albumDao = AlbumDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [mediaAssets, syncJobs, userSettings, albums];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('media_assets',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('sync_jobs', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$MediaAssetsTableCreateCompanionBuilder = MediaAssetsCompanion
    Function({
  Value<int> id,
  Value<String?> localId,
  Value<String?> cloudUuid,
  Value<String?> contentHash,
  required SyncStatus syncStatus,
  required MediaType assetType,
  Value<String?> filePath,
  Value<String?> fileName,
  Value<int?> width,
  Value<int?> height,
  Value<int?> durationSec,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$MediaAssetsTableUpdateCompanionBuilder = MediaAssetsCompanion
    Function({
  Value<int> id,
  Value<String?> localId,
  Value<String?> cloudUuid,
  Value<String?> contentHash,
  Value<SyncStatus> syncStatus,
  Value<MediaType> assetType,
  Value<String?> filePath,
  Value<String?> fileName,
  Value<int?> width,
  Value<int?> height,
  Value<int?> durationSec,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$MediaAssetsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MediaAssetsTable,
    MediaAsset,
    $$MediaAssetsTableFilterComposer,
    $$MediaAssetsTableOrderingComposer,
    $$MediaAssetsTableCreateCompanionBuilder,
    $$MediaAssetsTableUpdateCompanionBuilder> {
  $$MediaAssetsTableTableManager(_$AppDatabase db, $MediaAssetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$MediaAssetsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$MediaAssetsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> localId = const Value.absent(),
            Value<String?> cloudUuid = const Value.absent(),
            Value<String?> contentHash = const Value.absent(),
            Value<SyncStatus> syncStatus = const Value.absent(),
            Value<MediaType> assetType = const Value.absent(),
            Value<String?> filePath = const Value.absent(),
            Value<String?> fileName = const Value.absent(),
            Value<int?> width = const Value.absent(),
            Value<int?> height = const Value.absent(),
            Value<int?> durationSec = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              MediaAssetsCompanion(
            id: id,
            localId: localId,
            cloudUuid: cloudUuid,
            contentHash: contentHash,
            syncStatus: syncStatus,
            assetType: assetType,
            filePath: filePath,
            fileName: fileName,
            width: width,
            height: height,
            durationSec: durationSec,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> localId = const Value.absent(),
            Value<String?> cloudUuid = const Value.absent(),
            Value<String?> contentHash = const Value.absent(),
            required SyncStatus syncStatus,
            required MediaType assetType,
            Value<String?> filePath = const Value.absent(),
            Value<String?> fileName = const Value.absent(),
            Value<int?> width = const Value.absent(),
            Value<int?> height = const Value.absent(),
            Value<int?> durationSec = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
          }) =>
              MediaAssetsCompanion.insert(
            id: id,
            localId: localId,
            cloudUuid: cloudUuid,
            contentHash: contentHash,
            syncStatus: syncStatus,
            assetType: assetType,
            filePath: filePath,
            fileName: fileName,
            width: width,
            height: height,
            durationSec: durationSec,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
        ));
}

class $$MediaAssetsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $MediaAssetsTable> {
  $$MediaAssetsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get localId => $state.composableBuilder(
      column: $state.table.localId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get cloudUuid => $state.composableBuilder(
      column: $state.table.cloudUuid,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get contentHash => $state.composableBuilder(
      column: $state.table.contentHash,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<SyncStatus, SyncStatus, String>
      get syncStatus => $state.composableBuilder(
          column: $state.table.syncStatus,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<MediaType, MediaType, String> get assetType =>
      $state.composableBuilder(
          column: $state.table.assetType,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnFilters<String> get filePath => $state.composableBuilder(
      column: $state.table.filePath,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get fileName => $state.composableBuilder(
      column: $state.table.fileName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get width => $state.composableBuilder(
      column: $state.table.width,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get height => $state.composableBuilder(
      column: $state.table.height,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get durationSec => $state.composableBuilder(
      column: $state.table.durationSec,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ComposableFilter syncJobsRefs(
      ComposableFilter Function($$SyncJobsTableFilterComposer f) f) {
    final $$SyncJobsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.syncJobs,
        getReferencedColumn: (t) => t.assetId,
        builder: (joinBuilder, parentComposers) =>
            $$SyncJobsTableFilterComposer(ComposerState(
                $state.db, $state.db.syncJobs, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$MediaAssetsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $MediaAssetsTable> {
  $$MediaAssetsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get localId => $state.composableBuilder(
      column: $state.table.localId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get cloudUuid => $state.composableBuilder(
      column: $state.table.cloudUuid,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get contentHash => $state.composableBuilder(
      column: $state.table.contentHash,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get syncStatus => $state.composableBuilder(
      column: $state.table.syncStatus,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get assetType => $state.composableBuilder(
      column: $state.table.assetType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get filePath => $state.composableBuilder(
      column: $state.table.filePath,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get fileName => $state.composableBuilder(
      column: $state.table.fileName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get width => $state.composableBuilder(
      column: $state.table.width,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get height => $state.composableBuilder(
      column: $state.table.height,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get durationSec => $state.composableBuilder(
      column: $state.table.durationSec,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$SyncJobsTableCreateCompanionBuilder = SyncJobsCompanion Function({
  Value<int> id,
  Value<int?> assetId,
  required JobType jobType,
  required JobStatus status,
  Value<int> attempts,
  Value<String?> errorMessage,
  Value<DateTime> createdAt,
  Value<String?> relatedCloudUuid,
  Value<int> priority,
  Value<NetworkConstraint> networkConstraint,
});
typedef $$SyncJobsTableUpdateCompanionBuilder = SyncJobsCompanion Function({
  Value<int> id,
  Value<int?> assetId,
  Value<JobType> jobType,
  Value<JobStatus> status,
  Value<int> attempts,
  Value<String?> errorMessage,
  Value<DateTime> createdAt,
  Value<String?> relatedCloudUuid,
  Value<int> priority,
  Value<NetworkConstraint> networkConstraint,
});

class $$SyncJobsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncJobsTable,
    SyncJob,
    $$SyncJobsTableFilterComposer,
    $$SyncJobsTableOrderingComposer,
    $$SyncJobsTableCreateCompanionBuilder,
    $$SyncJobsTableUpdateCompanionBuilder> {
  $$SyncJobsTableTableManager(_$AppDatabase db, $SyncJobsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$SyncJobsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$SyncJobsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> assetId = const Value.absent(),
            Value<JobType> jobType = const Value.absent(),
            Value<JobStatus> status = const Value.absent(),
            Value<int> attempts = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String?> relatedCloudUuid = const Value.absent(),
            Value<int> priority = const Value.absent(),
            Value<NetworkConstraint> networkConstraint = const Value.absent(),
          }) =>
              SyncJobsCompanion(
            id: id,
            assetId: assetId,
            jobType: jobType,
            status: status,
            attempts: attempts,
            errorMessage: errorMessage,
            createdAt: createdAt,
            relatedCloudUuid: relatedCloudUuid,
            priority: priority,
            networkConstraint: networkConstraint,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> assetId = const Value.absent(),
            required JobType jobType,
            required JobStatus status,
            Value<int> attempts = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String?> relatedCloudUuid = const Value.absent(),
            Value<int> priority = const Value.absent(),
            Value<NetworkConstraint> networkConstraint = const Value.absent(),
          }) =>
              SyncJobsCompanion.insert(
            id: id,
            assetId: assetId,
            jobType: jobType,
            status: status,
            attempts: attempts,
            errorMessage: errorMessage,
            createdAt: createdAt,
            relatedCloudUuid: relatedCloudUuid,
            priority: priority,
            networkConstraint: networkConstraint,
          ),
        ));
}

class $$SyncJobsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $SyncJobsTable> {
  $$SyncJobsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<JobType, JobType, String> get jobType =>
      $state.composableBuilder(
          column: $state.table.jobType,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<JobStatus, JobStatus, String> get status =>
      $state.composableBuilder(
          column: $state.table.status,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnFilters<int> get attempts => $state.composableBuilder(
      column: $state.table.attempts,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get errorMessage => $state.composableBuilder(
      column: $state.table.errorMessage,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get relatedCloudUuid => $state.composableBuilder(
      column: $state.table.relatedCloudUuid,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get priority => $state.composableBuilder(
      column: $state.table.priority,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<NetworkConstraint, NetworkConstraint, String>
      get networkConstraint => $state.composableBuilder(
          column: $state.table.networkConstraint,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  $$MediaAssetsTableFilterComposer get assetId {
    final $$MediaAssetsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.assetId,
        referencedTable: $state.db.mediaAssets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$MediaAssetsTableFilterComposer(ComposerState($state.db,
                $state.db.mediaAssets, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$SyncJobsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $SyncJobsTable> {
  $$SyncJobsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get jobType => $state.composableBuilder(
      column: $state.table.jobType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get attempts => $state.composableBuilder(
      column: $state.table.attempts,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get errorMessage => $state.composableBuilder(
      column: $state.table.errorMessage,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get relatedCloudUuid => $state.composableBuilder(
      column: $state.table.relatedCloudUuid,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get priority => $state.composableBuilder(
      column: $state.table.priority,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get networkConstraint => $state.composableBuilder(
      column: $state.table.networkConstraint,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$MediaAssetsTableOrderingComposer get assetId {
    final $$MediaAssetsTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.assetId,
        referencedTable: $state.db.mediaAssets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$MediaAssetsTableOrderingComposer(ComposerState($state.db,
                $state.db.mediaAssets, joinBuilder, parentComposers)));
    return composer;
  }
}

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

class $$UserSettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserSettingsTable,
    UserSetting,
    $$UserSettingsTableFilterComposer,
    $$UserSettingsTableOrderingComposer,
    $$UserSettingsTableCreateCompanionBuilder,
    $$UserSettingsTableUpdateCompanionBuilder> {
  $$UserSettingsTableTableManager(_$AppDatabase db, $UserSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$UserSettingsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$UserSettingsTableOrderingComposer(ComposerState(db, table)),
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
        ));
}

class $$UserSettingsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $UserSettingsTable> {
  $$UserSettingsTableFilterComposer(super.$state);
  ColumnFilters<String> get key => $state.composableBuilder(
      column: $state.table.key,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get value => $state.composableBuilder(
      column: $state.table.value,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$UserSettingsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $UserSettingsTable> {
  $$UserSettingsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get key => $state.composableBuilder(
      column: $state.table.key,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get value => $state.composableBuilder(
      column: $state.table.value,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$AlbumsTableCreateCompanionBuilder = AlbumsCompanion Function({
  required String id,
  required String name,
  required int assetCount,
  required AlbumSource source,
  Value<String?> thumbnailId,
  Value<int> rowid,
});
typedef $$AlbumsTableUpdateCompanionBuilder = AlbumsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<int> assetCount,
  Value<AlbumSource> source,
  Value<String?> thumbnailId,
  Value<int> rowid,
});

class $$AlbumsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AlbumsTable,
    Album,
    $$AlbumsTableFilterComposer,
    $$AlbumsTableOrderingComposer,
    $$AlbumsTableCreateCompanionBuilder,
    $$AlbumsTableUpdateCompanionBuilder> {
  $$AlbumsTableTableManager(_$AppDatabase db, $AlbumsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$AlbumsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$AlbumsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> assetCount = const Value.absent(),
            Value<AlbumSource> source = const Value.absent(),
            Value<String?> thumbnailId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AlbumsCompanion(
            id: id,
            name: name,
            assetCount: assetCount,
            source: source,
            thumbnailId: thumbnailId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required int assetCount,
            required AlbumSource source,
            Value<String?> thumbnailId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AlbumsCompanion.insert(
            id: id,
            name: name,
            assetCount: assetCount,
            source: source,
            thumbnailId: thumbnailId,
            rowid: rowid,
          ),
        ));
}

class $$AlbumsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $AlbumsTable> {
  $$AlbumsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get assetCount => $state.composableBuilder(
      column: $state.table.assetCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<AlbumSource, AlbumSource, int> get source =>
      $state.composableBuilder(
          column: $state.table.source,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnFilters<String> get thumbnailId => $state.composableBuilder(
      column: $state.table.thumbnailId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$AlbumsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $AlbumsTable> {
  $$AlbumsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get assetCount => $state.composableBuilder(
      column: $state.table.assetCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get source => $state.composableBuilder(
      column: $state.table.source,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get thumbnailId => $state.composableBuilder(
      column: $state.table.thumbnailId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MediaAssetsTableTableManager get mediaAssets =>
      $$MediaAssetsTableTableManager(_db, _db.mediaAssets);
  $$SyncJobsTableTableManager get syncJobs =>
      $$SyncJobsTableTableManager(_db, _db.syncJobs);
  $$UserSettingsTableTableManager get userSettings =>
      $$UserSettingsTableTableManager(_db, _db.userSettings);
  $$AlbumsTableTableManager get albums =>
      $$AlbumsTableTableManager(_db, _db.albums);
}

mixin _$MediaAssetDaoMixin on DatabaseAccessor<AppDatabase> {
  $MediaAssetsTable get mediaAssets => attachedDatabase.mediaAssets;
  $SyncJobsTable get syncJobs => attachedDatabase.syncJobs;
}
mixin _$SyncJobDaoMixin on DatabaseAccessor<AppDatabase> {
  $MediaAssetsTable get mediaAssets => attachedDatabase.mediaAssets;
  $SyncJobsTable get syncJobs => attachedDatabase.syncJobs;
}
mixin _$AlbumDaoMixin on DatabaseAccessor<AppDatabase> {
  $AlbumsTable get albums => attachedDatabase.albums;
}
