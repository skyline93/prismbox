// lib/ui/group/viewmodels/post_detail_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/domain/entities/comment_entity.dart';
import 'package:mobile/domain/repositories/group_repository.dart';
import 'package:mobile/ui/group/viewmodels/post_detail_state.dart';

class PostDetailViewModel extends StateNotifier<PostDetailState> {
  final GroupRepository _groupRepository;
  final int _postId;

  // [修改] postId 参数类型从 String 变为 int
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
      // 调用 repository 提交
      await _groupRepository.postComment(
        postId: _postId,
        content: content,
        parentCommentId: parentId,
      );

      // 成功后，重新加载整个评论列表以获取最新数据
      // 也可以做乐观更新 (Optimistic Update)，这里为了简单先做刷新
      await _fetchComments();
      state = state.copyWith(
        isPostingComment: false,
        replyingToComment: null, // 清空回复状态
        commentPostedSuccessfully: parentId == null, // 只有顶级评论才触发滚动
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

  // UI 调用此方法来重置一次性事件的标志
  void consumePostSuccess() {
    state = state.copyWith(commentPostedSuccessfully: false);
  }
}
