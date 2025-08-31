// lib/data/services/group_api_service.dart

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class GroupApiService {
  final Dio _dio;

  GroupApiService(this._dio);

  Future<Response> getMyGroups() {
    return _dio.get('/groups');
  }

  Future<Response> getGroupMembers(String groupUuid) {
    return _dio.get('/groups/$groupUuid/members');
  }

  Future<Response> createGroup(Map<String, dynamic> data) {
    return _dio.post('/groups', data: data);
  }

  Future<Response> joinGroup(String inviteCode) {
    return _dio.post('/groups/join', data: {'code': inviteCode});
  }

  Future<Response> getGroupFeed(String groupUuid, int page, int limit) {
    return _dio.get(
      '/groups/$groupUuid/media',
      queryParameters: {'page': page, 'limit': limit},
    );
  }

  Future<Response> shareMediaToGroup(
    String groupUuid,
    Map<String, dynamic> data,
  ) {
    return _dio.post('/groups/$groupUuid/media', data: data);
  }

  Future<Response> getComments(int groupMediaId) {
    return _dio.get('/group-media/$groupMediaId/comments');
  }

  Future<Response> addComment(int groupMediaId, String content) {
    return _dio.post(
      '/group-media/$groupMediaId/comments',
      data: {'content': content},
    );
  }

  // 获取圈子详情
  Future<Response> getGroupDetails(String groupUuid) {
    return _dio.get('/groups/$groupUuid');
  }

  // 更新圈子信息
  Future<Response> updateGroup(String groupUuid, Map<String, dynamic> data) {
    return _dio.put('/groups/$groupUuid', data: data);
  }

  // 创建邀请码
  Future<Response> createInviteCode(String groupUuid) {
    // 假设后端接口不需要额外参数
    return _dio.post('/groups/$groupUuid/members/invite');
  }

  // 移除成员
  Future<Response> removeMember(String groupUuid, String userId) {
    return _dio.delete('/groups/$groupUuid/members/$userId');
  }

  // 主动退出圈子
  Future<Response> leaveGroup(String groupUuid) {
    // 假设后端接口为 POST /groups/{uuid}/leave
    return _dio.post('/groups/$groupUuid/leave');
  }
}
