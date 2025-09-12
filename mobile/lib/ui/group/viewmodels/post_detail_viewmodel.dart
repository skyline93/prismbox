// lib/ui/group/viewmodels/post_detail_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/domain/entities/comment_entity.dart';
import 'package:mobile/domain/repositories/group_repository.dart';
import 'package:mobile/ui/group/viewmodels/post_detail_state.dart';

class PostDetailViewModel extends StateNotifier<PostDetailState> {
  final GroupRepository _groupRepository;
  final int _postId;

  PostDetailViewModel(this._groupRepository, this._postId)
    : super(const PostDetailState()) {
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final comments = await _groupRepository.getComments(_postId);
      state = state.copyWith(isLoading: false, comments: comments);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> postComment(String content) async {
    state = state.copyWith(isPostingComment: true, errorMessage: null);
    try {
      final parentId = state.replyingToComment?.id;
      await _groupRepository.postComment(
        postId: _postId,
        content: content,
        parentCommentId: parentId,
      );

      await _fetchComments();
      state = state.copyWith(
        isPostingComment: false,
        replyingToComment: null,
        commentPostedSuccessfully: parentId == null,
      );
    } catch (e) {
      state = state.copyWith(
        isPostingComment: false,
        errorMessage: 'Failed to post comment: $e',
      );
    }
  }

  void setReplyingTo(CommentEntity comment) {
    state = state.copyWith(replyingToComment: comment);
  }

  void cancelReply() {
    state = state.copyWith(replyingToComment: null);
  }

  void consumePostSuccess() {
    state = state.copyWith(commentPostedSuccessfully: false);
  }
}
