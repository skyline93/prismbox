// lib/data/repositories/group_repository_impl.dart

import 'package:injectable/injectable.dart';
import 'package:mobile/data/models/media/media_model.dart'; // 导入ApiResponse
import 'package:mobile/data/models/group/group_models.dart';
import 'package:mobile/data/services/group_api_service.dart';
import 'package:mobile/domain/repositories/group_repository.dart';

@LazySingleton(as: GroupRepository) // 关键：将实现绑定到接口
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
  Future<List<GroupMediaModel>> fetchGroupFeed(String groupUuid, {int page = 1, int limit = 30}) async {
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
  Future<void> shareMediaToGroup(String groupUuid, {required List<String> mediaUuids, String? caption}) async {
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
  Future<List<GroupMemberModel>> fetchMembers({required String groupUuid}) async {
    // 假设你的 GroupApiService 中有一个 getGroupMembers 方法
    final response = await _apiService.getGroupMembers(groupUuid); 
    final apiResponse = ApiResponse.fromJson(
      response.data,
      (json) => (json as List<dynamic>)
          .map((item) => GroupMemberModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
    return apiResponse.data ?? [];
  }
}
