// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group_feed_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$GroupFeedState {
  /// Feed列表数据
  List<GroupFeedItemEntity> get feedItems => throw _privateConstructorUsedError;

  /// 是否正在进行初次加载
  bool get isLoading => throw _privateConstructorUsedError;

  /// 是否正在加载下一页
  bool get isLoadingNextPage => throw _privateConstructorUsedError;

  /// 是否已加载所有数据
  bool get hasReachedMax => throw _privateConstructorUsedError;

  /// 加载过程中发生的错误信息
  String? get errorMessage => throw _privateConstructorUsedError;

  /// 是否正在发布新帖子
  bool get isPosting => throw _privateConstructorUsedError;
  int get currentPage => throw _privateConstructorUsedError;

  /// 发布帖子时发生的错误信息
  String? get postError => throw _privateConstructorUsedError;

  /// Create a copy of GroupFeedState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GroupFeedStateCopyWith<GroupFeedState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GroupFeedStateCopyWith<$Res> {
  factory $GroupFeedStateCopyWith(
          GroupFeedState value, $Res Function(GroupFeedState) then) =
      _$GroupFeedStateCopyWithImpl<$Res, GroupFeedState>;
  @useResult
  $Res call(
      {List<GroupFeedItemEntity> feedItems,
      bool isLoading,
      bool isLoadingNextPage,
      bool hasReachedMax,
      String? errorMessage,
      bool isPosting,
      int currentPage,
      String? postError});
}

