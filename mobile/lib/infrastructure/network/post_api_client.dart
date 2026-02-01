// lib/infrastructure/network/post_api_client.dart

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/data/models/post/post.dart';
import 'package:prismbox/data/models/post/comment.dart';
import 'package:prismbox/infrastructure/api/api_service.dart';
import 'package:prismbox/infrastructure/api/exceptions/api_exception.dart';
import 'package:prismbox/infrastructure/api/utils/response_validator.dart';

/// 帖子 API 客户端
/// 封装帖子相关的 API 调用
class PostApiClient {
  final ApiService _apiService;
  final Logger _log = Logger('PostApiClient');

  PostApiClient(this._apiService);

  /// 创建帖子
  Future<Post> createPost({
    required String groupUuid,
    required List<String> mediaUuids,
    String? caption,
  }) async {
    try {
      final response = await _apiService.dio.post(
        '/api/v1/groups/$groupUuid/posts',
        data: {
          'media_uuids': mediaUuids,
          if (caption != null && caption.isNotEmpty) 'caption': caption,
        },
      );

      final data = ResponseValidator.validateAndExtract(response);
      return Post.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 获取全部圈子 Feed 流（当前用户加入的所有圈子的帖子混排）
  Future<List<Post>> getMyFeed({
    int page = 1,
    int limit = 20,
  }) async {
    _log.info('[PostApiClient] getMyFeed() called: page=$page, limit=$limit');
    try {
      const url = '/api/v1/groups/feed';
      final response = await _apiService.dio.get(
        url,
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = response.data;
      if (data is List) {
        return data
            .map((json) => Post.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      if (data is Map<String, dynamic>) {
        final listData = data['data'] as List?;
        if (listData != null) {
          return listData
              .map((json) => Post.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 获取圈子 Feed 流
  Future<List<Post>> getGroupFeed({
    required String groupUuid,
    int page = 1,
    int limit = 20,
  }) async {
    _log.info('[PostApiClient] getGroupFeed() called: groupUuid=$groupUuid, page=$page, limit=$limit');
    _log.info('[PostApiClient] API Service initialized');
    
    try {
      final url = '/api/v1/groups/$groupUuid/feed';
      _log.info('[PostApiClient] Making GET request to: $url');
      _log.info('[PostApiClient] Query parameters: page=$page, limit=$limit');
      
      final response = await _apiService.dio.get(
        url,
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      _log.info('[PostApiClient] Response received: statusCode=${response.statusCode}');
      _log.info('[PostApiClient] Response data type: ${response.data.runtimeType}');

      // ResponseInterceptor 已经提取了 data 字段
      final data = response.data;
      if (data is List) {
        _log.info('[PostApiClient] Data is List, length: ${data.length}');
        final posts = data
            .map((json) => Post.fromJson(json as Map<String, dynamic>))
            .toList();
        _log.info('[PostApiClient] Parsed ${posts.length} posts');
        return posts;
      }
      if (data is Map<String, dynamic>) {
        _log.info('[PostApiClient] Data is Map, extracting list');
        final listData = data['data'] as List?;
        if (listData != null) {
          _log.info('[PostApiClient] Found list in data, length: ${listData.length}');
          final posts = listData
              .map((json) => Post.fromJson(json as Map<String, dynamic>))
              .toList();
          _log.info('[PostApiClient] Parsed ${posts.length} posts');
          return posts;
        }
      }
      _log.warning('[PostApiClient] No posts found in response, returning empty list');
      return [];
    } on DioException catch (e) {
      _log.severe('[PostApiClient] DioException: ${e.message}', e);
      _log.severe('[PostApiClient] Error type: ${e.type}');
      if (e.response != null) {
        _log.severe('[PostApiClient] Response status: ${e.response!.statusCode}');
        _log.severe('[PostApiClient] Response data: ${e.response!.data}');
      }
      throw _handleError(e);
    } catch (e, stackTrace) {
      _log.severe('[PostApiClient] Unexpected error: $e', e, stackTrace);
      rethrow;
    }
  }

  /// 获取帖子详情
  /// 注意：后端可能没有单独的帖子详情 API，可能需要通过 Feed 流获取
  /// 这里先预留接口，如果后端没有，可以从 Feed 流中查找
  Future<Post?> getPostDetail({
    required String groupUuid,
    required int postId,
  }) async {
    // 后端可能没有单独的帖子详情 API
    // 这里先返回 null，后续如果需要可以通过 Feed 流查找
    // 或者后端添加了详情 API 后再实现
    return null;
  }

  /// 删除帖子
  /// 注意：后端可能没有删除帖子的 API，这里先预留接口
  Future<void> deletePost({
    required String groupUuid,
    required int postId,
  }) async {
    // 后端可能没有删除帖子的 API
    // 这里先抛出未实现错误，后续根据后端 API 实现
    throw ApiException(501, '删除帖子功能暂未实现');
  }

  /// 添加评论
  Future<Comment> addComment({
    required int postId,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      final response = await _apiService.dio.post(
        '/api/v1/posts/$postId/comments',
        data: {
          'content': content,
          if (parentCommentId != null) 'parent_comment_id': parentCommentId,
        },
      );

      final data = ResponseValidator.validateAndExtract(response);
      return Comment.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 获取评论列表
  Future<List<Comment>> getComments({
    required int postId,
  }) async {
    try {
      final response = await _apiService.dio.get(
        '/api/v1/posts/$postId/comments',
      );

      // ResponseInterceptor 已经提取了 data 字段
      final data = response.data;
      if (data is List) {
        return data
            .map((json) => Comment.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      if (data is Map<String, dynamic>) {
        final listData = data['data'] as List?;
        if (listData != null) {
          return listData
              .map((json) => Comment.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 删除评论
  Future<void> deleteComment({
    required String commentId,
  }) async {
    try {
      await _apiService.dio.delete('/api/v1/comments/$commentId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 处理错误
  ApiException _handleError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode ?? 500;
      final data = e.response!.data;
      String message = '请求失败';

      if (data is Map<String, dynamic>) {
        message = data['message'] as String? ?? message;
      } else if (data is String) {
        message = data;
      }

      return ApiException(statusCode, message);
    }
    return ApiException(503, '网络错误: ${e.message}');
  }
}

