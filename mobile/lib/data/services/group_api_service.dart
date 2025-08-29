// lib/data/services/group_api_service.dart

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class GroupApiService {
  final Dio _dio;

  // Dio 实例将由 get_it 通过 InjectableModule 自动注入
  GroupApiService(this._dio);

  // 获取用户加入的圈子列表
  Future<Response> getMyGroups() {
    return _dio.get('/groups');
  }
  
  // 新增：获取圈子成员列表
  // 根据你的项目蓝图，端点是 GET /groups/{uuid}/members
  Future<Response> getGroupMembers(String groupUuid) {
    return _dio.get('/groups/$groupUuid/members');
  }

  // 创建圈子
  Future<Response> createGroup(Map<String, dynamic> data) {
    return _dio.post('/groups', data: data);
  }

  // 使用邀请码加入圈子
  Future<Response> joinGroup(String inviteCode) {
    return _dio.post('/groups/join', data: {'code': inviteCode});
  }

  // 分页获取圈子 Feed
  Future<Response> getGroupFeed(String groupUuid, int page, int limit) {
    return _dio.get(
      '/groups/$groupUuid/media',
      queryParameters: {'page': page, 'limit': limit},
    );
  }

  // 分享媒体到圈子
  Future<Response> shareMediaToGroup(String groupUuid, Map<String, dynamic> data) {
    return _dio.post('/groups/$groupUuid/media', data: data);
  }

  // 获取评论列表
  Future<Response> getComments(int groupMediaId) {
    return _dio.get('/group-media/$groupMediaId/comments');
  }

  // 添加评论
  Future<Response> addComment(int groupMediaId, String content) {
    return _dio.post(
      '/group-media/$groupMediaId/comments',
      data: {'content': content},
    );
  }
}
