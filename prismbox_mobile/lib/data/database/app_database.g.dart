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
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarUrlMeta = const VerificationMeta(
    'avatarUrl',
  );
  @override
  late final GeneratedColumn<String> avatarUrl = GeneratedColumn<String>(
    'avatar_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    email,
    avatarUrl,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_entity';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserEntityData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('avatar_url')) {
      context.handle(
        _avatarUrlMeta,
        avatarUrl.isAcceptableOrUnknown(data['avatar_url']!, _avatarUrlMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
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
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      avatarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_url'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $UserEntityTable createAlias(String alias) {
    return $UserEntityTable(attachedDatabase, alias);
  }

  @override
  bool get withoutRowId => true;
  @override
  bool get isStrict => true;
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
  const UserEntityData({
    required this.id,
    required this.name,
    this.email,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });
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
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      avatarUrl: avatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarUrl),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserEntityData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
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

  UserEntityData copyWith({
    String? id,
    String? name,
    Value<String?> email = const Value.absent(),
    Value<String?> avatarUrl = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UserEntityData(
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
  }) : id = Value(id),
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

  UserEntityCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? email,
    Value<String?>? avatarUrl,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
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
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AssetType, int> type =
      GeneratedColumn<int>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<AssetType>($LocalAssetEntityTable.$convertertype);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationInSecondsMeta = const VerificationMeta(
    'durationInSeconds',
  );
  @override
  late final GeneratedColumn<int> durationInSeconds = GeneratedColumn<int>(
    'duration_in_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _checksumMeta = const VerificationMeta(
    'checksum',
  );
  @override
  late final GeneratedColumn<String> checksum = GeneratedColumn<String>(
    'checksum',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _orientationMeta = const VerificationMeta(
    'orientation',
  );
  @override
  late final GeneratedColumn<int> orientation = GeneratedColumn<int>(
    'orientation',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
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
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_asset_entity';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalAssetEntityData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    if (data.containsKey('duration_in_seconds')) {
      context.handle(
        _durationInSecondsMeta,
        durationInSeconds.isAcceptableOrUnknown(
          data['duration_in_seconds']!,
          _durationInSecondsMeta,
        ),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('checksum')) {
      context.handle(
        _checksumMeta,
        checksum.isAcceptableOrUnknown(data['checksum']!, _checksumMeta),
      );
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('orientation')) {
      context.handle(
        _orientationMeta,
        orientation.isAcceptableOrUnknown(
          data['orientation']!,
          _orientationMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalAssetEntityData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalAssetEntityData(
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: $LocalAssetEntityTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}type'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      ),
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      ),
      durationInSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_in_seconds'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      checksum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checksum'],
      ),
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      orientation: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}orientation'],
      )!,
    );
  }

  @override
  $LocalAssetEntityTable createAlias(String alias) {
    return $LocalAssetEntityTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AssetType, int, int> $convertertype =
      const EnumIndexConverter<AssetType>(AssetType.values);
  @override
  bool get withoutRowId => true;
  @override
  bool get isStrict => true;
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
  const LocalAssetEntityData({
    required this.name,
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
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    {
      map['type'] = Variable<int>(
        $LocalAssetEntityTable.$convertertype.toSql(type),
      );
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
    return map;
  }

  LocalAssetEntityCompanion toCompanion(bool nullToAbsent) {
    return LocalAssetEntityCompanion(
      name: Value(name),
      type: Value(type),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      width: width == null && nullToAbsent
          ? const Value.absent()
          : Value(width),
      height: height == null && nullToAbsent
          ? const Value.absent()
          : Value(height),
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
    );
  }

  factory LocalAssetEntityData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalAssetEntityData(
      name: serializer.fromJson<String>(json['name']),
      type: $LocalAssetEntityTable.$convertertype.fromJson(
        serializer.fromJson<int>(json['type']),
      ),
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
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<int>(
        $LocalAssetEntityTable.$convertertype.toJson(type),
      ),
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
    };
  }

  LocalAssetEntityData copyWith({
    String? name,
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
  }) => LocalAssetEntityData(
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
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      orientation: data.orientation.present
          ? data.orientation.value
          : this.orientation,
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
          ..write('orientation: $orientation')
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
  );
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
          other.orientation == this.orientation);
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
  }) : name = Value(name),
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
    });
  }

  LocalAssetEntityCompanion copyWith({
    Value<String>? name,
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
  }) {
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
        $LocalAssetEntityTable.$convertertype.toSql(type.value),
      );
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
          ..write('orientation: $orientation')
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
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AssetType, int> type =
      GeneratedColumn<int>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<AssetType>($RemoteAssetEntityTable.$convertertype);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationInSecondsMeta = const VerificationMeta(
    'durationInSeconds',
  );
  @override
  late final GeneratedColumn<int> durationInSeconds = GeneratedColumn<int>(
    'duration_in_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _checksumMeta = const VerificationMeta(
    'checksum',
  );
  @override
  late final GeneratedColumn<String> checksum = GeneratedColumn<String>(
    'checksum',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES user_entity (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _localDateTimeMeta = const VerificationMeta(
    'localDateTime',
  );
  @override
  late final GeneratedColumn<DateTime> localDateTime =
      GeneratedColumn<DateTime>(
        'local_date_time',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _thumbHashMeta = const VerificationMeta(
    'thumbHash',
  );
  @override
  late final GeneratedColumn<String> thumbHash = GeneratedColumn<String>(
    'thumb_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _livePhotoVideoIdMeta = const VerificationMeta(
    'livePhotoVideoId',
  );
  @override
  late final GeneratedColumn<String> livePhotoVideoId = GeneratedColumn<String>(
    'live_photo_video_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AssetVisibility, int> visibility =
      GeneratedColumn<int>(
        'visibility',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(1),
      ).withConverter<AssetVisibility>(
        $RemoteAssetEntityTable.$convertervisibility,
      );
  static const VerificationMeta _stackIdMeta = const VerificationMeta(
    'stackId',
  );
  @override
  late final GeneratedColumn<String> stackId = GeneratedColumn<String>(
    'stack_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _libraryIdMeta = const VerificationMeta(
    'libraryId',
  );
  @override
  late final GeneratedColumn<String> libraryId = GeneratedColumn<String>(
    'library_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
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
    libraryId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'remote_asset_entity';
  @override
  VerificationContext validateIntegrity(
    Insertable<RemoteAssetEntityData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    if (data.containsKey('duration_in_seconds')) {
      context.handle(
        _durationInSecondsMeta,
        durationInSeconds.isAcceptableOrUnknown(
          data['duration_in_seconds']!,
          _durationInSecondsMeta,
        ),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('checksum')) {
      context.handle(
        _checksumMeta,
        checksum.isAcceptableOrUnknown(data['checksum']!, _checksumMeta),
      );
    } else if (isInserting) {
      context.missing(_checksumMeta);
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('local_date_time')) {
      context.handle(
        _localDateTimeMeta,
        localDateTime.isAcceptableOrUnknown(
          data['local_date_time']!,
          _localDateTimeMeta,
        ),
      );
    }
    if (data.containsKey('thumb_hash')) {
      context.handle(
        _thumbHashMeta,
        thumbHash.isAcceptableOrUnknown(data['thumb_hash']!, _thumbHashMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('live_photo_video_id')) {
      context.handle(
        _livePhotoVideoIdMeta,
        livePhotoVideoId.isAcceptableOrUnknown(
          data['live_photo_video_id']!,
          _livePhotoVideoIdMeta,
        ),
      );
    }
    if (data.containsKey('stack_id')) {
      context.handle(
        _stackIdMeta,
        stackId.isAcceptableOrUnknown(data['stack_id']!, _stackIdMeta),
      );
    }
    if (data.containsKey('library_id')) {
      context.handle(
        _libraryIdMeta,
        libraryId.isAcceptableOrUnknown(data['library_id']!, _libraryIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RemoteAssetEntityData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RemoteAssetEntityData(
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: $RemoteAssetEntityTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}type'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      ),
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      ),
      durationInSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_in_seconds'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      checksum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checksum'],
      )!,
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      localDateTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}local_date_time'],
      ),
      thumbHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumb_hash'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      livePhotoVideoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}live_photo_video_id'],
      ),
      visibility: $RemoteAssetEntityTable.$convertervisibility.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}visibility'],
        )!,
      ),
      stackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stack_id'],
      ),
      libraryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}library_id'],
      ),
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
  @override
  bool get isStrict => true;
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
  const RemoteAssetEntityData({
    required this.name,
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
    this.libraryId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    {
      map['type'] = Variable<int>(
        $RemoteAssetEntityTable.$convertertype.toSql(type),
      );
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
        $RemoteAssetEntityTable.$convertervisibility.toSql(visibility),
      );
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
      width: width == null && nullToAbsent
          ? const Value.absent()
          : Value(width),
      height: height == null && nullToAbsent
          ? const Value.absent()
          : Value(height),
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

  factory RemoteAssetEntityData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RemoteAssetEntityData(
      name: serializer.fromJson<String>(json['name']),
      type: $RemoteAssetEntityTable.$convertertype.fromJson(
        serializer.fromJson<int>(json['type']),
      ),
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
      visibility: $RemoteAssetEntityTable.$convertervisibility.fromJson(
        serializer.fromJson<int>(json['visibility']),
      ),
      stackId: serializer.fromJson<String?>(json['stackId']),
      libraryId: serializer.fromJson<String?>(json['libraryId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<int>(
        $RemoteAssetEntityTable.$convertertype.toJson(type),
      ),
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
        $RemoteAssetEntityTable.$convertervisibility.toJson(visibility),
      ),
      'stackId': serializer.toJson<String?>(stackId),
      'libraryId': serializer.toJson<String?>(libraryId),
    };
  }

  RemoteAssetEntityData copyWith({
    String? name,
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
    Value<String?> libraryId = const Value.absent(),
  }) => RemoteAssetEntityData(
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
    localDateTime: localDateTime.present
        ? localDateTime.value
        : this.localDateTime,
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
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      localDateTime: data.localDateTime.present
          ? data.localDateTime.value
          : this.localDateTime,
      thumbHash: data.thumbHash.present ? data.thumbHash.value : this.thumbHash,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      livePhotoVideoId: data.livePhotoVideoId.present
          ? data.livePhotoVideoId.value
          : this.livePhotoVideoId,
      visibility: data.visibility.present
          ? data.visibility.value
          : this.visibility,
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
    libraryId,
  );
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
  }) : name = Value(name),
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

  RemoteAssetEntityCompanion copyWith({
    Value<String>? name,
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
    Value<String?>? libraryId,
  }) {
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
        $RemoteAssetEntityTable.$convertertype.toSql(type.value),
      );
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
        $RemoteAssetEntityTable.$convertervisibility.toSql(visibility.value),
      );
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
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES user_entity (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _thumbnailAssetIdMeta = const VerificationMeta(
    'thumbnailAssetId',
  );
  @override
  late final GeneratedColumn<String> thumbnailAssetId = GeneratedColumn<String>(
    'thumbnail_asset_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES remote_asset_entity (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _isActivityEnabledMeta = const VerificationMeta(
    'isActivityEnabled',
  );
  @override
  late final GeneratedColumn<bool> isActivityEnabled = GeneratedColumn<bool>(
    'is_activity_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_activity_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<AlbumOrder, int> order =
      GeneratedColumn<int>(
        'order',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(1),
      ).withConverter<AlbumOrder>($RemoteAlbumEntityTable.$converterorder);
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
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'remote_album_entity';
  @override
  VerificationContext validateIntegrity(
    Insertable<RemoteAlbumEntityData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('thumbnail_asset_id')) {
      context.handle(
        _thumbnailAssetIdMeta,
        thumbnailAssetId.isAcceptableOrUnknown(
          data['thumbnail_asset_id']!,
          _thumbnailAssetIdMeta,
        ),
      );
    }
    if (data.containsKey('is_activity_enabled')) {
      context.handle(
        _isActivityEnabledMeta,
        isActivityEnabled.isAcceptableOrUnknown(
          data['is_activity_enabled']!,
          _isActivityEnabledMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RemoteAlbumEntityData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RemoteAlbumEntityData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      thumbnailAssetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_asset_id'],
      ),
      isActivityEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_activity_enabled'],
      )!,
      order: $RemoteAlbumEntityTable.$converterorder.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}order'],
        )!,
      ),
    );
  }

  @override
  $RemoteAlbumEntityTable createAlias(String alias) {
    return $RemoteAlbumEntityTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AlbumOrder, int, int> $converterorder =
      const EnumIndexConverter<AlbumOrder>(AlbumOrder.values);
  @override
  bool get withoutRowId => true;
  @override
  bool get isStrict => true;
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
  const RemoteAlbumEntityData({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.ownerId,
    this.thumbnailAssetId,
    required this.isActivityEnabled,
    required this.order,
  });
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
      map['order'] = Variable<int>(
        $RemoteAlbumEntityTable.$converterorder.toSql(order),
      );
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
    );
  }

  factory RemoteAlbumEntityData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
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
      order: $RemoteAlbumEntityTable.$converterorder.fromJson(
        serializer.fromJson<int>(json['order']),
      ),
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
      'order': serializer.toJson<int>(
        $RemoteAlbumEntityTable.$converterorder.toJson(order),
      ),
    };
  }

  RemoteAlbumEntityData copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    String? ownerId,
    Value<String?> thumbnailAssetId = const Value.absent(),
    bool? isActivityEnabled,
    AlbumOrder? order,
  }) => RemoteAlbumEntityData(
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
  );
  RemoteAlbumEntityData copyWithCompanion(RemoteAlbumEntityCompanion data) {
    return RemoteAlbumEntityData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
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
          ..write('order: $order')
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
  );
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
          other.order == this.order);
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
  }) : id = Value(id),
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
    });
  }

  RemoteAlbumEntityCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? ownerId,
    Value<String?>? thumbnailAssetId,
    Value<bool>? isActivityEnabled,
    Value<AlbumOrder>? order,
  }) {
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
        $RemoteAlbumEntityTable.$converterorder.toSql(order.value),
      );
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
          ..write('order: $order')
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
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<BackupSelection, int>
  backupSelection =
      GeneratedColumn<int>(
        'backup_selection',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<BackupSelection>(
        $LocalAlbumEntityTable.$converterbackupSelection,
      );
  static const VerificationMeta _isIosSharedAlbumMeta = const VerificationMeta(
    'isIosSharedAlbum',
  );
  @override
  late final GeneratedColumn<bool> isIosSharedAlbum = GeneratedColumn<bool>(
    'is_ios_shared_album',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_ios_shared_album" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _linkedRemoteAlbumIdMeta =
      const VerificationMeta('linkedRemoteAlbumId');
  @override
  late final GeneratedColumn<String> linkedRemoteAlbumId =
      GeneratedColumn<String>(
        'linked_remote_album_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES remote_album_entity (id) ON DELETE SET NULL',
        ),
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    updatedAt,
    backupSelection,
    isIosSharedAlbum,
    linkedRemoteAlbumId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_album_entity';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalAlbumEntityData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_ios_shared_album')) {
      context.handle(
        _isIosSharedAlbumMeta,
        isIosSharedAlbum.isAcceptableOrUnknown(
          data['is_ios_shared_album']!,
          _isIosSharedAlbumMeta,
        ),
      );
    }
    if (data.containsKey('linked_remote_album_id')) {
      context.handle(
        _linkedRemoteAlbumIdMeta,
        linkedRemoteAlbumId.isAcceptableOrUnknown(
          data['linked_remote_album_id']!,
          _linkedRemoteAlbumIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalAlbumEntityData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalAlbumEntityData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      backupSelection: $LocalAlbumEntityTable.$converterbackupSelection.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}backup_selection'],
        )!,
      ),
      isIosSharedAlbum: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_ios_shared_album'],
      )!,
      linkedRemoteAlbumId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_remote_album_id'],
      ),
    );
  }

  @override
  $LocalAlbumEntityTable createAlias(String alias) {
    return $LocalAlbumEntityTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<BackupSelection, int, int>
  $converterbackupSelection = const EnumIndexConverter<BackupSelection>(
    BackupSelection.values,
  );
  @override
  bool get withoutRowId => true;
  @override
  bool get isStrict => true;
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
  const LocalAlbumEntityData({
    required this.id,
    required this.name,
    required this.updatedAt,
    required this.backupSelection,
    required this.isIosSharedAlbum,
    this.linkedRemoteAlbumId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    {
      map['backup_selection'] = Variable<int>(
        $LocalAlbumEntityTable.$converterbackupSelection.toSql(backupSelection),
      );
    }
    map['is_ios_shared_album'] = Variable<bool>(isIosSharedAlbum);
    if (!nullToAbsent || linkedRemoteAlbumId != null) {
      map['linked_remote_album_id'] = Variable<String>(linkedRemoteAlbumId);
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
    );
  }

  factory LocalAlbumEntityData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalAlbumEntityData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      backupSelection: $LocalAlbumEntityTable.$converterbackupSelection
          .fromJson(serializer.fromJson<int>(json['backupSelection'])),
      isIosSharedAlbum: serializer.fromJson<bool>(json['isIosSharedAlbum']),
      linkedRemoteAlbumId: serializer.fromJson<String?>(
        json['linkedRemoteAlbumId'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'backupSelection': serializer.toJson<int>(
        $LocalAlbumEntityTable.$converterbackupSelection.toJson(
          backupSelection,
        ),
      ),
      'isIosSharedAlbum': serializer.toJson<bool>(isIosSharedAlbum),
      'linkedRemoteAlbumId': serializer.toJson<String?>(linkedRemoteAlbumId),
    };
  }

  LocalAlbumEntityData copyWith({
    String? id,
    String? name,
    DateTime? updatedAt,
    BackupSelection? backupSelection,
    bool? isIosSharedAlbum,
    Value<String?> linkedRemoteAlbumId = const Value.absent(),
  }) => LocalAlbumEntityData(
    id: id ?? this.id,
    name: name ?? this.name,
    updatedAt: updatedAt ?? this.updatedAt,
    backupSelection: backupSelection ?? this.backupSelection,
    isIosSharedAlbum: isIosSharedAlbum ?? this.isIosSharedAlbum,
    linkedRemoteAlbumId: linkedRemoteAlbumId.present
        ? linkedRemoteAlbumId.value
        : this.linkedRemoteAlbumId,
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
          ..write('linkedRemoteAlbumId: $linkedRemoteAlbumId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    updatedAt,
    backupSelection,
    isIosSharedAlbum,
    linkedRemoteAlbumId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalAlbumEntityData &&
          other.id == this.id &&
          other.name == this.name &&
          other.updatedAt == this.updatedAt &&
          other.backupSelection == this.backupSelection &&
          other.isIosSharedAlbum == this.isIosSharedAlbum &&
          other.linkedRemoteAlbumId == this.linkedRemoteAlbumId);
}

class LocalAlbumEntityCompanion extends UpdateCompanion<LocalAlbumEntityData> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime> updatedAt;
  final Value<BackupSelection> backupSelection;
  final Value<bool> isIosSharedAlbum;
  final Value<String?> linkedRemoteAlbumId;
  const LocalAlbumEntityCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.backupSelection = const Value.absent(),
    this.isIosSharedAlbum = const Value.absent(),
    this.linkedRemoteAlbumId = const Value.absent(),
  });
  LocalAlbumEntityCompanion.insert({
    required String id,
    required String name,
    required DateTime updatedAt,
    this.backupSelection = const Value.absent(),
    this.isIosSharedAlbum = const Value.absent(),
    this.linkedRemoteAlbumId = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       updatedAt = Value(updatedAt);
  static Insertable<LocalAlbumEntityData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? updatedAt,
    Expression<int>? backupSelection,
    Expression<bool>? isIosSharedAlbum,
    Expression<String>? linkedRemoteAlbumId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (backupSelection != null) 'backup_selection': backupSelection,
      if (isIosSharedAlbum != null) 'is_ios_shared_album': isIosSharedAlbum,
      if (linkedRemoteAlbumId != null)
        'linked_remote_album_id': linkedRemoteAlbumId,
    });
  }

  LocalAlbumEntityCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<DateTime>? updatedAt,
    Value<BackupSelection>? backupSelection,
    Value<bool>? isIosSharedAlbum,
    Value<String?>? linkedRemoteAlbumId,
  }) {
    return LocalAlbumEntityCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      updatedAt: updatedAt ?? this.updatedAt,
      backupSelection: backupSelection ?? this.backupSelection,
      isIosSharedAlbum: isIosSharedAlbum ?? this.isIosSharedAlbum,
      linkedRemoteAlbumId: linkedRemoteAlbumId ?? this.linkedRemoteAlbumId,
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
      map['backup_selection'] = Variable<int>(
        $LocalAlbumEntityTable.$converterbackupSelection.toSql(
          backupSelection.value,
        ),
      );
    }
    if (isIosSharedAlbum.present) {
      map['is_ios_shared_album'] = Variable<bool>(isIosSharedAlbum.value);
    }
    if (linkedRemoteAlbumId.present) {
      map['linked_remote_album_id'] = Variable<String>(
        linkedRemoteAlbumId.value,
      );
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
          ..write('linkedRemoteAlbumId: $linkedRemoteAlbumId')
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
  static const VerificationMeta _assetIdMeta = const VerificationMeta(
    'assetId',
  );
  @override
  late final GeneratedColumn<String> assetId = GeneratedColumn<String>(
    'asset_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES remote_asset_entity (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _albumIdMeta = const VerificationMeta(
    'albumId',
  );
  @override
  late final GeneratedColumn<String> albumId = GeneratedColumn<String>(
    'album_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES remote_album_entity (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [assetId, albumId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'album_asset_entity';
  @override
  VerificationContext validateIntegrity(
    Insertable<AlbumAssetEntityData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('album_id')) {
      context.handle(
        _albumIdMeta,
        albumId.isAcceptableOrUnknown(data['album_id']!, _albumIdMeta),
      );
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
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_id'],
      )!,
      albumId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album_id'],
      )!,
    );
  }

  @override
  $AlbumAssetEntityTable createAlias(String alias) {
    return $AlbumAssetEntityTable(attachedDatabase, alias);
  }

  @override
  bool get withoutRowId => true;
  @override
  bool get isStrict => true;
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

  factory AlbumAssetEntityData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
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
  }) : assetId = Value(assetId),
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

  AlbumAssetEntityCompanion copyWith({
    Value<String>? assetId,
    Value<String>? albumId,
  }) {
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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UserEntityTable userEntity = $UserEntityTable(this);
  late final $LocalAssetEntityTable localAssetEntity = $LocalAssetEntityTable(
    this,
  );
  late final $RemoteAssetEntityTable remoteAssetEntity =
      $RemoteAssetEntityTable(this);
  late final $RemoteAlbumEntityTable remoteAlbumEntity =
      $RemoteAlbumEntityTable(this);
  late final $LocalAlbumEntityTable localAlbumEntity = $LocalAlbumEntityTable(
    this,
  );
  late final $AlbumAssetEntityTable albumAssetEntity = $AlbumAssetEntityTable(
    this,
  );
  late final Index idxLocalAssetChecksum = Index(
    'idx_local_asset_checksum',
    'CREATE INDEX IF NOT EXISTS idx_local_asset_checksum ON local_asset_entity (checksum)',
  );
  late final Index idxRemoteAssetOwnerChecksum = Index(
    'idx_remote_asset_owner_checksum',
    'CREATE INDEX IF NOT EXISTS idx_remote_asset_owner_checksum ON remote_asset_entity (owner_id, checksum)',
  );
  late final Index uQRemoteAssetsOwnerChecksum = Index(
    'UQ_remote_assets_owner_checksum',
    'CREATE UNIQUE INDEX IF NOT EXISTS UQ_remote_assets_owner_checksum ON remote_asset_entity (owner_id, checksum) WHERE(library_id IS NULL)',
  );
  late final Index uQRemoteAssetsOwnerLibraryChecksum = Index(
    'UQ_remote_assets_owner_library_checksum',
    'CREATE UNIQUE INDEX IF NOT EXISTS UQ_remote_assets_owner_library_checksum ON remote_asset_entity (owner_id, library_id, checksum) WHERE(library_id IS NOT NULL)',
  );
  late final Index idxRemoteAssetChecksum = Index(
    'idx_remote_asset_checksum',
    'CREATE INDEX IF NOT EXISTS idx_remote_asset_checksum ON remote_asset_entity (checksum)',
  );
  late final UserDao userDao = UserDao(this as AppDatabase);
  late final LocalAssetDao localAssetDao = LocalAssetDao(this as AppDatabase);
  late final RemoteAssetDao remoteAssetDao = RemoteAssetDao(
    this as AppDatabase,
  );
  late final AlbumDao albumDao = AlbumDao(this as AppDatabase);
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
    idxLocalAssetChecksum,
    idxRemoteAssetOwnerChecksum,
    uQRemoteAssetsOwnerChecksum,
    uQRemoteAssetsOwnerLibraryChecksum,
    idxRemoteAssetChecksum,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'user_entity',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('remote_asset_entity', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'user_entity',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('remote_album_entity', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'remote_asset_entity',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('remote_album_entity', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'remote_album_entity',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('local_album_entity', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'remote_asset_entity',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('album_asset_entity', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'remote_album_entity',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('album_asset_entity', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$UserEntityTableCreateCompanionBuilder =
    UserEntityCompanion Function({
      required String id,
      required String name,
      Value<String?> email,
      Value<String?> avatarUrl,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$UserEntityTableUpdateCompanionBuilder =
    UserEntityCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> email,
      Value<String?> avatarUrl,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$UserEntityTableReferences
    extends BaseReferences<_$AppDatabase, $UserEntityTable, UserEntityData> {
  $$UserEntityTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $RemoteAssetEntityTable,
    List<RemoteAssetEntityData>
  >
  _remoteAssetEntityRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.remoteAssetEntity,
        aliasName: $_aliasNameGenerator(
          db.userEntity.id,
          db.remoteAssetEntity.ownerId,
        ),
      );

  $$RemoteAssetEntityTableProcessedTableManager get remoteAssetEntityRefs {
    final manager = $$RemoteAssetEntityTableTableManager(
      $_db,
      $_db.remoteAssetEntity,
    ).filter((f) => f.ownerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _remoteAssetEntityRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $RemoteAlbumEntityTable,
    List<RemoteAlbumEntityData>
  >
  _remoteAlbumEntityRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.remoteAlbumEntity,
        aliasName: $_aliasNameGenerator(
          db.userEntity.id,
          db.remoteAlbumEntity.ownerId,
        ),
      );

  $$RemoteAlbumEntityTableProcessedTableManager get remoteAlbumEntityRefs {
    final manager = $$RemoteAlbumEntityTableTableManager(
      $_db,
      $_db.remoteAlbumEntity,
    ).filter((f) => f.ownerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _remoteAlbumEntityRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$UserEntityTableFilterComposer
    extends Composer<_$AppDatabase, $UserEntityTable> {
  $$UserEntityTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> remoteAssetEntityRefs(
    Expression<bool> Function($$RemoteAssetEntityTableFilterComposer f) f,
  ) {
    final $$RemoteAssetEntityTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.remoteAssetEntity,
      getReferencedColumn: (t) => t.ownerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemoteAssetEntityTableFilterComposer(
            $db: $db,
            $table: $db.remoteAssetEntity,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> remoteAlbumEntityRefs(
    Expression<bool> Function($$RemoteAlbumEntityTableFilterComposer f) f,
  ) {
    final $$RemoteAlbumEntityTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.remoteAlbumEntity,
      getReferencedColumn: (t) => t.ownerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemoteAlbumEntityTableFilterComposer(
            $db: $db,
            $table: $db.remoteAlbumEntity,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UserEntityTableOrderingComposer
    extends Composer<_$AppDatabase, $UserEntityTable> {
  $$UserEntityTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserEntityTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserEntityTable> {
  $$UserEntityTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get avatarUrl =>
      $composableBuilder(column: $table.avatarUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> remoteAssetEntityRefs<T extends Object>(
    Expression<T> Function($$RemoteAssetEntityTableAnnotationComposer a) f,
  ) {
    final $$RemoteAssetEntityTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.remoteAssetEntity,
          getReferencedColumn: (t) => t.ownerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RemoteAssetEntityTableAnnotationComposer(
                $db: $db,
                $table: $db.remoteAssetEntity,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> remoteAlbumEntityRefs<T extends Object>(
    Expression<T> Function($$RemoteAlbumEntityTableAnnotationComposer a) f,
  ) {
    final $$RemoteAlbumEntityTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.remoteAlbumEntity,
          getReferencedColumn: (t) => t.ownerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RemoteAlbumEntityTableAnnotationComposer(
                $db: $db,
                $table: $db.remoteAlbumEntity,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$UserEntityTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserEntityTable,
          UserEntityData,
          $$UserEntityTableFilterComposer,
          $$UserEntityTableOrderingComposer,
          $$UserEntityTableAnnotationComposer,
          $$UserEntityTableCreateCompanionBuilder,
          $$UserEntityTableUpdateCompanionBuilder,
          (UserEntityData, $$UserEntityTableReferences),
          UserEntityData,
          PrefetchHooks Function({
            bool remoteAssetEntityRefs,
            bool remoteAlbumEntityRefs,
          })
        > {
  $$UserEntityTableTableManager(_$AppDatabase db, $UserEntityTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserEntityTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserEntityTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserEntityTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => UserEntityCompanion(
                id: id,
                name: name,
                email: email,
                avatarUrl: avatarUrl,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> email = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => UserEntityCompanion.insert(
                id: id,
                name: name,
                email: email,
                avatarUrl: avatarUrl,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$UserEntityTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({remoteAssetEntityRefs = false, remoteAlbumEntityRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (remoteAssetEntityRefs) db.remoteAssetEntity,
                    if (remoteAlbumEntityRefs) db.remoteAlbumEntity,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (remoteAssetEntityRefs)
                        await $_getPrefetchedData<
                          UserEntityData,
                          $UserEntityTable,
                          RemoteAssetEntityData
                        >(
                          currentTable: table,
                          referencedTable: $$UserEntityTableReferences
                              ._remoteAssetEntityRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UserEntityTableReferences(
                                db,
                                table,
                                p0,
                              ).remoteAssetEntityRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.ownerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (remoteAlbumEntityRefs)
                        await $_getPrefetchedData<
                          UserEntityData,
                          $UserEntityTable,
                          RemoteAlbumEntityData
                        >(
                          currentTable: table,
                          referencedTable: $$UserEntityTableReferences
                              ._remoteAlbumEntityRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UserEntityTableReferences(
                                db,
                                table,
                                p0,
                              ).remoteAlbumEntityRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.ownerId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$UserEntityTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserEntityTable,
      UserEntityData,
      $$UserEntityTableFilterComposer,
      $$UserEntityTableOrderingComposer,
      $$UserEntityTableAnnotationComposer,
      $$UserEntityTableCreateCompanionBuilder,
      $$UserEntityTableUpdateCompanionBuilder,
      (UserEntityData, $$UserEntityTableReferences),
      UserEntityData,
      PrefetchHooks Function({
        bool remoteAssetEntityRefs,
        bool remoteAlbumEntityRefs,
      })
    >;
typedef $$LocalAssetEntityTableCreateCompanionBuilder =
    LocalAssetEntityCompanion Function({
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
    });
typedef $$LocalAssetEntityTableUpdateCompanionBuilder =
    LocalAssetEntityCompanion Function({
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
    });

class $$LocalAssetEntityTableFilterComposer
    extends Composer<_$AppDatabase, $LocalAssetEntityTable> {
  $$LocalAssetEntityTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AssetType, AssetType, int> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationInSeconds => $composableBuilder(
    column: $table.durationInSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orientation => $composableBuilder(
    column: $table.orientation,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalAssetEntityTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalAssetEntityTable> {
  $$LocalAssetEntityTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationInSeconds => $composableBuilder(
    column: $table.durationInSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orientation => $composableBuilder(
    column: $table.orientation,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalAssetEntityTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalAssetEntityTable> {
  $$LocalAssetEntityTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AssetType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<int> get durationInSeconds => $composableBuilder(
    column: $table.durationInSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get checksum =>
      $composableBuilder(column: $table.checksum, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<int> get orientation => $composableBuilder(
    column: $table.orientation,
    builder: (column) => column,
  );
}

class $$LocalAssetEntityTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalAssetEntityTable,
          LocalAssetEntityData,
          $$LocalAssetEntityTableFilterComposer,
          $$LocalAssetEntityTableOrderingComposer,
          $$LocalAssetEntityTableAnnotationComposer,
          $$LocalAssetEntityTableCreateCompanionBuilder,
          $$LocalAssetEntityTableUpdateCompanionBuilder,
          (
            LocalAssetEntityData,
            BaseReferences<
              _$AppDatabase,
              $LocalAssetEntityTable,
              LocalAssetEntityData
            >,
          ),
          LocalAssetEntityData,
          PrefetchHooks Function()
        > {
  $$LocalAssetEntityTableTableManager(
    _$AppDatabase db,
    $LocalAssetEntityTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalAssetEntityTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalAssetEntityTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalAssetEntityTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
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
              }) => LocalAssetEntityCompanion(
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
              ),
          createCompanionCallback:
              ({
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
              }) => LocalAssetEntityCompanion.insert(
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
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalAssetEntityTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalAssetEntityTable,
      LocalAssetEntityData,
      $$LocalAssetEntityTableFilterComposer,
      $$LocalAssetEntityTableOrderingComposer,
      $$LocalAssetEntityTableAnnotationComposer,
      $$LocalAssetEntityTableCreateCompanionBuilder,
      $$LocalAssetEntityTableUpdateCompanionBuilder,
      (
        LocalAssetEntityData,
        BaseReferences<
          _$AppDatabase,
          $LocalAssetEntityTable,
          LocalAssetEntityData
        >,
      ),
      LocalAssetEntityData,
      PrefetchHooks Function()
    >;
typedef $$RemoteAssetEntityTableCreateCompanionBuilder =
    RemoteAssetEntityCompanion Function({
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
typedef $$RemoteAssetEntityTableUpdateCompanionBuilder =
    RemoteAssetEntityCompanion Function({
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

final class $$RemoteAssetEntityTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $RemoteAssetEntityTable,
          RemoteAssetEntityData
        > {
  $$RemoteAssetEntityTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $UserEntityTable _ownerIdTable(_$AppDatabase db) =>
      db.userEntity.createAlias(
        $_aliasNameGenerator(db.remoteAssetEntity.ownerId, db.userEntity.id),
      );

  $$UserEntityTableProcessedTableManager get ownerId {
    final $_column = $_itemColumn<String>('owner_id')!;

    final manager = $$UserEntityTableTableManager(
      $_db,
      $_db.userEntity,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ownerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $RemoteAlbumEntityTable,
    List<RemoteAlbumEntityData>
  >
  _remoteAlbumEntityRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.remoteAlbumEntity,
        aliasName: $_aliasNameGenerator(
          db.remoteAssetEntity.id,
          db.remoteAlbumEntity.thumbnailAssetId,
        ),
      );

  $$RemoteAlbumEntityTableProcessedTableManager get remoteAlbumEntityRefs {
    final manager =
        $$RemoteAlbumEntityTableTableManager(
          $_db,
          $_db.remoteAlbumEntity,
        ).filter(
          (f) => f.thumbnailAssetId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _remoteAlbumEntityRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AlbumAssetEntityTable, List<AlbumAssetEntityData>>
  _albumAssetEntityRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.albumAssetEntity,
    aliasName: $_aliasNameGenerator(
      db.remoteAssetEntity.id,
      db.albumAssetEntity.assetId,
    ),
  );

  $$AlbumAssetEntityTableProcessedTableManager get albumAssetEntityRefs {
    final manager = $$AlbumAssetEntityTableTableManager(
      $_db,
      $_db.albumAssetEntity,
    ).filter((f) => f.assetId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _albumAssetEntityRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RemoteAssetEntityTableFilterComposer
    extends Composer<_$AppDatabase, $RemoteAssetEntityTable> {
  $$RemoteAssetEntityTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AssetType, AssetType, int> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationInSeconds => $composableBuilder(
    column: $table.durationInSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get localDateTime => $composableBuilder(
    column: $table.localDateTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbHash => $composableBuilder(
    column: $table.thumbHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get livePhotoVideoId => $composableBuilder(
    column: $table.livePhotoVideoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AssetVisibility, AssetVisibility, int>
  get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get stackId => $composableBuilder(
    column: $table.stackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get libraryId => $composableBuilder(
    column: $table.libraryId,
    builder: (column) => ColumnFilters(column),
  );

  $$UserEntityTableFilterComposer get ownerId {
    final $$UserEntityTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerId,
      referencedTable: $db.userEntity,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserEntityTableFilterComposer(
            $db: $db,
            $table: $db.userEntity,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> remoteAlbumEntityRefs(
    Expression<bool> Function($$RemoteAlbumEntityTableFilterComposer f) f,
  ) {
    final $$RemoteAlbumEntityTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.remoteAlbumEntity,
      getReferencedColumn: (t) => t.thumbnailAssetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemoteAlbumEntityTableFilterComposer(
            $db: $db,
            $table: $db.remoteAlbumEntity,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> albumAssetEntityRefs(
    Expression<bool> Function($$AlbumAssetEntityTableFilterComposer f) f,
  ) {
    final $$AlbumAssetEntityTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.albumAssetEntity,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlbumAssetEntityTableFilterComposer(
            $db: $db,
            $table: $db.albumAssetEntity,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RemoteAssetEntityTableOrderingComposer
    extends Composer<_$AppDatabase, $RemoteAssetEntityTable> {
  $$RemoteAssetEntityTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationInSeconds => $composableBuilder(
    column: $table.durationInSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get localDateTime => $composableBuilder(
    column: $table.localDateTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbHash => $composableBuilder(
    column: $table.thumbHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get livePhotoVideoId => $composableBuilder(
    column: $table.livePhotoVideoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stackId => $composableBuilder(
    column: $table.stackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get libraryId => $composableBuilder(
    column: $table.libraryId,
    builder: (column) => ColumnOrderings(column),
  );

  $$UserEntityTableOrderingComposer get ownerId {
    final $$UserEntityTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerId,
      referencedTable: $db.userEntity,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserEntityTableOrderingComposer(
            $db: $db,
            $table: $db.userEntity,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RemoteAssetEntityTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemoteAssetEntityTable> {
  $$RemoteAssetEntityTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AssetType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<int> get durationInSeconds => $composableBuilder(
    column: $table.durationInSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get checksum =>
      $composableBuilder(column: $table.checksum, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get localDateTime => $composableBuilder(
    column: $table.localDateTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thumbHash =>
      $composableBuilder(column: $table.thumbHash, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get livePhotoVideoId => $composableBuilder(
    column: $table.livePhotoVideoId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<AssetVisibility, int> get visibility =>
      $composableBuilder(
        column: $table.visibility,
        builder: (column) => column,
      );

  GeneratedColumn<String> get stackId =>
      $composableBuilder(column: $table.stackId, builder: (column) => column);

  GeneratedColumn<String> get libraryId =>
      $composableBuilder(column: $table.libraryId, builder: (column) => column);

  $$UserEntityTableAnnotationComposer get ownerId {
    final $$UserEntityTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerId,
      referencedTable: $db.userEntity,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserEntityTableAnnotationComposer(
            $db: $db,
            $table: $db.userEntity,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> remoteAlbumEntityRefs<T extends Object>(
    Expression<T> Function($$RemoteAlbumEntityTableAnnotationComposer a) f,
  ) {
    final $$RemoteAlbumEntityTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.remoteAlbumEntity,
          getReferencedColumn: (t) => t.thumbnailAssetId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RemoteAlbumEntityTableAnnotationComposer(
                $db: $db,
                $table: $db.remoteAlbumEntity,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> albumAssetEntityRefs<T extends Object>(
    Expression<T> Function($$AlbumAssetEntityTableAnnotationComposer a) f,
  ) {
    final $$AlbumAssetEntityTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.albumAssetEntity,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlbumAssetEntityTableAnnotationComposer(
            $db: $db,
            $table: $db.albumAssetEntity,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RemoteAssetEntityTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemoteAssetEntityTable,
          RemoteAssetEntityData,
          $$RemoteAssetEntityTableFilterComposer,
          $$RemoteAssetEntityTableOrderingComposer,
          $$RemoteAssetEntityTableAnnotationComposer,
          $$RemoteAssetEntityTableCreateCompanionBuilder,
          $$RemoteAssetEntityTableUpdateCompanionBuilder,
          (RemoteAssetEntityData, $$RemoteAssetEntityTableReferences),
          RemoteAssetEntityData,
          PrefetchHooks Function({
            bool ownerId,
            bool remoteAlbumEntityRefs,
            bool albumAssetEntityRefs,
          })
        > {
  $$RemoteAssetEntityTableTableManager(
    _$AppDatabase db,
    $RemoteAssetEntityTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemoteAssetEntityTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemoteAssetEntityTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemoteAssetEntityTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
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
              }) => RemoteAssetEntityCompanion(
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
          createCompanionCallback:
              ({
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
              }) => RemoteAssetEntityCompanion.insert(
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
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RemoteAssetEntityTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                ownerId = false,
                remoteAlbumEntityRefs = false,
                albumAssetEntityRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (remoteAlbumEntityRefs) db.remoteAlbumEntity,
                    if (albumAssetEntityRefs) db.albumAssetEntity,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (ownerId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.ownerId,
                                    referencedTable:
                                        $$RemoteAssetEntityTableReferences
                                            ._ownerIdTable(db),
                                    referencedColumn:
                                        $$RemoteAssetEntityTableReferences
                                            ._ownerIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (remoteAlbumEntityRefs)
                        await $_getPrefetchedData<
                          RemoteAssetEntityData,
                          $RemoteAssetEntityTable,
                          RemoteAlbumEntityData
                        >(
                          currentTable: table,
                          referencedTable: $$RemoteAssetEntityTableReferences
                              ._remoteAlbumEntityRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RemoteAssetEntityTableReferences(
                                db,
                                table,
                                p0,
                              ).remoteAlbumEntityRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.thumbnailAssetId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (albumAssetEntityRefs)
                        await $_getPrefetchedData<
                          RemoteAssetEntityData,
                          $RemoteAssetEntityTable,
                          AlbumAssetEntityData
                        >(
                          currentTable: table,
                          referencedTable: $$RemoteAssetEntityTableReferences
                              ._albumAssetEntityRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RemoteAssetEntityTableReferences(
                                db,
                                table,
                                p0,
                              ).albumAssetEntityRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.assetId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$RemoteAssetEntityTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemoteAssetEntityTable,
      RemoteAssetEntityData,
      $$RemoteAssetEntityTableFilterComposer,
      $$RemoteAssetEntityTableOrderingComposer,
      $$RemoteAssetEntityTableAnnotationComposer,
      $$RemoteAssetEntityTableCreateCompanionBuilder,
      $$RemoteAssetEntityTableUpdateCompanionBuilder,
      (RemoteAssetEntityData, $$RemoteAssetEntityTableReferences),
      RemoteAssetEntityData,
      PrefetchHooks Function({
        bool ownerId,
        bool remoteAlbumEntityRefs,
        bool albumAssetEntityRefs,
      })
    >;
typedef $$RemoteAlbumEntityTableCreateCompanionBuilder =
    RemoteAlbumEntityCompanion Function({
      required String id,
      required String name,
      Value<String?> description,
      required DateTime createdAt,
      required DateTime updatedAt,
      required String ownerId,
      Value<String?> thumbnailAssetId,
      Value<bool> isActivityEnabled,
      Value<AlbumOrder> order,
    });
typedef $$RemoteAlbumEntityTableUpdateCompanionBuilder =
    RemoteAlbumEntityCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> description,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String> ownerId,
      Value<String?> thumbnailAssetId,
      Value<bool> isActivityEnabled,
      Value<AlbumOrder> order,
    });

final class $$RemoteAlbumEntityTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $RemoteAlbumEntityTable,
          RemoteAlbumEntityData
        > {
  $$RemoteAlbumEntityTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $UserEntityTable _ownerIdTable(_$AppDatabase db) =>
      db.userEntity.createAlias(
        $_aliasNameGenerator(db.remoteAlbumEntity.ownerId, db.userEntity.id),
      );

  $$UserEntityTableProcessedTableManager get ownerId {
    final $_column = $_itemColumn<String>('owner_id')!;

    final manager = $$UserEntityTableTableManager(
      $_db,
      $_db.userEntity,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ownerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $RemoteAssetEntityTable _thumbnailAssetIdTable(_$AppDatabase db) =>
      db.remoteAssetEntity.createAlias(
        $_aliasNameGenerator(
          db.remoteAlbumEntity.thumbnailAssetId,
          db.remoteAssetEntity.id,
        ),
      );

  $$RemoteAssetEntityTableProcessedTableManager? get thumbnailAssetId {
    final $_column = $_itemColumn<String>('thumbnail_asset_id');
    if ($_column == null) return null;
    final manager = $$RemoteAssetEntityTableTableManager(
      $_db,
      $_db.remoteAssetEntity,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_thumbnailAssetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$LocalAlbumEntityTable, List<LocalAlbumEntityData>>
  _localAlbumEntityRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.localAlbumEntity,
    aliasName: $_aliasNameGenerator(
      db.remoteAlbumEntity.id,
      db.localAlbumEntity.linkedRemoteAlbumId,
    ),
  );

  $$LocalAlbumEntityTableProcessedTableManager get localAlbumEntityRefs {
    final manager =
        $$LocalAlbumEntityTableTableManager($_db, $_db.localAlbumEntity).filter(
          (f) =>
              f.linkedRemoteAlbumId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _localAlbumEntityRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AlbumAssetEntityTable, List<AlbumAssetEntityData>>
  _albumAssetEntityRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.albumAssetEntity,
    aliasName: $_aliasNameGenerator(
      db.remoteAlbumEntity.id,
      db.albumAssetEntity.albumId,
    ),
  );

  $$AlbumAssetEntityTableProcessedTableManager get albumAssetEntityRefs {
    final manager = $$AlbumAssetEntityTableTableManager(
      $_db,
      $_db.albumAssetEntity,
    ).filter((f) => f.albumId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _albumAssetEntityRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RemoteAlbumEntityTableFilterComposer
    extends Composer<_$AppDatabase, $RemoteAlbumEntityTable> {
  $$RemoteAlbumEntityTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActivityEnabled => $composableBuilder(
    column: $table.isActivityEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AlbumOrder, AlbumOrder, int> get order =>
      $composableBuilder(
        column: $table.order,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$UserEntityTableFilterComposer get ownerId {
    final $$UserEntityTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerId,
      referencedTable: $db.userEntity,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserEntityTableFilterComposer(
            $db: $db,
            $table: $db.userEntity,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RemoteAssetEntityTableFilterComposer get thumbnailAssetId {
    final $$RemoteAssetEntityTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.thumbnailAssetId,
      referencedTable: $db.remoteAssetEntity,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemoteAssetEntityTableFilterComposer(
            $db: $db,
            $table: $db.remoteAssetEntity,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> localAlbumEntityRefs(
    Expression<bool> Function($$LocalAlbumEntityTableFilterComposer f) f,
  ) {
    final $$LocalAlbumEntityTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localAlbumEntity,
      getReferencedColumn: (t) => t.linkedRemoteAlbumId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalAlbumEntityTableFilterComposer(
            $db: $db,
            $table: $db.localAlbumEntity,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> albumAssetEntityRefs(
    Expression<bool> Function($$AlbumAssetEntityTableFilterComposer f) f,
  ) {
    final $$AlbumAssetEntityTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.albumAssetEntity,
      getReferencedColumn: (t) => t.albumId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlbumAssetEntityTableFilterComposer(
            $db: $db,
            $table: $db.albumAssetEntity,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RemoteAlbumEntityTableOrderingComposer
    extends Composer<_$AppDatabase, $RemoteAlbumEntityTable> {
  $$RemoteAlbumEntityTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActivityEnabled => $composableBuilder(
    column: $table.isActivityEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnOrderings(column),
  );

  $$UserEntityTableOrderingComposer get ownerId {
    final $$UserEntityTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerId,
      referencedTable: $db.userEntity,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserEntityTableOrderingComposer(
            $db: $db,
            $table: $db.userEntity,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RemoteAssetEntityTableOrderingComposer get thumbnailAssetId {
    final $$RemoteAssetEntityTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.thumbnailAssetId,
      referencedTable: $db.remoteAssetEntity,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemoteAssetEntityTableOrderingComposer(
            $db: $db,
            $table: $db.remoteAssetEntity,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RemoteAlbumEntityTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemoteAlbumEntityTable> {
  $$RemoteAlbumEntityTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isActivityEnabled => $composableBuilder(
    column: $table.isActivityEnabled,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<AlbumOrder, int> get order =>
      $composableBuilder(column: $table.order, builder: (column) => column);

  $$UserEntityTableAnnotationComposer get ownerId {
    final $$UserEntityTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerId,
      referencedTable: $db.userEntity,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserEntityTableAnnotationComposer(
            $db: $db,
            $table: $db.userEntity,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RemoteAssetEntityTableAnnotationComposer get thumbnailAssetId {
    final $$RemoteAssetEntityTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.thumbnailAssetId,
          referencedTable: $db.remoteAssetEntity,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RemoteAssetEntityTableAnnotationComposer(
                $db: $db,
                $table: $db.remoteAssetEntity,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<T> localAlbumEntityRefs<T extends Object>(
    Expression<T> Function($$LocalAlbumEntityTableAnnotationComposer a) f,
  ) {
    final $$LocalAlbumEntityTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localAlbumEntity,
      getReferencedColumn: (t) => t.linkedRemoteAlbumId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalAlbumEntityTableAnnotationComposer(
            $db: $db,
            $table: $db.localAlbumEntity,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> albumAssetEntityRefs<T extends Object>(
    Expression<T> Function($$AlbumAssetEntityTableAnnotationComposer a) f,
  ) {
    final $$AlbumAssetEntityTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.albumAssetEntity,
      getReferencedColumn: (t) => t.albumId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlbumAssetEntityTableAnnotationComposer(
            $db: $db,
            $table: $db.albumAssetEntity,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RemoteAlbumEntityTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemoteAlbumEntityTable,
          RemoteAlbumEntityData,
          $$RemoteAlbumEntityTableFilterComposer,
          $$RemoteAlbumEntityTableOrderingComposer,
          $$RemoteAlbumEntityTableAnnotationComposer,
          $$RemoteAlbumEntityTableCreateCompanionBuilder,
          $$RemoteAlbumEntityTableUpdateCompanionBuilder,
          (RemoteAlbumEntityData, $$RemoteAlbumEntityTableReferences),
          RemoteAlbumEntityData,
          PrefetchHooks Function({
            bool ownerId,
            bool thumbnailAssetId,
            bool localAlbumEntityRefs,
            bool albumAssetEntityRefs,
          })
        > {
  $$RemoteAlbumEntityTableTableManager(
    _$AppDatabase db,
    $RemoteAlbumEntityTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemoteAlbumEntityTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemoteAlbumEntityTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemoteAlbumEntityTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<String?> thumbnailAssetId = const Value.absent(),
                Value<bool> isActivityEnabled = const Value.absent(),
                Value<AlbumOrder> order = const Value.absent(),
              }) => RemoteAlbumEntityCompanion(
                id: id,
                name: name,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
                ownerId: ownerId,
                thumbnailAssetId: thumbnailAssetId,
                isActivityEnabled: isActivityEnabled,
                order: order,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> description = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                required String ownerId,
                Value<String?> thumbnailAssetId = const Value.absent(),
                Value<bool> isActivityEnabled = const Value.absent(),
                Value<AlbumOrder> order = const Value.absent(),
              }) => RemoteAlbumEntityCompanion.insert(
                id: id,
                name: name,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
                ownerId: ownerId,
                thumbnailAssetId: thumbnailAssetId,
                isActivityEnabled: isActivityEnabled,
                order: order,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RemoteAlbumEntityTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                ownerId = false,
                thumbnailAssetId = false,
                localAlbumEntityRefs = false,
                albumAssetEntityRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (localAlbumEntityRefs) db.localAlbumEntity,
                    if (albumAssetEntityRefs) db.albumAssetEntity,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (ownerId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.ownerId,
                                    referencedTable:
                                        $$RemoteAlbumEntityTableReferences
                                            ._ownerIdTable(db),
                                    referencedColumn:
                                        $$RemoteAlbumEntityTableReferences
                                            ._ownerIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (thumbnailAssetId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.thumbnailAssetId,
                                    referencedTable:
                                        $$RemoteAlbumEntityTableReferences
                                            ._thumbnailAssetIdTable(db),
                                    referencedColumn:
                                        $$RemoteAlbumEntityTableReferences
                                            ._thumbnailAssetIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (localAlbumEntityRefs)
                        await $_getPrefetchedData<
                          RemoteAlbumEntityData,
                          $RemoteAlbumEntityTable,
                          LocalAlbumEntityData
                        >(
                          currentTable: table,
                          referencedTable: $$RemoteAlbumEntityTableReferences
                              ._localAlbumEntityRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RemoteAlbumEntityTableReferences(
                                db,
                                table,
                                p0,
                              ).localAlbumEntityRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.linkedRemoteAlbumId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (albumAssetEntityRefs)
                        await $_getPrefetchedData<
                          RemoteAlbumEntityData,
                          $RemoteAlbumEntityTable,
                          AlbumAssetEntityData
                        >(
                          currentTable: table,
                          referencedTable: $$RemoteAlbumEntityTableReferences
                              ._albumAssetEntityRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RemoteAlbumEntityTableReferences(
                                db,
                                table,
                                p0,
                              ).albumAssetEntityRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.albumId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$RemoteAlbumEntityTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemoteAlbumEntityTable,
      RemoteAlbumEntityData,
      $$RemoteAlbumEntityTableFilterComposer,
      $$RemoteAlbumEntityTableOrderingComposer,
      $$RemoteAlbumEntityTableAnnotationComposer,
      $$RemoteAlbumEntityTableCreateCompanionBuilder,
      $$RemoteAlbumEntityTableUpdateCompanionBuilder,
      (RemoteAlbumEntityData, $$RemoteAlbumEntityTableReferences),
      RemoteAlbumEntityData,
      PrefetchHooks Function({
        bool ownerId,
        bool thumbnailAssetId,
        bool localAlbumEntityRefs,
        bool albumAssetEntityRefs,
      })
    >;
typedef $$LocalAlbumEntityTableCreateCompanionBuilder =
    LocalAlbumEntityCompanion Function({
      required String id,
      required String name,
      required DateTime updatedAt,
      Value<BackupSelection> backupSelection,
      Value<bool> isIosSharedAlbum,
      Value<String?> linkedRemoteAlbumId,
    });
typedef $$LocalAlbumEntityTableUpdateCompanionBuilder =
    LocalAlbumEntityCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<DateTime> updatedAt,
      Value<BackupSelection> backupSelection,
      Value<bool> isIosSharedAlbum,
      Value<String?> linkedRemoteAlbumId,
    });

final class $$LocalAlbumEntityTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $LocalAlbumEntityTable,
          LocalAlbumEntityData
        > {
  $$LocalAlbumEntityTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RemoteAlbumEntityTable _linkedRemoteAlbumIdTable(_$AppDatabase db) =>
      db.remoteAlbumEntity.createAlias(
        $_aliasNameGenerator(
          db.localAlbumEntity.linkedRemoteAlbumId,
          db.remoteAlbumEntity.id,
        ),
      );

  $$RemoteAlbumEntityTableProcessedTableManager? get linkedRemoteAlbumId {
    final $_column = $_itemColumn<String>('linked_remote_album_id');
    if ($_column == null) return null;
    final manager = $$RemoteAlbumEntityTableTableManager(
      $_db,
      $_db.remoteAlbumEntity,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_linkedRemoteAlbumIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LocalAlbumEntityTableFilterComposer
    extends Composer<_$AppDatabase, $LocalAlbumEntityTable> {
  $$LocalAlbumEntityTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<BackupSelection, BackupSelection, int>
  get backupSelection => $composableBuilder(
    column: $table.backupSelection,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get isIosSharedAlbum => $composableBuilder(
    column: $table.isIosSharedAlbum,
    builder: (column) => ColumnFilters(column),
  );

  $$RemoteAlbumEntityTableFilterComposer get linkedRemoteAlbumId {
    final $$RemoteAlbumEntityTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.linkedRemoteAlbumId,
      referencedTable: $db.remoteAlbumEntity,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemoteAlbumEntityTableFilterComposer(
            $db: $db,
            $table: $db.remoteAlbumEntity,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalAlbumEntityTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalAlbumEntityTable> {
  $$LocalAlbumEntityTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get backupSelection => $composableBuilder(
    column: $table.backupSelection,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isIosSharedAlbum => $composableBuilder(
    column: $table.isIosSharedAlbum,
    builder: (column) => ColumnOrderings(column),
  );

  $$RemoteAlbumEntityTableOrderingComposer get linkedRemoteAlbumId {
    final $$RemoteAlbumEntityTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.linkedRemoteAlbumId,
      referencedTable: $db.remoteAlbumEntity,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemoteAlbumEntityTableOrderingComposer(
            $db: $db,
            $table: $db.remoteAlbumEntity,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalAlbumEntityTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalAlbumEntityTable> {
  $$LocalAlbumEntityTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BackupSelection, int> get backupSelection =>
      $composableBuilder(
        column: $table.backupSelection,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get isIosSharedAlbum => $composableBuilder(
    column: $table.isIosSharedAlbum,
    builder: (column) => column,
  );

  $$RemoteAlbumEntityTableAnnotationComposer get linkedRemoteAlbumId {
    final $$RemoteAlbumEntityTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.linkedRemoteAlbumId,
          referencedTable: $db.remoteAlbumEntity,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RemoteAlbumEntityTableAnnotationComposer(
                $db: $db,
                $table: $db.remoteAlbumEntity,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$LocalAlbumEntityTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalAlbumEntityTable,
          LocalAlbumEntityData,
          $$LocalAlbumEntityTableFilterComposer,
          $$LocalAlbumEntityTableOrderingComposer,
          $$LocalAlbumEntityTableAnnotationComposer,
          $$LocalAlbumEntityTableCreateCompanionBuilder,
          $$LocalAlbumEntityTableUpdateCompanionBuilder,
          (LocalAlbumEntityData, $$LocalAlbumEntityTableReferences),
          LocalAlbumEntityData,
          PrefetchHooks Function({bool linkedRemoteAlbumId})
        > {
  $$LocalAlbumEntityTableTableManager(
    _$AppDatabase db,
    $LocalAlbumEntityTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalAlbumEntityTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalAlbumEntityTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalAlbumEntityTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<BackupSelection> backupSelection = const Value.absent(),
                Value<bool> isIosSharedAlbum = const Value.absent(),
                Value<String?> linkedRemoteAlbumId = const Value.absent(),
              }) => LocalAlbumEntityCompanion(
                id: id,
                name: name,
                updatedAt: updatedAt,
                backupSelection: backupSelection,
                isIosSharedAlbum: isIosSharedAlbum,
                linkedRemoteAlbumId: linkedRemoteAlbumId,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required DateTime updatedAt,
                Value<BackupSelection> backupSelection = const Value.absent(),
                Value<bool> isIosSharedAlbum = const Value.absent(),
                Value<String?> linkedRemoteAlbumId = const Value.absent(),
              }) => LocalAlbumEntityCompanion.insert(
                id: id,
                name: name,
                updatedAt: updatedAt,
                backupSelection: backupSelection,
                isIosSharedAlbum: isIosSharedAlbum,
                linkedRemoteAlbumId: linkedRemoteAlbumId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LocalAlbumEntityTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({linkedRemoteAlbumId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (linkedRemoteAlbumId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.linkedRemoteAlbumId,
                                referencedTable:
                                    $$LocalAlbumEntityTableReferences
                                        ._linkedRemoteAlbumIdTable(db),
                                referencedColumn:
                                    $$LocalAlbumEntityTableReferences
                                        ._linkedRemoteAlbumIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LocalAlbumEntityTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalAlbumEntityTable,
      LocalAlbumEntityData,
      $$LocalAlbumEntityTableFilterComposer,
      $$LocalAlbumEntityTableOrderingComposer,
      $$LocalAlbumEntityTableAnnotationComposer,
      $$LocalAlbumEntityTableCreateCompanionBuilder,
      $$LocalAlbumEntityTableUpdateCompanionBuilder,
      (LocalAlbumEntityData, $$LocalAlbumEntityTableReferences),
      LocalAlbumEntityData,
      PrefetchHooks Function({bool linkedRemoteAlbumId})
    >;
typedef $$AlbumAssetEntityTableCreateCompanionBuilder =
    AlbumAssetEntityCompanion Function({
      required String assetId,
      required String albumId,
    });
typedef $$AlbumAssetEntityTableUpdateCompanionBuilder =
    AlbumAssetEntityCompanion Function({
      Value<String> assetId,
      Value<String> albumId,
    });

final class $$AlbumAssetEntityTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $AlbumAssetEntityTable,
          AlbumAssetEntityData
        > {
  $$AlbumAssetEntityTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RemoteAssetEntityTable _assetIdTable(_$AppDatabase db) =>
      db.remoteAssetEntity.createAlias(
        $_aliasNameGenerator(
          db.albumAssetEntity.assetId,
          db.remoteAssetEntity.id,
        ),
      );

  $$RemoteAssetEntityTableProcessedTableManager get assetId {
    final $_column = $_itemColumn<String>('asset_id')!;

    final manager = $$RemoteAssetEntityTableTableManager(
      $_db,
      $_db.remoteAssetEntity,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_assetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $RemoteAlbumEntityTable _albumIdTable(_$AppDatabase db) =>
      db.remoteAlbumEntity.createAlias(
        $_aliasNameGenerator(
          db.albumAssetEntity.albumId,
          db.remoteAlbumEntity.id,
        ),
      );

  $$RemoteAlbumEntityTableProcessedTableManager get albumId {
    final $_column = $_itemColumn<String>('album_id')!;

    final manager = $$RemoteAlbumEntityTableTableManager(
      $_db,
      $_db.remoteAlbumEntity,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_albumIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AlbumAssetEntityTableFilterComposer
    extends Composer<_$AppDatabase, $AlbumAssetEntityTable> {
  $$AlbumAssetEntityTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$RemoteAssetEntityTableFilterComposer get assetId {
    final $$RemoteAssetEntityTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.remoteAssetEntity,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemoteAssetEntityTableFilterComposer(
            $db: $db,
            $table: $db.remoteAssetEntity,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RemoteAlbumEntityTableFilterComposer get albumId {
    final $$RemoteAlbumEntityTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.albumId,
      referencedTable: $db.remoteAlbumEntity,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemoteAlbumEntityTableFilterComposer(
            $db: $db,
            $table: $db.remoteAlbumEntity,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AlbumAssetEntityTableOrderingComposer
    extends Composer<_$AppDatabase, $AlbumAssetEntityTable> {
  $$AlbumAssetEntityTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$RemoteAssetEntityTableOrderingComposer get assetId {
    final $$RemoteAssetEntityTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.remoteAssetEntity,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemoteAssetEntityTableOrderingComposer(
            $db: $db,
            $table: $db.remoteAssetEntity,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RemoteAlbumEntityTableOrderingComposer get albumId {
    final $$RemoteAlbumEntityTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.albumId,
      referencedTable: $db.remoteAlbumEntity,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemoteAlbumEntityTableOrderingComposer(
            $db: $db,
            $table: $db.remoteAlbumEntity,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AlbumAssetEntityTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlbumAssetEntityTable> {
  $$AlbumAssetEntityTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$RemoteAssetEntityTableAnnotationComposer get assetId {
    final $$RemoteAssetEntityTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.assetId,
          referencedTable: $db.remoteAssetEntity,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RemoteAssetEntityTableAnnotationComposer(
                $db: $db,
                $table: $db.remoteAssetEntity,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$RemoteAlbumEntityTableAnnotationComposer get albumId {
    final $$RemoteAlbumEntityTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.albumId,
          referencedTable: $db.remoteAlbumEntity,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RemoteAlbumEntityTableAnnotationComposer(
                $db: $db,
                $table: $db.remoteAlbumEntity,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$AlbumAssetEntityTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AlbumAssetEntityTable,
          AlbumAssetEntityData,
          $$AlbumAssetEntityTableFilterComposer,
          $$AlbumAssetEntityTableOrderingComposer,
          $$AlbumAssetEntityTableAnnotationComposer,
          $$AlbumAssetEntityTableCreateCompanionBuilder,
          $$AlbumAssetEntityTableUpdateCompanionBuilder,
          (AlbumAssetEntityData, $$AlbumAssetEntityTableReferences),
          AlbumAssetEntityData,
          PrefetchHooks Function({bool assetId, bool albumId})
        > {
  $$AlbumAssetEntityTableTableManager(
    _$AppDatabase db,
    $AlbumAssetEntityTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlbumAssetEntityTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlbumAssetEntityTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlbumAssetEntityTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> assetId = const Value.absent(),
                Value<String> albumId = const Value.absent(),
              }) =>
                  AlbumAssetEntityCompanion(assetId: assetId, albumId: albumId),
          createCompanionCallback:
              ({required String assetId, required String albumId}) =>
                  AlbumAssetEntityCompanion.insert(
                    assetId: assetId,
                    albumId: albumId,
                  ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AlbumAssetEntityTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({assetId = false, albumId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (assetId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.assetId,
                                referencedTable:
                                    $$AlbumAssetEntityTableReferences
                                        ._assetIdTable(db),
                                referencedColumn:
                                    $$AlbumAssetEntityTableReferences
                                        ._assetIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (albumId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.albumId,
                                referencedTable:
                                    $$AlbumAssetEntityTableReferences
                                        ._albumIdTable(db),
                                referencedColumn:
                                    $$AlbumAssetEntityTableReferences
                                        ._albumIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AlbumAssetEntityTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AlbumAssetEntityTable,
      AlbumAssetEntityData,
      $$AlbumAssetEntityTableFilterComposer,
      $$AlbumAssetEntityTableOrderingComposer,
      $$AlbumAssetEntityTableAnnotationComposer,
      $$AlbumAssetEntityTableCreateCompanionBuilder,
      $$AlbumAssetEntityTableUpdateCompanionBuilder,
      (AlbumAssetEntityData, $$AlbumAssetEntityTableReferences),
      AlbumAssetEntityData,
      PrefetchHooks Function({bool assetId, bool albumId})
    >;

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
}
