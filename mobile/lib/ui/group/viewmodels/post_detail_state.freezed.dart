// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'post_detail_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$PostDetailState {
  bool get isLoading => throw _privateConstructorUsedError;
  bool get isPostingComment => throw _privateConstructorUsedError;
  List<CommentEntity> get comments => throw _privateConstructorUsedError;
  CommentEntity? get replyingToComment => throw _privateConstructorUsedError;
  String? get errorMessage =>
      throw _privateConstructorUsedError; // 用于通知 UI 评论成功，以便执行滚动等一次性操作
  bool get commentPostedSuccessfully => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $PostDetailStateCopyWith<PostDetailState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PostDetailStateCopyWith<$Res> {
  factory $PostDetailStateCopyWith(
          PostDetailState value, $Res Function(PostDetailState) then) =
      _$PostDetailStateCopyWithImpl<$Res, PostDetailState>;
  @useResult
  $Res call(
      {bool isLoading,
      bool isPostingComment,
      List<CommentEntity> comments,
      CommentEntity? replyingToComment,
      String? errorMessage,
      bool commentPostedSuccessfully});

  $CommentEntityCopyWith<$Res>? get replyingToComment;
}

/// @nodoc
class _$PostDetailStateCopyWithImpl<$Res, $Val extends PostDetailState>
    implements $PostDetailStateCopyWith<$Res> {
  _$PostDetailStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? isPostingComment = null,
    Object? comments = null,
    Object? replyingToComment = freezed,
    Object? errorMessage = freezed,
    Object? commentPostedSuccessfully = null,
  }) {
    return _then(_value.copyWith(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isPostingComment: null == isPostingComment
          ? _value.isPostingComment
          : isPostingComment // ignore: cast_nullable_to_non_nullable
              as bool,
      comments: null == comments
          ? _value.comments
          : comments // ignore: cast_nullable_to_non_nullable
              as List<CommentEntity>,
      replyingToComment: freezed == replyingToComment
          ? _value.replyingToComment
          : replyingToComment // ignore: cast_nullable_to_non_nullable
              as CommentEntity?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      commentPostedSuccessfully: null == commentPostedSuccessfully
          ? _value.commentPostedSuccessfully
          : commentPostedSuccessfully // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $CommentEntityCopyWith<$Res>? get replyingToComment {
    if (_value.replyingToComment == null) {
      return null;
    }

    return $CommentEntityCopyWith<$Res>(_value.replyingToComment!, (value) {
      return _then(_value.copyWith(replyingToComment: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PostDetailStateImplCopyWith<$Res>
    implements $PostDetailStateCopyWith<$Res> {
  factory _$$PostDetailStateImplCopyWith(_$PostDetailStateImpl value,
          $Res Function(_$PostDetailStateImpl) then) =
      __$$PostDetailStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isLoading,
      bool isPostingComment,
      List<CommentEntity> comments,
      CommentEntity? replyingToComment,
      String? errorMessage,
      bool commentPostedSuccessfully});

  @override
  $CommentEntityCopyWith<$Res>? get replyingToComment;
}

/// @nodoc
class __$$PostDetailStateImplCopyWithImpl<$Res>
    extends _$PostDetailStateCopyWithImpl<$Res, _$PostDetailStateImpl>
    implements _$$PostDetailStateImplCopyWith<$Res> {
  __$$PostDetailStateImplCopyWithImpl(
      _$PostDetailStateImpl _value, $Res Function(_$PostDetailStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? isPostingComment = null,
    Object? comments = null,
    Object? replyingToComment = freezed,
    Object? errorMessage = freezed,
    Object? commentPostedSuccessfully = null,
  }) {
    return _then(_$PostDetailStateImpl(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isPostingComment: null == isPostingComment
          ? _value.isPostingComment
          : isPostingComment // ignore: cast_nullable_to_non_nullable
              as bool,
      comments: null == comments
          ? _value._comments
          : comments // ignore: cast_nullable_to_non_nullable
              as List<CommentEntity>,
      replyingToComment: freezed == replyingToComment
          ? _value.replyingToComment
          : replyingToComment // ignore: cast_nullable_to_non_nullable
              as CommentEntity?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      commentPostedSuccessfully: null == commentPostedSuccessfully
          ? _value.commentPostedSuccessfully
          : commentPostedSuccessfully // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$PostDetailStateImpl implements _PostDetailState {
  const _$PostDetailStateImpl(
      {this.isLoading = true,
      this.isPostingComment = false,
      final List<CommentEntity> comments = const [],
      this.replyingToComment,
      this.errorMessage,
      this.commentPostedSuccessfully = false})
      : _comments = comments;

  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool isPostingComment;
  final List<CommentEntity> _comments;
  @override
  @JsonKey()
  List<CommentEntity> get comments {
    if (_comments is EqualUnmodifiableListView) return _comments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_comments);
  }

  @override
  final CommentEntity? replyingToComment;
  @override
  final String? errorMessage;
// 用于通知 UI 评论成功，以便执行滚动等一次性操作
  @override
  @JsonKey()
  final bool commentPostedSuccessfully;

  @override
  String toString() {
    return 'PostDetailState(isLoading: $isLoading, isPostingComment: $isPostingComment, comments: $comments, replyingToComment: $replyingToComment, errorMessage: $errorMessage, commentPostedSuccessfully: $commentPostedSuccessfully)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PostDetailStateImpl &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isPostingComment, isPostingComment) ||
                other.isPostingComment == isPostingComment) &&
            const DeepCollectionEquality().equals(other._comments, _comments) &&
            (identical(other.replyingToComment, replyingToComment) ||
                other.replyingToComment == replyingToComment) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.commentPostedSuccessfully,
                    commentPostedSuccessfully) ||
                other.commentPostedSuccessfully == commentPostedSuccessfully));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      isLoading,
      isPostingComment,
      const DeepCollectionEquality().hash(_comments),
      replyingToComment,
      errorMessage,
      commentPostedSuccessfully);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PostDetailStateImplCopyWith<_$PostDetailStateImpl> get copyWith =>
      __$$PostDetailStateImplCopyWithImpl<_$PostDetailStateImpl>(
          this, _$identity);
}

abstract class _PostDetailState implements PostDetailState {
  const factory _PostDetailState(
      {final bool isLoading,
      final bool isPostingComment,
      final List<CommentEntity> comments,
      final CommentEntity? replyingToComment,
      final String? errorMessage,
      final bool commentPostedSuccessfully}) = _$PostDetailStateImpl;

  @override
  bool get isLoading;
  @override
  bool get isPostingComment;
  @override
  List<CommentEntity> get comments;
  @override
  CommentEntity? get replyingToComment;
  @override
  String? get errorMessage;
  @override // 用于通知 UI 评论成功，以便执行滚动等一次性操作
  bool get commentPostedSuccessfully;
  @override
  @JsonKey(ignore: true)
  _$$PostDetailStateImplCopyWith<_$PostDetailStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