/// @nodoc
class _$GroupFeedStateCopyWithImpl<$Res, $Val extends GroupFeedState>
    implements $GroupFeedStateCopyWith<$Res> {
  _$GroupFeedStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GroupFeedState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? feedItems = null,
    Object? isLoading = null,
    Object? isLoadingNextPage = null,
    Object? hasReachedMax = null,
    Object? errorMessage = freezed,
    Object? isPosting = null,
    Object? currentPage = null,
    Object? postError = freezed,
  }) {
    return _then(_value.copyWith(
      feedItems: null == feedItems
          ? _value.feedItems
          : feedItems // ignore: cast_nullable_to_non_nullable
              as List<GroupFeedItemEntity>,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoadingNextPage: null == isLoadingNextPage
          ? _value.isLoadingNextPage
          : isLoadingNextPage // ignore: cast_nullable_to_non_nullable
              as bool,
      hasReachedMax: null == hasReachedMax
          ? _value.hasReachedMax
          : hasReachedMax // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      isPosting: null == isPosting
          ? _value.isPosting
          : isPosting // ignore: cast_nullable_to_non_nullable
              as bool,
      currentPage: null == currentPage
          ? _value.currentPage
          : currentPage // ignore: cast_nullable_to_non_nullable
              as int,
      postError: freezed == postError
          ? _value.postError
          : postError // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GroupFeedStateImplCopyWith<$Res>
    implements $GroupFeedStateCopyWith<$Res> {
  factory _$$GroupFeedStateImplCopyWith(_$GroupFeedStateImpl value,
          $Res Function(_$GroupFeedStateImpl) then) =
      __$$GroupFeedStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<GroupFeedItemEntity> feedItems,
      bool isLoading,
      bool isLoadingNextPage,
      bool hasReachedMax,
      String? errorMessage,
      bool isPosting,
      int currentPage,
      String? postError});
}

/// @nodoc
class __$$GroupFeedStateImplCopyWithImpl<$Res>
    extends _$GroupFeedStateCopyWithImpl<$Res, _$GroupFeedStateImpl>
    implements _$$GroupFeedStateImplCopyWith<$Res> {
  __$$GroupFeedStateImplCopyWithImpl(
      _$GroupFeedStateImpl _value, $Res Function(_$GroupFeedStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of GroupFeedState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? feedItems = null,
    Object? isLoading = null,
    Object? isLoadingNextPage = null,
    Object? hasReachedMax = null,
    Object? errorMessage = freezed,
    Object? isPosting = null,
    Object? currentPage = null,
    Object? postError = freezed,
  }) {
    return _then(_$GroupFeedStateImpl(
      feedItems: null == feedItems
          ? _value._feedItems
          : feedItems // ignore: cast_nullable_to_non_nullable
              as List<GroupFeedItemEntity>,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoadingNextPage: null == isLoadingNextPage
          ? _value.isLoadingNextPage
          : isLoadingNextPage // ignore: cast_nullable_to_non_nullable
              as bool,
      hasReachedMax: null == hasReachedMax
          ? _value.hasReachedMax
          : hasReachedMax // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      isPosting: null == isPosting
          ? _value.isPosting
          : isPosting // ignore: cast_nullable_to_non_nullable
              as bool,
      currentPage: null == currentPage
          ? _value.currentPage
          : currentPage // ignore: cast_nullable_to_non_nullable
              as int,
      postError: freezed == postError
          ? _value.postError
          : postError // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$GroupFeedStateImpl implements _GroupFeedState {
  const _$GroupFeedStateImpl(
      {final List<GroupFeedItemEntity> feedItems = const [],
      this.isLoading = true,
      this.isLoadingNextPage = false,
      this.hasReachedMax = false,
      this.errorMessage,
      this.isPosting = false,
      this.currentPage = 1,
      this.postError})
      : _feedItems = feedItems;

  /// Feed列表数据
  final List<GroupFeedItemEntity> _feedItems;

  /// Feed列表数据
  @override
  @JsonKey()
  List<GroupFeedItemEntity> get feedItems {
    if (_feedItems is EqualUnmodifiableListView) return _feedItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_feedItems);
  }

  /// 是否正在进行初次加载
  @override
  @JsonKey()
  final bool isLoading;

  /// 是否正在加载下一页
  @override
  @JsonKey()
  final bool isLoadingNextPage;

  /// 是否已加载所有数据
  @override
  @JsonKey()
  final bool hasReachedMax;

  /// 加载过程中发生的错误信息
  @override
  final String? errorMessage;

  /// 是否正在发布新帖子
  @override
  @JsonKey()
  final bool isPosting;
  @override
  @JsonKey()
  final int currentPage;

  /// 发布帖子时发生的错误信息
  @override
  final String? postError;

  @override
  String toString() {
    return 'GroupFeedState(feedItems: $feedItems, isLoading: $isLoading, isLoadingNextPage: $isLoadingNextPage, hasReachedMax: $hasReachedMax, errorMessage: $errorMessage, isPosting: $isPosting, currentPage: $currentPage, postError: $postError)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GroupFeedStateImpl &&
            const DeepCollectionEquality()
                .equals(other._feedItems, _feedItems) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isLoadingNextPage, isLoadingNextPage) ||
                other.isLoadingNextPage == isLoadingNextPage) &&
            (identical(other.hasReachedMax, hasReachedMax) ||
                other.hasReachedMax == hasReachedMax) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.isPosting, isPosting) ||
                other.isPosting == isPosting) &&
            (identical(other.currentPage, currentPage) ||
                other.currentPage == currentPage) &&
            (identical(other.postError, postError) ||
                other.postError == postError));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_feedItems),
      isLoading,
      isLoadingNextPage,
      hasReachedMax,
      errorMessage,
      isPosting,
      currentPage,
      postError);

  /// Create a copy of GroupFeedState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GroupFeedStateImplCopyWith<_$GroupFeedStateImpl> get copyWith =>
      __$$GroupFeedStateImplCopyWithImpl<_$GroupFeedStateImpl>(
          this, _$identity);
}

abstract class _GroupFeedState implements GroupFeedState {
  const factory _GroupFeedState(
      {final List<GroupFeedItemEntity> feedItems,
      final bool isLoading,
      final bool isLoadingNextPage,
      final bool hasReachedMax,
      final String? errorMessage,
      final bool isPosting,
      final int currentPage,
      final String? postError}) = _$GroupFeedStateImpl;

  /// Feed列表数据
  @override
  List<GroupFeedItemEntity> get feedItems;

  /// 是否正在进行初次加载
  @override
  bool get isLoading;

  /// 是否正在加载下一页
  @override
  bool get isLoadingNextPage;

  /// 是否已加载所有数据
  @override
  bool get hasReachedMax;

  /// 加载过程中发生的错误信息
  @override
  String? get errorMessage;

  /// 是否正在发布新帖子
  @override
  bool get isPosting;
  @override
  int get currentPage;

  /// 发布帖子时发生的错误信息
  @override
  String? get postError;

  /// Create a copy of GroupFeedState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GroupFeedStateImplCopyWith<_$GroupFeedStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
