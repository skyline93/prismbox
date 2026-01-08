// lib/infrastructure/network/group_api_client.dart

import 'package:dio/dio.dart';
import 'package:prismbox/data/models/group/group.dart';
import 'package:prismbox/data/models/group/group_detail.dart';
import 'package:prismbox/data/models/group/group_invite.dart';
import 'package:prismbox/data/models/group/group_member.dart';
import 'package:prismbox/infrastructure/api/api_service.dart';
import 'package:prismbox/infrastructure/api/exceptions/api_exception.dart';
import 'package:prismbox/infrastructure/api/utils/response_validator.dart';

/// 圈子 API 客户端
/// 封装圈子相关的 API 调用
class GroupApiClient {
  final ApiService _apiService;

  GroupApiClient(this._apiService);

  /// 创建圈子
  Future<Group> createGroup({
    required String name,
    String? description,
  }) async {
    try {
      final response = await _apiService.dio.post(
        '/api/v1/groups',
        data: {
          'name': name,
          if (description != null) 'description': description,
        },
      );

      final data = ResponseValidator.validateAndExtract(response);
      return Group.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 获取我的圈子列表
  Future<List<Group>> getMyGroups() async {
    try {
      final response = await _apiService.dio.get('/api/v1/groups');

      // ResponseInterceptor 已经提取了 data 字段
      // 如果 data 是数组，直接使用；如果是 Map，则从 data 字段提取
      final data = response.data;
      if (data is List) {
        return data.map((json) => Group.fromJson(json as Map<String, dynamic>)).toList();
      }
      // 如果 data 是 Map，可能是包装格式，尝试提取
      if (data is Map<String, dynamic>) {
        final listData = data['data'] as List?;
        if (listData != null) {
          return listData.map((json) => Group.fromJson(json as Map<String, dynamic>)).toList();
        }
      }
      return [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 获取圈子详情
  Future<GroupDetail> getGroupDetails(String groupUuid) async {
    try {
      final response = await _apiService.dio.get('/api/v1/groups/$groupUuid');

      final data = ResponseValidator.validateAndExtract(response);
      return GroupDetail.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 更新圈子信息
  Future<Group> updateGroup({
    required String groupUuid,
    String? name,
    String? description,
  }) async {
    try {
      final response = await _apiService.dio.put(
        '/api/v1/groups/$groupUuid',
        data: {
          if (name != null) 'name': name,
          if (description != null) 'description': description,
        },
      );

      final data = ResponseValidator.validateAndExtract(response);
      return Group.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 使用邀请码加入圈子
  Future<Group> joinGroup(String code) async {
    try {
      final response = await _apiService.dio.post(
        '/api/v1/groups/join',
        data: {'code': code},
      );

      final data = ResponseValidator.validateAndExtract(response);
      return Group.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 退出圈子
  Future<void> leaveGroup(String groupUuid) async {
    try {
      await _apiService.dio.post('/api/v1/groups/$groupUuid/leave');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 获取圈子成员列表
  Future<List<GroupMember>> getGroupMembers(String groupUuid) async {
    try {
      final response = await _apiService.dio.get('/api/v1/groups/$groupUuid/members');

      // ResponseInterceptor 已经提取了 data 字段
      final data = response.data;
      if (data is List) {
        return data.map((json) => GroupMember.fromJson(json as Map<String, dynamic>)).toList();
      }
      // 如果 data 是 Map，可能是包装格式，尝试提取
      if (data is Map<String, dynamic>) {
        final listData = data['data'] as List?;
        if (listData != null) {
          return listData.map((json) => GroupMember.fromJson(json as Map<String, dynamic>)).toList();
        }
      }
      return [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 创建邀请码
  Future<GroupInvite> createInvite(String groupUuid) async {
    try {
      final response = await _apiService.dio.post('/api/v1/groups/$groupUuid/members/invite');

      final data = ResponseValidator.validateAndExtract(response);
      return GroupInvite.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 移除成员
  Future<void> removeMember(String groupUuid, int userId) async {
    try {
      await _apiService.dio.delete('/api/v1/groups/$groupUuid/members/$userId');
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

