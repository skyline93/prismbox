// lib/data/repositories/group_repository_impl.dart

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:mobile/data/models/media/media_model.dart';
import 'package:mobile/data/models/group/group_models.dart';
import 'package:mobile/data/services/group_api_service.dart';
import 'package:mobile/domain/repositories/group_repository.dart';
import 'package:mobile/domain/entities/group_feed_item_entity.dart';
import 'package:mobile/domain/entities/comment_entity.dart';

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
    final response = await _apiService.getGroupFeed(groupUuid, page, limit);

    final apiResponse = ApiResponse.fromJson(
      response.data,
      (json) => (json as List<dynamic>)
          .map((item) => GroupPostModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );

    final List<GroupPostModel> groupPostModels = apiResponse.data ?? [];

    return groupPostModels
        .map((model) => GroupFeedItemEntity.fromGroupPostModel(model))
        .toList();
  }

  @override
  Future<void> createPost({
    required String groupUuid,
    required String content,
    required List<String> mediaUuids,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'caption': content,
        'media_uuids': mediaUuids,
      };
      await _apiService.createPost(groupUuid, data);
    } on DioException catch (e) {
      throw Exception('Failed to create post: ${e.message}');
    }
  }

  @override
  Future<List<CommentModel>> fetchComments(int postId) async {
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

  @override
  Future<List<CommentEntity>> getComments(int postId) async {
    try {
      final response = await _apiService.getPostComments(postId.toString());
      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => (json as List<dynamic>)
            .map((item) => CommentModel.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
      final List<CommentModel> commentModels = apiResponse.data ?? [];
      return commentModels.map((model) => model.toEntity()).toList();
    } on DioException catch (e) {
      throw Exception('Failed to fetch comments: ${e.message}');
    }
  }

  @override
  Future<CommentEntity> postComment({
    required int postId,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'content': content,
        if (parentCommentId != null) 'parent_comment_id': parentCommentId,
      };
      final response = await _apiService.createComment(postId.toString(), data);
      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => CommentModel.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data!.toEntity();
    } on DioException catch (e) {
      throw Exception('Failed to post comment: ${e.message}');
    }
  }
}
