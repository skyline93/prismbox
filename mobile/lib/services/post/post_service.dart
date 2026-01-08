// lib/services/post/post_service.dart

import 'package:logging/logging.dart';
import 'package:prismbox/data/models/post/post.dart';
import 'package:prismbox/infrastructure/network/post_api_client.dart';
import 'package:prismbox/services/post/post_task_manager.dart';

/// 帖子服务
/// 封装帖子相关的业务逻辑和 API 调用
/// 
/// 注意：当前实现完全在线访问，直接调用 API，不存储到本地数据库
/// 后续可以添加缓存层（内存缓存或本地数据库）来优化性能
class PostService {
  final PostApiClient _apiClient;
  final PostTaskManager? _postTaskManager; // 可选，用于后台发布
  final Logger _log = Logger('PostService');

  PostService(
    this._apiClient, {
    PostTaskManager? postTaskManager,
  }) : _postTaskManager = postTaskManager;

  /// 创建帖子（后台任务方式）
  /// 
  /// [userId] 用户 ID
  /// [groupUuid] 圈子 UUID
  /// [caption] 帖子文字说明（可选）
  /// [mediaPaths] 媒体文件路径列表（至少一个）
  /// [mediaAssetIds] 媒体资产 ID 列表（LocalAssetEntity 的 id，可选，如果提供则使用）
  /// 
  /// 返回任务 ID
  /// 
  /// 注意：使用后台任务方式，媒体上传和帖子创建在后台执行
  /// 如果提供了 mediaAssetIds，将使用 LocalAssetEntity 的 assetId 来创建上传任务
  Future<String> createPostTask({
    required String userId,
    required String groupUuid,
    String? caption,
    required List<String> mediaPaths,
    List<String>? mediaAssetIds,
  }) async {
    final postTaskManager = _postTaskManager;
    if (postTaskManager == null) {
      throw StateError('PostTaskManager is not available');
    }

    if (mediaPaths.isEmpty) {
      throw ArgumentError('媒体文件路径列表不能为空');
    }

    if (mediaAssetIds != null && mediaAssetIds.length != mediaPaths.length) {
      throw ArgumentError('媒体文件路径和资产 ID 数量不匹配');
    }

    _log.info('Creating post task: groupUuid=$groupUuid, mediaCount=${mediaPaths.length}');

    final taskId = await postTaskManager.createTask(
      userId: userId,
      groupId: groupUuid,
      caption: caption,
      mediaPaths: mediaPaths,
      mediaAssetIds: mediaAssetIds,
    );

    _log.info('Post task created: taskId=$taskId');
    return taskId;
  }

  /// 创建帖子（直接调用 API，用于内部使用）
  /// 
  /// [groupUuid] 圈子 UUID
  /// [mediaUuids] 媒体 UUID 列表（至少一个）
  /// [caption] 帖子文字说明（可选）
  /// 
  /// 返回创建的帖子信息
  /// 
  /// 注意：媒体需要先上传，传入已上传的 media UUID
  /// 此方法由 PostTaskManager 内部调用
  Future<Post> createPost({
    required String groupUuid,
    required List<String> mediaUuids,
    String? caption,
  }) async {
    try {
      _log.info('Creating post in group: $groupUuid with ${mediaUuids.length} media');
      
      if (mediaUuids.isEmpty) {
        throw ArgumentError('媒体 UUID 列表不能为空');
      }
      
      final post = await _apiClient.createPost(
        groupUuid: groupUuid,
        mediaUuids: mediaUuids,
        caption: caption,
      );
      
      _log.info('Post created successfully: ${post.id}');
      return post;
    } catch (e) {
      _log.severe('Failed to create post: $e', e);
      rethrow;
    }
  }

  /// 获取圈子 Feed 流
  /// 
  /// [groupUuid] 圈子 UUID
  /// [page] 页码（从 1 开始，默认 1）
  /// [limit] 每页数量（默认 20）
  /// 
  /// 返回帖子列表
  /// 
  /// 注意：直接调用 API，不进行缓存
  /// 后续可以添加缓存层（最近访问的帖子、最近 N 条等）
  Future<List<Post>> getGroupFeed({
    required String groupUuid,
    int page = 1,
    int limit = 20,
  }) async {
    _log.info('[PostService] getGroupFeed() called: groupUuid=$groupUuid, page=$page, limit=$limit');
    try {
      _log.info('[PostService] Calling _apiClient.getGroupFeed()');
      
      final posts = await _apiClient.getGroupFeed(
        groupUuid: groupUuid,
        page: page,
        limit: limit,
      );
      
      _log.info('[PostService] _apiClient returned ${posts.length} posts');
      return posts;
    } catch (e, stackTrace) {
      _log.severe('[PostService] Failed to fetch group feed: $e', e, stackTrace);
      rethrow;
    }
  }

  /// 获取帖子详情
  /// 
  /// [groupUuid] 圈子 UUID
  /// [postId] 帖子 ID
  /// 
  /// 返回帖子详情，如果不存在则返回 null
  /// 
  /// 注意：后端可能没有单独的帖子详情 API，这里先预留接口
  /// 后续可以根据后端 API 实现，或通过 Feed 流查找
  Future<Post?> getPostDetail({
    required String groupUuid,
    required int postId,
  }) async {
    try {
      _log.fine('Fetching post detail: $postId in group: $groupUuid');
      
      // 后端可能没有单独的帖子详情 API
      // 这里先返回 null，后续如果需要可以通过 Feed 流查找
      // 或者后端添加了详情 API 后再实现
      final post = await _apiClient.getPostDetail(
        groupUuid: groupUuid,
        postId: postId,
      );
      
      if (post != null) {
        _log.fine('Post detail fetched successfully');
      } else {
        _log.fine('Post detail not found');
      }
      
      return post;
    } catch (e) {
      _log.severe('Failed to fetch post detail: $e', e);
      rethrow;
    }
  }

  /// 删除帖子
  /// 
  /// [groupUuid] 圈子 UUID
  /// [postId] 帖子 ID
  /// 
  /// 注意：后端可能没有删除帖子的 API，这里先预留接口
  Future<void> deletePost({
    required String groupUuid,
    required int postId,
  }) async {
    try {
      _log.info('Deleting post: $postId in group: $groupUuid');
      
      await _apiClient.deletePost(
        groupUuid: groupUuid,
        postId: postId,
      );
      
      _log.info('Post deleted successfully');
    } catch (e) {
      _log.severe('Failed to delete post: $e', e);
      rethrow;
    }
  }
}

