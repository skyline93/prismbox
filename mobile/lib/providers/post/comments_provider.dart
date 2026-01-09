// lib/providers/post/comments_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:prismbox/data/models/post/comment.dart';
import 'package:prismbox/providers/post/post_providers.dart';

part 'comments_provider.g.dart';

/// 评论列表 Provider
/// 管理评论列表状态（内存中）
/// 使用 family 参数，参数为 postId (int)
@riverpod
class CommentsProvider extends _$CommentsProvider {
  @override
  Future<List<Comment>> build(int postId) async {
    // 在 build 方法中直接加载评论，确保每次 Provider 重建时都会重新加载
    final service = ref.read(commentServiceProvider);
    final comments = await service.getComments(postId: postId);
    return comments;
  }

  /// 加载评论列表（刷新）
  Future<void> load() async {
    if (state.isLoading) return; // 防止重复加载

    state = const AsyncValue.loading();
    try {
      final service = ref.read(commentServiceProvider);
      final comments = await service.getComments(postId: postId);
      state = AsyncValue.data(comments);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// 刷新评论列表
  Future<void> refresh() async {
    await load();
  }

  /// 添加新评论（评论添加后调用）
  void addComment(Comment comment) {
    final currentComments = state.value ?? [];
    state = AsyncValue.data([comment, ...currentComments]);
  }

  /// 删除评论
  void removeComment(String commentId) {
    final currentComments = state.value ?? [];
    final updatedComments = currentComments
        .where((c) => c.id != commentId)
        .map((c) => _removeCommentRecursive(c, commentId))
        .where((c) => c != null)
        .cast<Comment>()
        .toList();
    state = AsyncValue.data(updatedComments);
  }

  /// 递归删除评论（包括回复）
  Comment? _removeCommentRecursive(Comment comment, String commentId) {
    if (comment.id == commentId) {
      return null;
    }

    final updatedReplies = comment.replies
        .map((r) => _removeCommentRecursive(r, commentId))
        .where((r) => r != null)
        .cast<Comment>()
        .toList();

    return Comment(
      id: comment.id,
      createdAt: comment.createdAt,
      content: comment.content,
      author: comment.author,
      likesCount: comment.likesCount,
      replies: updatedReplies,
    );
  }
}

