// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UserEntityTable extends UserEntity
    with TableInfo<$UserEntityTable, UserEntityData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserEntityTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _avatarUrlMeta =
      const VerificationMeta('avatarUrl');
  @override
  late final GeneratedColumn<String> avatarUrl = GeneratedColumn<String>(
      'avatar_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
  List<GeneratedColumn> get $columns =>
      [id, name, email, avatarUrl, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_entity';
  @override
  VerificationContext validateIntegrity(Insertable<UserEntityData> instance,
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
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    }
    if (data.containsKey('avatar_url')) {
      context.handle(_avatarUrlMeta,
          avatarUrl.isAcceptableOrUnknown(data['avatar_url']!, _avatarUrlMeta));
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
  UserEntityData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserEntityData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email']),
      avatarUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}avatar_url']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $UserEntityTable createAlias(String alias) {
    return $UserEntityTable(attachedDatabase, alias);
  }

  @override
  bool get withoutRowId => true;
}

class UserEntityData extends DataClass implements Insertable<UserEntityData> {
  /// 用户 ID（主键）
  final String id;

  /// 用户名
  final String name;

  /// 邮箱
  final String? email;

  /// 头像 URL
  final String? avatarUrl;

  /// 创建时间
  final DateTime createdAt;

  /// 更新时间
  final DateTime updatedAt;
  const UserEntityData(
      {required this.id,
      required this.name,
      this.email,
      this.avatarUrl,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || avatarUrl != null) {
      map['avatar_url'] = Variable<String>(avatarUrl);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UserEntityCompanion toCompanion(bool nullToAbsent) {
    return UserEntityCompanion(
      id: Value(id),
      name: Value(name),
      email:
          email == null && nullToAbsent ? const Value.absent() : Value(email),
      avatarUrl: avatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarUrl),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserEntityData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserEntityData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      email: serializer.fromJson<String?>(json['email']),
      avatarUrl: serializer.fromJson<String?>(json['avatarUrl']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'email': serializer.toJson<String?>(email),
      'avatarUrl': serializer.toJson<String?>(avatarUrl),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UserEntityData copyWith(
          {String? id,
          String? name,
          Value<String?> email = const Value.absent(),
          Value<String?> avatarUrl = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      UserEntityData(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email.present ? email.value : this.email,
        avatarUrl: avatarUrl.present ? avatarUrl.value : this.avatarUrl,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  UserEntityData copyWithCompanion(UserEntityCompanion data) {
    return UserEntityData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
      avatarUrl: data.avatarUrl.present ? data.avatarUrl.value : this.avatarUrl,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserEntityData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, email, avatarUrl, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserEntityData &&
          other.id == this.id &&
          other.name == this.name &&
          other.email == this.email &&
          other.avatarUrl == this.avatarUrl &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class UserEntityCompanion extends UpdateCompanion<UserEntityData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> email;
  final Value<String?> avatarUrl;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const UserEntityCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  UserEntityCompanion.insert({
    required String id,
    required String name,
    this.email = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  })  : id = Value(id),
        name = Value(name),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<UserEntityData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? email,
    Expression<String>? avatarUrl,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  UserEntityCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? email,
      Value<String?>? avatarUrl,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return UserEntityCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (avatarUrl.present) {
      map['avatar_url'] = Variable<String>(avatarUrl.value);
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
    return (StringBuffer('UserEntityCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $LocalAssetEntityTable extends LocalAssetEntity
    with TableInfo<$LocalAssetEntityTable, LocalAssetEntityData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalAssetEntityTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumnWithTypeConverter<AssetType, int> type =
      GeneratedColumn<int>('type', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<AssetType>($LocalAssetEntityTable.$convertertype);
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
  static const VerificationMeta _durationInSecondsMeta =
      const VerificationMeta('durationInSeconds');
  @override
  late final GeneratedColumn<int> durationInSeconds = GeneratedColumn<int>(
      'duration_in_seconds', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _checksumMeta =
      const VerificationMeta('checksum');
  @override
  late final GeneratedColumn<String> checksum = GeneratedColumn<String>(
      'checksum', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
      'path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isFavoriteMeta =
      const VerificationMeta('isFavorite');
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
      'is_favorite', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_favorite" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _orientationMeta =
      const VerificationMeta('orientation');
  @override
  late final GeneratedColumn<int> orientation = GeneratedColumn<int>(
      'orientation', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isInPrivateSpaceMeta =
      const VerificationMeta('isInPrivateSpace');
  @override
  late final GeneratedColumn<bool> isInPrivateSpace = GeneratedColumn<bool>(
      'is_in_private_space', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_in_private_space" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _migrationStatusMeta =
      const VerificationMeta('migrationStatus');
  @override
  late final GeneratedColumnWithTypeConverter<MigrationStatus, int>
      migrationStatus = GeneratedColumn<int>(
              'migration_status', aliasedName, false,
              type: DriftSqlType.int,
              requiredDuringInsert: false,
              defaultValue: const Constant(0))
          .withConverter<MigrationStatus>(
              $LocalAssetEntityTable.$convertermigrationStatus);
  @override
  List<GeneratedColumn> get $columns => [
        name,
        type,
        createdAt,
        updatedAt,
        width,
        height,
        durationInSeconds,
        id,
        checksum,
        path,
        isFavorite,
        orientation,
        isInPrivateSpace,
        migrationStatus
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_asset_entity';
  @override
  VerificationContext validateIntegrity(
      Insertable<LocalAssetEntityData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    context.handle(_typeMeta, const VerificationResult.success());
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
    if (data.containsKey('width')) {
      context.handle(
          _widthMeta, width.isAcceptableOrUnknown(data['width']!, _widthMeta));
    }
    if (data.containsKey('height')) {
      context.handle(_heightMeta,
          height.isAcceptableOrUnknown(data['height']!, _heightMeta));
    }
    if (data.containsKey('duration_in_seconds')) {
      context.handle(
          _durationInSecondsMeta,
          durationInSeconds.isAcceptableOrUnknown(
              data['duration_in_seconds']!, _durationInSecondsMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('checksum')) {
      context.handle(_checksumMeta,
          checksum.isAcceptableOrUnknown(data['checksum']!, _checksumMeta));
    }
    if (data.containsKey('path')) {
      context.handle(
          _pathMeta, path.isAcceptableOrUnknown(data['path']!, _pathMeta));
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
          _isFavoriteMeta,
          isFavorite.isAcceptableOrUnknown(
              data['is_favorite']!, _isFavoriteMeta));
    }
    if (data.containsKey('orientation')) {
      context.handle(
          _orientationMeta,
          orientation.isAcceptableOrUnknown(
              data['orientation']!, _orientationMeta));
    }
    if (data.containsKey('is_in_private_space')) {
      context.handle(
          _isInPrivateSpaceMeta,
          isInPrivateSpace.isAcceptableOrUnknown(
              data['is_in_private_space']!, _isInPrivateSpaceMeta));
    }
    context.handle(_migrationStatusMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalAssetEntityData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalAssetEntityData(
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: $LocalAssetEntityTable.$convertertype.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}type'])!),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      width: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}width']),
      height: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}height']),
      durationInSeconds: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}duration_in_seconds']),
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      checksum: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}checksum']),
      path: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}path'])!,
      isFavorite: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_favorite'])!,
      orientation: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}orientation'])!,
      isInPrivateSpace: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}is_in_private_space'])!,
      migrationStatus: $LocalAssetEntityTable.$convertermigrationStatus.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.int, data['${effectivePrefix}migration_status'])!),
    );
  }

  @override
  $LocalAssetEntityTable createAlias(String alias) {
    return $LocalAssetEntityTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AssetType, int, int> $convertertype =
      const EnumIndexConverter<AssetType>(AssetType.values);
  static JsonTypeConverter2<MigrationStatus, int, int>
      $convertermigrationStatus =
      const EnumIndexConverter<MigrationStatus>(MigrationStatus.values);
  @override
  bool get withoutRowId => true;
}

class LocalAssetEntityData extends DataClass
    implements Insertable<LocalAssetEntityData> {
  /// 资产名称
  final String name;

  /// 资产类型
  final AssetType type;

  /// 创建时间
  final DateTime createdAt;

  /// 更新时间
  final DateTime updatedAt;

  /// 宽度（像素）
  final int? width;

  /// 高度（像素）
  final int? height;

  /// 时长（秒，仅视频/音频）
  final int? durationInSeconds;

  /// 主键（设备资产 ID）
  final String id;

  /// 文件哈希（用于与远程资产关联）
  final String? checksum;

  /// 文件路径（本地文件系统的完整路径）
  ///
  /// **用途**：
  /// - 用于读取文件内容（图片/视频显示）
  /// - 用于上传任务（备份模块需要文件路径）
  /// - 用于文件存在性检查
  ///
  /// **注意**：此字段为必填，因为本地资产必须知道文件的实际位置
  /// 才能进行读取、上传等操作。虽然可以通过 photo_manager 的 AssetEntity
  /// 通过 ID 获取文件，但存储路径可以避免每次查询，提升性能。
  final String path;

  /// 是否收藏（用于备份时同步服务器状态）
  final bool isFavorite;

  /// 图片方向（0-8，EXIF 方向值）
  final int orientation;

  /// 是否在私有空间
  /// 标识文件是否已迁移到应用私有目录
  final bool isInPrivateSpace;

  /// 迁移状态枚举
  /// 用于跟踪迁移到私有空间或移回系统相册的操作状态
  final MigrationStatus migrationStatus;
  const LocalAssetEntityData(
      {required this.name,
      required this.type,
      required this.createdAt,
      required this.updatedAt,
      this.width,
      this.height,
      this.durationInSeconds,
      required this.id,
      this.checksum,
      required this.path,
      required this.isFavorite,
      required this.orientation,
      required this.isInPrivateSpace,
      required this.migrationStatus});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    {
      map['type'] =
          Variable<int>($LocalAssetEntityTable.$convertertype.toSql(type));
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || width != null) {
      map['width'] = Variable<int>(width);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int>(height);
    }
    if (!nullToAbsent || durationInSeconds != null) {
      map['duration_in_seconds'] = Variable<int>(durationInSeconds);
    }
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || checksum != null) {
      map['checksum'] = Variable<String>(checksum);
    }
    map['path'] = Variable<String>(path);
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['orientation'] = Variable<int>(orientation);
    map['is_in_private_space'] = Variable<bool>(isInPrivateSpace);
    {
      map['migration_status'] = Variable<int>($LocalAssetEntityTable
          .$convertermigrationStatus
          .toSql(migrationStatus));
    }
    return map;
  }

  LocalAssetEntityCompanion toCompanion(bool nullToAbsent) {
    return LocalAssetEntityCompanion(
      name: Value(name),
      type: Value(type),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      width:
          width == null && nullToAbsent ? const Value.absent() : Value(width),
      height:
          height == null && nullToAbsent ? const Value.absent() : Value(height),
      durationInSeconds: durationInSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationInSeconds),
      id: Value(id),
      checksum: checksum == null && nullToAbsent
          ? const Value.absent()
          : Value(checksum),
      path: Value(path),
      isFavorite: Value(isFavorite),
      orientation: Value(orientation),
      isInPrivateSpace: Value(isInPrivateSpace),
      migrationStatus: Value(migrationStatus),
    );
  }

  factory LocalAssetEntityData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalAssetEntityData(
      name: serializer.fromJson<String>(json['name']),
      type: $LocalAssetEntityTable.$convertertype
          .fromJson(serializer.fromJson<int>(json['type'])),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      width: serializer.fromJson<int?>(json['width']),
      height: serializer.fromJson<int?>(json['height']),
      durationInSeconds: serializer.fromJson<int?>(json['durationInSeconds']),
      id: serializer.fromJson<String>(json['id']),
      checksum: serializer.fromJson<String?>(json['checksum']),
      path: serializer.fromJson<String>(json['path']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      orientation: serializer.fromJson<int>(json['orientation']),
      isInPrivateSpace: serializer.fromJson<bool>(json['isInPrivateSpace']),
      migrationStatus: $LocalAssetEntityTable.$convertermigrationStatus
          .fromJson(serializer.fromJson<int>(json['migrationStatus'])),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'type': serializer
          .toJson<int>($LocalAssetEntityTable.$convertertype.toJson(type)),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'width': serializer.toJson<int?>(width),
      'height': serializer.toJson<int?>(height),
      'durationInSeconds': serializer.toJson<int?>(durationInSeconds),
      'id': serializer.toJson<String>(id),
      'checksum': serializer.toJson<String?>(checksum),
      'path': serializer.toJson<String>(path),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'orientation': serializer.toJson<int>(orientation),
      'isInPrivateSpace': serializer.toJson<bool>(isInPrivateSpace),
      'migrationStatus': serializer.toJson<int>($LocalAssetEntityTable
          .$convertermigrationStatus
          .toJson(migrationStatus)),
    };
  }

  LocalAssetEntityData copyWith(
          {String? name,
          AssetType? type,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<int?> width = const Value.absent(),
          Value<int?> height = const Value.absent(),
          Value<int?> durationInSeconds = const Value.absent(),
          String? id,
          Value<String?> checksum = const Value.absent(),
          String? path,
          bool? isFavorite,
          int? orientation,
          bool? isInPrivateSpace,
          MigrationStatus? migrationStatus}) =>
      LocalAssetEntityData(
        name: name ?? this.name,
        type: type ?? this.type,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        width: width.present ? width.value : this.width,
        height: height.present ? height.value : this.height,
        durationInSeconds: durationInSeconds.present
            ? durationInSeconds.value
            : this.durationInSeconds,
        id: id ?? this.id,
        checksum: checksum.present ? checksum.value : this.checksum,
        path: path ?? this.path,
        isFavorite: isFavorite ?? this.isFavorite,
        orientation: orientation ?? this.orientation,
        isInPrivateSpace: isInPrivateSpace ?? this.isInPrivateSpace,
        migrationStatus: migrationStatus ?? this.migrationStatus,
      );
  LocalAssetEntityData copyWithCompanion(LocalAssetEntityCompanion data) {
    return LocalAssetEntityData(
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      durationInSeconds: data.durationInSeconds.present
          ? data.durationInSeconds.value
          : this.durationInSeconds,
      id: data.id.present ? data.id.value : this.id,
      checksum: data.checksum.present ? data.checksum.value : this.checksum,
      path: data.path.present ? data.path.value : this.path,
      isFavorite:
          data.isFavorite.present ? data.isFavorite.value : this.isFavorite,
      orientation:
          data.orientation.present ? data.orientation.value : this.orientation,
      isInPrivateSpace: data.isInPrivateSpace.present
          ? data.isInPrivateSpace.value
          : this.isInPrivateSpace,
      migrationStatus: data.migrationStatus.present
          ? data.migrationStatus.value
          : this.migrationStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalAssetEntityData(')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('durationInSeconds: $durationInSeconds, ')
          ..write('id: $id, ')
          ..write('checksum: $checksum, ')
          ..write('path: $path, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('orientation: $orientation, ')
          ..write('isInPrivateSpace: $isInPrivateSpace, ')
          ..write('migrationStatus: $migrationStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      name,
      type,
      createdAt,
      updatedAt,
      width,
      height,
      durationInSeconds,
      id,
      checksum,
      path,
      isFavorite,
      orientation,
      isInPrivateSpace,
      migrationStatus);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalAssetEntityData &&
          other.name == this.name &&
          other.type == this.type &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.width == this.width &&
          other.height == this.height &&
          other.durationInSeconds == this.durationInSeconds &&
          other.id == this.id &&
          other.checksum == this.checksum &&
          other.path == this.path &&
          other.isFavorite == this.isFavorite &&
          other.orientation == this.orientation &&
          other.isInPrivateSpace == this.isInPrivateSpace &&
          other.migrationStatus == this.migrationStatus);
}

class LocalAssetEntityCompanion extends UpdateCompanion<LocalAssetEntityData> {
  final Value<String> name;
  final Value<AssetType> type;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int?> width;
  final Value<int?> height;
  final Value<int?> durationInSeconds;
  final Value<String> id;
  final Value<String?> checksum;
  final Value<String> path;
  final Value<bool> isFavorite;
  final Value<int> orientation;
  final Value<bool> isInPrivateSpace;
  final Value<MigrationStatus> migrationStatus;
  const LocalAssetEntityCompanion({
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.durationInSeconds = const Value.absent(),
    this.id = const Value.absent(),
    this.checksum = const Value.absent(),
    this.path = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.orientation = const Value.absent(),
    this.isInPrivateSpace = const Value.absent(),
    this.migrationStatus = const Value.absent(),
  });
  LocalAssetEntityCompanion.insert({
    required String name,
    required AssetType type,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.durationInSeconds = const Value.absent(),
    required String id,
    this.checksum = const Value.absent(),
    required String path,
    this.isFavorite = const Value.absent(),
    this.orientation = const Value.absent(),
    this.isInPrivateSpace = const Value.absent(),
    this.migrationStatus = const Value.absent(),
  })  : name = Value(name),
        type = Value(type),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        id = Value(id),
        path = Value(path);
  static Insertable<LocalAssetEntityData> custom({
    Expression<String>? name,
    Expression<int>? type,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? width,
    Expression<int>? height,
    Expression<int>? durationInSeconds,
    Expression<String>? id,
    Expression<String>? checksum,
    Expression<String>? path,
    Expression<bool>? isFavorite,
    Expression<int>? orientation,
    Expression<bool>? isInPrivateSpace,
    Expression<int>? migrationStatus,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (durationInSeconds != null) 'duration_in_seconds': durationInSeconds,
      if (id != null) 'id': id,
      if (checksum != null) 'checksum': checksum,
      if (path != null) 'path': path,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (orientation != null) 'orientation': orientation,
      if (isInPrivateSpace != null) 'is_in_private_space': isInPrivateSpace,
      if (migrationStatus != null) 'migration_status': migrationStatus,
    });
  }

  LocalAssetEntityCompanion copyWith(
      {Value<String>? name,
      Value<AssetType>? type,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int?>? width,
      Value<int?>? height,
      Value<int?>? durationInSeconds,
      Value<String>? id,
      Value<String?>? checksum,
      Value<String>? path,
      Value<bool>? isFavorite,
      Value<int>? orientation,
      Value<bool>? isInPrivateSpace,
      Value<MigrationStatus>? migrationStatus}) {
    return LocalAssetEntityCompanion(
      name: name ?? this.name,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      width: width ?? this.width,
      height: height ?? this.height,
      durationInSeconds: durationInSeconds ?? this.durationInSeconds,
      id: id ?? this.id,
      checksum: checksum ?? this.checksum,
      path: path ?? this.path,
      isFavorite: isFavorite ?? this.isFavorite,
      orientation: orientation ?? this.orientation,
      isInPrivateSpace: isInPrivateSpace ?? this.isInPrivateSpace,
      migrationStatus: migrationStatus ?? this.migrationStatus,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(
          $LocalAssetEntityTable.$convertertype.toSql(type.value));
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (durationInSeconds.present) {
      map['duration_in_seconds'] = Variable<int>(durationInSeconds.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (checksum.present) {
      map['checksum'] = Variable<String>(checksum.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (orientation.present) {
      map['orientation'] = Variable<int>(orientation.value);
    }
    if (isInPrivateSpace.present) {
      map['is_in_private_space'] = Variable<bool>(isInPrivateSpace.value);
    }
    if (migrationStatus.present) {
      map['migration_status'] = Variable<int>($LocalAssetEntityTable
          .$convertermigrationStatus
          .toSql(migrationStatus.value));
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalAssetEntityCompanion(')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('durationInSeconds: $durationInSeconds, ')
          ..write('id: $id, ')
          ..write('checksum: $checksum, ')
          ..write('path: $path, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('orientation: $orientation, ')
          ..write('isInPrivateSpace: $isInPrivateSpace, ')
          ..write('migrationStatus: $migrationStatus')
          ..write(')'))
        .toString();
  }
}

class $RemoteAssetEntityTable extends RemoteAssetEntity
    with TableInfo<$RemoteAssetEntityTable, RemoteAssetEntityData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemoteAssetEntityTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumnWithTypeConverter<AssetType, int> type =
      GeneratedColumn<int>('type', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<AssetType>($RemoteAssetEntityTable.$convertertype);
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
  static const VerificationMeta _durationInSecondsMeta =
      const VerificationMeta('durationInSeconds');
  @override
  late final GeneratedColumn<int> durationInSeconds = GeneratedColumn<int>(
      'duration_in_seconds', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _checksumMeta =
      const VerificationMeta('checksum');
  @override
  late final GeneratedColumn<String> checksum = GeneratedColumn<String>(
      'checksum', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isFavoriteMeta =
      const VerificationMeta('isFavorite');
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
      'is_favorite', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_favorite" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _ownerIdMeta =
      const VerificationMeta('ownerId');
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
      'owner_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES user_entity (id) ON DELETE CASCADE'));
  static const VerificationMeta _localDateTimeMeta =
      const VerificationMeta('localDateTime');
  @override
  late final GeneratedColumn<DateTime> localDateTime =
      GeneratedColumn<DateTime>('local_date_time', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _thumbHashMeta =
      const VerificationMeta('thumbHash');
  @override
  late final GeneratedColumn<String> thumbHash = GeneratedColumn<String>(
      'thumb_hash', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _livePhotoVideoIdMeta =
      const VerificationMeta('livePhotoVideoId');
  @override
  late final GeneratedColumn<String> livePhotoVideoId = GeneratedColumn<String>(
      'live_photo_video_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _visibilityMeta =
      const VerificationMeta('visibility');
  @override
  late final GeneratedColumnWithTypeConverter<AssetVisibility, int> visibility =
      GeneratedColumn<int>('visibility', aliasedName, false,
              type: DriftSqlType.int,
              requiredDuringInsert: false,
              defaultValue: const Constant(1))
          .withConverter<AssetVisibility>(
              $RemoteAssetEntityTable.$convertervisibility);
  static const VerificationMeta _stackIdMeta =
      const VerificationMeta('stackId');
  @override
  late final GeneratedColumn<String> stackId = GeneratedColumn<String>(
      'stack_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _libraryIdMeta =
      const VerificationMeta('libraryId');
  @override
  late final GeneratedColumn<String> libraryId = GeneratedColumn<String>(
      'library_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        name,
        type,
        createdAt,
        updatedAt,
        width,
        height,
        durationInSeconds,
        id,
        checksum,
        isFavorite,
        ownerId,
        localDateTime,
        thumbHash,
        deletedAt,
        livePhotoVideoId,
        visibility,
        stackId,
        libraryId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'remote_asset_entity';
  @override
  VerificationContext validateIntegrity(
      Insertable<RemoteAssetEntityData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    context.handle(_typeMeta, const VerificationResult.success());
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
    if (data.containsKey('width')) {
      context.handle(
          _widthMeta, width.isAcceptableOrUnknown(data['width']!, _widthMeta));
    }
    if (data.containsKey('height')) {
      context.handle(_heightMeta,
          height.isAcceptableOrUnknown(data['height']!, _heightMeta));
    }
    if (data.containsKey('duration_in_seconds')) {
      context.handle(
          _durationInSecondsMeta,
          durationInSeconds.isAcceptableOrUnknown(
              data['duration_in_seconds']!, _durationInSecondsMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('checksum')) {
      context.handle(_checksumMeta,
          checksum.isAcceptableOrUnknown(data['checksum']!, _checksumMeta));
    } else if (isInserting) {
      context.missing(_checksumMeta);
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
          _isFavoriteMeta,
          isFavorite.isAcceptableOrUnknown(
              data['is_favorite']!, _isFavoriteMeta));
    }
    if (data.containsKey('owner_id')) {
      context.handle(_ownerIdMeta,
          ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta));
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('local_date_time')) {
      context.handle(
          _localDateTimeMeta,
          localDateTime.isAcceptableOrUnknown(
              data['local_date_time']!, _localDateTimeMeta));
    }
    if (data.containsKey('thumb_hash')) {
      context.handle(_thumbHashMeta,
          thumbHash.isAcceptableOrUnknown(data['thumb_hash']!, _thumbHashMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('live_photo_video_id')) {
      context.handle(
          _livePhotoVideoIdMeta,
          livePhotoVideoId.isAcceptableOrUnknown(
              data['live_photo_video_id']!, _livePhotoVideoIdMeta));
    }
    context.handle(_visibilityMeta, const VerificationResult.success());
    if (data.containsKey('stack_id')) {
      context.handle(_stackIdMeta,
          stackId.isAcceptableOrUnknown(data['stack_id']!, _stackIdMeta));
    }
    if (data.containsKey('library_id')) {
      context.handle(_libraryIdMeta,
          libraryId.isAcceptableOrUnknown(data['library_id']!, _libraryIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RemoteAssetEntityData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RemoteAssetEntityData(
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: $RemoteAssetEntityTable.$convertertype.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}type'])!),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      width: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}width']),
      height: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}height']),
      durationInSeconds: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}duration_in_seconds']),
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      checksum: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}checksum'])!,
      isFavorite: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_favorite'])!,
      ownerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_id'])!,
      localDateTime: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}local_date_time']),
      thumbHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}thumb_hash']),
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      livePhotoVideoId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}live_photo_video_id']),
      visibility: $RemoteAssetEntityTable.$convertervisibility.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}visibility'])!),
      stackId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stack_id']),
      libraryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}library_id']),
    );
  }

  @override
  $RemoteAssetEntityTable createAlias(String alias) {
    return $RemoteAssetEntityTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AssetType, int, int> $convertertype =
      const EnumIndexConverter<AssetType>(AssetType.values);
  static JsonTypeConverter2<AssetVisibility, int, int> $convertervisibility =
      const EnumIndexConverter<AssetVisibility>(AssetVisibility.values);
  @override
  bool get withoutRowId => true;
}

class RemoteAssetEntityData extends DataClass
    implements Insertable<RemoteAssetEntityData> {
  /// 资产名称
  final String name;

  /// 资产类型
  final AssetType type;

  /// 创建时间
  final DateTime createdAt;

  /// 更新时间
  final DateTime updatedAt;

  /// 宽度（像素）
  final int? width;

  /// 高度（像素）
  final int? height;

  /// 时长（秒，仅视频/音频）
  final int? durationInSeconds;

  /// 主键（服务器端资产 ID）
  final String id;

  /// 文件哈希（必填，用于去重和关联）
  final String checksum;

  /// 是否收藏
  final bool isFavorite;

  /// 所有者用户 ID
  final String ownerId;

  /// 本地拍摄时间
  final DateTime? localDateTime;

  /// 缩略图哈希
  final String? thumbHash;

  /// 删除时间（软删除）
  final DateTime? deletedAt;

  /// Live Photo 视频 ID
  final String? livePhotoVideoId;

  /// 可见性枚举
  final AssetVisibility visibility;

  /// 堆叠 ID
  final String? stackId;

  /// 库 ID（支持多库）
  final String? libraryId;
  const RemoteAssetEntityData(
      {required this.name,
      required this.type,
      required this.createdAt,
      required this.updatedAt,
      this.width,
      this.height,
      this.durationInSeconds,
      required this.id,
      required this.checksum,
      required this.isFavorite,
      required this.ownerId,
      this.localDateTime,
      this.thumbHash,
      this.deletedAt,
      this.livePhotoVideoId,
      required this.visibility,
      this.stackId,
      this.libraryId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    {
      map['type'] =
          Variable<int>($RemoteAssetEntityTable.$convertertype.toSql(type));
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || width != null) {
      map['width'] = Variable<int>(width);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int>(height);
    }
    if (!nullToAbsent || durationInSeconds != null) {
      map['duration_in_seconds'] = Variable<int>(durationInSeconds);
    }
    map['id'] = Variable<String>(id);
    map['checksum'] = Variable<String>(checksum);
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['owner_id'] = Variable<String>(ownerId);
    if (!nullToAbsent || localDateTime != null) {
      map['local_date_time'] = Variable<DateTime>(localDateTime);
    }
    if (!nullToAbsent || thumbHash != null) {
      map['thumb_hash'] = Variable<String>(thumbHash);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || livePhotoVideoId != null) {
      map['live_photo_video_id'] = Variable<String>(livePhotoVideoId);
    }
    {
      map['visibility'] = Variable<int>(
          $RemoteAssetEntityTable.$convertervisibility.toSql(visibility));
    }
    if (!nullToAbsent || stackId != null) {
      map['stack_id'] = Variable<String>(stackId);
    }
    if (!nullToAbsent || libraryId != null) {
      map['library_id'] = Variable<String>(libraryId);
    }
    return map;
  }

  RemoteAssetEntityCompanion toCompanion(bool nullToAbsent) {
    return RemoteAssetEntityCompanion(
      name: Value(name),
      type: Value(type),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      width:
          width == null && nullToAbsent ? const Value.absent() : Value(width),
      height:
          height == null && nullToAbsent ? const Value.absent() : Value(height),
      durationInSeconds: durationInSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationInSeconds),
      id: Value(id),
      checksum: Value(checksum),
      isFavorite: Value(isFavorite),
      ownerId: Value(ownerId),
      localDateTime: localDateTime == null && nullToAbsent
          ? const Value.absent()
          : Value(localDateTime),
      thumbHash: thumbHash == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbHash),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      livePhotoVideoId: livePhotoVideoId == null && nullToAbsent
          ? const Value.absent()
          : Value(livePhotoVideoId),
      visibility: Value(visibility),
      stackId: stackId == null && nullToAbsent
          ? const Value.absent()
          : Value(stackId),
      libraryId: libraryId == null && nullToAbsent
          ? const Value.absent()
          : Value(libraryId),
    );
  }

  factory RemoteAssetEntityData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RemoteAssetEntityData(
      name: serializer.fromJson<String>(json['name']),
      type: $RemoteAssetEntityTable.$convertertype
          .fromJson(serializer.fromJson<int>(json['type'])),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      width: serializer.fromJson<int?>(json['width']),
      height: serializer.fromJson<int?>(json['height']),
      durationInSeconds: serializer.fromJson<int?>(json['durationInSeconds']),
      id: serializer.fromJson<String>(json['id']),
      checksum: serializer.fromJson<String>(json['checksum']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      localDateTime: serializer.fromJson<DateTime?>(json['localDateTime']),
      thumbHash: serializer.fromJson<String?>(json['thumbHash']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      livePhotoVideoId: serializer.fromJson<String?>(json['livePhotoVideoId']),
      visibility: $RemoteAssetEntityTable.$convertervisibility
          .fromJson(serializer.fromJson<int>(json['visibility'])),
      stackId: serializer.fromJson<String?>(json['stackId']),
      libraryId: serializer.fromJson<String?>(json['libraryId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'type': serializer
          .toJson<int>($RemoteAssetEntityTable.$convertertype.toJson(type)),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'width': serializer.toJson<int?>(width),
      'height': serializer.toJson<int?>(height),
      'durationInSeconds': serializer.toJson<int?>(durationInSeconds),
      'id': serializer.toJson<String>(id),
      'checksum': serializer.toJson<String>(checksum),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'ownerId': serializer.toJson<String>(ownerId),
      'localDateTime': serializer.toJson<DateTime?>(localDateTime),
      'thumbHash': serializer.toJson<String?>(thumbHash),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'livePhotoVideoId': serializer.toJson<String?>(livePhotoVideoId),
      'visibility': serializer.toJson<int>(
          $RemoteAssetEntityTable.$convertervisibility.toJson(visibility)),
      'stackId': serializer.toJson<String?>(stackId),
      'libraryId': serializer.toJson<String?>(libraryId),
    };
  }

  RemoteAssetEntityData copyWith(
          {String? name,
          AssetType? type,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<int?> width = const Value.absent(),
          Value<int?> height = const Value.absent(),
          Value<int?> durationInSeconds = const Value.absent(),
          String? id,
          String? checksum,
          bool? isFavorite,
          String? ownerId,
          Value<DateTime?> localDateTime = const Value.absent(),
          Value<String?> thumbHash = const Value.absent(),
          Value<DateTime?> deletedAt = const Value.absent(),
          Value<String?> livePhotoVideoId = const Value.absent(),
          AssetVisibility? visibility,
          Value<String?> stackId = const Value.absent(),
          Value<String?> libraryId = const Value.absent()}) =>
      RemoteAssetEntityData(
        name: name ?? this.name,
        type: type ?? this.type,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        width: width.present ? width.value : this.width,
        height: height.present ? height.value : this.height,
        durationInSeconds: durationInSeconds.present
            ? durationInSeconds.value
            : this.durationInSeconds,
        id: id ?? this.id,
        checksum: checksum ?? this.checksum,
        isFavorite: isFavorite ?? this.isFavorite,
        ownerId: ownerId ?? this.ownerId,
        localDateTime:
            localDateTime.present ? localDateTime.value : this.localDateTime,
        thumbHash: thumbHash.present ? thumbHash.value : this.thumbHash,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        livePhotoVideoId: livePhotoVideoId.present
            ? livePhotoVideoId.value
            : this.livePhotoVideoId,
        visibility: visibility ?? this.visibility,
        stackId: stackId.present ? stackId.value : this.stackId,
        libraryId: libraryId.present ? libraryId.value : this.libraryId,
      );
  RemoteAssetEntityData copyWithCompanion(RemoteAssetEntityCompanion data) {
    return RemoteAssetEntityData(
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      durationInSeconds: data.durationInSeconds.present
          ? data.durationInSeconds.value
          : this.durationInSeconds,
      id: data.id.present ? data.id.value : this.id,
      checksum: data.checksum.present ? data.checksum.value : this.checksum,
      isFavorite:
          data.isFavorite.present ? data.isFavorite.value : this.isFavorite,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      localDateTime: data.localDateTime.present
          ? data.localDateTime.value
          : this.localDateTime,
      thumbHash: data.thumbHash.present ? data.thumbHash.value : this.thumbHash,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      livePhotoVideoId: data.livePhotoVideoId.present
          ? data.livePhotoVideoId.value
          : this.livePhotoVideoId,
      visibility:
          data.visibility.present ? data.visibility.value : this.visibility,
      stackId: data.stackId.present ? data.stackId.value : this.stackId,
      libraryId: data.libraryId.present ? data.libraryId.value : this.libraryId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RemoteAssetEntityData(')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('durationInSeconds: $durationInSeconds, ')
          ..write('id: $id, ')
          ..write('checksum: $checksum, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('ownerId: $ownerId, ')
          ..write('localDateTime: $localDateTime, ')
          ..write('thumbHash: $thumbHash, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('livePhotoVideoId: $livePhotoVideoId, ')
          ..write('visibility: $visibility, ')
          ..write('stackId: $stackId, ')
          ..write('libraryId: $libraryId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      name,
      type,
      createdAt,
      updatedAt,
      width,
      height,
      durationInSeconds,
      id,
      checksum,
      isFavorite,
      ownerId,
      localDateTime,
      thumbHash,
      deletedAt,
      livePhotoVideoId,
      visibility,
      stackId,
      libraryId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RemoteAssetEntityData &&
          other.name == this.name &&
          other.type == this.type &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.width == this.width &&
          other.height == this.height &&
          other.durationInSeconds == this.durationInSeconds &&
          other.id == this.id &&
          other.checksum == this.checksum &&
          other.isFavorite == this.isFavorite &&
          other.ownerId == this.ownerId &&
          other.localDateTime == this.localDateTime &&
          other.thumbHash == this.thumbHash &&
          other.deletedAt == this.deletedAt &&
          other.livePhotoVideoId == this.livePhotoVideoId &&
          other.visibility == this.visibility &&
          other.stackId == this.stackId &&
          other.libraryId == this.libraryId);
}

class RemoteAssetEntityCompanion
    extends UpdateCompanion<RemoteAssetEntityData> {
  final Value<String> name;
  final Value<AssetType> type;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int?> width;
  final Value<int?> height;
  final Value<int?> durationInSeconds;
  final Value<String> id;
  final Value<String> checksum;
  final Value<bool> isFavorite;
  final Value<String> ownerId;
  final Value<DateTime?> localDateTime;
  final Value<String?> thumbHash;
  final Value<DateTime?> deletedAt;
  final Value<String?> livePhotoVideoId;
  final Value<AssetVisibility> visibility;
  final Value<String?> stackId;
  final Value<String?> libraryId;
  const RemoteAssetEntityCompanion({
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.durationInSeconds = const Value.absent(),
    this.id = const Value.absent(),
    this.checksum = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.localDateTime = const Value.absent(),
    this.thumbHash = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.livePhotoVideoId = const Value.absent(),
    this.visibility = const Value.absent(),
    this.stackId = const Value.absent(),
    this.libraryId = const Value.absent(),
  });
  RemoteAssetEntityCompanion.insert({
    required String name,
    required AssetType type,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.durationInSeconds = const Value.absent(),
    required String id,
    required String checksum,
    this.isFavorite = const Value.absent(),
    required String ownerId,
    this.localDateTime = const Value.absent(),
    this.thumbHash = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.livePhotoVideoId = const Value.absent(),
    this.visibility = const Value.absent(),
    this.stackId = const Value.absent(),
    this.libraryId = const Value.absent(),
  })  : name = Value(name),
        type = Value(type),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        id = Value(id),
        checksum = Value(checksum),
        ownerId = Value(ownerId);
  static Insertable<RemoteAssetEntityData> custom({
    Expression<String>? name,
    Expression<int>? type,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? width,
    Expression<int>? height,
    Expression<int>? durationInSeconds,
    Expression<String>? id,
    Expression<String>? checksum,
    Expression<bool>? isFavorite,
    Expression<String>? ownerId,
    Expression<DateTime>? localDateTime,
    Expression<String>? thumbHash,
    Expression<DateTime>? deletedAt,
    Expression<String>? livePhotoVideoId,
    Expression<int>? visibility,
    Expression<String>? stackId,
    Expression<String>? libraryId,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (durationInSeconds != null) 'duration_in_seconds': durationInSeconds,
      if (id != null) 'id': id,
      if (checksum != null) 'checksum': checksum,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (ownerId != null) 'owner_id': ownerId,
      if (localDateTime != null) 'local_date_time': localDateTime,
      if (thumbHash != null) 'thumb_hash': thumbHash,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (livePhotoVideoId != null) 'live_photo_video_id': livePhotoVideoId,
      if (visibility != null) 'visibility': visibility,
      if (stackId != null) 'stack_id': stackId,
      if (libraryId != null) 'library_id': libraryId,
    });
  }

  RemoteAssetEntityCompanion copyWith(
      {Value<String>? name,
      Value<AssetType>? type,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int?>? width,
      Value<int?>? height,
      Value<int?>? durationInSeconds,
      Value<String>? id,
      Value<String>? checksum,
      Value<bool>? isFavorite,
      Value<String>? ownerId,
      Value<DateTime?>? localDateTime,
      Value<String?>? thumbHash,
      Value<DateTime?>? deletedAt,
      Value<String?>? livePhotoVideoId,
      Value<AssetVisibility>? visibility,
      Value<String?>? stackId,
      Value<String?>? libraryId}) {
    return RemoteAssetEntityCompanion(
      name: name ?? this.name,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      width: width ?? this.width,
      height: height ?? this.height,
      durationInSeconds: durationInSeconds ?? this.durationInSeconds,
      id: id ?? this.id,
      checksum: checksum ?? this.checksum,
      isFavorite: isFavorite ?? this.isFavorite,
      ownerId: ownerId ?? this.ownerId,
      localDateTime: localDateTime ?? this.localDateTime,
      thumbHash: thumbHash ?? this.thumbHash,
      deletedAt: deletedAt ?? this.deletedAt,
      livePhotoVideoId: livePhotoVideoId ?? this.livePhotoVideoId,
      visibility: visibility ?? this.visibility,
      stackId: stackId ?? this.stackId,
      libraryId: libraryId ?? this.libraryId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(
          $RemoteAssetEntityTable.$convertertype.toSql(type.value));
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (durationInSeconds.present) {
      map['duration_in_seconds'] = Variable<int>(durationInSeconds.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (checksum.present) {
      map['checksum'] = Variable<String>(checksum.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (localDateTime.present) {
      map['local_date_time'] = Variable<DateTime>(localDateTime.value);
    }
    if (thumbHash.present) {
      map['thumb_hash'] = Variable<String>(thumbHash.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (livePhotoVideoId.present) {
      map['live_photo_video_id'] = Variable<String>(livePhotoVideoId.value);
    }
    if (visibility.present) {
      map['visibility'] = Variable<int>(
          $RemoteAssetEntityTable.$convertervisibility.toSql(visibility.value));
    }
    if (stackId.present) {
      map['stack_id'] = Variable<String>(stackId.value);
    }
    if (libraryId.present) {
      map['library_id'] = Variable<String>(libraryId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemoteAssetEntityCompanion(')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('durationInSeconds: $durationInSeconds, ')
          ..write('id: $id, ')
          ..write('checksum: $checksum, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('ownerId: $ownerId, ')
          ..write('localDateTime: $localDateTime, ')
          ..write('thumbHash: $thumbHash, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('livePhotoVideoId: $livePhotoVideoId, ')
          ..write('visibility: $visibility, ')
          ..write('stackId: $stackId, ')
          ..write('libraryId: $libraryId')
          ..write(')'))
        .toString();
  }
}

class $RemoteAlbumEntityTable extends RemoteAlbumEntity
    with TableInfo<$RemoteAlbumEntityTable, RemoteAlbumEntityData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemoteAlbumEntityTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
  static const VerificationMeta _ownerIdMeta =
      const VerificationMeta('ownerId');
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
      'owner_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES user_entity (id) ON DELETE CASCADE'));
  static const VerificationMeta _thumbnailAssetIdMeta =
      const VerificationMeta('thumbnailAssetId');
  @override
  late final GeneratedColumn<String> thumbnailAssetId = GeneratedColumn<String>(
      'thumbnail_asset_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES remote_asset_entity (id) ON DELETE SET NULL'));
  static const VerificationMeta _isActivityEnabledMeta =
      const VerificationMeta('isActivityEnabled');
  @override
  late final GeneratedColumn<bool> isActivityEnabled = GeneratedColumn<bool>(
      'is_activity_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_activity_enabled" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumnWithTypeConverter<AlbumOrder, int> order =
      GeneratedColumn<int>('order', aliasedName, false,
              type: DriftSqlType.int,
              requiredDuringInsert: false,
              defaultValue: const Constant(1))
          .withConverter<AlbumOrder>($RemoteAlbumEntityTable.$converterorder);
  static const VerificationMeta _isEncryptedMeta =
      const VerificationMeta('isEncrypted');
  @override
  late final GeneratedColumn<bool> isEncrypted = GeneratedColumn<bool>(
      'is_encrypted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_encrypted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _albumTypeMeta =
      const VerificationMeta('albumType');
  @override
  late final GeneratedColumnWithTypeConverter<AlbumType, int> albumType =
      GeneratedColumn<int>('album_type', aliasedName, false,
              type: DriftSqlType.int,
              requiredDuringInsert: false,
              defaultValue: const Constant(0))
          .withConverter<AlbumType>(
              $RemoteAlbumEntityTable.$converteralbumType);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        description,
        createdAt,
        updatedAt,
        ownerId,
        thumbnailAssetId,
        isActivityEnabled,
        order,
        isEncrypted,
        albumType
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'remote_album_entity';
  @override
  VerificationContext validateIntegrity(
      Insertable<RemoteAlbumEntityData> instance,
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
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
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
    if (data.containsKey('owner_id')) {
      context.handle(_ownerIdMeta,
          ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta));
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('thumbnail_asset_id')) {
      context.handle(
          _thumbnailAssetIdMeta,
          thumbnailAssetId.isAcceptableOrUnknown(
              data['thumbnail_asset_id']!, _thumbnailAssetIdMeta));
    }
    if (data.containsKey('is_activity_enabled')) {
      context.handle(
          _isActivityEnabledMeta,
          isActivityEnabled.isAcceptableOrUnknown(
              data['is_activity_enabled']!, _isActivityEnabledMeta));
    }
    context.handle(_orderMeta, const VerificationResult.success());
    if (data.containsKey('is_encrypted')) {
      context.handle(
          _isEncryptedMeta,
          isEncrypted.isAcceptableOrUnknown(
              data['is_encrypted']!, _isEncryptedMeta));
    }
    context.handle(_albumTypeMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RemoteAlbumEntityData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RemoteAlbumEntityData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      ownerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_id'])!,
      thumbnailAssetId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}thumbnail_asset_id']),
      isActivityEnabled: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}is_activity_enabled'])!,
      order: $RemoteAlbumEntityTable.$converterorder.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order'])!),
      isEncrypted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_encrypted'])!,
      albumType: $RemoteAlbumEntityTable.$converteralbumType.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}album_type'])!),
    );
  }

  @override
  $RemoteAlbumEntityTable createAlias(String alias) {
    return $RemoteAlbumEntityTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AlbumOrder, int, int> $converterorder =
      const EnumIndexConverter<AlbumOrder>(AlbumOrder.values);
  static JsonTypeConverter2<AlbumType, int, int> $converteralbumType =
      const EnumIndexConverter<AlbumType>(AlbumType.values);
  @override
  bool get withoutRowId => true;
}

class RemoteAlbumEntityData extends DataClass
    implements Insertable<RemoteAlbumEntityData> {
  /// 主键
  final String id;

  /// 相册名称
  final String name;

  /// 相册描述
  final String? description;

  /// 创建时间
  final DateTime createdAt;

  /// 更新时间
  final DateTime updatedAt;

  /// 所有者用户 ID
  final String ownerId;

  /// 缩略图资产 ID
  final String? thumbnailAssetId;

  /// 是否启用活动功能
  final bool isActivityEnabled;

  /// 排序方式枚举
  final AlbumOrder order;

  /// 是否加密
  final bool isEncrypted;

  /// 相册类型枚举
  final AlbumType albumType;
  const RemoteAlbumEntityData(
      {required this.id,
      required this.name,
      this.description,
      required this.createdAt,
      required this.updatedAt,
      required this.ownerId,
      this.thumbnailAssetId,
      required this.isActivityEnabled,
      required this.order,
      required this.isEncrypted,
      required this.albumType});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['owner_id'] = Variable<String>(ownerId);
    if (!nullToAbsent || thumbnailAssetId != null) {
      map['thumbnail_asset_id'] = Variable<String>(thumbnailAssetId);
    }
    map['is_activity_enabled'] = Variable<bool>(isActivityEnabled);
    {
      map['order'] =
          Variable<int>($RemoteAlbumEntityTable.$converterorder.toSql(order));
    }
    map['is_encrypted'] = Variable<bool>(isEncrypted);
    {
      map['album_type'] = Variable<int>(
          $RemoteAlbumEntityTable.$converteralbumType.toSql(albumType));
    }
    return map;
  }

  RemoteAlbumEntityCompanion toCompanion(bool nullToAbsent) {
    return RemoteAlbumEntityCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      ownerId: Value(ownerId),
      thumbnailAssetId: thumbnailAssetId == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailAssetId),
      isActivityEnabled: Value(isActivityEnabled),
      order: Value(order),
      isEncrypted: Value(isEncrypted),
      albumType: Value(albumType),
    );
  }

  factory RemoteAlbumEntityData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RemoteAlbumEntityData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      thumbnailAssetId: serializer.fromJson<String?>(json['thumbnailAssetId']),
      isActivityEnabled: serializer.fromJson<bool>(json['isActivityEnabled']),
      order: $RemoteAlbumEntityTable.$converterorder
          .fromJson(serializer.fromJson<int>(json['order'])),
      isEncrypted: serializer.fromJson<bool>(json['isEncrypted']),
      albumType: $RemoteAlbumEntityTable.$converteralbumType
          .fromJson(serializer.fromJson<int>(json['albumType'])),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'ownerId': serializer.toJson<String>(ownerId),
      'thumbnailAssetId': serializer.toJson<String?>(thumbnailAssetId),
      'isActivityEnabled': serializer.toJson<bool>(isActivityEnabled),
      'order': serializer
          .toJson<int>($RemoteAlbumEntityTable.$converterorder.toJson(order)),
      'isEncrypted': serializer.toJson<bool>(isEncrypted),
      'albumType': serializer.toJson<int>(
          $RemoteAlbumEntityTable.$converteralbumType.toJson(albumType)),
    };
  }

  RemoteAlbumEntityData copyWith(
          {String? id,
          String? name,
          Value<String?> description = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          String? ownerId,
          Value<String?> thumbnailAssetId = const Value.absent(),
          bool? isActivityEnabled,
          AlbumOrder? order,
          bool? isEncrypted,
          AlbumType? albumType}) =>
      RemoteAlbumEntityData(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description.present ? description.value : this.description,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        ownerId: ownerId ?? this.ownerId,
        thumbnailAssetId: thumbnailAssetId.present
            ? thumbnailAssetId.value
            : this.thumbnailAssetId,
        isActivityEnabled: isActivityEnabled ?? this.isActivityEnabled,
        order: order ?? this.order,
        isEncrypted: isEncrypted ?? this.isEncrypted,
        albumType: albumType ?? this.albumType,
      );
  RemoteAlbumEntityData copyWithCompanion(RemoteAlbumEntityCompanion data) {
    return RemoteAlbumEntityData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      thumbnailAssetId: data.thumbnailAssetId.present
          ? data.thumbnailAssetId.value
          : this.thumbnailAssetId,
      isActivityEnabled: data.isActivityEnabled.present
          ? data.isActivityEnabled.value
          : this.isActivityEnabled,
      order: data.order.present ? data.order.value : this.order,
      isEncrypted:
          data.isEncrypted.present ? data.isEncrypted.value : this.isEncrypted,
      albumType: data.albumType.present ? data.albumType.value : this.albumType,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RemoteAlbumEntityData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('ownerId: $ownerId, ')
          ..write('thumbnailAssetId: $thumbnailAssetId, ')
          ..write('isActivityEnabled: $isActivityEnabled, ')
          ..write('order: $order, ')
          ..write('isEncrypted: $isEncrypted, ')
          ..write('albumType: $albumType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      description,
      createdAt,
      updatedAt,
      ownerId,
      thumbnailAssetId,
      isActivityEnabled,
      order,
      isEncrypted,
      albumType);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RemoteAlbumEntityData &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.ownerId == this.ownerId &&
          other.thumbnailAssetId == this.thumbnailAssetId &&
          other.isActivityEnabled == this.isActivityEnabled &&
          other.order == this.order &&
          other.isEncrypted == this.isEncrypted &&
          other.albumType == this.albumType);
}

class RemoteAlbumEntityCompanion
    extends UpdateCompanion<RemoteAlbumEntityData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> ownerId;
  final Value<String?> thumbnailAssetId;
  final Value<bool> isActivityEnabled;
  final Value<AlbumOrder> order;
  final Value<bool> isEncrypted;
  final Value<AlbumType> albumType;
  const RemoteAlbumEntityCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.thumbnailAssetId = const Value.absent(),
    this.isActivityEnabled = const Value.absent(),
    this.order = const Value.absent(),
    this.isEncrypted = const Value.absent(),
    this.albumType = const Value.absent(),
  });
  RemoteAlbumEntityCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required String ownerId,
    this.thumbnailAssetId = const Value.absent(),
    this.isActivityEnabled = const Value.absent(),
    this.order = const Value.absent(),
    this.isEncrypted = const Value.absent(),
    this.albumType = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        ownerId = Value(ownerId);
  static Insertable<RemoteAlbumEntityData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? ownerId,
    Expression<String>? thumbnailAssetId,
    Expression<bool>? isActivityEnabled,
    Expression<int>? order,
    Expression<bool>? isEncrypted,
    Expression<int>? albumType,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (ownerId != null) 'owner_id': ownerId,
      if (thumbnailAssetId != null) 'thumbnail_asset_id': thumbnailAssetId,
      if (isActivityEnabled != null) 'is_activity_enabled': isActivityEnabled,
      if (order != null) 'order': order,
      if (isEncrypted != null) 'is_encrypted': isEncrypted,
      if (albumType != null) 'album_type': albumType,
    });
  }

  RemoteAlbumEntityCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? description,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<String>? ownerId,
      Value<String?>? thumbnailAssetId,
      Value<bool>? isActivityEnabled,
      Value<AlbumOrder>? order,
      Value<bool>? isEncrypted,
      Value<AlbumType>? albumType}) {
    return RemoteAlbumEntityCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ownerId: ownerId ?? this.ownerId,
      thumbnailAssetId: thumbnailAssetId ?? this.thumbnailAssetId,
      isActivityEnabled: isActivityEnabled ?? this.isActivityEnabled,
      order: order ?? this.order,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      albumType: albumType ?? this.albumType,
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
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (thumbnailAssetId.present) {
      map['thumbnail_asset_id'] = Variable<String>(thumbnailAssetId.value);
    }
    if (isActivityEnabled.present) {
      map['is_activity_enabled'] = Variable<bool>(isActivityEnabled.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(
          $RemoteAlbumEntityTable.$converterorder.toSql(order.value));
    }
    if (isEncrypted.present) {
      map['is_encrypted'] = Variable<bool>(isEncrypted.value);
    }
    if (albumType.present) {
      map['album_type'] = Variable<int>(
          $RemoteAlbumEntityTable.$converteralbumType.toSql(albumType.value));
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemoteAlbumEntityCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('ownerId: $ownerId, ')
          ..write('thumbnailAssetId: $thumbnailAssetId, ')
          ..write('isActivityEnabled: $isActivityEnabled, ')
          ..write('order: $order, ')
          ..write('isEncrypted: $isEncrypted, ')
          ..write('albumType: $albumType')
          ..write(')'))
        .toString();
  }
}

class $LocalAlbumEntityTable extends LocalAlbumEntity
    with TableInfo<$LocalAlbumEntityTable, LocalAlbumEntityData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalAlbumEntityTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _backupSelectionMeta =
      const VerificationMeta('backupSelection');
  @override
  late final GeneratedColumnWithTypeConverter<BackupSelection, int>
      backupSelection = GeneratedColumn<int>(
              'backup_selection', aliasedName, false,
              type: DriftSqlType.int,
              requiredDuringInsert: false,
              defaultValue: const Constant(0))
          .withConverter<BackupSelection>(
              $LocalAlbumEntityTable.$converterbackupSelection);
  static const VerificationMeta _isIosSharedAlbumMeta =
      const VerificationMeta('isIosSharedAlbum');
  @override
  late final GeneratedColumn<bool> isIosSharedAlbum = GeneratedColumn<bool>(
      'is_ios_shared_album', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_ios_shared_album" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _linkedRemoteAlbumIdMeta =
      const VerificationMeta('linkedRemoteAlbumId');
  @override
  late final GeneratedColumn<String> linkedRemoteAlbumId =
      GeneratedColumn<String>('linked_remote_album_id', aliasedName, true,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'REFERENCES remote_album_entity (id) ON DELETE SET NULL'));
  static const VerificationMeta _isEncryptedMeta =
      const VerificationMeta('isEncrypted');
  @override
  late final GeneratedColumn<bool> isEncrypted = GeneratedColumn<bool>(
      'is_encrypted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_encrypted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _albumTypeMeta =
      const VerificationMeta('albumType');
  @override
  late final GeneratedColumnWithTypeConverter<AlbumType, int> albumType =
      GeneratedColumn<int>('album_type', aliasedName, false,
              type: DriftSqlType.int,
              requiredDuringInsert: false,
              defaultValue: const Constant(0))
          .withConverter<AlbumType>($LocalAlbumEntityTable.$converteralbumType);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        updatedAt,
        backupSelection,
        isIosSharedAlbum,
        linkedRemoteAlbumId,
        isEncrypted,
        albumType
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_album_entity';
  @override
  VerificationContext validateIntegrity(
      Insertable<LocalAlbumEntityData> instance,
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
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    context.handle(_backupSelectionMeta, const VerificationResult.success());
    if (data.containsKey('is_ios_shared_album')) {
      context.handle(
          _isIosSharedAlbumMeta,
          isIosSharedAlbum.isAcceptableOrUnknown(
              data['is_ios_shared_album']!, _isIosSharedAlbumMeta));
    }
    if (data.containsKey('linked_remote_album_id')) {
      context.handle(
          _linkedRemoteAlbumIdMeta,
          linkedRemoteAlbumId.isAcceptableOrUnknown(
              data['linked_remote_album_id']!, _linkedRemoteAlbumIdMeta));
    }
    if (data.containsKey('is_encrypted')) {
      context.handle(
          _isEncryptedMeta,
          isEncrypted.isAcceptableOrUnknown(
              data['is_encrypted']!, _isEncryptedMeta));
    }
    context.handle(_albumTypeMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalAlbumEntityData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalAlbumEntityData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      backupSelection: $LocalAlbumEntityTable.$converterbackupSelection.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.int, data['${effectivePrefix}backup_selection'])!),
      isIosSharedAlbum: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}is_ios_shared_album'])!,
      linkedRemoteAlbumId: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}linked_remote_album_id']),
      isEncrypted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_encrypted'])!,
      albumType: $LocalAlbumEntityTable.$converteralbumType.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}album_type'])!),
    );
  }

  @override
  $LocalAlbumEntityTable createAlias(String alias) {
    return $LocalAlbumEntityTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<BackupSelection, int, int>
      $converterbackupSelection =
      const EnumIndexConverter<BackupSelection>(BackupSelection.values);
  static JsonTypeConverter2<AlbumType, int, int> $converteralbumType =
      const EnumIndexConverter<AlbumType>(AlbumType.values);
  @override
  bool get withoutRowId => true;
}

class LocalAlbumEntityData extends DataClass
    implements Insertable<LocalAlbumEntityData> {
  /// 主键（设备相册 ID）
  final String id;

  /// 相册名称
  final String name;

  /// 更新时间
  final DateTime updatedAt;

  /// 备份选择枚举（none/selected/excluded）
  final BackupSelection backupSelection;

  /// 是否为 iOS 共享相册
  final bool isIosSharedAlbum;

  /// 关联的远程相册 ID
  final String? linkedRemoteAlbumId;

  /// 是否加密
  final bool isEncrypted;

  /// 相册类型枚举
  final AlbumType albumType;
  const LocalAlbumEntityData(
      {required this.id,
      required this.name,
      required this.updatedAt,
      required this.backupSelection,
      required this.isIosSharedAlbum,
      this.linkedRemoteAlbumId,
      required this.isEncrypted,
      required this.albumType});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    {
      map['backup_selection'] = Variable<int>($LocalAlbumEntityTable
          .$converterbackupSelection
          .toSql(backupSelection));
    }
    map['is_ios_shared_album'] = Variable<bool>(isIosSharedAlbum);
    if (!nullToAbsent || linkedRemoteAlbumId != null) {
      map['linked_remote_album_id'] = Variable<String>(linkedRemoteAlbumId);
    }
    map['is_encrypted'] = Variable<bool>(isEncrypted);
    {
      map['album_type'] = Variable<int>(
          $LocalAlbumEntityTable.$converteralbumType.toSql(albumType));
    }
    return map;
  }

  LocalAlbumEntityCompanion toCompanion(bool nullToAbsent) {
    return LocalAlbumEntityCompanion(
      id: Value(id),
      name: Value(name),
      updatedAt: Value(updatedAt),
      backupSelection: Value(backupSelection),
      isIosSharedAlbum: Value(isIosSharedAlbum),
      linkedRemoteAlbumId: linkedRemoteAlbumId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedRemoteAlbumId),
      isEncrypted: Value(isEncrypted),
      albumType: Value(albumType),
    );
  }

  factory LocalAlbumEntityData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalAlbumEntityData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      backupSelection: $LocalAlbumEntityTable.$converterbackupSelection
          .fromJson(serializer.fromJson<int>(json['backupSelection'])),
      isIosSharedAlbum: serializer.fromJson<bool>(json['isIosSharedAlbum']),
      linkedRemoteAlbumId:
          serializer.fromJson<String?>(json['linkedRemoteAlbumId']),
      isEncrypted: serializer.fromJson<bool>(json['isEncrypted']),
      albumType: $LocalAlbumEntityTable.$converteralbumType
          .fromJson(serializer.fromJson<int>(json['albumType'])),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'backupSelection': serializer.toJson<int>($LocalAlbumEntityTable
          .$converterbackupSelection
          .toJson(backupSelection)),
      'isIosSharedAlbum': serializer.toJson<bool>(isIosSharedAlbum),
      'linkedRemoteAlbumId': serializer.toJson<String?>(linkedRemoteAlbumId),
      'isEncrypted': serializer.toJson<bool>(isEncrypted),
      'albumType': serializer.toJson<int>(
          $LocalAlbumEntityTable.$converteralbumType.toJson(albumType)),
    };
  }

  LocalAlbumEntityData copyWith(
          {String? id,
          String? name,
          DateTime? updatedAt,
          BackupSelection? backupSelection,
          bool? isIosSharedAlbum,
          Value<String?> linkedRemoteAlbumId = const Value.absent(),
          bool? isEncrypted,
          AlbumType? albumType}) =>
      LocalAlbumEntityData(
        id: id ?? this.id,
        name: name ?? this.name,
        updatedAt: updatedAt ?? this.updatedAt,
        backupSelection: backupSelection ?? this.backupSelection,
        isIosSharedAlbum: isIosSharedAlbum ?? this.isIosSharedAlbum,
        linkedRemoteAlbumId: linkedRemoteAlbumId.present
            ? linkedRemoteAlbumId.value
            : this.linkedRemoteAlbumId,
        isEncrypted: isEncrypted ?? this.isEncrypted,
        albumType: albumType ?? this.albumType,
      );
  LocalAlbumEntityData copyWithCompanion(LocalAlbumEntityCompanion data) {
    return LocalAlbumEntityData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      backupSelection: data.backupSelection.present
          ? data.backupSelection.value
          : this.backupSelection,
      isIosSharedAlbum: data.isIosSharedAlbum.present
          ? data.isIosSharedAlbum.value
          : this.isIosSharedAlbum,
      linkedRemoteAlbumId: data.linkedRemoteAlbumId.present
          ? data.linkedRemoteAlbumId.value
          : this.linkedRemoteAlbumId,
      isEncrypted:
          data.isEncrypted.present ? data.isEncrypted.value : this.isEncrypted,
      albumType: data.albumType.present ? data.albumType.value : this.albumType,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalAlbumEntityData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('backupSelection: $backupSelection, ')
          ..write('isIosSharedAlbum: $isIosSharedAlbum, ')
          ..write('linkedRemoteAlbumId: $linkedRemoteAlbumId, ')
          ..write('isEncrypted: $isEncrypted, ')
          ..write('albumType: $albumType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, updatedAt, backupSelection,
      isIosSharedAlbum, linkedRemoteAlbumId, isEncrypted, albumType);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalAlbumEntityData &&
          other.id == this.id &&
          other.name == this.name &&
          other.updatedAt == this.updatedAt &&
          other.backupSelection == this.backupSelection &&
          other.isIosSharedAlbum == this.isIosSharedAlbum &&
          other.linkedRemoteAlbumId == this.linkedRemoteAlbumId &&
          other.isEncrypted == this.isEncrypted &&
          other.albumType == this.albumType);
}

class LocalAlbumEntityCompanion extends UpdateCompanion<LocalAlbumEntityData> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime> updatedAt;
  final Value<BackupSelection> backupSelection;
  final Value<bool> isIosSharedAlbum;
  final Value<String?> linkedRemoteAlbumId;
  final Value<bool> isEncrypted;
  final Value<AlbumType> albumType;
  const LocalAlbumEntityCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.backupSelection = const Value.absent(),
    this.isIosSharedAlbum = const Value.absent(),
    this.linkedRemoteAlbumId = const Value.absent(),
    this.isEncrypted = const Value.absent(),
    this.albumType = const Value.absent(),
  });
  LocalAlbumEntityCompanion.insert({
    required String id,
    required String name,
    required DateTime updatedAt,
    this.backupSelection = const Value.absent(),
    this.isIosSharedAlbum = const Value.absent(),
    this.linkedRemoteAlbumId = const Value.absent(),
    this.isEncrypted = const Value.absent(),
    this.albumType = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        updatedAt = Value(updatedAt);
  static Insertable<LocalAlbumEntityData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? updatedAt,
    Expression<int>? backupSelection,
    Expression<bool>? isIosSharedAlbum,
    Expression<String>? linkedRemoteAlbumId,
    Expression<bool>? isEncrypted,
    Expression<int>? albumType,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (backupSelection != null) 'backup_selection': backupSelection,
      if (isIosSharedAlbum != null) 'is_ios_shared_album': isIosSharedAlbum,
      if (linkedRemoteAlbumId != null)
        'linked_remote_album_id': linkedRemoteAlbumId,
      if (isEncrypted != null) 'is_encrypted': isEncrypted,
      if (albumType != null) 'album_type': albumType,
    });
  }

  LocalAlbumEntityCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<DateTime>? updatedAt,
      Value<BackupSelection>? backupSelection,
      Value<bool>? isIosSharedAlbum,
      Value<String?>? linkedRemoteAlbumId,
      Value<bool>? isEncrypted,
      Value<AlbumType>? albumType}) {
    return LocalAlbumEntityCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      updatedAt: updatedAt ?? this.updatedAt,
      backupSelection: backupSelection ?? this.backupSelection,
      isIosSharedAlbum: isIosSharedAlbum ?? this.isIosSharedAlbum,
      linkedRemoteAlbumId: linkedRemoteAlbumId ?? this.linkedRemoteAlbumId,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      albumType: albumType ?? this.albumType,
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
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (backupSelection.present) {
      map['backup_selection'] = Variable<int>($LocalAlbumEntityTable
          .$converterbackupSelection
          .toSql(backupSelection.value));
    }
    if (isIosSharedAlbum.present) {
      map['is_ios_shared_album'] = Variable<bool>(isIosSharedAlbum.value);
    }
    if (linkedRemoteAlbumId.present) {
      map['linked_remote_album_id'] =
          Variable<String>(linkedRemoteAlbumId.value);
    }
    if (isEncrypted.present) {
      map['is_encrypted'] = Variable<bool>(isEncrypted.value);
    }
    if (albumType.present) {
      map['album_type'] = Variable<int>(
          $LocalAlbumEntityTable.$converteralbumType.toSql(albumType.value));
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalAlbumEntityCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('backupSelection: $backupSelection, ')
          ..write('isIosSharedAlbum: $isIosSharedAlbum, ')
          ..write('linkedRemoteAlbumId: $linkedRemoteAlbumId, ')
          ..write('isEncrypted: $isEncrypted, ')
          ..write('albumType: $albumType')
          ..write(')'))
        .toString();
  }
}

class $AlbumAssetEntityTable extends AlbumAssetEntity
    with TableInfo<$AlbumAssetEntityTable, AlbumAssetEntityData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlbumAssetEntityTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _assetIdMeta =
      const VerificationMeta('assetId');
  @override
  late final GeneratedColumn<String> assetId = GeneratedColumn<String>(
      'asset_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES remote_asset_entity (id) ON DELETE CASCADE'));
  static const VerificationMeta _albumIdMeta =
      const VerificationMeta('albumId');
  @override
  late final GeneratedColumn<String> albumId = GeneratedColumn<String>(
      'album_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES remote_album_entity (id) ON DELETE CASCADE'));
  @override
  List<GeneratedColumn> get $columns => [assetId, albumId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'album_asset_entity';
  @override
  VerificationContext validateIntegrity(
      Insertable<AlbumAssetEntityData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('asset_id')) {
      context.handle(_assetIdMeta,
          assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta));
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('album_id')) {
      context.handle(_albumIdMeta,
          albumId.isAcceptableOrUnknown(data['album_id']!, _albumIdMeta));
    } else if (isInserting) {
      context.missing(_albumIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {assetId, albumId};
  @override
  AlbumAssetEntityData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AlbumAssetEntityData(
      assetId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}asset_id'])!,
      albumId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}album_id'])!,
    );
  }

  @override
  $AlbumAssetEntityTable createAlias(String alias) {
    return $AlbumAssetEntityTable(attachedDatabase, alias);
  }

  @override
  bool get withoutRowId => true;
}

