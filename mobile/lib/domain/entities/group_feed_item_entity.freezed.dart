// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group_feed_item_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$FeedAuthorEntity {
  int get userId => throw _privateConstructorUsedError;
  String get username => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $FeedAuthorEntityCopyWith<FeedAuthorEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FeedAuthorEntityCopyWith<$Res> {
  factory $FeedAuthorEntityCopyWith(
          FeedAuthorEntity value, $Res Function(FeedAuthorEntity) then) =
      _$FeedAuthorEntityCopyWithImpl<$Res, FeedAuthorEntity>;
  @useResult
  $Res call({int userId, String username, String? avatarUrl});
}

/// @nodoc
class _$FeedAuthorEntityCopyWithImpl<$Res, $Val extends FeedAuthorEntity>
    implements $FeedAuthorEntityCopyWith<$Res> {
  _$FeedAuthorEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? username = null,
    Object? avatarUrl = freezed,
  }) {
    return _then(_value.copyWith(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as int,
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FeedAuthorEntityImplCopyWith<$Res>
    implements $FeedAuthorEntityCopyWith<$Res> {
  factory _$$FeedAuthorEntityImplCopyWith(_$FeedAuthorEntityImpl value,
          $Res Function(_$FeedAuthorEntityImpl) then) =
      __$$FeedAuthorEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int userId, String username, String? avatarUrl});
}

/// @nodoc
class __$$FeedAuthorEntityImplCopyWithImpl<$Res>
    extends _$FeedAuthorEntityCopyWithImpl<$Res, _$FeedAuthorEntityImpl>
    implements _$$FeedAuthorEntityImplCopyWith<$Res> {
  __$$FeedAuthorEntityImplCopyWithImpl(_$FeedAuthorEntityImpl _value,
      $Res Function(_$FeedAuthorEntityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? username = null,
    Object? avatarUrl = freezed,
  }) {
    return _then(_$FeedAuthorEntityImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as int,
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$FeedAuthorEntityImpl implements _FeedAuthorEntity {
  const _$FeedAuthorEntityImpl(
      {required this.userId, required this.username, this.avatarUrl});

  @override
  final int userId;
  @override
  final String username;
  @override
  final String? avatarUrl;

  @override
  String toString() {
    return 'FeedAuthorEntity(userId: $userId, username: $username, avatarUrl: $avatarUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FeedAuthorEntityImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl));
  }

  @override
  int get hashCode => Object.hash(runtimeType, userId, username, avatarUrl);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FeedAuthorEntityImplCopyWith<_$FeedAuthorEntityImpl> get copyWith =>
      __$$FeedAuthorEntityImplCopyWithImpl<_$FeedAuthorEntityImpl>(
          this, _$identity);
}

abstract class _FeedAuthorEntity implements FeedAuthorEntity {
  const factory _FeedAuthorEntity(
      {required final int userId,
      required final String username,
      final String? avatarUrl}) = _$FeedAuthorEntityImpl;

  @override
  int get userId;
  @override
  String get username;
  @override
  String? get avatarUrl;
  @override
  @JsonKey(ignore: true)
  _$$FeedAuthorEntityImplCopyWith<_$FeedAuthorEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$GroupFeedItemEntity {
  int get id => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  FeedAuthorEntity get author => throw _privateConstructorUsedError;
  List<UnifiedMediaEntity> get mediaAttachments =>
      throw _privateConstructorUsedError; // 注意: 点赞和评论数在当前的 GroupMediaModel 中不存在。
// 此处添加是为了UI统一，数据将在后续或通过聚合接口提供。
  int get likesCount => throw _privateConstructorUsedError;
  int get commentsCount => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $GroupFeedItemEntityCopyWith<GroupFeedItemEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GroupFeedItemEntityCopyWith<$Res> {
  factory $GroupFeedItemEntityCopyWith(
          GroupFeedItemEntity value, $Res Function(GroupFeedItemEntity) then) =
      _$GroupFeedItemEntityCopyWithImpl<$Res, GroupFeedItemEntity>;
  @useResult
  $Res call(
      {int id,
      String content,
      DateTime createdAt,
      FeedAuthorEntity author,
      List<UnifiedMediaEntity> mediaAttachments,
      int likesCount,
      int commentsCount});

  $FeedAuthorEntityCopyWith<$Res> get author;
}

/// @nodoc
class _$GroupFeedItemEntityCopyWithImpl<$Res, $Val extends GroupFeedItemEntity>
    implements $GroupFeedItemEntityCopyWith<$Res> {
  _$GroupFeedItemEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = null,
    Object? createdAt = null,
    Object? author = null,
    Object? mediaAttachments = null,
    Object? likesCount = null,
    Object? commentsCount = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      author: null == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as FeedAuthorEntity,
      mediaAttachments: null == mediaAttachments
          ? _value.mediaAttachments
          : mediaAttachments // ignore: cast_nullable_to_non_nullable
              as List<UnifiedMediaEntity>,
      likesCount: null == likesCount
          ? _value.likesCount
          : likesCount // ignore: cast_nullable_to_non_nullable
              as int,
      commentsCount: null == commentsCount
          ? _value.commentsCount
          : commentsCount // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $FeedAuthorEntityCopyWith<$Res> get author {
    return $FeedAuthorEntityCopyWith<$Res>(_value.author, (value) {
      return _then(_value.copyWith(author: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$GroupFeedItemEntityImplCopyWith<$Res>
    implements $GroupFeedItemEntityCopyWith<$Res> {
  factory _$$GroupFeedItemEntityImplCopyWith(_$GroupFeedItemEntityImpl value,
          $Res Function(_$GroupFeedItemEntityImpl) then) =
      __$$GroupFeedItemEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String content,
      DateTime createdAt,
      FeedAuthorEntity author,
      List<UnifiedMediaEntity> mediaAttachments,
      int likesCount,
      int commentsCount});

  @override
  $FeedAuthorEntityCopyWith<$Res> get author;
}

/// @nodoc
class __$$GroupFeedItemEntityImplCopyWithImpl<$Res>
    extends _$GroupFeedItemEntityCopyWithImpl<$Res, _$GroupFeedItemEntityImpl>
    implements _$$GroupFeedItemEntityImplCopyWith<$Res> {
  __$$GroupFeedItemEntityImplCopyWithImpl(_$GroupFeedItemEntityImpl _value,
      $Res Function(_$GroupFeedItemEntityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = null,
    Object? createdAt = null,
    Object? author = null,
    Object? mediaAttachments = null,
    Object? likesCount = null,
    Object? commentsCount = null,
  }) {
    return _then(_$GroupFeedItemEntityImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      author: null == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as FeedAuthorEntity,
      mediaAttachments: null == mediaAttachments
          ? _value._mediaAttachments
          : mediaAttachments // ignore: cast_nullable_to_non_nullable
              as List<UnifiedMediaEntity>,
      likesCount: null == likesCount
          ? _value.likesCount
          : likesCount // ignore: cast_nullable_to_non_nullable
              as int,
      commentsCount: null == commentsCount
          ? _value.commentsCount
          : commentsCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$GroupFeedItemEntityImpl implements _GroupFeedItemEntity {
  const _$GroupFeedItemEntityImpl(
      {required this.id,
      required this.content,
      required this.createdAt,
      required this.author,
      required final List<UnifiedMediaEntity> mediaAttachments,
      this.likesCount = 0,
      this.commentsCount = 0})
      : _mediaAttachments = mediaAttachments;

  @override
  final int id;
  @override
  final String content;
  @override
  final DateTime createdAt;
  @override
  final FeedAuthorEntity author;
  final List<UnifiedMediaEntity> _mediaAttachments;
  @override
  List<UnifiedMediaEntity> get mediaAttachments {
    if (_mediaAttachments is EqualUnmodifiableListView)
      return _mediaAttachments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_mediaAttachments);
  }

// 注意: 点赞和评论数在当前的 GroupMediaModel 中不存在。
// 此处添加是为了UI统一，数据将在后续或通过聚合接口提供。
  @override
  @JsonKey()
  final int likesCount;
  @override
  @JsonKey()
  final int commentsCount;

  @override
  String toString() {
    return 'GroupFeedItemEntity(id: $id, content: $content, createdAt: $createdAt, author: $author, mediaAttachments: $mediaAttachments, likesCount: $likesCount, commentsCount: $commentsCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GroupFeedItemEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.author, author) || other.author == author) &&
            const DeepCollectionEquality()
                .equals(other._mediaAttachments, _mediaAttachments) &&
            (identical(other.likesCount, likesCount) ||
                other.likesCount == likesCount) &&
            (identical(other.commentsCount, commentsCount) ||
                other.commentsCount == commentsCount));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      content,
      createdAt,
      author,
      const DeepCollectionEquality().hash(_mediaAttachments),
      likesCount,
      commentsCount);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GroupFeedItemEntityImplCopyWith<_$GroupFeedItemEntityImpl> get copyWith =>
      __$$GroupFeedItemEntityImplCopyWithImpl<_$GroupFeedItemEntityImpl>(
          this, _$identity);
}

abstract class _GroupFeedItemEntity implements GroupFeedItemEntity {
  const factory _GroupFeedItemEntity(
      {required final int id,
      required final String content,
      required final DateTime createdAt,
      required final FeedAuthorEntity author,
      required final List<UnifiedMediaEntity> mediaAttachments,
      final int likesCount,
      final int commentsCount}) = _$GroupFeedItemEntityImpl;

  @override
  int get id;
  @override
  String get content;
  @override
  DateTime get createdAt;
  @override
  FeedAuthorEntity get author;
  @override
  List<UnifiedMediaEntity> get mediaAttachments;
  @override // 注意: 点赞和评论数在当前的 GroupMediaModel 中不存在。
// 此处添加是为了UI统一，数据将在后续或通过聚合接口提供。
  int get likesCount;
  @override
  int get commentsCount;
  @override
  @JsonKey(ignore: true)
  _$$GroupFeedItemEntityImplCopyWith<_$GroupFeedItemEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
