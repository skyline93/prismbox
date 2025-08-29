import 'package:injectable/injectable.dart';
import 'package:mobile/data/models/media/media_model.dart';
import 'package:mobile/data/models/group/group_models.dart';
import 'package:mobile/data/services/group_api_service.dart';
import 'package:mobile/domain/repositories/group_repository.dart';

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
  Future<List<GroupMediaModel>> fetchGroupFeed(
    String groupUuid, {
    int page = 1,
    int limit = 30,
  }) async {
    final response = await _apiService.getGroupFeed(groupUuid, page, limit);
    final apiResponse = ApiResponse.fromJson(
      response.data,
      (json) => (json as List<dynamic>)
          .map((item) => GroupMediaModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
    return apiResponse.data ?? [];
  }

  @override
  Future<void> shareMediaToGroup(
    String groupUuid, {
    required List<String> mediaUuids,
    String? caption,
  }) async {
    await _apiService.shareMediaToGroup(groupUuid, {
      'media_uuids': mediaUuids,
      if (caption != null) 'caption': caption,
    });
  }

  @override
  Future<List<CommentModel>> fetchComments(int groupMediaId) async {
    final response = await _apiService.getComments(groupMediaId);
    final apiResponse = ApiResponse.fromJson(
      response.data,
      (json) => (json as List<dynamic>)
          .map((item) => CommentModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
    return apiResponse.data ?? [];
  }

  @override
  Future<CommentModel> addComment(int groupMediaId, String content) async {
    final response = await _apiService.addComment(groupMediaId, content);
    final apiResponse = ApiResponse.fromJson(
      response.data,
      (json) => CommentModel.fromJson(json as Map<String, dynamic>),
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

  // === M4 新增实现 ===

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
}
