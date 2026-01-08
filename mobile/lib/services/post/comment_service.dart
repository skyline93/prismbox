// lib/services/post/comment_service.dart

import 'package:logging/logging.dart';
import 'package:prismbox/data/models/post/comment.dart';
import 'package:prismbox/infrastructure/network/post_api_client.dart';

/// 评论服务
/// 封装评论相关的业务逻辑和 API 调用
/// 
/// 注意：当前实现完全在线访问，直接调用 API，不存储到本地数据库
/// 后续可以添加缓存层（内存缓存或本地数据库）来优化性能
class CommentService {
  final PostApiClient _apiClient;
  final Logger _log = Logger('CommentService');

  CommentService(this._apiClient);

  /// 添加评论
  /// 
  /// [postId] 帖子 ID
  /// [content] 评论内容（必填）
  /// [parentCommentId] 父评论 ID（可选，用于回复）
  /// 
  /// 返回创建的评论信息
  Future<Comment> addComment({
    required int postId,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      _log.info('Adding comment to post: $postId');
      
      if (content.trim().isEmpty) {
        throw ArgumentError('评论内容不能为空');
      }
      
      final comment = await _apiClient.addComment(
        postId: postId,
        content: content.trim(),
        parentCommentId: parentCommentId,
      );
      
      _log.info('Comment added successfully: ${comment.id}');
      return comment;
    } catch (e) {
      _log.severe('Failed to add comment: $e', e);
      rethrow;
    }
  }

  /// 获取评论列表
  /// 
  /// [postId] 帖子 ID
  /// 
  /// 返回评论列表（包含嵌套回复）
  /// 
  /// 注意：直接调用 API，不进行缓存
  /// 后续可以添加缓存层（最近 N 条评论等）
  Future<List<Comment>> getComments({
    required int postId,
  }) async {
    try {
      _log.fine('Fetching comments for post: $postId');
      
      final comments = await _apiClient.getComments(postId: postId);
      
      _log.fine('Fetched ${comments.length} comments');
      return comments;
    } catch (e) {
      _log.severe('Failed to fetch comments: $e', e);
      rethrow;
    }
  }

  /// 删除评论
  /// 
  /// [commentId] 评论 ID
  /// 
  /// 注意：只有评论作者或管理员可以删除
  Future<void> deleteComment({
    required String commentId,
  }) async {
    try {
      _log.info('Deleting comment: $commentId');
      
      await _apiClient.deleteComment(commentId: commentId);
      
      _log.info('Comment deleted successfully');
    } catch (e) {
      _log.severe('Failed to delete comment: $e', e);
      rethrow;
    }
  }
}