class AlbumAssetEntityData extends DataClass
    implements Insertable<AlbumAssetEntityData> {
  /// 资产 ID
  final String assetId;

  /// 相册 ID
  final String albumId;
  const AlbumAssetEntityData({required this.assetId, required this.albumId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['asset_id'] = Variable<String>(assetId);
    map['album_id'] = Variable<String>(albumId);
    return map;
  }

  AlbumAssetEntityCompanion toCompanion(bool nullToAbsent) {
    return AlbumAssetEntityCompanion(
      assetId: Value(assetId),
      albumId: Value(albumId),
    );
  }

  factory AlbumAssetEntityData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AlbumAssetEntityData(
      assetId: serializer.fromJson<String>(json['assetId']),
      albumId: serializer.fromJson<String>(json['albumId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'assetId': serializer.toJson<String>(assetId),
      'albumId': serializer.toJson<String>(albumId),
    };
  }

  AlbumAssetEntityData copyWith({String? assetId, String? albumId}) =>
      AlbumAssetEntityData(
        assetId: assetId ?? this.assetId,
        albumId: albumId ?? this.albumId,
      );
  AlbumAssetEntityData copyWithCompanion(AlbumAssetEntityCompanion data) {
    return AlbumAssetEntityData(
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      albumId: data.albumId.present ? data.albumId.value : this.albumId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AlbumAssetEntityData(')
          ..write('assetId: $assetId, ')
          ..write('albumId: $albumId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(assetId, albumId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlbumAssetEntityData &&
          other.assetId == this.assetId &&
          other.albumId == this.albumId);
}

class AlbumAssetEntityCompanion extends UpdateCompanion<AlbumAssetEntityData> {
  final Value<String> assetId;
  final Value<String> albumId;
  const AlbumAssetEntityCompanion({
    this.assetId = const Value.absent(),
    this.albumId = const Value.absent(),
  });
  AlbumAssetEntityCompanion.insert({
    required String assetId,
    required String albumId,
  })  : assetId = Value(assetId),
        albumId = Value(albumId);
  static Insertable<AlbumAssetEntityData> custom({
    Expression<String>? assetId,
    Expression<String>? albumId,
  }) {
    return RawValuesInsertable({
      if (assetId != null) 'asset_id': assetId,
      if (albumId != null) 'album_id': albumId,
    });
  }

  AlbumAssetEntityCompanion copyWith(
      {Value<String>? assetId, Value<String>? albumId}) {
    return AlbumAssetEntityCompanion(
      assetId: assetId ?? this.assetId,
      albumId: albumId ?? this.albumId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (assetId.present) {
      map['asset_id'] = Variable<String>(assetId.value);
    }
    if (albumId.present) {
      map['album_id'] = Variable<String>(albumId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlbumAssetEntityCompanion(')
          ..write('assetId: $assetId, ')
          ..write('albumId: $albumId')
          ..write(')'))
        .toString();
  }
}

class $LocalAlbumAssetEntityTable extends LocalAlbumAssetEntity
    with TableInfo<$LocalAlbumAssetEntityTable, LocalAlbumAssetEntityData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalAlbumAssetEntityTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _assetIdMeta =
      const VerificationMeta('assetId');
  @override
  late final GeneratedColumn<String> assetId = GeneratedColumn<String>(
      'asset_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES local_asset_entity (id) ON DELETE CASCADE'));
  static const VerificationMeta _albumIdMeta =
      const VerificationMeta('albumId');
  @override
  late final GeneratedColumn<String> albumId = GeneratedColumn<String>(
      'album_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES local_album_entity (id) ON DELETE CASCADE'));
  @override
  List<GeneratedColumn> get $columns => [assetId, albumId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_album_asset_entity';
  @override
  VerificationContext validateIntegrity(
      Insertable<LocalAlbumAssetEntityData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('asset_id')) {
      context.handle(_assetIdMeta,
          assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta));
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('album_id')) {
      context.handle(_albumIdMeta,
          albumId.isAcceptableOrUnknown(data['album_id']!, _albumIdMeta));
    } else if (isInserting) {
      context.missing(_albumIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {assetId, albumId};
  @override
  LocalAlbumAssetEntityData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalAlbumAssetEntityData(
      assetId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}asset_id'])!,
      albumId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}album_id'])!,
    );
  }

  @override
  $LocalAlbumAssetEntityTable createAlias(String alias) {
    return $LocalAlbumAssetEntityTable(attachedDatabase, alias);
  }

  @override
  bool get withoutRowId => true;
}

class LocalAlbumAssetEntityData extends DataClass
    implements Insertable<LocalAlbumAssetEntityData> {
  /// 资产 ID（本地资产 ID）
  final String assetId;

  /// 相册 ID（本地相册 ID）
  final String albumId;
  const LocalAlbumAssetEntityData(
      {required this.assetId, required this.albumId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['asset_id'] = Variable<String>(assetId);
    map['album_id'] = Variable<String>(albumId);
    return map;
  }

  LocalAlbumAssetEntityCompanion toCompanion(bool nullToAbsent) {
    return LocalAlbumAssetEntityCompanion(
      assetId: Value(assetId),
      albumId: Value(albumId),
    );
  }

  factory LocalAlbumAssetEntityData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalAlbumAssetEntityData(
      assetId: serializer.fromJson<String>(json['assetId']),
      albumId: serializer.fromJson<String>(json['albumId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'assetId': serializer.toJson<String>(assetId),
      'albumId': serializer.toJson<String>(albumId),
    };
  }

  LocalAlbumAssetEntityData copyWith({String? assetId, String? albumId}) =>
      LocalAlbumAssetEntityData(
        assetId: assetId ?? this.assetId,
        albumId: albumId ?? this.albumId,
      );
  LocalAlbumAssetEntityData copyWithCompanion(
      LocalAlbumAssetEntityCompanion data) {
    return LocalAlbumAssetEntityData(
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      albumId: data.albumId.present ? data.albumId.value : this.albumId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalAlbumAssetEntityData(')
          ..write('assetId: $assetId, ')
          ..write('albumId: $albumId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(assetId, albumId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalAlbumAssetEntityData &&
          other.assetId == this.assetId &&
          other.albumId == this.albumId);
}

class LocalAlbumAssetEntityCompanion
    extends UpdateCompanion<LocalAlbumAssetEntityData> {
  final Value<String> assetId;
  final Value<String> albumId;
  const LocalAlbumAssetEntityCompanion({
    this.assetId = const Value.absent(),
    this.albumId = const Value.absent(),
  });
  LocalAlbumAssetEntityCompanion.insert({
    required String assetId,
    required String albumId,
  })  : assetId = Value(assetId),
        albumId = Value(albumId);
  static Insertable<LocalAlbumAssetEntityData> custom({
    Expression<String>? assetId,
    Expression<String>? albumId,
  }) {
    return RawValuesInsertable({
      if (assetId != null) 'asset_id': assetId,
      if (albumId != null) 'album_id': albumId,
    });
  }

  LocalAlbumAssetEntityCompanion copyWith(
      {Value<String>? assetId, Value<String>? albumId}) {
    return LocalAlbumAssetEntityCompanion(
      assetId: assetId ?? this.assetId,
      albumId: albumId ?? this.albumId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (assetId.present) {
      map['asset_id'] = Variable<String>(assetId.value);
    }
    if (albumId.present) {
      map['album_id'] = Variable<String>(albumId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalAlbumAssetEntityCompanion(')
          ..write('assetId: $assetId, ')
          ..write('albumId: $albumId')
          ..write(')'))
        .toString();
  }
}

class $AlbumSessionEntityTable extends AlbumSessionEntity
    with TableInfo<$AlbumSessionEntityTable, AlbumSessionEntityData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlbumSessionEntityTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _albumIdMeta =
      const VerificationMeta('albumId');
  @override
  late final GeneratedColumn<String> albumId = GeneratedColumn<String>(
      'album_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES remote_album_entity (id) ON DELETE CASCADE'));
  static const VerificationMeta _sessionTokenMeta =
      const VerificationMeta('sessionToken');
  @override
  late final GeneratedColumn<String> sessionToken = GeneratedColumn<String>(
      'session_token', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _expiresAtMeta =
      const VerificationMeta('expiresAt');
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
      'expires_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, albumId, sessionToken, expiresAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'album_session_entity';
  @override
  VerificationContext validateIntegrity(
      Insertable<AlbumSessionEntityData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('album_id')) {
      context.handle(_albumIdMeta,
          albumId.isAcceptableOrUnknown(data['album_id']!, _albumIdMeta));
    } else if (isInserting) {
      context.missing(_albumIdMeta);
    }
    if (data.containsKey('session_token')) {
      context.handle(
          _sessionTokenMeta,
          sessionToken.isAcceptableOrUnknown(
              data['session_token']!, _sessionTokenMeta));
    } else if (isInserting) {
      context.missing(_sessionTokenMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(_expiresAtMeta,
          expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta));
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AlbumSessionEntityData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AlbumSessionEntityData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      albumId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}album_id'])!,
      sessionToken: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_token'])!,
      expiresAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}expires_at'])!,
    );
  }

  @override
  $AlbumSessionEntityTable createAlias(String alias) {
    return $AlbumSessionEntityTable(attachedDatabase, alias);
  }

  @override
  bool get withoutRowId => true;
}

class AlbumSessionEntityData extends DataClass
    implements Insertable<AlbumSessionEntityData> {
  /// 主键
  final String id;

  /// 相册 ID
  final String albumId;

  /// 会话令牌（加密存储）
  final String sessionToken;

  /// 过期时间
  final DateTime expiresAt;
  const AlbumSessionEntityData(
      {required this.id,
      required this.albumId,
      required this.sessionToken,
      required this.expiresAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['album_id'] = Variable<String>(albumId);
    map['session_token'] = Variable<String>(sessionToken);
    map['expires_at'] = Variable<DateTime>(expiresAt);
    return map;
  }

  AlbumSessionEntityCompanion toCompanion(bool nullToAbsent) {
    return AlbumSessionEntityCompanion(
      id: Value(id),
      albumId: Value(albumId),
      sessionToken: Value(sessionToken),
      expiresAt: Value(expiresAt),
    );
  }

  factory AlbumSessionEntityData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AlbumSessionEntityData(
      id: serializer.fromJson<String>(json['id']),
      albumId: serializer.fromJson<String>(json['albumId']),
      sessionToken: serializer.fromJson<String>(json['sessionToken']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'albumId': serializer.toJson<String>(albumId),
      'sessionToken': serializer.toJson<String>(sessionToken),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
    };
  }

  AlbumSessionEntityData copyWith(
          {String? id,
          String? albumId,
          String? sessionToken,
          DateTime? expiresAt}) =>
      AlbumSessionEntityData(
        id: id ?? this.id,
        albumId: albumId ?? this.albumId,
        sessionToken: sessionToken ?? this.sessionToken,
        expiresAt: expiresAt ?? this.expiresAt,
      );
  AlbumSessionEntityData copyWithCompanion(AlbumSessionEntityCompanion data) {
    return AlbumSessionEntityData(
      id: data.id.present ? data.id.value : this.id,
      albumId: data.albumId.present ? data.albumId.value : this.albumId,
      sessionToken: data.sessionToken.present
          ? data.sessionToken.value
          : this.sessionToken,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AlbumSessionEntityData(')
          ..write('id: $id, ')
          ..write('albumId: $albumId, ')
          ..write('sessionToken: $sessionToken, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, albumId, sessionToken, expiresAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlbumSessionEntityData &&
          other.id == this.id &&
          other.albumId == this.albumId &&
          other.sessionToken == this.sessionToken &&
          other.expiresAt == this.expiresAt);
}

class AlbumSessionEntityCompanion
    extends UpdateCompanion<AlbumSessionEntityData> {
  final Value<String> id;
  final Value<String> albumId;
  final Value<String> sessionToken;
  final Value<DateTime> expiresAt;
  const AlbumSessionEntityCompanion({
    this.id = const Value.absent(),
    this.albumId = const Value.absent(),
    this.sessionToken = const Value.absent(),
    this.expiresAt = const Value.absent(),
  });
  AlbumSessionEntityCompanion.insert({
    required String id,
    required String albumId,
    required String sessionToken,
    required DateTime expiresAt,
  })  : id = Value(id),
        albumId = Value(albumId),
        sessionToken = Value(sessionToken),
        expiresAt = Value(expiresAt);
  static Insertable<AlbumSessionEntityData> custom({
    Expression<String>? id,
    Expression<String>? albumId,
    Expression<String>? sessionToken,
    Expression<DateTime>? expiresAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (albumId != null) 'album_id': albumId,
      if (sessionToken != null) 'session_token': sessionToken,
      if (expiresAt != null) 'expires_at': expiresAt,
    });
  }

  AlbumSessionEntityCompanion copyWith(
      {Value<String>? id,
      Value<String>? albumId,
      Value<String>? sessionToken,
      Value<DateTime>? expiresAt}) {
    return AlbumSessionEntityCompanion(
      id: id ?? this.id,
      albumId: albumId ?? this.albumId,
      sessionToken: sessionToken ?? this.sessionToken,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (albumId.present) {
      map['album_id'] = Variable<String>(albumId.value);
    }
    if (sessionToken.present) {
      map['session_token'] = Variable<String>(sessionToken.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlbumSessionEntityCompanion(')
          ..write('id: $id, ')
          ..write('albumId: $albumId, ')
          ..write('sessionToken: $sessionToken, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }
}

class $RetryTaskEntityTable extends RetryTaskEntity
    with TableInfo<$RetryTaskEntityTable, RetryTaskEntityData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RetryTaskEntityTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _taskTypeMeta =
      const VerificationMeta('taskType');
  @override
  late final GeneratedColumn<int> taskType = GeneratedColumn<int>(
      'task_type', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _albumIdMeta =
      const VerificationMeta('albumId');
  @override
  late final GeneratedColumn<String> albumId = GeneratedColumn<String>(
      'album_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _assetIdsMeta =
      const VerificationMeta('assetIds');
  @override
  late final GeneratedColumn<String> assetIds = GeneratedColumn<String>(
      'asset_ids', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _extraDataMeta =
      const VerificationMeta('extraData');
  @override
  late final GeneratedColumn<String> extraData = GeneratedColumn<String>(
      'extra_data', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastRetryAtMeta =
      const VerificationMeta('lastRetryAt');
  @override
  late final GeneratedColumn<DateTime> lastRetryAt = GeneratedColumn<DateTime>(
      'last_retry_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, taskType, albumId, assetIds, extraData, retryCount, lastRetryAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'retry_task_entity';
  @override
  VerificationContext validateIntegrity(
      Insertable<RetryTaskEntityData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('task_type')) {
      context.handle(_taskTypeMeta,
          taskType.isAcceptableOrUnknown(data['task_type']!, _taskTypeMeta));
    } else if (isInserting) {
      context.missing(_taskTypeMeta);
    }
    if (data.containsKey('album_id')) {
      context.handle(_albumIdMeta,
          albumId.isAcceptableOrUnknown(data['album_id']!, _albumIdMeta));
    } else if (isInserting) {
      context.missing(_albumIdMeta);
    }
    if (data.containsKey('asset_ids')) {
      context.handle(_assetIdsMeta,
          assetIds.isAcceptableOrUnknown(data['asset_ids']!, _assetIdsMeta));
    } else if (isInserting) {
      context.missing(_assetIdsMeta);
    }
    if (data.containsKey('extra_data')) {
      context.handle(_extraDataMeta,
          extraData.isAcceptableOrUnknown(data['extra_data']!, _extraDataMeta));
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    }
    if (data.containsKey('last_retry_at')) {
      context.handle(
          _lastRetryAtMeta,
          lastRetryAt.isAcceptableOrUnknown(
              data['last_retry_at']!, _lastRetryAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RetryTaskEntityData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RetryTaskEntityData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      taskType: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}task_type'])!,
      albumId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}album_id'])!,
      assetIds: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}asset_ids'])!,
      extraData: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}extra_data']),
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      lastRetryAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_retry_at']),
    );
  }

  @override
  $RetryTaskEntityTable createAlias(String alias) {
    return $RetryTaskEntityTable(attachedDatabase, alias);
  }

  @override
  bool get withoutRowId => true;
}

class RetryTaskEntityData extends DataClass
    implements Insertable<RetryTaskEntityData> {
  /// 主键（任务ID）
  final String id;

  /// 任务类型
  final int taskType;

  /// 相册ID
  final String albumId;

  /// 资产ID列表（JSON格式存储）
  final String assetIds;

  /// 额外数据（JSON格式存储，可选）
  final String? extraData;

  /// 重试次数
  final int retryCount;

  /// 最后重试时间
  final DateTime? lastRetryAt;
  const RetryTaskEntityData(
      {required this.id,
      required this.taskType,
      required this.albumId,
      required this.assetIds,
      this.extraData,
      required this.retryCount,
      this.lastRetryAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['task_type'] = Variable<int>(taskType);
    map['album_id'] = Variable<String>(albumId);
    map['asset_ids'] = Variable<String>(assetIds);
    if (!nullToAbsent || extraData != null) {
      map['extra_data'] = Variable<String>(extraData);
    }
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastRetryAt != null) {
      map['last_retry_at'] = Variable<DateTime>(lastRetryAt);
    }
    return map;
  }

  RetryTaskEntityCompanion toCompanion(bool nullToAbsent) {
    return RetryTaskEntityCompanion(
      id: Value(id),
      taskType: Value(taskType),
      albumId: Value(albumId),
      assetIds: Value(assetIds),
      extraData: extraData == null && nullToAbsent
          ? const Value.absent()
          : Value(extraData),
      retryCount: Value(retryCount),
      lastRetryAt: lastRetryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastRetryAt),
    );
  }

  factory RetryTaskEntityData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RetryTaskEntityData(
      id: serializer.fromJson<String>(json['id']),
      taskType: serializer.fromJson<int>(json['taskType']),
      albumId: serializer.fromJson<String>(json['albumId']),
      assetIds: serializer.fromJson<String>(json['assetIds']),
      extraData: serializer.fromJson<String?>(json['extraData']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastRetryAt: serializer.fromJson<DateTime?>(json['lastRetryAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'taskType': serializer.toJson<int>(taskType),
      'albumId': serializer.toJson<String>(albumId),
      'assetIds': serializer.toJson<String>(assetIds),
      'extraData': serializer.toJson<String?>(extraData),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastRetryAt': serializer.toJson<DateTime?>(lastRetryAt),
    };
  }

  RetryTaskEntityData copyWith(
          {String? id,
          int? taskType,
          String? albumId,
          String? assetIds,
          Value<String?> extraData = const Value.absent(),
          int? retryCount,
          Value<DateTime?> lastRetryAt = const Value.absent()}) =>
      RetryTaskEntityData(
        id: id ?? this.id,
        taskType: taskType ?? this.taskType,
        albumId: albumId ?? this.albumId,
        assetIds: assetIds ?? this.assetIds,
        extraData: extraData.present ? extraData.value : this.extraData,
        retryCount: retryCount ?? this.retryCount,
        lastRetryAt: lastRetryAt.present ? lastRetryAt.value : this.lastRetryAt,
      );
  RetryTaskEntityData copyWithCompanion(RetryTaskEntityCompanion data) {
    return RetryTaskEntityData(
      id: data.id.present ? data.id.value : this.id,
      taskType: data.taskType.present ? data.taskType.value : this.taskType,
      albumId: data.albumId.present ? data.albumId.value : this.albumId,
      assetIds: data.assetIds.present ? data.assetIds.value : this.assetIds,
      extraData: data.extraData.present ? data.extraData.value : this.extraData,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      lastRetryAt:
          data.lastRetryAt.present ? data.lastRetryAt.value : this.lastRetryAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RetryTaskEntityData(')
          ..write('id: $id, ')
          ..write('taskType: $taskType, ')
          ..write('albumId: $albumId, ')
          ..write('assetIds: $assetIds, ')
          ..write('extraData: $extraData, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastRetryAt: $lastRetryAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, taskType, albumId, assetIds, extraData, retryCount, lastRetryAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RetryTaskEntityData &&
          other.id == this.id &&
          other.taskType == this.taskType &&
          other.albumId == this.albumId &&
          other.assetIds == this.assetIds &&
          other.extraData == this.extraData &&
          other.retryCount == this.retryCount &&
          other.lastRetryAt == this.lastRetryAt);
}

class RetryTaskEntityCompanion extends UpdateCompanion<RetryTaskEntityData> {
  final Value<String> id;
  final Value<int> taskType;
  final Value<String> albumId;
  final Value<String> assetIds;
  final Value<String?> extraData;
  final Value<int> retryCount;
  final Value<DateTime?> lastRetryAt;
  const RetryTaskEntityCompanion({
    this.id = const Value.absent(),
    this.taskType = const Value.absent(),
    this.albumId = const Value.absent(),
    this.assetIds = const Value.absent(),
    this.extraData = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastRetryAt = const Value.absent(),
  });
  RetryTaskEntityCompanion.insert({
    required String id,
    required int taskType,
    required String albumId,
    required String assetIds,
    this.extraData = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastRetryAt = const Value.absent(),
  })  : id = Value(id),
        taskType = Value(taskType),
        albumId = Value(albumId),
        assetIds = Value(assetIds);
  static Insertable<RetryTaskEntityData> custom({
    Expression<String>? id,
    Expression<int>? taskType,
    Expression<String>? albumId,
    Expression<String>? assetIds,
    Expression<String>? extraData,
    Expression<int>? retryCount,
    Expression<DateTime>? lastRetryAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskType != null) 'task_type': taskType,
      if (albumId != null) 'album_id': albumId,
      if (assetIds != null) 'asset_ids': assetIds,
      if (extraData != null) 'extra_data': extraData,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastRetryAt != null) 'last_retry_at': lastRetryAt,
    });
  }

  RetryTaskEntityCompanion copyWith(
      {Value<String>? id,
      Value<int>? taskType,
      Value<String>? albumId,
      Value<String>? assetIds,
      Value<String?>? extraData,
      Value<int>? retryCount,
      Value<DateTime?>? lastRetryAt}) {
    return RetryTaskEntityCompanion(
      id: id ?? this.id,
      taskType: taskType ?? this.taskType,
      albumId: albumId ?? this.albumId,
      assetIds: assetIds ?? this.assetIds,
      extraData: extraData ?? this.extraData,
      retryCount: retryCount ?? this.retryCount,
      lastRetryAt: lastRetryAt ?? this.lastRetryAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (taskType.present) {
      map['task_type'] = Variable<int>(taskType.value);
    }
    if (albumId.present) {
      map['album_id'] = Variable<String>(albumId.value);
    }
    if (assetIds.present) {
      map['asset_ids'] = Variable<String>(assetIds.value);
    }
    if (extraData.present) {
      map['extra_data'] = Variable<String>(extraData.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastRetryAt.present) {
      map['last_retry_at'] = Variable<DateTime>(lastRetryAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RetryTaskEntityCompanion(')
          ..write('id: $id, ')
          ..write('taskType: $taskType, ')
          ..write('albumId: $albumId, ')
          ..write('assetIds: $assetIds, ')
          ..write('extraData: $extraData, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastRetryAt: $lastRetryAt')
          ..write(')'))
        .toString();
  }
}

class $StoreEntityTable extends StoreEntity
    with TableInfo<$StoreEntityTable, StoreEntityData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoreEntityTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<int> key = GeneratedColumn<int>(
      'key', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'store_entity';
  @override
  VerificationContext validateIntegrity(Insertable<StoreEntityData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  StoreEntityData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoreEntityData(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value']),
    );
  }

  @override
  $StoreEntityTable createAlias(String alias) {
    return $StoreEntityTable(attachedDatabase, alias);
  }
}

class StoreEntityData extends DataClass implements Insertable<StoreEntityData> {
  /// 键ID（对应StoreKey.id）
  final int key;

  /// 值（JSON字符串）
  final String? value;
  const StoreEntityData({required this.key, this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<int>(key);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    return map;
  }

  StoreEntityCompanion toCompanion(bool nullToAbsent) {
    return StoreEntityCompanion(
      key: Value(key),
      value:
          value == null && nullToAbsent ? const Value.absent() : Value(value),
    );
  }

  factory StoreEntityData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoreEntityData(
      key: serializer.fromJson<int>(json['key']),
      value: serializer.fromJson<String?>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<int>(key),
      'value': serializer.toJson<String?>(value),
    };
  }

  StoreEntityData copyWith(
          {int? key, Value<String?> value = const Value.absent()}) =>
      StoreEntityData(
        key: key ?? this.key,
        value: value.present ? value.value : this.value,
      );
  StoreEntityData copyWithCompanion(StoreEntityCompanion data) {
    return StoreEntityData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoreEntityData(')
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
      (other is StoreEntityData &&
          other.key == this.key &&
          other.value == this.value);
}

class StoreEntityCompanion extends UpdateCompanion<StoreEntityData> {
  final Value<int> key;
  final Value<String?> value;
  const StoreEntityCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
  });
  StoreEntityCompanion.insert({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
  });
  static Insertable<StoreEntityData> custom({
    Expression<int>? key,
    Expression<String>? value,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
    });
  }

  StoreEntityCompanion copyWith({Value<int>? key, Value<String?>? value}) {
    return StoreEntityCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<int>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoreEntityCompanion(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }
}

class $BackupStatusEntityTable extends BackupStatusEntity
    with TableInfo<$BackupStatusEntityTable, BackupStatusEntityData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BackupStatusEntityTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES user_entity (id) ON DELETE CASCADE'));
  static const VerificationMeta _lastBackupTimeMeta =
      const VerificationMeta('lastBackupTime');
  @override
  late final GeneratedColumn<DateTime> lastBackupTime =
      GeneratedColumn<DateTime>('last_backup_time', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _enabledMeta =
      const VerificationMeta('enabled');
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
      'enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("enabled" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _autoBackupModeMeta =
      const VerificationMeta('autoBackupMode');
  @override
  late final GeneratedColumnWithTypeConverter<AutoBackupMode, int>
      autoBackupMode = GeneratedColumn<int>(
              'auto_backup_mode', aliasedName, false,
              type: DriftSqlType.int,
              requiredDuringInsert: false,
              defaultValue: const Constant(0))
          .withConverter<AutoBackupMode>(
              $BackupStatusEntityTable.$converterautoBackupMode);
  static const VerificationMeta _timeRangeStartMeta =
      const VerificationMeta('timeRangeStart');
  @override
  late final GeneratedColumn<DateTime> timeRangeStart =
      GeneratedColumn<DateTime>('time_range_start', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _timeRangeEndMeta =
      const VerificationMeta('timeRangeEnd');
  @override
  late final GeneratedColumn<DateTime> timeRangeEnd = GeneratedColumn<DateTime>(
      'time_range_end', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
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
        userId,
        lastBackupTime,
        enabled,
        autoBackupMode,
        timeRangeStart,
        timeRangeEnd,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'backup_status_entity';
  @override
  VerificationContext validateIntegrity(
      Insertable<BackupStatusEntityData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('last_backup_time')) {
      context.handle(
          _lastBackupTimeMeta,
          lastBackupTime.isAcceptableOrUnknown(
              data['last_backup_time']!, _lastBackupTimeMeta));
    }
    if (data.containsKey('enabled')) {
      context.handle(_enabledMeta,
          enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta));
    }
    context.handle(_autoBackupModeMeta, const VerificationResult.success());
    if (data.containsKey('time_range_start')) {
      context.handle(
          _timeRangeStartMeta,
          timeRangeStart.isAcceptableOrUnknown(
              data['time_range_start']!, _timeRangeStartMeta));
    }
    if (data.containsKey('time_range_end')) {
      context.handle(
          _timeRangeEndMeta,
          timeRangeEnd.isAcceptableOrUnknown(
              data['time_range_end']!, _timeRangeEndMeta));
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
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  BackupStatusEntityData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BackupStatusEntityData(
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      lastBackupTime: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_backup_time']),
      enabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}enabled'])!,
      autoBackupMode: $BackupStatusEntityTable.$converterautoBackupMode.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.int, data['${effectivePrefix}auto_backup_mode'])!),
      timeRangeStart: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}time_range_start']),
      timeRangeEnd: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}time_range_end']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $BackupStatusEntityTable createAlias(String alias) {
    return $BackupStatusEntityTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AutoBackupMode, int, int> $converterautoBackupMode =
      const EnumIndexConverter<AutoBackupMode>(AutoBackupMode.values);
  @override
  bool get withoutRowId => true;
}

class BackupStatusEntityData extends DataClass
    implements Insertable<BackupStatusEntityData> {
  /// 用户 ID（主键，外键关联 UserEntity）
  final String userId;

  /// 最后自动备份时间（用于增量同步）
  final DateTime? lastBackupTime;

  /// 该用户的自动备份是否启用
  final bool enabled;

  /// 自动备份模式枚举
  final AutoBackupMode autoBackupMode;

  /// 时间段起始（time_range 模式）
  final DateTime? timeRangeStart;

  /// 时间段结束（time_range 模式）
  final DateTime? timeRangeEnd;

  /// 创建时间
  final DateTime createdAt;

  /// 更新时间
  final DateTime updatedAt;
  const BackupStatusEntityData(
      {required this.userId,
      this.lastBackupTime,
      required this.enabled,
      required this.autoBackupMode,
      this.timeRangeStart,
      this.timeRangeEnd,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || lastBackupTime != null) {
      map['last_backup_time'] = Variable<DateTime>(lastBackupTime);
    }
    map['enabled'] = Variable<bool>(enabled);
    {
      map['auto_backup_mode'] = Variable<int>($BackupStatusEntityTable
          .$converterautoBackupMode
          .toSql(autoBackupMode));
    }
    if (!nullToAbsent || timeRangeStart != null) {
      map['time_range_start'] = Variable<DateTime>(timeRangeStart);
    }
    if (!nullToAbsent || timeRangeEnd != null) {
      map['time_range_end'] = Variable<DateTime>(timeRangeEnd);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BackupStatusEntityCompanion toCompanion(bool nullToAbsent) {
    return BackupStatusEntityCompanion(
      userId: Value(userId),
      lastBackupTime: lastBackupTime == null && nullToAbsent
          ? const Value.absent()
          : Value(lastBackupTime),
      enabled: Value(enabled),
      autoBackupMode: Value(autoBackupMode),
      timeRangeStart: timeRangeStart == null && nullToAbsent
          ? const Value.absent()
          : Value(timeRangeStart),
      timeRangeEnd: timeRangeEnd == null && nullToAbsent
          ? const Value.absent()
          : Value(timeRangeEnd),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BackupStatusEntityData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BackupStatusEntityData(
      userId: serializer.fromJson<String>(json['userId']),
      lastBackupTime: serializer.fromJson<DateTime?>(json['lastBackupTime']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      autoBackupMode: $BackupStatusEntityTable.$converterautoBackupMode
          .fromJson(serializer.fromJson<int>(json['autoBackupMode'])),
      timeRangeStart: serializer.fromJson<DateTime?>(json['timeRangeStart']),
      timeRangeEnd: serializer.fromJson<DateTime?>(json['timeRangeEnd']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'lastBackupTime': serializer.toJson<DateTime?>(lastBackupTime),
      'enabled': serializer.toJson<bool>(enabled),
      'autoBackupMode': serializer.toJson<int>($BackupStatusEntityTable
          .$converterautoBackupMode
          .toJson(autoBackupMode)),
      'timeRangeStart': serializer.toJson<DateTime?>(timeRangeStart),
      'timeRangeEnd': serializer.toJson<DateTime?>(timeRangeEnd),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BackupStatusEntityData copyWith(
          {String? userId,
          Value<DateTime?> lastBackupTime = const Value.absent(),
          bool? enabled,
          AutoBackupMode? autoBackupMode,
          Value<DateTime?> timeRangeStart = const Value.absent(),
          Value<DateTime?> timeRangeEnd = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      BackupStatusEntityData(
        userId: userId ?? this.userId,
        lastBackupTime:
            lastBackupTime.present ? lastBackupTime.value : this.lastBackupTime,
        enabled: enabled ?? this.enabled,
        autoBackupMode: autoBackupMode ?? this.autoBackupMode,
        timeRangeStart:
            timeRangeStart.present ? timeRangeStart.value : this.timeRangeStart,
        timeRangeEnd:
            timeRangeEnd.present ? timeRangeEnd.value : this.timeRangeEnd,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  BackupStatusEntityData copyWithCompanion(BackupStatusEntityCompanion data) {
    return BackupStatusEntityData(
      userId: data.userId.present ? data.userId.value : this.userId,
      lastBackupTime: data.lastBackupTime.present
          ? data.lastBackupTime.value
          : this.lastBackupTime,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      autoBackupMode: data.autoBackupMode.present
          ? data.autoBackupMode.value
          : this.autoBackupMode,
      timeRangeStart: data.timeRangeStart.present
          ? data.timeRangeStart.value
          : this.timeRangeStart,
      timeRangeEnd: data.timeRangeEnd.present
          ? data.timeRangeEnd.value
          : this.timeRangeEnd,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BackupStatusEntityData(')
          ..write('userId: $userId, ')
          ..write('lastBackupTime: $lastBackupTime, ')
          ..write('enabled: $enabled, ')
          ..write('autoBackupMode: $autoBackupMode, ')
          ..write('timeRangeStart: $timeRangeStart, ')
          ..write('timeRangeEnd: $timeRangeEnd, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, lastBackupTime, enabled,
      autoBackupMode, timeRangeStart, timeRangeEnd, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BackupStatusEntityData &&
          other.userId == this.userId &&
          other.lastBackupTime == this.lastBackupTime &&
          other.enabled == this.enabled &&
          other.autoBackupMode == this.autoBackupMode &&
          other.timeRangeStart == this.timeRangeStart &&
          other.timeRangeEnd == this.timeRangeEnd &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BackupStatusEntityCompanion
    extends UpdateCompanion<BackupStatusEntityData> {
  final Value<String> userId;
  final Value<DateTime?> lastBackupTime;
  final Value<bool> enabled;
  final Value<AutoBackupMode> autoBackupMode;
  final Value<DateTime?> timeRangeStart;
  final Value<DateTime?> timeRangeEnd;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const BackupStatusEntityCompanion({
    this.userId = const Value.absent(),
    this.lastBackupTime = const Value.absent(),
    this.enabled = const Value.absent(),
    this.autoBackupMode = const Value.absent(),
    this.timeRangeStart = const Value.absent(),
    this.timeRangeEnd = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  BackupStatusEntityCompanion.insert({
    required String userId,
    this.lastBackupTime = const Value.absent(),
    this.enabled = const Value.absent(),
    this.autoBackupMode = const Value.absent(),
    this.timeRangeStart = const Value.absent(),
    this.timeRangeEnd = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  })  : userId = Value(userId),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<BackupStatusEntityData> custom({
    Expression<String>? userId,
    Expression<DateTime>? lastBackupTime,
    Expression<bool>? enabled,
    Expression<int>? autoBackupMode,
    Expression<DateTime>? timeRangeStart,
    Expression<DateTime>? timeRangeEnd,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (lastBackupTime != null) 'last_backup_time': lastBackupTime,
      if (enabled != null) 'enabled': enabled,
      if (autoBackupMode != null) 'auto_backup_mode': autoBackupMode,
      if (timeRangeStart != null) 'time_range_start': timeRangeStart,
      if (timeRangeEnd != null) 'time_range_end': timeRangeEnd,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  BackupStatusEntityCompanion copyWith(
      {Value<String>? userId,
      Value<DateTime?>? lastBackupTime,
      Value<bool>? enabled,
      Value<AutoBackupMode>? autoBackupMode,
      Value<DateTime?>? timeRangeStart,
      Value<DateTime?>? timeRangeEnd,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return BackupStatusEntityCompanion(
      userId: userId ?? this.userId,
      lastBackupTime: lastBackupTime ?? this.lastBackupTime,
      enabled: enabled ?? this.enabled,
      autoBackupMode: autoBackupMode ?? this.autoBackupMode,
      timeRangeStart: timeRangeStart ?? this.timeRangeStart,
      timeRangeEnd: timeRangeEnd ?? this.timeRangeEnd,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (lastBackupTime.present) {
      map['last_backup_time'] = Variable<DateTime>(lastBackupTime.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (autoBackupMode.present) {
      map['auto_backup_mode'] = Variable<int>($BackupStatusEntityTable
          .$converterautoBackupMode
          .toSql(autoBackupMode.value));
    }
    if (timeRangeStart.present) {
      map['time_range_start'] = Variable<DateTime>(timeRangeStart.value);
    }
    if (timeRangeEnd.present) {
      map['time_range_end'] = Variable<DateTime>(timeRangeEnd.value);
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
    return (StringBuffer('BackupStatusEntityCompanion(')
          ..write('userId: $userId, ')
          ..write('lastBackupTime: $lastBackupTime, ')
          ..write('enabled: $enabled, ')
          ..write('autoBackupMode: $autoBackupMode, ')
          ..write('timeRangeStart: $timeRangeStart, ')
          ..write('timeRangeEnd: $timeRangeEnd, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $UploadTaskEntityTable extends UploadTaskEntity
    with TableInfo<$UploadTaskEntityTable, UploadTaskEntityData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UploadTaskEntityTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES user_entity (id) ON DELETE CASCADE'));
  static const VerificationMeta _assetIdMeta =
      const VerificationMeta('assetId');
  @override
  late final GeneratedColumn<String> assetId = GeneratedColumn<String>(
      'asset_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _localPathMeta =
      const VerificationMeta('localPath');
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
      'local_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _remotePathMeta =
      const VerificationMeta('remotePath');
  @override
  late final GeneratedColumn<String> remotePath = GeneratedColumn<String>(
      'remote_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fileSizeMeta =
      const VerificationMeta('fileSize');
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
      'file_size', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _taskTypeMeta =
      const VerificationMeta('taskType');
  @override
  late final GeneratedColumnWithTypeConverter<UploadTaskType, int> taskType =
      GeneratedColumn<int>('task_type', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<UploadTaskType>(
              $UploadTaskEntityTable.$convertertaskType);
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
      'priority', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(5));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumnWithTypeConverter<UploadTaskStatus, int> status =
      GeneratedColumn<int>('status', aliasedName, false,
              type: DriftSqlType.int,
              requiredDuringInsert: false,
              defaultValue: const Constant(0))
          .withConverter<UploadTaskStatus>(
              $UploadTaskEntityTable.$converterstatus);
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _maxRetriesMeta =
      const VerificationMeta('maxRetries');
  @override
  late final GeneratedColumn<int> maxRetries = GeneratedColumn<int>(
      'max_retries', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(3));
  static const VerificationMeta _errorMessageMeta =
      const VerificationMeta('errorMessage');
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
      'error_message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _uploadedAtMeta =
      const VerificationMeta('uploadedAt');
  @override
  late final GeneratedColumn<DateTime> uploadedAt = GeneratedColumn<DateTime>(
      'uploaded_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
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
  static const VerificationMeta _progressMeta =
      const VerificationMeta('progress');
  @override
  late final GeneratedColumn<int> progress = GeneratedColumn<int>(
      'progress', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        assetId,
        localPath,
        remotePath,
        fileSize,
        taskType,
        priority,
        status,
        retryCount,
        maxRetries,
        errorMessage,
        uploadedAt,
        createdAt,
        updatedAt,
        progress
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'upload_task_entity';
  @override
  VerificationContext validateIntegrity(
      Insertable<UploadTaskEntityData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('asset_id')) {
      context.handle(_assetIdMeta,
          assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta));
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(_localPathMeta,
          localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta));
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('remote_path')) {
      context.handle(
          _remotePathMeta,
          remotePath.isAcceptableOrUnknown(
              data['remote_path']!, _remotePathMeta));
    } else if (isInserting) {
      context.missing(_remotePathMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(_fileSizeMeta,
          fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta));
    } else if (isInserting) {
      context.missing(_fileSizeMeta);
    }
    context.handle(_taskTypeMeta, const VerificationResult.success());
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    }
    context.handle(_statusMeta, const VerificationResult.success());
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    }
    if (data.containsKey('max_retries')) {
      context.handle(
          _maxRetriesMeta,
          maxRetries.isAcceptableOrUnknown(
              data['max_retries']!, _maxRetriesMeta));
    }
    if (data.containsKey('error_message')) {
      context.handle(
          _errorMessageMeta,
          errorMessage.isAcceptableOrUnknown(
              data['error_message']!, _errorMessageMeta));
    }
    if (data.containsKey('uploaded_at')) {
      context.handle(
          _uploadedAtMeta,
          uploadedAt.isAcceptableOrUnknown(
              data['uploaded_at']!, _uploadedAtMeta));
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
    if (data.containsKey('progress')) {
      context.handle(_progressMeta,
          progress.isAcceptableOrUnknown(data['progress']!, _progressMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UploadTaskEntityData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UploadTaskEntityData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      assetId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}asset_id'])!,
      localPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_path'])!,
      remotePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}remote_path'])!,
      fileSize: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}file_size'])!,
      taskType: $UploadTaskEntityTable.$convertertaskType.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}task_type'])!),
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}priority'])!,
      status: $UploadTaskEntityTable.$converterstatus.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}status'])!),
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      maxRetries: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}max_retries'])!,
      errorMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error_message']),
      uploadedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}uploaded_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      progress: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}progress'])!,
    );
  }

  @override
  $UploadTaskEntityTable createAlias(String alias) {
    return $UploadTaskEntityTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<UploadTaskType, int, int> $convertertaskType =
      const EnumIndexConverter<UploadTaskType>(UploadTaskType.values);
  static JsonTypeConverter2<UploadTaskStatus, int, int> $converterstatus =
      const EnumIndexConverter<UploadTaskStatus>(UploadTaskStatus.values);
  @override
  bool get withoutRowId => true;
}

class UploadTaskEntityData extends DataClass
    implements Insertable<UploadTaskEntityData> {
  /// 任务 ID（主键）
  final String id;

  /// 用户 ID（外键，用于多用户隔离）
  final String userId;

  /// 资产 ID（本地资产ID，关联LocalAssetEntity）
  final String assetId;

  /// 本地文件路径
  final String localPath;

  /// 远程路径（上传目标路径）
  final String remotePath;

  /// 文件大小（字节）
  final int fileSize;

  /// 任务类型（manual/auto）
  final UploadTaskType taskType;

  /// 优先级（数字越小优先级越高，manual: 1, auto: 5）
  final int priority;

  /// 任务状态
  final UploadTaskStatus status;

  /// 重试次数
  final int retryCount;

  /// 最大重试次数（默认 3）
  final int maxRetries;

  /// 错误信息
  final String? errorMessage;

  /// 上传完成时间
  final DateTime? uploadedAt;

  /// 创建时间
  final DateTime createdAt;

  /// 更新时间
  final DateTime updatedAt;

  /// 进度百分比（0-100）
  final int progress;
  const UploadTaskEntityData(
      {required this.id,
      required this.userId,
      required this.assetId,
      required this.localPath,
      required this.remotePath,
      required this.fileSize,
      required this.taskType,
      required this.priority,
      required this.status,
      required this.retryCount,
      required this.maxRetries,
      this.errorMessage,
      this.uploadedAt,
      required this.createdAt,
      required this.updatedAt,
      required this.progress});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['asset_id'] = Variable<String>(assetId);
    map['local_path'] = Variable<String>(localPath);
    map['remote_path'] = Variable<String>(remotePath);
    map['file_size'] = Variable<int>(fileSize);
    {
      map['task_type'] = Variable<int>(
          $UploadTaskEntityTable.$convertertaskType.toSql(taskType));
    }
    map['priority'] = Variable<int>(priority);
    {
      map['status'] =
          Variable<int>($UploadTaskEntityTable.$converterstatus.toSql(status));
    }
    map['retry_count'] = Variable<int>(retryCount);
    map['max_retries'] = Variable<int>(maxRetries);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    if (!nullToAbsent || uploadedAt != null) {
      map['uploaded_at'] = Variable<DateTime>(uploadedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['progress'] = Variable<int>(progress);
    return map;
  }

  UploadTaskEntityCompanion toCompanion(bool nullToAbsent) {
    return UploadTaskEntityCompanion(
      id: Value(id),
      userId: Value(userId),
      assetId: Value(assetId),
      localPath: Value(localPath),
      remotePath: Value(remotePath),
      fileSize: Value(fileSize),
      taskType: Value(taskType),
      priority: Value(priority),
      status: Value(status),
      retryCount: Value(retryCount),
      maxRetries: Value(maxRetries),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      uploadedAt: uploadedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      progress: Value(progress),
    );
  }

  factory UploadTaskEntityData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UploadTaskEntityData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      assetId: serializer.fromJson<String>(json['assetId']),
      localPath: serializer.fromJson<String>(json['localPath']),
      remotePath: serializer.fromJson<String>(json['remotePath']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      taskType: $UploadTaskEntityTable.$convertertaskType
          .fromJson(serializer.fromJson<int>(json['taskType'])),
      priority: serializer.fromJson<int>(json['priority']),
      status: $UploadTaskEntityTable.$converterstatus
          .fromJson(serializer.fromJson<int>(json['status'])),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      maxRetries: serializer.fromJson<int>(json['maxRetries']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      uploadedAt: serializer.fromJson<DateTime?>(json['uploadedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      progress: serializer.fromJson<int>(json['progress']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'assetId': serializer.toJson<String>(assetId),
      'localPath': serializer.toJson<String>(localPath),
      'remotePath': serializer.toJson<String>(remotePath),
      'fileSize': serializer.toJson<int>(fileSize),
      'taskType': serializer.toJson<int>(
          $UploadTaskEntityTable.$convertertaskType.toJson(taskType)),
      'priority': serializer.toJson<int>(priority),
      'status': serializer
          .toJson<int>($UploadTaskEntityTable.$converterstatus.toJson(status)),
      'retryCount': serializer.toJson<int>(retryCount),
      'maxRetries': serializer.toJson<int>(maxRetries),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'uploadedAt': serializer.toJson<DateTime?>(uploadedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'progress': serializer.toJson<int>(progress),
    };
  }

  UploadTaskEntityData copyWith(
          {String? id,
          String? userId,
          String? assetId,
          String? localPath,
          String? remotePath,
          int? fileSize,
          UploadTaskType? taskType,
          int? priority,
          UploadTaskStatus? status,
          int? retryCount,
          int? maxRetries,
          Value<String?> errorMessage = const Value.absent(),
          Value<DateTime?> uploadedAt = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          int? progress}) =>
      UploadTaskEntityData(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        assetId: assetId ?? this.assetId,
        localPath: localPath ?? this.localPath,
        remotePath: remotePath ?? this.remotePath,
        fileSize: fileSize ?? this.fileSize,
        taskType: taskType ?? this.taskType,
        priority: priority ?? this.priority,
        status: status ?? this.status,
        retryCount: retryCount ?? this.retryCount,
        maxRetries: maxRetries ?? this.maxRetries,
        errorMessage:
            errorMessage.present ? errorMessage.value : this.errorMessage,
        uploadedAt: uploadedAt.present ? uploadedAt.value : this.uploadedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        progress: progress ?? this.progress,
      );
  UploadTaskEntityData copyWithCompanion(UploadTaskEntityCompanion data) {
    return UploadTaskEntityData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      remotePath:
          data.remotePath.present ? data.remotePath.value : this.remotePath,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      taskType: data.taskType.present ? data.taskType.value : this.taskType,
      priority: data.priority.present ? data.priority.value : this.priority,
      status: data.status.present ? data.status.value : this.status,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      maxRetries:
          data.maxRetries.present ? data.maxRetries.value : this.maxRetries,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      uploadedAt:
          data.uploadedAt.present ? data.uploadedAt.value : this.uploadedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      progress: data.progress.present ? data.progress.value : this.progress,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UploadTaskEntityData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('assetId: $assetId, ')
          ..write('localPath: $localPath, ')
          ..write('remotePath: $remotePath, ')
          ..write('fileSize: $fileSize, ')
          ..write('taskType: $taskType, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('maxRetries: $maxRetries, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('uploadedAt: $uploadedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('progress: $progress')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      assetId,
      localPath,
      remotePath,
      fileSize,
      taskType,
      priority,
      status,
      retryCount,
      maxRetries,
      errorMessage,
      uploadedAt,
      createdAt,
      updatedAt,
      progress);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UploadTaskEntityData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.assetId == this.assetId &&
          other.localPath == this.localPath &&
          other.remotePath == this.remotePath &&
          other.fileSize == this.fileSize &&
          other.taskType == this.taskType &&
          other.priority == this.priority &&
          other.status == this.status &&
          other.retryCount == this.retryCount &&
          other.maxRetries == this.maxRetries &&
          other.errorMessage == this.errorMessage &&
          other.uploadedAt == this.uploadedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.progress == this.progress);
}

class UploadTaskEntityCompanion extends UpdateCompanion<UploadTaskEntityData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> assetId;
  final Value<String> localPath;
  final Value<String> remotePath;
  final Value<int> fileSize;
  final Value<UploadTaskType> taskType;
  final Value<int> priority;
  final Value<UploadTaskStatus> status;
  final Value<int> retryCount;
  final Value<int> maxRetries;
  final Value<String?> errorMessage;
  final Value<DateTime?> uploadedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> progress;
  const UploadTaskEntityCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.assetId = const Value.absent(),
    this.localPath = const Value.absent(),
    this.remotePath = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.taskType = const Value.absent(),
    this.priority = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.maxRetries = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.uploadedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.progress = const Value.absent(),
  });
  UploadTaskEntityCompanion.insert({
    required String id,
    required String userId,
    required String assetId,
    required String localPath,
    required String remotePath,
    required int fileSize,
    required UploadTaskType taskType,
    this.priority = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.maxRetries = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.uploadedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.progress = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        assetId = Value(assetId),
        localPath = Value(localPath),
        remotePath = Value(remotePath),
        fileSize = Value(fileSize),
        taskType = Value(taskType),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<UploadTaskEntityData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? assetId,
    Expression<String>? localPath,
    Expression<String>? remotePath,
    Expression<int>? fileSize,
    Expression<int>? taskType,
    Expression<int>? priority,
    Expression<int>? status,
    Expression<int>? retryCount,
    Expression<int>? maxRetries,
    Expression<String>? errorMessage,
    Expression<DateTime>? uploadedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? progress,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (assetId != null) 'asset_id': assetId,
      if (localPath != null) 'local_path': localPath,
      if (remotePath != null) 'remote_path': remotePath,
      if (fileSize != null) 'file_size': fileSize,
      if (taskType != null) 'task_type': taskType,
      if (priority != null) 'priority': priority,
      if (status != null) 'status': status,
      if (retryCount != null) 'retry_count': retryCount,
      if (maxRetries != null) 'max_retries': maxRetries,
      if (errorMessage != null) 'error_message': errorMessage,
      if (uploadedAt != null) 'uploaded_at': uploadedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (progress != null) 'progress': progress,
    });
  }

  UploadTaskEntityCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? assetId,
      Value<String>? localPath,
      Value<String>? remotePath,
      Value<int>? fileSize,
      Value<UploadTaskType>? taskType,
      Value<int>? priority,
      Value<UploadTaskStatus>? status,
      Value<int>? retryCount,
      Value<int>? maxRetries,
      Value<String?>? errorMessage,
      Value<DateTime?>? uploadedAt,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? progress}) {
    return UploadTaskEntityCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      assetId: assetId ?? this.assetId,
      localPath: localPath ?? this.localPath,
      remotePath: remotePath ?? this.remotePath,
      fileSize: fileSize ?? this.fileSize,
      taskType: taskType ?? this.taskType,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
      errorMessage: errorMessage ?? this.errorMessage,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      progress: progress ?? this.progress,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<String>(assetId.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (remotePath.present) {
      map['remote_path'] = Variable<String>(remotePath.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (taskType.present) {
      map['task_type'] = Variable<int>(
          $UploadTaskEntityTable.$convertertaskType.toSql(taskType.value));
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(
          $UploadTaskEntityTable.$converterstatus.toSql(status.value));
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (maxRetries.present) {
      map['max_retries'] = Variable<int>(maxRetries.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (uploadedAt.present) {
      map['uploaded_at'] = Variable<DateTime>(uploadedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (progress.present) {
      map['progress'] = Variable<int>(progress.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UploadTaskEntityCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('assetId: $assetId, ')
          ..write('localPath: $localPath, ')
          ..write('remotePath: $remotePath, ')
          ..write('fileSize: $fileSize, ')
          ..write('taskType: $taskType, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('maxRetries: $maxRetries, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('uploadedAt: $uploadedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('progress: $progress')
          ..write(')'))
        .toString();
  }
}

class $SyncCheckpointEntityTable extends SyncCheckpointEntity
    with TableInfo<$SyncCheckpointEntityTable, SyncCheckpointEntityData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncCheckpointEntityTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES user_entity (id) ON DELETE CASCADE'));
  static const VerificationMeta _syncTypeMeta =
      const VerificationMeta('syncType');
  @override
  late final GeneratedColumn<String> syncType = GeneratedColumn<String>(
      'sync_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ackMeta = const VerificationMeta('ack');
  @override
  late final GeneratedColumn<String> ack = GeneratedColumn<String>(
      'ack', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
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
  static const VerificationMeta _lastSyncTimeMeta =
      const VerificationMeta('lastSyncTime');
  @override
  late final GeneratedColumn<DateTime> lastSyncTime = GeneratedColumn<DateTime>(
      'last_sync_time', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [userId, syncType, ack, createdAt, updatedAt, lastSyncTime];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_checkpoint_entity';
  @override
  VerificationContext validateIntegrity(
      Insertable<SyncCheckpointEntityData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('sync_type')) {
      context.handle(_syncTypeMeta,
          syncType.isAcceptableOrUnknown(data['sync_type']!, _syncTypeMeta));
    } else if (isInserting) {
      context.missing(_syncTypeMeta);
    }
    if (data.containsKey('ack')) {
      context.handle(
          _ackMeta, ack.isAcceptableOrUnknown(data['ack']!, _ackMeta));
    } else if (isInserting) {
      context.missing(_ackMeta);
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
    if (data.containsKey('last_sync_time')) {
      context.handle(
          _lastSyncTimeMeta,
          lastSyncTime.isAcceptableOrUnknown(
              data['last_sync_time']!, _lastSyncTimeMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, syncType};
  @override
  SyncCheckpointEntityData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncCheckpointEntityData(
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      syncType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_type'])!,
      ack: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ack'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      lastSyncTime: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_sync_time']),
    );
  }

  @override
  $SyncCheckpointEntityTable createAlias(String alias) {
    return $SyncCheckpointEntityTable(attachedDatabase, alias);
  }

  @override
  bool get withoutRowId => true;
}

class SyncCheckpointEntityData extends DataClass
    implements Insertable<SyncCheckpointEntityData> {
  /// 用户 ID
  final String userId;

  /// 同步类型（如 "assets_v1"）
  final String syncType;

  /// Checkpoint ID（由服务器生成）
  final String ack;

  /// 创建时间
  final DateTime createdAt;

  /// 更新时间
  final DateTime updatedAt;

  /// 最后同步时间（专门用于增量同步）
  /// 记录每次同步完成的时间，用于增量同步的 updatedAfter 参数
  final DateTime? lastSyncTime;
  const SyncCheckpointEntityData(
      {required this.userId,
      required this.syncType,
      required this.ack,
      required this.createdAt,
      required this.updatedAt,
      this.lastSyncTime});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['sync_type'] = Variable<String>(syncType);
    map['ack'] = Variable<String>(ack);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || lastSyncTime != null) {
      map['last_sync_time'] = Variable<DateTime>(lastSyncTime);
    }
    return map;
  }

  SyncCheckpointEntityCompanion toCompanion(bool nullToAbsent) {
    return SyncCheckpointEntityCompanion(
      userId: Value(userId),
      syncType: Value(syncType),
      ack: Value(ack),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastSyncTime: lastSyncTime == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncTime),
    );
  }

  factory SyncCheckpointEntityData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncCheckpointEntityData(
      userId: serializer.fromJson<String>(json['userId']),
      syncType: serializer.fromJson<String>(json['syncType']),
      ack: serializer.fromJson<String>(json['ack']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      lastSyncTime: serializer.fromJson<DateTime?>(json['lastSyncTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'syncType': serializer.toJson<String>(syncType),
      'ack': serializer.toJson<String>(ack),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lastSyncTime': serializer.toJson<DateTime?>(lastSyncTime),
    };
  }

  SyncCheckpointEntityData copyWith(
          {String? userId,
          String? syncType,
          String? ack,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> lastSyncTime = const Value.absent()}) =>
      SyncCheckpointEntityData(
        userId: userId ?? this.userId,
        syncType: syncType ?? this.syncType,
        ack: ack ?? this.ack,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        lastSyncTime:
            lastSyncTime.present ? lastSyncTime.value : this.lastSyncTime,
      );
  SyncCheckpointEntityData copyWithCompanion(
      SyncCheckpointEntityCompanion data) {
    return SyncCheckpointEntityData(
      userId: data.userId.present ? data.userId.value : this.userId,
      syncType: data.syncType.present ? data.syncType.value : this.syncType,
      ack: data.ack.present ? data.ack.value : this.ack,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastSyncTime: data.lastSyncTime.present
          ? data.lastSyncTime.value
          : this.lastSyncTime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncCheckpointEntityData(')
          ..write('userId: $userId, ')
          ..write('syncType: $syncType, ')
          ..write('ack: $ack, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSyncTime: $lastSyncTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(userId, syncType, ack, createdAt, updatedAt, lastSyncTime);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncCheckpointEntityData &&
          other.userId == this.userId &&
          other.syncType == this.syncType &&
          other.ack == this.ack &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastSyncTime == this.lastSyncTime);
}

class SyncCheckpointEntityCompanion
    extends UpdateCompanion<SyncCheckpointEntityData> {
  final Value<String> userId;
  final Value<String> syncType;
  final Value<String> ack;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> lastSyncTime;
  const SyncCheckpointEntityCompanion({
    this.userId = const Value.absent(),
    this.syncType = const Value.absent(),
    this.ack = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastSyncTime = const Value.absent(),
  });
  SyncCheckpointEntityCompanion.insert({
    required String userId,
    required String syncType,
    required String ack,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.lastSyncTime = const Value.absent(),
  })  : userId = Value(userId),
        syncType = Value(syncType),
        ack = Value(ack),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<SyncCheckpointEntityData> custom({
    Expression<String>? userId,
    Expression<String>? syncType,
    Expression<String>? ack,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? lastSyncTime,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (syncType != null) 'sync_type': syncType,
      if (ack != null) 'ack': ack,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastSyncTime != null) 'last_sync_time': lastSyncTime,
    });
  }

  SyncCheckpointEntityCompanion copyWith(
      {Value<String>? userId,
      Value<String>? syncType,
      Value<String>? ack,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? lastSyncTime}) {
    return SyncCheckpointEntityCompanion(
      userId: userId ?? this.userId,
      syncType: syncType ?? this.syncType,
      ack: ack ?? this.ack,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (syncType.present) {
      map['sync_type'] = Variable<String>(syncType.value);
    }
    if (ack.present) {
      map['ack'] = Variable<String>(ack.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (lastSyncTime.present) {
      map['last_sync_time'] = Variable<DateTime>(lastSyncTime.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncCheckpointEntityCompanion(')
          ..write('userId: $userId, ')
          ..write('syncType: $syncType, ')
          ..write('ack: $ack, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSyncTime: $lastSyncTime')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UserEntityTable userEntity = $UserEntityTable(this);
  late final $LocalAssetEntityTable localAssetEntity =
      $LocalAssetEntityTable(this);
  late final $RemoteAssetEntityTable remoteAssetEntity =
      $RemoteAssetEntityTable(this);
  late final $RemoteAlbumEntityTable remoteAlbumEntity =
      $RemoteAlbumEntityTable(this);
  late final $LocalAlbumEntityTable localAlbumEntity =
      $LocalAlbumEntityTable(this);
  late final $AlbumAssetEntityTable albumAssetEntity =
      $AlbumAssetEntityTable(this);
  late final $LocalAlbumAssetEntityTable localAlbumAssetEntity =
      $LocalAlbumAssetEntityTable(this);
  late final $AlbumSessionEntityTable albumSessionEntity =
      $AlbumSessionEntityTable(this);
  late final $RetryTaskEntityTable retryTaskEntity =
      $RetryTaskEntityTable(this);
  late final $StoreEntityTable storeEntity = $StoreEntityTable(this);
  late final $BackupStatusEntityTable backupStatusEntity =
      $BackupStatusEntityTable(this);
  late final $UploadTaskEntityTable uploadTaskEntity =
      $UploadTaskEntityTable(this);
  late final $SyncCheckpointEntityTable syncCheckpointEntity =
      $SyncCheckpointEntityTable(this);
  late final Index idxLocalAssetChecksum = Index('idx_local_asset_checksum',
      'CREATE INDEX idx_local_asset_checksum ON local_asset_entity (checksum)');
  late final Index idxRemoteAssetOwnerChecksum = Index(
      'idx_remote_asset_owner_checksum',
      'CREATE INDEX idx_remote_asset_owner_checksum ON remote_asset_entity (owner_id, checksum)');
  late final Index idxRemoteAssetChecksum = Index('idx_remote_asset_checksum',
      'CREATE INDEX idx_remote_asset_checksum ON remote_asset_entity (checksum)');
  late final Index idxBackupStatusUserId = Index('idx_backup_status_user_id',
      'CREATE INDEX idx_backup_status_user_id ON backup_status_entity (user_id)');
  late final Index idxUploadTaskUserId = Index('idx_upload_task_user_id',
      'CREATE INDEX idx_upload_task_user_id ON upload_task_entity (user_id)');
  late final Index idxUploadTaskStatus = Index('idx_upload_task_status',
      'CREATE INDEX idx_upload_task_status ON upload_task_entity (status)');
  late final Index idxUploadTaskType = Index('idx_upload_task_type',
      'CREATE INDEX idx_upload_task_type ON upload_task_entity (task_type)');
  late final Index idxUploadTaskPriority = Index('idx_upload_task_priority',
      'CREATE INDEX idx_upload_task_priority ON upload_task_entity (priority)');
  late final Index idxUploadTaskAssetId = Index('idx_upload_task_asset_id',
      'CREATE INDEX idx_upload_task_asset_id ON upload_task_entity (asset_id)');
  late final UserDao userDao = UserDao(this as AppDatabase);
  late final LocalAssetDao localAssetDao = LocalAssetDao(this as AppDatabase);
  late final RemoteAssetDao remoteAssetDao =
      RemoteAssetDao(this as AppDatabase);
  late final AlbumDao albumDao = AlbumDao(this as AppDatabase);
  late final BackupStatusDao backupStatusDao =
      BackupStatusDao(this as AppDatabase);
  late final UploadTaskDao uploadTaskDao = UploadTaskDao(this as AppDatabase);
  late final SyncCheckpointDao syncCheckpointDao =
      SyncCheckpointDao(this as AppDatabase);
  late final RetryTaskDao retryTaskDao = RetryTaskDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        userEntity,
        localAssetEntity,
        remoteAssetEntity,
        remoteAlbumEntity,
        localAlbumEntity,
        albumAssetEntity,
        localAlbumAssetEntity,
        albumSessionEntity,
        retryTaskEntity,
        storeEntity,
        backupStatusEntity,
        uploadTaskEntity,
        syncCheckpointEntity,
        idxLocalAssetChecksum,
        idxRemoteAssetOwnerChecksum,
        idxRemoteAssetChecksum,
        idxBackupStatusUserId,
        idxUploadTaskUserId,
        idxUploadTaskStatus,
        idxUploadTaskType,
        idxUploadTaskPriority,
        idxUploadTaskAssetId
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('user_entity',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('remote_asset_entity', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('user_entity',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('remote_album_entity', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('remote_asset_entity',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('remote_album_entity', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('remote_album_entity',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('local_album_entity', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('remote_asset_entity',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('album_asset_entity', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('remote_album_entity',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('album_asset_entity', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('local_asset_entity',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('local_album_asset_entity', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('local_album_entity',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('local_album_asset_entity', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('remote_album_entity',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('album_session_entity', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('user_entity',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('backup_status_entity', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('user_entity',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('upload_task_entity', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('user_entity',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('sync_checkpoint_entity', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$UserEntityTableCreateCompanionBuilder = UserEntityCompanion Function({
  required String id,
  required String name,
  Value<String?> email,
  Value<String?> avatarUrl,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$UserEntityTableUpdateCompanionBuilder = UserEntityCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> email,
  Value<String?> avatarUrl,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$UserEntityTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserEntityTable,
    UserEntityData,
    $$UserEntityTableFilterComposer,
    $$UserEntityTableOrderingComposer,
    $$UserEntityTableCreateCompanionBuilder,
    $$UserEntityTableUpdateCompanionBuilder> {
  $$UserEntityTableTableManager(_$AppDatabase db, $UserEntityTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$UserEntityTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$UserEntityTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<String?> avatarUrl = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              UserEntityCompanion(
            id: id,
            name: name,
            email: email,
            avatarUrl: avatarUrl,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> email = const Value.absent(),
            Value<String?> avatarUrl = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
          }) =>
              UserEntityCompanion.insert(
            id: id,
            name: name,
            email: email,
            avatarUrl: avatarUrl,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
        ));
}

class $$UserEntityTableFilterComposer
    extends FilterComposer<_$AppDatabase, $UserEntityTable> {
  $$UserEntityTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get email => $state.composableBuilder(
      column: $state.table.email,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get avatarUrl => $state.composableBuilder(
      column: $state.table.avatarUrl,
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

  ComposableFilter remoteAssetEntityRefs(
      ComposableFilter Function($$RemoteAssetEntityTableFilterComposer f) f) {
    final $$RemoteAssetEntityTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $state.db.remoteAssetEntity,
            getReferencedColumn: (t) => t.ownerId,
            builder: (joinBuilder, parentComposers) =>
                $$RemoteAssetEntityTableFilterComposer(ComposerState(
                    $state.db,
                    $state.db.remoteAssetEntity,
                    joinBuilder,
                    parentComposers)));
    return f(composer);
  }

  ComposableFilter remoteAlbumEntityRefs(
      ComposableFilter Function($$RemoteAlbumEntityTableFilterComposer f) f) {
    final $$RemoteAlbumEntityTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $state.db.remoteAlbumEntity,
            getReferencedColumn: (t) => t.ownerId,
            builder: (joinBuilder, parentComposers) =>
                $$RemoteAlbumEntityTableFilterComposer(ComposerState(
                    $state.db,
                    $state.db.remoteAlbumEntity,
                    joinBuilder,
                    parentComposers)));
    return f(composer);
  }

  ComposableFilter backupStatusEntityRefs(
      ComposableFilter Function($$BackupStatusEntityTableFilterComposer f) f) {
    final $$BackupStatusEntityTableFilterComposer composer = $state
        .composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $state.db.backupStatusEntity,
            getReferencedColumn: (t) => t.userId,
            builder: (joinBuilder, parentComposers) =>
                $$BackupStatusEntityTableFilterComposer(ComposerState(
                    $state.db,
                    $state.db.backupStatusEntity,
                    joinBuilder,
                    parentComposers)));
    return f(composer);
  }

  ComposableFilter uploadTaskEntityRefs(
      ComposableFilter Function($$UploadTaskEntityTableFilterComposer f) f) {
    final $$UploadTaskEntityTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $state.db.uploadTaskEntity,
            getReferencedColumn: (t) => t.userId,
            builder: (joinBuilder, parentComposers) =>
                $$UploadTaskEntityTableFilterComposer(ComposerState($state.db,
                    $state.db.uploadTaskEntity, joinBuilder, parentComposers)));
    return f(composer);
  }

  ComposableFilter syncCheckpointEntityRefs(
      ComposableFilter Function($$SyncCheckpointEntityTableFilterComposer f)
          f) {
    final $$SyncCheckpointEntityTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $state.db.syncCheckpointEntity,
            getReferencedColumn: (t) => t.userId,
            builder: (joinBuilder, parentComposers) =>
                $$SyncCheckpointEntityTableFilterComposer(ComposerState(
                    $state.db,
                    $state.db.syncCheckpointEntity,
                    joinBuilder,
                    parentComposers)));
    return f(composer);
  }
}

class $$UserEntityTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $UserEntityTable> {
  $$UserEntityTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get email => $state.composableBuilder(
      column: $state.table.email,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get avatarUrl => $state.composableBuilder(
      column: $state.table.avatarUrl,
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

typedef $$LocalAssetEntityTableCreateCompanionBuilder
    = LocalAssetEntityCompanion Function({
  required String name,
  required AssetType type,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int?> width,
  Value<int?> height,
  Value<int?> durationInSeconds,
  required String id,
  Value<String?> checksum,
  required String path,
  Value<bool> isFavorite,
  Value<int> orientation,
  Value<bool> isInPrivateSpace,
  Value<MigrationStatus> migrationStatus,
});
typedef $$LocalAssetEntityTableUpdateCompanionBuilder
    = LocalAssetEntityCompanion Function({
  Value<String> name,
  Value<AssetType> type,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int?> width,
  Value<int?> height,
  Value<int?> durationInSeconds,
  Value<String> id,
  Value<String?> checksum,
  Value<String> path,
  Value<bool> isFavorite,
  Value<int> orientation,
  Value<bool> isInPrivateSpace,
  Value<MigrationStatus> migrationStatus,
});

class $$LocalAssetEntityTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalAssetEntityTable,
    LocalAssetEntityData,
    $$LocalAssetEntityTableFilterComposer,
    $$LocalAssetEntityTableOrderingComposer,
    $$LocalAssetEntityTableCreateCompanionBuilder,
    $$LocalAssetEntityTableUpdateCompanionBuilder> {
  $$LocalAssetEntityTableTableManager(
      _$AppDatabase db, $LocalAssetEntityTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$LocalAssetEntityTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$LocalAssetEntityTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> name = const Value.absent(),
            Value<AssetType> type = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int?> width = const Value.absent(),
            Value<int?> height = const Value.absent(),
            Value<int?> durationInSeconds = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<String?> checksum = const Value.absent(),
            Value<String> path = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<int> orientation = const Value.absent(),
            Value<bool> isInPrivateSpace = const Value.absent(),
            Value<MigrationStatus> migrationStatus = const Value.absent(),
          }) =>
              LocalAssetEntityCompanion(
            name: name,
            type: type,
            createdAt: createdAt,
            updatedAt: updatedAt,
            width: width,
            height: height,
            durationInSeconds: durationInSeconds,
            id: id,
            checksum: checksum,
            path: path,
            isFavorite: isFavorite,
            orientation: orientation,
            isInPrivateSpace: isInPrivateSpace,
            migrationStatus: migrationStatus,
          ),
          createCompanionCallback: ({
            required String name,
            required AssetType type,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int?> width = const Value.absent(),
            Value<int?> height = const Value.absent(),
            Value<int?> durationInSeconds = const Value.absent(),
            required String id,
            Value<String?> checksum = const Value.absent(),
            required String path,
            Value<bool> isFavorite = const Value.absent(),
            Value<int> orientation = const Value.absent(),
            Value<bool> isInPrivateSpace = const Value.absent(),
            Value<MigrationStatus> migrationStatus = const Value.absent(),
          }) =>
              LocalAssetEntityCompanion.insert(
            name: name,
            type: type,
            createdAt: createdAt,
            updatedAt: updatedAt,
            width: width,
            height: height,
            durationInSeconds: durationInSeconds,
            id: id,
            checksum: checksum,
            path: path,
            isFavorite: isFavorite,
            orientation: orientation,
            isInPrivateSpace: isInPrivateSpace,
            migrationStatus: migrationStatus,
          ),
        ));
}

class $$LocalAssetEntityTableFilterComposer
    extends FilterComposer<_$AppDatabase, $LocalAssetEntityTable> {
  $$LocalAssetEntityTableFilterComposer(super.$state);
  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<AssetType, AssetType, int> get type =>
      $state.composableBuilder(
          column: $state.table.type,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
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

  ColumnFilters<int> get durationInSeconds => $state.composableBuilder(
      column: $state.table.durationInSeconds,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get checksum => $state.composableBuilder(
      column: $state.table.checksum,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get path => $state.composableBuilder(
      column: $state.table.path,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isFavorite => $state.composableBuilder(
      column: $state.table.isFavorite,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get orientation => $state.composableBuilder(
      column: $state.table.orientation,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isInPrivateSpace => $state.composableBuilder(
      column: $state.table.isInPrivateSpace,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<MigrationStatus, MigrationStatus, int>
      get migrationStatus => $state.composableBuilder(
          column: $state.table.migrationStatus,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ComposableFilter localAlbumAssetEntityRefs(
      ComposableFilter Function($$LocalAlbumAssetEntityTableFilterComposer f)
          f) {
    final $$LocalAlbumAssetEntityTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $state.db.localAlbumAssetEntity,
            getReferencedColumn: (t) => t.assetId,
            builder: (joinBuilder, parentComposers) =>
                $$LocalAlbumAssetEntityTableFilterComposer(ComposerState(
                    $state.db,
                    $state.db.localAlbumAssetEntity,
                    joinBuilder,
                    parentComposers)));
    return f(composer);
  }
}

class $$LocalAssetEntityTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $LocalAssetEntityTable> {
  $$LocalAssetEntityTableOrderingComposer(super.$state);
  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get type => $state.composableBuilder(
      column: $state.table.type,
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

  ColumnOrderings<int> get width => $state.composableBuilder(
      column: $state.table.width,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get height => $state.composableBuilder(
      column: $state.table.height,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get durationInSeconds => $state.composableBuilder(
      column: $state.table.durationInSeconds,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get checksum => $state.composableBuilder(
      column: $state.table.checksum,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get path => $state.composableBuilder(
      column: $state.table.path,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isFavorite => $state.composableBuilder(
      column: $state.table.isFavorite,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get orientation => $state.composableBuilder(
      column: $state.table.orientation,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isInPrivateSpace => $state.composableBuilder(
      column: $state.table.isInPrivateSpace,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get migrationStatus => $state.composableBuilder(
      column: $state.table.migrationStatus,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$RemoteAssetEntityTableCreateCompanionBuilder
    = RemoteAssetEntityCompanion Function({
  required String name,
  required AssetType type,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int?> width,
  Value<int?> height,
  Value<int?> durationInSeconds,
  required String id,
  required String checksum,
  Value<bool> isFavorite,
  required String ownerId,
  Value<DateTime?> localDateTime,
  Value<String?> thumbHash,
  Value<DateTime?> deletedAt,
  Value<String?> livePhotoVideoId,
  Value<AssetVisibility> visibility,
  Value<String?> stackId,
  Value<String?> libraryId,
});
typedef $$RemoteAssetEntityTableUpdateCompanionBuilder
    = RemoteAssetEntityCompanion Function({
  Value<String> name,
  Value<AssetType> type,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int?> width,
  Value<int?> height,
  Value<int?> durationInSeconds,
  Value<String> id,
  Value<String> checksum,
  Value<bool> isFavorite,
  Value<String> ownerId,
  Value<DateTime?> localDateTime,
  Value<String?> thumbHash,
  Value<DateTime?> deletedAt,
  Value<String?> livePhotoVideoId,
  Value<AssetVisibility> visibility,
  Value<String?> stackId,
  Value<String?> libraryId,
});

class $$RemoteAssetEntityTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RemoteAssetEntityTable,
    RemoteAssetEntityData,
    $$RemoteAssetEntityTableFilterComposer,
    $$RemoteAssetEntityTableOrderingComposer,
    $$RemoteAssetEntityTableCreateCompanionBuilder,
    $$RemoteAssetEntityTableUpdateCompanionBuilder> {
  $$RemoteAssetEntityTableTableManager(
      _$AppDatabase db, $RemoteAssetEntityTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$RemoteAssetEntityTableFilterComposer(ComposerState(db, table)),
          orderingComposer: $$RemoteAssetEntityTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> name = const Value.absent(),
            Value<AssetType> type = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int?> width = const Value.absent(),
            Value<int?> height = const Value.absent(),
            Value<int?> durationInSeconds = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<String> checksum = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<String> ownerId = const Value.absent(),
            Value<DateTime?> localDateTime = const Value.absent(),
            Value<String?> thumbHash = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String?> livePhotoVideoId = const Value.absent(),
            Value<AssetVisibility> visibility = const Value.absent(),
            Value<String?> stackId = const Value.absent(),
            Value<String?> libraryId = const Value.absent(),
          }) =>
              RemoteAssetEntityCompanion(
            name: name,
            type: type,
            createdAt: createdAt,
            updatedAt: updatedAt,
            width: width,
            height: height,
            durationInSeconds: durationInSeconds,
            id: id,
            checksum: checksum,
            isFavorite: isFavorite,
            ownerId: ownerId,
            localDateTime: localDateTime,
            thumbHash: thumbHash,
            deletedAt: deletedAt,
            livePhotoVideoId: livePhotoVideoId,
            visibility: visibility,
            stackId: stackId,
            libraryId: libraryId,
          ),
          createCompanionCallback: ({
            required String name,
            required AssetType type,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int?> width = const Value.absent(),
            Value<int?> height = const Value.absent(),
            Value<int?> durationInSeconds = const Value.absent(),
            required String id,
            required String checksum,
            Value<bool> isFavorite = const Value.absent(),
            required String ownerId,
            Value<DateTime?> localDateTime = const Value.absent(),
            Value<String?> thumbHash = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String?> livePhotoVideoId = const Value.absent(),
            Value<AssetVisibility> visibility = const Value.absent(),
            Value<String?> stackId = const Value.absent(),
            Value<String?> libraryId = const Value.absent(),
          }) =>
              RemoteAssetEntityCompanion.insert(
            name: name,
            type: type,
            createdAt: createdAt,
            updatedAt: updatedAt,
            width: width,
            height: height,
            durationInSeconds: durationInSeconds,
            id: id,
            checksum: checksum,
            isFavorite: isFavorite,
            ownerId: ownerId,
            localDateTime: localDateTime,
            thumbHash: thumbHash,
            deletedAt: deletedAt,
            livePhotoVideoId: livePhotoVideoId,
            visibility: visibility,
            stackId: stackId,
            libraryId: libraryId,
          ),
        ));
}

class $$RemoteAssetEntityTableFilterComposer
    extends FilterComposer<_$AppDatabase, $RemoteAssetEntityTable> {
  $$RemoteAssetEntityTableFilterComposer(super.$state);
  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<AssetType, AssetType, int> get type =>
      $state.composableBuilder(
          column: $state.table.type,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
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

  ColumnFilters<int> get durationInSeconds => $state.composableBuilder(
      column: $state.table.durationInSeconds,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get checksum => $state.composableBuilder(
      column: $state.table.checksum,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isFavorite => $state.composableBuilder(
      column: $state.table.isFavorite,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get localDateTime => $state.composableBuilder(
      column: $state.table.localDateTime,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get thumbHash => $state.composableBuilder(
      column: $state.table.thumbHash,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get deletedAt => $state.composableBuilder(
      column: $state.table.deletedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get livePhotoVideoId => $state.composableBuilder(
      column: $state.table.livePhotoVideoId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<AssetVisibility, AssetVisibility, int>
      get visibility => $state.composableBuilder(
          column: $state.table.visibility,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnFilters<String> get stackId => $state.composableBuilder(
      column: $state.table.stackId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get libraryId => $state.composableBuilder(
      column: $state.table.libraryId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$UserEntityTableFilterComposer get ownerId {
    final $$UserEntityTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.ownerId,
        referencedTable: $state.db.userEntity,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$UserEntityTableFilterComposer(ComposerState($state.db,
                $state.db.userEntity, joinBuilder, parentComposers)));
    return composer;
  }

  ComposableFilter remoteAlbumEntityRefs(
      ComposableFilter Function($$RemoteAlbumEntityTableFilterComposer f) f) {
    final $$RemoteAlbumEntityTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $state.db.remoteAlbumEntity,
            getReferencedColumn: (t) => t.thumbnailAssetId,
            builder: (joinBuilder, parentComposers) =>
                $$RemoteAlbumEntityTableFilterComposer(ComposerState(
                    $state.db,
                    $state.db.remoteAlbumEntity,
                    joinBuilder,
                    parentComposers)));
    return f(composer);
  }

  ComposableFilter albumAssetEntityRefs(
      ComposableFilter Function($$AlbumAssetEntityTableFilterComposer f) f) {
    final $$AlbumAssetEntityTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $state.db.albumAssetEntity,
            getReferencedColumn: (t) => t.assetId,
            builder: (joinBuilder, parentComposers) =>
                $$AlbumAssetEntityTableFilterComposer(ComposerState($state.db,
                    $state.db.albumAssetEntity, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$RemoteAssetEntityTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $RemoteAssetEntityTable> {
  $$RemoteAssetEntityTableOrderingComposer(super.$state);
  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get type => $state.composableBuilder(
      column: $state.table.type,
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

  ColumnOrderings<int> get width => $state.composableBuilder(
      column: $state.table.width,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get height => $state.composableBuilder(
      column: $state.table.height,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get durationInSeconds => $state.composableBuilder(
      column: $state.table.durationInSeconds,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get checksum => $state.composableBuilder(
      column: $state.table.checksum,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isFavorite => $state.composableBuilder(
      column: $state.table.isFavorite,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get localDateTime => $state.composableBuilder(
      column: $state.table.localDateTime,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get thumbHash => $state.composableBuilder(
      column: $state.table.thumbHash,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get deletedAt => $state.composableBuilder(
      column: $state.table.deletedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get livePhotoVideoId => $state.composableBuilder(
      column: $state.table.livePhotoVideoId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get visibility => $state.composableBuilder(
      column: $state.table.visibility,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get stackId => $state.composableBuilder(
      column: $state.table.stackId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get libraryId => $state.composableBuilder(
      column: $state.table.libraryId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$UserEntityTableOrderingComposer get ownerId {
    final $$UserEntityTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.ownerId,
        referencedTable: $state.db.userEntity,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$UserEntityTableOrderingComposer(ComposerState($state.db,
                $state.db.userEntity, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$RemoteAlbumEntityTableCreateCompanionBuilder
    = RemoteAlbumEntityCompanion Function({
  required String id,
  required String name,
  Value<String?> description,
  required DateTime createdAt,
  required DateTime updatedAt,
  required String ownerId,
  Value<String?> thumbnailAssetId,
  Value<bool> isActivityEnabled,
  Value<AlbumOrder> order,
  Value<bool> isEncrypted,
  Value<AlbumType> albumType,
});
typedef $$RemoteAlbumEntityTableUpdateCompanionBuilder
    = RemoteAlbumEntityCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> description,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String> ownerId,
  Value<String?> thumbnailAssetId,
  Value<bool> isActivityEnabled,
  Value<AlbumOrder> order,
  Value<bool> isEncrypted,
  Value<AlbumType> albumType,
});

class $$RemoteAlbumEntityTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RemoteAlbumEntityTable,
    RemoteAlbumEntityData,
    $$RemoteAlbumEntityTableFilterComposer,
    $$RemoteAlbumEntityTableOrderingComposer,
    $$RemoteAlbumEntityTableCreateCompanionBuilder,
    $$RemoteAlbumEntityTableUpdateCompanionBuilder> {
  $$RemoteAlbumEntityTableTableManager(
      _$AppDatabase db, $RemoteAlbumEntityTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$RemoteAlbumEntityTableFilterComposer(ComposerState(db, table)),
          orderingComposer: $$RemoteAlbumEntityTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<String> ownerId = const Value.absent(),
            Value<String?> thumbnailAssetId = const Value.absent(),
            Value<bool> isActivityEnabled = const Value.absent(),
            Value<AlbumOrder> order = const Value.absent(),
            Value<bool> isEncrypted = const Value.absent(),
            Value<AlbumType> albumType = const Value.absent(),
          }) =>
              RemoteAlbumEntityCompanion(
            id: id,
            name: name,
            description: description,
            createdAt: createdAt,
            updatedAt: updatedAt,
            ownerId: ownerId,
            thumbnailAssetId: thumbnailAssetId,
            isActivityEnabled: isActivityEnabled,
            order: order,
            isEncrypted: isEncrypted,
            albumType: albumType,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> description = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            required String ownerId,
            Value<String?> thumbnailAssetId = const Value.absent(),
            Value<bool> isActivityEnabled = const Value.absent(),
            Value<AlbumOrder> order = const Value.absent(),
            Value<bool> isEncrypted = const Value.absent(),
            Value<AlbumType> albumType = const Value.absent(),
          }) =>
              RemoteAlbumEntityCompanion.insert(
            id: id,
            name: name,
            description: description,
            createdAt: createdAt,
            updatedAt: updatedAt,
            ownerId: ownerId,
            thumbnailAssetId: thumbnailAssetId,
            isActivityEnabled: isActivityEnabled,
            order: order,
            isEncrypted: isEncrypted,
            albumType: albumType,
          ),
        ));
}

class $$RemoteAlbumEntityTableFilterComposer
    extends FilterComposer<_$AppDatabase, $RemoteAlbumEntityTable> {
  $$RemoteAlbumEntityTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get description => $state.composableBuilder(
      column: $state.table.description,
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

  ColumnFilters<bool> get isActivityEnabled => $state.composableBuilder(
      column: $state.table.isActivityEnabled,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<AlbumOrder, AlbumOrder, int> get order =>
      $state.composableBuilder(
          column: $state.table.order,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnFilters<bool> get isEncrypted => $state.composableBuilder(
      column: $state.table.isEncrypted,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<AlbumType, AlbumType, int> get albumType =>
      $state.composableBuilder(
          column: $state.table.albumType,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  $$UserEntityTableFilterComposer get ownerId {
    final $$UserEntityTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.ownerId,
        referencedTable: $state.db.userEntity,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$UserEntityTableFilterComposer(ComposerState($state.db,
                $state.db.userEntity, joinBuilder, parentComposers)));
    return composer;
  }

  $$RemoteAssetEntityTableFilterComposer get thumbnailAssetId {
    final $$RemoteAssetEntityTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.thumbnailAssetId,
            referencedTable: $state.db.remoteAssetEntity,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder, parentComposers) =>
                $$RemoteAssetEntityTableFilterComposer(ComposerState(
                    $state.db,
                    $state.db.remoteAssetEntity,
                    joinBuilder,
                    parentComposers)));
    return composer;
  }

  ComposableFilter localAlbumEntityRefs(
      ComposableFilter Function($$LocalAlbumEntityTableFilterComposer f) f) {
    final $$LocalAlbumEntityTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $state.db.localAlbumEntity,
            getReferencedColumn: (t) => t.linkedRemoteAlbumId,
            builder: (joinBuilder, parentComposers) =>
                $$LocalAlbumEntityTableFilterComposer(ComposerState($state.db,
                    $state.db.localAlbumEntity, joinBuilder, parentComposers)));
    return f(composer);
  }

  ComposableFilter albumAssetEntityRefs(
      ComposableFilter Function($$AlbumAssetEntityTableFilterComposer f) f) {
    final $$AlbumAssetEntityTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $state.db.albumAssetEntity,
            getReferencedColumn: (t) => t.albumId,
            builder: (joinBuilder, parentComposers) =>
                $$AlbumAssetEntityTableFilterComposer(ComposerState($state.db,
                    $state.db.albumAssetEntity, joinBuilder, parentComposers)));
    return f(composer);
  }

  ComposableFilter albumSessionEntityRefs(
      ComposableFilter Function($$AlbumSessionEntityTableFilterComposer f) f) {
    final $$AlbumSessionEntityTableFilterComposer composer = $state
        .composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $state.db.albumSessionEntity,
            getReferencedColumn: (t) => t.albumId,
            builder: (joinBuilder, parentComposers) =>
                $$AlbumSessionEntityTableFilterComposer(ComposerState(
                    $state.db,
                    $state.db.albumSessionEntity,
                    joinBuilder,
                    parentComposers)));
    return f(composer);
  }
}

class $$RemoteAlbumEntityTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $RemoteAlbumEntityTable> {
  $$RemoteAlbumEntityTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get description => $state.composableBuilder(
      column: $state.table.description,
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

  ColumnOrderings<bool> get isActivityEnabled => $state.composableBuilder(
      column: $state.table.isActivityEnabled,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get order => $state.composableBuilder(
      column: $state.table.order,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isEncrypted => $state.composableBuilder(
      column: $state.table.isEncrypted,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get albumType => $state.composableBuilder(
      column: $state.table.albumType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$UserEntityTableOrderingComposer get ownerId {
    final $$UserEntityTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.ownerId,
        referencedTable: $state.db.userEntity,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$UserEntityTableOrderingComposer(ComposerState($state.db,
                $state.db.userEntity, joinBuilder, parentComposers)));
    return composer;
  }

  $$RemoteAssetEntityTableOrderingComposer get thumbnailAssetId {
    final $$RemoteAssetEntityTableOrderingComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.thumbnailAssetId,
            referencedTable: $state.db.remoteAssetEntity,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder, parentComposers) =>
                $$RemoteAssetEntityTableOrderingComposer(ComposerState(
                    $state.db,
                    $state.db.remoteAssetEntity,
                    joinBuilder,
                    parentComposers)));
    return composer;
  }
}

typedef $$LocalAlbumEntityTableCreateCompanionBuilder
    = LocalAlbumEntityCompanion Function({
  required String id,
  required String name,
  required DateTime updatedAt,
  Value<BackupSelection> backupSelection,
  Value<bool> isIosSharedAlbum,
  Value<String?> linkedRemoteAlbumId,
  Value<bool> isEncrypted,
  Value<AlbumType> albumType,
});
typedef $$LocalAlbumEntityTableUpdateCompanionBuilder
    = LocalAlbumEntityCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<DateTime> updatedAt,
  Value<BackupSelection> backupSelection,
  Value<bool> isIosSharedAlbum,
  Value<String?> linkedRemoteAlbumId,
  Value<bool> isEncrypted,
  Value<AlbumType> albumType,
});

class $$LocalAlbumEntityTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalAlbumEntityTable,
    LocalAlbumEntityData,
    $$LocalAlbumEntityTableFilterComposer,
    $$LocalAlbumEntityTableOrderingComposer,
    $$LocalAlbumEntityTableCreateCompanionBuilder,
    $$LocalAlbumEntityTableUpdateCompanionBuilder> {
  $$LocalAlbumEntityTableTableManager(
      _$AppDatabase db, $LocalAlbumEntityTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$LocalAlbumEntityTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$LocalAlbumEntityTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<BackupSelection> backupSelection = const Value.absent(),
            Value<bool> isIosSharedAlbum = const Value.absent(),
            Value<String?> linkedRemoteAlbumId = const Value.absent(),
            Value<bool> isEncrypted = const Value.absent(),
            Value<AlbumType> albumType = const Value.absent(),
          }) =>
              LocalAlbumEntityCompanion(
            id: id,
            name: name,
            updatedAt: updatedAt,
            backupSelection: backupSelection,
            isIosSharedAlbum: isIosSharedAlbum,
            linkedRemoteAlbumId: linkedRemoteAlbumId,
            isEncrypted: isEncrypted,
            albumType: albumType,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required DateTime updatedAt,
            Value<BackupSelection> backupSelection = const Value.absent(),
            Value<bool> isIosSharedAlbum = const Value.absent(),
            Value<String?> linkedRemoteAlbumId = const Value.absent(),
            Value<bool> isEncrypted = const Value.absent(),
            Value<AlbumType> albumType = const Value.absent(),
          }) =>
              LocalAlbumEntityCompanion.insert(
            id: id,
            name: name,
            updatedAt: updatedAt,
            backupSelection: backupSelection,
            isIosSharedAlbum: isIosSharedAlbum,
            linkedRemoteAlbumId: linkedRemoteAlbumId,
            isEncrypted: isEncrypted,
            albumType: albumType,
          ),
        ));
}

class $$LocalAlbumEntityTableFilterComposer
    extends FilterComposer<_$AppDatabase, $LocalAlbumEntityTable> {
  $$LocalAlbumEntityTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<BackupSelection, BackupSelection, int>
      get backupSelection => $state.composableBuilder(
          column: $state.table.backupSelection,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnFilters<bool> get isIosSharedAlbum => $state.composableBuilder(
      column: $state.table.isIosSharedAlbum,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isEncrypted => $state.composableBuilder(
      column: $state.table.isEncrypted,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<AlbumType, AlbumType, int> get albumType =>
      $state.composableBuilder(
          column: $state.table.albumType,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  $$RemoteAlbumEntityTableFilterComposer get linkedRemoteAlbumId {
    final $$RemoteAlbumEntityTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.linkedRemoteAlbumId,
            referencedTable: $state.db.remoteAlbumEntity,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder, parentComposers) =>
                $$RemoteAlbumEntityTableFilterComposer(ComposerState(
                    $state.db,
                    $state.db.remoteAlbumEntity,
                    joinBuilder,
                    parentComposers)));
    return composer;
  }

  ComposableFilter localAlbumAssetEntityRefs(
      ComposableFilter Function($$LocalAlbumAssetEntityTableFilterComposer f)
          f) {
    final $$LocalAlbumAssetEntityTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $state.db.localAlbumAssetEntity,
            getReferencedColumn: (t) => t.albumId,
            builder: (joinBuilder, parentComposers) =>
                $$LocalAlbumAssetEntityTableFilterComposer(ComposerState(
                    $state.db,
                    $state.db.localAlbumAssetEntity,
                    joinBuilder,
                    parentComposers)));
    return f(composer);
  }
}

class $$LocalAlbumEntityTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $LocalAlbumEntityTable> {
  $$LocalAlbumEntityTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get backupSelection => $state.composableBuilder(
      column: $state.table.backupSelection,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isIosSharedAlbum => $state.composableBuilder(
      column: $state.table.isIosSharedAlbum,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isEncrypted => $state.composableBuilder(
      column: $state.table.isEncrypted,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get albumType => $state.composableBuilder(
      column: $state.table.albumType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$RemoteAlbumEntityTableOrderingComposer get linkedRemoteAlbumId {
    final $$RemoteAlbumEntityTableOrderingComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.linkedRemoteAlbumId,
            referencedTable: $state.db.remoteAlbumEntity,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder, parentComposers) =>
                $$RemoteAlbumEntityTableOrderingComposer(ComposerState(
                    $state.db,
                    $state.db.remoteAlbumEntity,
                    joinBuilder,
                    parentComposers)));
    return composer;
  }
}

typedef $$AlbumAssetEntityTableCreateCompanionBuilder
    = AlbumAssetEntityCompanion Function({
  required String assetId,
  required String albumId,
});
typedef $$AlbumAssetEntityTableUpdateCompanionBuilder
    = AlbumAssetEntityCompanion Function({
  Value<String> assetId,
  Value<String> albumId,
});

class $$AlbumAssetEntityTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AlbumAssetEntityTable,
    AlbumAssetEntityData,
    $$AlbumAssetEntityTableFilterComposer,
    $$AlbumAssetEntityTableOrderingComposer,
    $$AlbumAssetEntityTableCreateCompanionBuilder,
    $$AlbumAssetEntityTableUpdateCompanionBuilder> {
  $$AlbumAssetEntityTableTableManager(
      _$AppDatabase db, $AlbumAssetEntityTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$AlbumAssetEntityTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$AlbumAssetEntityTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> assetId = const Value.absent(),
            Value<String> albumId = const Value.absent(),
          }) =>
              AlbumAssetEntityCompanion(
            assetId: assetId,
            albumId: albumId,
          ),
          createCompanionCallback: ({
            required String assetId,
            required String albumId,
          }) =>
              AlbumAssetEntityCompanion.insert(
            assetId: assetId,
            albumId: albumId,
          ),
        ));
}

class $$AlbumAssetEntityTableFilterComposer
    extends FilterComposer<_$AppDatabase, $AlbumAssetEntityTable> {
  $$AlbumAssetEntityTableFilterComposer(super.$state);
  $$RemoteAssetEntityTableFilterComposer get assetId {
    final $$RemoteAssetEntityTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.assetId,
            referencedTable: $state.db.remoteAssetEntity,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder, parentComposers) =>
                $$RemoteAssetEntityTableFilterComposer(ComposerState(
                    $state.db,
                    $state.db.remoteAssetEntity,
                    joinBuilder,
                    parentComposers)));
    return composer;
  }

  $$RemoteAlbumEntityTableFilterComposer get albumId {
    final $$RemoteAlbumEntityTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.albumId,
            referencedTable: $state.db.remoteAlbumEntity,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder, parentComposers) =>
                $$RemoteAlbumEntityTableFilterComposer(ComposerState(
                    $state.db,
                    $state.db.remoteAlbumEntity,
                    joinBuilder,
                    parentComposers)));
    return composer;
  }
}

class $$AlbumAssetEntityTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $AlbumAssetEntityTable> {
  $$AlbumAssetEntityTableOrderingComposer(super.$state);
  $$RemoteAssetEntityTableOrderingComposer get assetId {
    final $$RemoteAssetEntityTableOrderingComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.assetId,
            referencedTable: $state.db.remoteAssetEntity,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder, parentComposers) =>
                $$RemoteAssetEntityTableOrderingComposer(ComposerState(
                    $state.db,
                    $state.db.remoteAssetEntity,
                    joinBuilder,
                    parentComposers)));
    return composer;
  }

  $$RemoteAlbumEntityTableOrderingComposer get albumId {
    final $$RemoteAlbumEntityTableOrderingComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.albumId,
            referencedTable: $state.db.remoteAlbumEntity,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder, parentComposers) =>
                $$RemoteAlbumEntityTableOrderingComposer(ComposerState(
                    $state.db,
                    $state.db.remoteAlbumEntity,
                    joinBuilder,
                    parentComposers)));
    return composer;
  }
}

typedef $$LocalAlbumAssetEntityTableCreateCompanionBuilder
    = LocalAlbumAssetEntityCompanion Function({
  required String assetId,
  required String albumId,
});
typedef $$LocalAlbumAssetEntityTableUpdateCompanionBuilder
    = LocalAlbumAssetEntityCompanion Function({
  Value<String> assetId,
  Value<String> albumId,
});

class $$LocalAlbumAssetEntityTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalAlbumAssetEntityTable,
    LocalAlbumAssetEntityData,
    $$LocalAlbumAssetEntityTableFilterComposer,
    $$LocalAlbumAssetEntityTableOrderingComposer,
    $$LocalAlbumAssetEntityTableCreateCompanionBuilder,
    $$LocalAlbumAssetEntityTableUpdateCompanionBuilder> {
  $$LocalAlbumAssetEntityTableTableManager(
      _$AppDatabase db, $LocalAlbumAssetEntityTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer: $$LocalAlbumAssetEntityTableFilterComposer(
              ComposerState(db, table)),
          orderingComposer: $$LocalAlbumAssetEntityTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> assetId = const Value.absent(),
            Value<String> albumId = const Value.absent(),
          }) =>
              LocalAlbumAssetEntityCompanion(
            assetId: assetId,
            albumId: albumId,
          ),
          createCompanionCallback: ({
            required String assetId,
            required String albumId,
          }) =>
              LocalAlbumAssetEntityCompanion.insert(
            assetId: assetId,
            albumId: albumId,
          ),
        ));
}

class $$LocalAlbumAssetEntityTableFilterComposer
    extends FilterComposer<_$AppDatabase, $LocalAlbumAssetEntityTable> {
  $$LocalAlbumAssetEntityTableFilterComposer(super.$state);
  $$LocalAssetEntityTableFilterComposer get assetId {
    final $$LocalAssetEntityTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.assetId,
            referencedTable: $state.db.localAssetEntity,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder, parentComposers) =>
                $$LocalAssetEntityTableFilterComposer(ComposerState($state.db,
                    $state.db.localAssetEntity, joinBuilder, parentComposers)));
    return composer;
  }

  $$LocalAlbumEntityTableFilterComposer get albumId {
    final $$LocalAlbumEntityTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.albumId,
            referencedTable: $state.db.localAlbumEntity,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder, parentComposers) =>
                $$LocalAlbumEntityTableFilterComposer(ComposerState($state.db,
                    $state.db.localAlbumEntity, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$LocalAlbumAssetEntityTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $LocalAlbumAssetEntityTable> {
  $$LocalAlbumAssetEntityTableOrderingComposer(super.$state);
  $$LocalAssetEntityTableOrderingComposer get assetId {
    final $$LocalAssetEntityTableOrderingComposer composer = $state
        .composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.assetId,
            referencedTable: $state.db.localAssetEntity,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder, parentComposers) =>
                $$LocalAssetEntityTableOrderingComposer(ComposerState($state.db,
                    $state.db.localAssetEntity, joinBuilder, parentComposers)));
    return composer;
  }

  $$LocalAlbumEntityTableOrderingComposer get albumId {
    final $$LocalAlbumEntityTableOrderingComposer composer = $state
        .composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.albumId,
            referencedTable: $state.db.localAlbumEntity,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder, parentComposers) =>
                $$LocalAlbumEntityTableOrderingComposer(ComposerState($state.db,
                    $state.db.localAlbumEntity, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$AlbumSessionEntityTableCreateCompanionBuilder
    = AlbumSessionEntityCompanion Function({
  required String id,
  required String albumId,
  required String sessionToken,
  required DateTime expiresAt,
});
typedef $$AlbumSessionEntityTableUpdateCompanionBuilder
    = AlbumSessionEntityCompanion Function({
  Value<String> id,
  Value<String> albumId,
  Value<String> sessionToken,
  Value<DateTime> expiresAt,
});

class $$AlbumSessionEntityTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AlbumSessionEntityTable,
    AlbumSessionEntityData,
    $$AlbumSessionEntityTableFilterComposer,
    $$AlbumSessionEntityTableOrderingComposer,
    $$AlbumSessionEntityTableCreateCompanionBuilder,
    $$AlbumSessionEntityTableUpdateCompanionBuilder> {
  $$AlbumSessionEntityTableTableManager(
      _$AppDatabase db, $AlbumSessionEntityTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$AlbumSessionEntityTableFilterComposer(ComposerState(db, table)),
          orderingComposer: $$AlbumSessionEntityTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> albumId = const Value.absent(),
            Value<String> sessionToken = const Value.absent(),
            Value<DateTime> expiresAt = const Value.absent(),
          }) =>
              AlbumSessionEntityCompanion(
            id: id,
            albumId: albumId,
            sessionToken: sessionToken,
            expiresAt: expiresAt,
          ),
          createCompanionCallback: ({
            required String id,
            required String albumId,
            required String sessionToken,
            required DateTime expiresAt,
          }) =>
              AlbumSessionEntityCompanion.insert(
            id: id,
            albumId: albumId,
            sessionToken: sessionToken,
            expiresAt: expiresAt,
          ),
        ));
}

class $$AlbumSessionEntityTableFilterComposer
    extends FilterComposer<_$AppDatabase, $AlbumSessionEntityTable> {
  $$AlbumSessionEntityTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get sessionToken => $state.composableBuilder(
      column: $state.table.sessionToken,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get expiresAt => $state.composableBuilder(
      column: $state.table.expiresAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$RemoteAlbumEntityTableFilterComposer get albumId {
    final $$RemoteAlbumEntityTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.albumId,
            referencedTable: $state.db.remoteAlbumEntity,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder, parentComposers) =>
                $$RemoteAlbumEntityTableFilterComposer(ComposerState(
                    $state.db,
                    $state.db.remoteAlbumEntity,
                    joinBuilder,
                    parentComposers)));
    return composer;
  }
}

class $$AlbumSessionEntityTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $AlbumSessionEntityTable> {
  $$AlbumSessionEntityTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get sessionToken => $state.composableBuilder(
      column: $state.table.sessionToken,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get expiresAt => $state.composableBuilder(
      column: $state.table.expiresAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$RemoteAlbumEntityTableOrderingComposer get albumId {
    final $$RemoteAlbumEntityTableOrderingComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.albumId,
            referencedTable: $state.db.remoteAlbumEntity,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder, parentComposers) =>
                $$RemoteAlbumEntityTableOrderingComposer(ComposerState(
                    $state.db,
                    $state.db.remoteAlbumEntity,
                    joinBuilder,
                    parentComposers)));
    return composer;
  }
}

typedef $$RetryTaskEntityTableCreateCompanionBuilder = RetryTaskEntityCompanion
    Function({
  required String id,
  required int taskType,
  required String albumId,
  required String assetIds,
  Value<String?> extraData,
  Value<int> retryCount,
  Value<DateTime?> lastRetryAt,
});
typedef $$RetryTaskEntityTableUpdateCompanionBuilder = RetryTaskEntityCompanion
    Function({
  Value<String> id,
  Value<int> taskType,
  Value<String> albumId,
  Value<String> assetIds,
  Value<String?> extraData,
  Value<int> retryCount,
  Value<DateTime?> lastRetryAt,
});

class $$RetryTaskEntityTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RetryTaskEntityTable,
    RetryTaskEntityData,
    $$RetryTaskEntityTableFilterComposer,
    $$RetryTaskEntityTableOrderingComposer,
    $$RetryTaskEntityTableCreateCompanionBuilder,
    $$RetryTaskEntityTableUpdateCompanionBuilder> {
  $$RetryTaskEntityTableTableManager(
      _$AppDatabase db, $RetryTaskEntityTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$RetryTaskEntityTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$RetryTaskEntityTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<int> taskType = const Value.absent(),
            Value<String> albumId = const Value.absent(),
            Value<String> assetIds = const Value.absent(),
            Value<String?> extraData = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<DateTime?> lastRetryAt = const Value.absent(),
          }) =>
              RetryTaskEntityCompanion(
            id: id,
            taskType: taskType,
            albumId: albumId,
            assetIds: assetIds,
            extraData: extraData,
            retryCount: retryCount,
            lastRetryAt: lastRetryAt,
          ),
          createCompanionCallback: ({
            required String id,
            required int taskType,
            required String albumId,
            required String assetIds,
            Value<String?> extraData = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<DateTime?> lastRetryAt = const Value.absent(),
          }) =>
              RetryTaskEntityCompanion.insert(
            id: id,
            taskType: taskType,
            albumId: albumId,
            assetIds: assetIds,
            extraData: extraData,
            retryCount: retryCount,
            lastRetryAt: lastRetryAt,
          ),
        ));
}

class $$RetryTaskEntityTableFilterComposer
    extends FilterComposer<_$AppDatabase, $RetryTaskEntityTable> {
  $$RetryTaskEntityTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get taskType => $state.composableBuilder(
      column: $state.table.taskType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get albumId => $state.composableBuilder(
      column: $state.table.albumId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get assetIds => $state.composableBuilder(
      column: $state.table.assetIds,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get extraData => $state.composableBuilder(
      column: $state.table.extraData,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get retryCount => $state.composableBuilder(
      column: $state.table.retryCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get lastRetryAt => $state.composableBuilder(
      column: $state.table.lastRetryAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$RetryTaskEntityTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $RetryTaskEntityTable> {
  $$RetryTaskEntityTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get taskType => $state.composableBuilder(
      column: $state.table.taskType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get albumId => $state.composableBuilder(
      column: $state.table.albumId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get assetIds => $state.composableBuilder(
      column: $state.table.assetIds,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get extraData => $state.composableBuilder(
      column: $state.table.extraData,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get retryCount => $state.composableBuilder(
      column: $state.table.retryCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get lastRetryAt => $state.composableBuilder(
      column: $state.table.lastRetryAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$StoreEntityTableCreateCompanionBuilder = StoreEntityCompanion
    Function({
  Value<int> key,
  Value<String?> value,
});
typedef $$StoreEntityTableUpdateCompanionBuilder = StoreEntityCompanion
    Function({
  Value<int> key,
  Value<String?> value,
});

class $$StoreEntityTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StoreEntityTable,
    StoreEntityData,
    $$StoreEntityTableFilterComposer,
    $$StoreEntityTableOrderingComposer,
    $$StoreEntityTableCreateCompanionBuilder,
    $$StoreEntityTableUpdateCompanionBuilder> {
  $$StoreEntityTableTableManager(_$AppDatabase db, $StoreEntityTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$StoreEntityTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$StoreEntityTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> key = const Value.absent(),
            Value<String?> value = const Value.absent(),
          }) =>
              StoreEntityCompanion(
            key: key,
            value: value,
          ),
          createCompanionCallback: ({
            Value<int> key = const Value.absent(),
            Value<String?> value = const Value.absent(),
          }) =>
              StoreEntityCompanion.insert(
            key: key,
            value: value,
          ),
        ));
}

class $$StoreEntityTableFilterComposer
    extends FilterComposer<_$AppDatabase, $StoreEntityTable> {
  $$StoreEntityTableFilterComposer(super.$state);
  ColumnFilters<int> get key => $state.composableBuilder(
      column: $state.table.key,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get value => $state.composableBuilder(
      column: $state.table.value,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$StoreEntityTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $StoreEntityTable> {
  $$StoreEntityTableOrderingComposer(super.$state);
  ColumnOrderings<int> get key => $state.composableBuilder(
      column: $state.table.key,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get value => $state.composableBuilder(
      column: $state.table.value,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$BackupStatusEntityTableCreateCompanionBuilder
    = BackupStatusEntityCompanion Function({
  required String userId,
  Value<DateTime?> lastBackupTime,
  Value<bool> enabled,
  Value<AutoBackupMode> autoBackupMode,
  Value<DateTime?> timeRangeStart,
  Value<DateTime?> timeRangeEnd,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$BackupStatusEntityTableUpdateCompanionBuilder
    = BackupStatusEntityCompanion Function({
  Value<String> userId,
  Value<DateTime?> lastBackupTime,
  Value<bool> enabled,
  Value<AutoBackupMode> autoBackupMode,
  Value<DateTime?> timeRangeStart,
  Value<DateTime?> timeRangeEnd,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$BackupStatusEntityTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BackupStatusEntityTable,
    BackupStatusEntityData,
    $$BackupStatusEntityTableFilterComposer,
    $$BackupStatusEntityTableOrderingComposer,
    $$BackupStatusEntityTableCreateCompanionBuilder,
    $$BackupStatusEntityTableUpdateCompanionBuilder> {
  $$BackupStatusEntityTableTableManager(
      _$AppDatabase db, $BackupStatusEntityTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$BackupStatusEntityTableFilterComposer(ComposerState(db, table)),
          orderingComposer: $$BackupStatusEntityTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> userId = const Value.absent(),
            Value<DateTime?> lastBackupTime = const Value.absent(),
            Value<bool> enabled = const Value.absent(),
            Value<AutoBackupMode> autoBackupMode = const Value.absent(),
            Value<DateTime?> timeRangeStart = const Value.absent(),
            Value<DateTime?> timeRangeEnd = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              BackupStatusEntityCompanion(
            userId: userId,
            lastBackupTime: lastBackupTime,
            enabled: enabled,
            autoBackupMode: autoBackupMode,
            timeRangeStart: timeRangeStart,
            timeRangeEnd: timeRangeEnd,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            required String userId,
            Value<DateTime?> lastBackupTime = const Value.absent(),
            Value<bool> enabled = const Value.absent(),
            Value<AutoBackupMode> autoBackupMode = const Value.absent(),
            Value<DateTime?> timeRangeStart = const Value.absent(),
            Value<DateTime?> timeRangeEnd = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
          }) =>
              BackupStatusEntityCompanion.insert(
            userId: userId,
            lastBackupTime: lastBackupTime,
            enabled: enabled,
            autoBackupMode: autoBackupMode,
            timeRangeStart: timeRangeStart,
            timeRangeEnd: timeRangeEnd,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
        ));
}

class $$BackupStatusEntityTableFilterComposer
    extends FilterComposer<_$AppDatabase, $BackupStatusEntityTable> {
  $$BackupStatusEntityTableFilterComposer(super.$state);
  ColumnFilters<DateTime> get lastBackupTime => $state.composableBuilder(
      column: $state.table.lastBackupTime,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get enabled => $state.composableBuilder(
      column: $state.table.enabled,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<AutoBackupMode, AutoBackupMode, int>
      get autoBackupMode => $state.composableBuilder(
          column: $state.table.autoBackupMode,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get timeRangeStart => $state.composableBuilder(
      column: $state.table.timeRangeStart,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get timeRangeEnd => $state.composableBuilder(
      column: $state.table.timeRangeEnd,
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

  $$UserEntityTableFilterComposer get userId {
    final $$UserEntityTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $state.db.userEntity,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$UserEntityTableFilterComposer(ComposerState($state.db,
                $state.db.userEntity, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$BackupStatusEntityTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $BackupStatusEntityTable> {
  $$BackupStatusEntityTableOrderingComposer(super.$state);
  ColumnOrderings<DateTime> get lastBackupTime => $state.composableBuilder(
      column: $state.table.lastBackupTime,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get enabled => $state.composableBuilder(
      column: $state.table.enabled,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get autoBackupMode => $state.composableBuilder(
      column: $state.table.autoBackupMode,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get timeRangeStart => $state.composableBuilder(
      column: $state.table.timeRangeStart,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get timeRangeEnd => $state.composableBuilder(
      column: $state.table.timeRangeEnd,
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

  $$UserEntityTableOrderingComposer get userId {
    final $$UserEntityTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $state.db.userEntity,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$UserEntityTableOrderingComposer(ComposerState($state.db,
                $state.db.userEntity, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$UploadTaskEntityTableCreateCompanionBuilder
    = UploadTaskEntityCompanion Function({
  required String id,
  required String userId,
  required String assetId,
  required String localPath,
  required String remotePath,
  required int fileSize,
  required UploadTaskType taskType,
  Value<int> priority,
  Value<UploadTaskStatus> status,
  Value<int> retryCount,
  Value<int> maxRetries,
  Value<String?> errorMessage,
  Value<DateTime?> uploadedAt,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> progress,
});
typedef $$UploadTaskEntityTableUpdateCompanionBuilder
    = UploadTaskEntityCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> assetId,
  Value<String> localPath,
  Value<String> remotePath,
  Value<int> fileSize,
  Value<UploadTaskType> taskType,
  Value<int> priority,
  Value<UploadTaskStatus> status,
  Value<int> retryCount,
  Value<int> maxRetries,
  Value<String?> errorMessage,
  Value<DateTime?> uploadedAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> progress,
});

class $$UploadTaskEntityTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UploadTaskEntityTable,
    UploadTaskEntityData,
    $$UploadTaskEntityTableFilterComposer,
    $$UploadTaskEntityTableOrderingComposer,
    $$UploadTaskEntityTableCreateCompanionBuilder,
    $$UploadTaskEntityTableUpdateCompanionBuilder> {
  $$UploadTaskEntityTableTableManager(
      _$AppDatabase db, $UploadTaskEntityTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$UploadTaskEntityTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$UploadTaskEntityTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> assetId = const Value.absent(),
            Value<String> localPath = const Value.absent(),
            Value<String> remotePath = const Value.absent(),
            Value<int> fileSize = const Value.absent(),
            Value<UploadTaskType> taskType = const Value.absent(),
            Value<int> priority = const Value.absent(),
            Value<UploadTaskStatus> status = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<int> maxRetries = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<DateTime?> uploadedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> progress = const Value.absent(),
          }) =>
              UploadTaskEntityCompanion(
            id: id,
            userId: userId,
            assetId: assetId,
            localPath: localPath,
            remotePath: remotePath,
            fileSize: fileSize,
            taskType: taskType,
            priority: priority,
            status: status,
            retryCount: retryCount,
            maxRetries: maxRetries,
            errorMessage: errorMessage,
            uploadedAt: uploadedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            progress: progress,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String assetId,
            required String localPath,
            required String remotePath,
            required int fileSize,
            required UploadTaskType taskType,
            Value<int> priority = const Value.absent(),
            Value<UploadTaskStatus> status = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<int> maxRetries = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<DateTime?> uploadedAt = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> progress = const Value.absent(),
          }) =>
              UploadTaskEntityCompanion.insert(
            id: id,
            userId: userId,
            assetId: assetId,
            localPath: localPath,
            remotePath: remotePath,
            fileSize: fileSize,
            taskType: taskType,
            priority: priority,
            status: status,
            retryCount: retryCount,
            maxRetries: maxRetries,
            errorMessage: errorMessage,
            uploadedAt: uploadedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            progress: progress,
          ),
        ));
}

class $$UploadTaskEntityTableFilterComposer
    extends FilterComposer<_$AppDatabase, $UploadTaskEntityTable> {
  $$UploadTaskEntityTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get assetId => $state.composableBuilder(
      column: $state.table.assetId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get localPath => $state.composableBuilder(
      column: $state.table.localPath,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get remotePath => $state.composableBuilder(
      column: $state.table.remotePath,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get fileSize => $state.composableBuilder(
      column: $state.table.fileSize,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<UploadTaskType, UploadTaskType, int>
      get taskType => $state.composableBuilder(
          column: $state.table.taskType,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnFilters<int> get priority => $state.composableBuilder(
      column: $state.table.priority,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<UploadTaskStatus, UploadTaskStatus, int>
      get status => $state.composableBuilder(
          column: $state.table.status,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnFilters<int> get retryCount => $state.composableBuilder(
      column: $state.table.retryCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get maxRetries => $state.composableBuilder(
      column: $state.table.maxRetries,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get errorMessage => $state.composableBuilder(
      column: $state.table.errorMessage,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get uploadedAt => $state.composableBuilder(
      column: $state.table.uploadedAt,
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

  ColumnFilters<int> get progress => $state.composableBuilder(
      column: $state.table.progress,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$UserEntityTableFilterComposer get userId {
    final $$UserEntityTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $state.db.userEntity,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$UserEntityTableFilterComposer(ComposerState($state.db,
                $state.db.userEntity, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$UploadTaskEntityTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $UploadTaskEntityTable> {
  $$UploadTaskEntityTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get assetId => $state.composableBuilder(
      column: $state.table.assetId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get localPath => $state.composableBuilder(
      column: $state.table.localPath,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get remotePath => $state.composableBuilder(
      column: $state.table.remotePath,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get fileSize => $state.composableBuilder(
      column: $state.table.fileSize,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get taskType => $state.composableBuilder(
      column: $state.table.taskType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get priority => $state.composableBuilder(
      column: $state.table.priority,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get retryCount => $state.composableBuilder(
      column: $state.table.retryCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get maxRetries => $state.composableBuilder(
      column: $state.table.maxRetries,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get errorMessage => $state.composableBuilder(
      column: $state.table.errorMessage,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get uploadedAt => $state.composableBuilder(
      column: $state.table.uploadedAt,
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

  ColumnOrderings<int> get progress => $state.composableBuilder(
      column: $state.table.progress,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$UserEntityTableOrderingComposer get userId {
    final $$UserEntityTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $state.db.userEntity,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$UserEntityTableOrderingComposer(ComposerState($state.db,
                $state.db.userEntity, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$SyncCheckpointEntityTableCreateCompanionBuilder
    = SyncCheckpointEntityCompanion Function({
  required String userId,
  required String syncType,
  required String ack,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> lastSyncTime,
});
typedef $$SyncCheckpointEntityTableUpdateCompanionBuilder
    = SyncCheckpointEntityCompanion Function({
  Value<String> userId,
  Value<String> syncType,
  Value<String> ack,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> lastSyncTime,
});

class $$SyncCheckpointEntityTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncCheckpointEntityTable,
    SyncCheckpointEntityData,
    $$SyncCheckpointEntityTableFilterComposer,
    $$SyncCheckpointEntityTableOrderingComposer,
    $$SyncCheckpointEntityTableCreateCompanionBuilder,
    $$SyncCheckpointEntityTableUpdateCompanionBuilder> {
  $$SyncCheckpointEntityTableTableManager(
      _$AppDatabase db, $SyncCheckpointEntityTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer: $$SyncCheckpointEntityTableFilterComposer(
              ComposerState(db, table)),
          orderingComposer: $$SyncCheckpointEntityTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> userId = const Value.absent(),
            Value<String> syncType = const Value.absent(),
            Value<String> ack = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> lastSyncTime = const Value.absent(),
          }) =>
              SyncCheckpointEntityCompanion(
            userId: userId,
            syncType: syncType,
            ack: ack,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastSyncTime: lastSyncTime,
          ),
          createCompanionCallback: ({
            required String userId,
            required String syncType,
            required String ack,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> lastSyncTime = const Value.absent(),
          }) =>
              SyncCheckpointEntityCompanion.insert(
            userId: userId,
            syncType: syncType,
            ack: ack,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastSyncTime: lastSyncTime,
          ),
        ));
}

class $$SyncCheckpointEntityTableFilterComposer
    extends FilterComposer<_$AppDatabase, $SyncCheckpointEntityTable> {
  $$SyncCheckpointEntityTableFilterComposer(super.$state);
  ColumnFilters<String> get syncType => $state.composableBuilder(
      column: $state.table.syncType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get ack => $state.composableBuilder(
      column: $state.table.ack,
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

  ColumnFilters<DateTime> get lastSyncTime => $state.composableBuilder(
      column: $state.table.lastSyncTime,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$UserEntityTableFilterComposer get userId {
    final $$UserEntityTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $state.db.userEntity,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$UserEntityTableFilterComposer(ComposerState($state.db,
                $state.db.userEntity, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$SyncCheckpointEntityTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $SyncCheckpointEntityTable> {
  $$SyncCheckpointEntityTableOrderingComposer(super.$state);
  ColumnOrderings<String> get syncType => $state.composableBuilder(
      column: $state.table.syncType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get ack => $state.composableBuilder(
      column: $state.table.ack,
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

  ColumnOrderings<DateTime> get lastSyncTime => $state.composableBuilder(
      column: $state.table.lastSyncTime,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$UserEntityTableOrderingComposer get userId {
    final $$UserEntityTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $state.db.userEntity,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$UserEntityTableOrderingComposer(ComposerState($state.db,
                $state.db.userEntity, joinBuilder, parentComposers)));
    return composer;
  }
}

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UserEntityTableTableManager get userEntity =>
      $$UserEntityTableTableManager(_db, _db.userEntity);
  $$LocalAssetEntityTableTableManager get localAssetEntity =>
      $$LocalAssetEntityTableTableManager(_db, _db.localAssetEntity);
  $$RemoteAssetEntityTableTableManager get remoteAssetEntity =>
      $$RemoteAssetEntityTableTableManager(_db, _db.remoteAssetEntity);
  $$RemoteAlbumEntityTableTableManager get remoteAlbumEntity =>
      $$RemoteAlbumEntityTableTableManager(_db, _db.remoteAlbumEntity);
  $$LocalAlbumEntityTableTableManager get localAlbumEntity =>
      $$LocalAlbumEntityTableTableManager(_db, _db.localAlbumEntity);
  $$AlbumAssetEntityTableTableManager get albumAssetEntity =>
      $$AlbumAssetEntityTableTableManager(_db, _db.albumAssetEntity);
  $$LocalAlbumAssetEntityTableTableManager get localAlbumAssetEntity =>
      $$LocalAlbumAssetEntityTableTableManager(_db, _db.localAlbumAssetEntity);
  $$AlbumSessionEntityTableTableManager get albumSessionEntity =>
      $$AlbumSessionEntityTableTableManager(_db, _db.albumSessionEntity);
  $$RetryTaskEntityTableTableManager get retryTaskEntity =>
      $$RetryTaskEntityTableTableManager(_db, _db.retryTaskEntity);
  $$StoreEntityTableTableManager get storeEntity =>
      $$StoreEntityTableTableManager(_db, _db.storeEntity);
  $$BackupStatusEntityTableTableManager get backupStatusEntity =>
      $$BackupStatusEntityTableTableManager(_db, _db.backupStatusEntity);
  $$UploadTaskEntityTableTableManager get uploadTaskEntity =>
      $$UploadTaskEntityTableTableManager(_db, _db.uploadTaskEntity);
  $$SyncCheckpointEntityTableTableManager get syncCheckpointEntity =>
      $$SyncCheckpointEntityTableTableManager(_db, _db.syncCheckpointEntity);
}
