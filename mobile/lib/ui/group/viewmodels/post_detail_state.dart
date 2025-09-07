// lib/ui/group/viewmodels/post_detail_state.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mobile/domain/entities/comment_entity.dart';

part 'post_detail_state.freezed.dart';

@freezed
class PostDetailState with _$PostDetailState {
  const factory PostDetailState({
    @Default(true) bool isLoading,
    @Default(false) bool isPostingComment,
    @Default([]) List<CommentEntity> comments,
    CommentEntity? replyingToComment,
    String? errorMessage,
    // 用于通知 UI 评论成功，以便执行滚动等一次性操作
    @Default(false) bool commentPostedSuccessfully,
  }) = _PostDetailState;
}
