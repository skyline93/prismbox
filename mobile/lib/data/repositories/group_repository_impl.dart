// lib/data/repositories/group_repository_impl.dart

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:mobile/data/models/media/media_model.dart';
import 'package:mobile/data/models/group/group_models.dart';
import 'package:mobile/data/services/group_api_service.dart';
import 'package:mobile/domain/repositories/group_repository.dart';
import 'package:mobile/domain/entities/group_feed_item_entity.dart';

@LazySingleton(as: GroupRepository)
class GroupRepositoryImpl implements GroupRepository {
  final GroupApiService _apiService;

  GroupRepositoryImpl(this._apiService);

  @override
  Future<List<GroupModel>> fetchMyGroups() async {
    final response = await _apiService.getMyGroups();
    final apiResponse = ApiResponse.fromJson(
      response.data,
      (json) => (json as List<dynamic>)
          .map((item) => GroupModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
    return apiResponse.data ?? [];
  }

  @override
  Future<GroupModel> createGroup(String name, {String? description}) async {
    final response = await _apiService.createGroup({
      'name': name,
      if (description != null) 'description': description,
    });
    final apiResponse = ApiResponse.fromJson(
      response.data,
      (json) => GroupModel.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }

  @override
  Future<GroupModel> joinGroup(String inviteCode) async {
    final response = await _apiService.joinGroup(inviteCode);
    final apiResponse = ApiResponse.fromJson(
      response.data,
      (json) => GroupModel.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }

  @override
  Future<List<GroupMemberModel>> fetchMembers({
    required String groupUuid,
  }) async {
    final response = await _apiService.getGroupMembers(groupUuid);
    final apiResponse = ApiResponse.fromJson(
      response.data,
      (json) => (json as List<dynamic>)
          .map(
            (item) => GroupMemberModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
    return apiResponse.data ?? [];
  }

  @override
  Future<GroupModel> fetchGroupDetails(String groupUuid) async {
    final response = await _apiService.getGroupDetails(groupUuid);
    final apiResponse = ApiResponse.fromJson(
      response.data,
      (json) => GroupModel.fromJson(json as Map<String, dynamic>),
    );
    // 假设 GroupModel 中包含了当前用户的角色信息
    return apiResponse.data!;
  }

  @override
  Future<GroupModel> updateGroup(
    String groupUuid, {
    String? name,
    String? description,
  }) async {
    final response = await _apiService.updateGroup(groupUuid, {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
    });
    final apiResponse = ApiResponse.fromJson(
      response.data,
      (json) => GroupModel.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }

  @override
  Future<InviteCodeModel> createInviteCode(String groupUuid) async {
    final response = await _apiService.createInviteCode(groupUuid);
    final apiResponse = ApiResponse.fromJson(
      response.data,
      (json) => InviteCodeModel.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }

  @override
  Future<void> removeMember({
    required String groupUuid,
    required String userId,
  }) async {
    await _apiService.removeMember(groupUuid, userId);
  }

  @override
  Future<void> leaveGroup(String groupUuid) async {
    await _apiService.leaveGroup(groupUuid);
  }

  @override
  Future<List<GroupFeedItemEntity>> getGroupFeed(
    String groupUuid, {
    int page = 1,
    int limit = 20,
  }) async {
    // 1. 调用更新后的API服务 (假设它现在请求 GET /groups/{uuid}/feed)
    final response = await _apiService.getGroupFeed(groupUuid, page, limit);

    // 2. 使用 ApiResponse 解析，但将内部转换器从 GroupMediaModel 切换为 GroupPostModel
    final apiResponse = ApiResponse.fromJson(
      response.data,
      (json) => (json as List<dynamic>)
          .map((item) => GroupPostModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );

    // 3. 安全地获取解析后的数据模型列表
    final List<GroupPostModel> groupPostModels = apiResponse.data ?? [];

    // 4. 将新的 `GroupPostModel` 列表映射为领域实体 `GroupFeedItemEntity` 列表
    //    这里会调用我们在上一步改造好的 `fromGroupPostModel` 工厂方法
    return groupPostModels
        .map((model) => GroupFeedItemEntity.fromGroupPostModel(model))
        .toList();
  }

  @override
  Future<void> createPost({
    required String groupUuid,
    required String content,
    required List<String> mediaUuids,
    // replyPermission 字段可以保留，如果后端支持的话
    // ReplyPermission? replyPermission,
  }) async {
    try {
      // 构建请求体以匹配新的 `POST /groups/{uuid}/posts` API
      final Map<String, dynamic> data = {
        'caption': content,
        'media_uuids': mediaUuids,
        // 如果后端实现了 reply_permission，可以取消这行注释
        // if (replyPermission != null) 'reply_permission': replyPermission.toJson(),
      };
      // 调用更新后的 ApiService 方法
      await _apiService.createPost(groupUuid, data);
    } on DioException catch (e) {
      // 良好的错误处理
      throw Exception('Failed to create post: ${e.message}');
    }
  }

  @override
  Future<List<CommentModel>> fetchComments(int postId) async {
    // <-- 参数从 groupMediaId 变为 postId
    // 假设 ApiService 也已更新
    final response = await _apiService.getComments(postId);
    final apiResponse = ApiResponse.fromJson(
      response.data,
      (json) => (json as List<dynamic>)
          .map((item) => CommentModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
    return apiResponse.data ?? [];
  }

  @override
  Future<CommentModel> addComment(int postId, String content) async {
    // <-- 参数从 groupMediaId 变为 postId
    // 假设 ApiService 也已更新
    final response = await _apiService.addComment(postId, content);
    final apiResponse = ApiResponse.fromJson(
      response.data,
      (json) => CommentModel.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }

  @override
  Future<Uint8List> downloadGroupMediaThumbnail(
    String groupUuid,
    String mediaUuid,
  ) async {
    final thumbnailData = await _apiService.downloadGroupMediaThumbnail(
      groupUuid,
      mediaUuid,
    );
    return thumbnailData;
  }

  @override
  Future<Uint8List> downloadGroupMediaPreview(
    String groupUuid,
    String mediaUuid,
  ) async {
    final thumbnailData = await _apiService.downloadGroupMediaPreview(
      groupUuid,
      mediaUuid,
    );
    return thumbnailData;
  }
}
