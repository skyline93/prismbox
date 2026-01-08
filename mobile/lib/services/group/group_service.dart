// lib/services/group/group_service.dart

import 'package:logging/logging.dart';
import 'package:prismbox/data/models/group/group.dart';
import 'package:prismbox/data/models/group/group_detail.dart';
import 'package:prismbox/data/models/group/group_invite.dart';
import 'package:prismbox/data/models/group/group_member.dart';
import 'package:prismbox/infrastructure/network/group_api_client.dart';

/// 圈子服务
/// 封装圈子相关的业务逻辑和 API 调用
/// 
/// 注意：当前实现完全在线访问，直接调用 API，不存储到本地数据库
/// 后续可以添加缓存层（内存缓存或本地数据库）来优化性能
class GroupService {
  final GroupApiClient _apiClient;
  final Logger _log = Logger('GroupService');

  GroupService(this._apiClient);

  /// 创建圈子
  /// 
  /// [name] 圈子名称（必填，1-100字符）
  /// [description] 圈子描述（可选）
  /// 
  /// 返回创建的圈子信息
  Future<Group> createGroup({
    required String name,
    String? description,
  }) async {
    try {
      _log.info('Creating group: $name');
      final group = await _apiClient.createGroup(
        name: name,
        description: description,
      );
      _log.info('Group created successfully: ${group.uuid}');
      return group;
    } catch (e) {
      _log.severe('Failed to create group: $e', e);
      rethrow;
    }
  }

  /// 获取我的圈子列表
  /// 
  /// 返回当前用户加入的所有圈子列表
  Future<List<Group>> getMyGroups() async {
    try {
      _log.fine('Fetching my groups');
      final groups = await _apiClient.getMyGroups();
      _log.fine('Fetched ${groups.length} groups');
      return groups;
    } catch (e) {
      _log.severe('Failed to fetch my groups: $e', e);
      rethrow;
    }
  }

  /// 获取圈子详情
  /// 
  /// [groupUuid] 圈子 UUID
  /// 
  /// 返回圈子详情，包含成员统计和当前用户角色
  Future<GroupDetail> getGroupDetails(String groupUuid) async {
    try {
      _log.fine('Fetching group details: $groupUuid');
      final details = await _apiClient.getGroupDetails(groupUuid);
      _log.fine('Group details fetched successfully');
      return details;
    } catch (e) {
      _log.severe('Failed to fetch group details: $e', e);
      rethrow;
    }
  }

  /// 更新圈子信息
  /// 
  /// [groupUuid] 圈子 UUID
  /// [name] 新名称（可选）
  /// [description] 新描述（可选）
  /// 
  /// 返回更新后的圈子信息
  Future<Group> updateGroup({
    required String groupUuid,
    String? name,
    String? description,
  }) async {
    try {
      _log.info('Updating group: $groupUuid');
      final group = await _apiClient.updateGroup(
        groupUuid: groupUuid,
        name: name,
        description: description,
      );
      _log.info('Group updated successfully');
      return group;
    } catch (e) {
      _log.severe('Failed to update group: $e', e);
      rethrow;
    }
  }

  /// 使用邀请码加入圈子
  /// 
  /// [code] 邀请码
  /// 
  /// 返回加入的圈子信息
  Future<Group> joinGroup(String code) async {
    try {
      _log.info('Joining group with code: $code');
      final group = await _apiClient.joinGroup(code);
      _log.info('Joined group successfully: ${group.uuid}');
      return group;
    } catch (e) {
      _log.severe('Failed to join group: $e', e);
      rethrow;
    }
  }

  /// 退出圈子
  /// 
  /// [groupUuid] 圈子 UUID
  /// 
  /// 注意：所有者不能退出圈子
  Future<void> leaveGroup(String groupUuid) async {
    try {
      _log.info('Leaving group: $groupUuid');
      await _apiClient.leaveGroup(groupUuid);
      _log.info('Left group successfully');
    } catch (e) {
      _log.severe('Failed to leave group: $e', e);
      rethrow;
    }
  }

  /// 获取圈子成员列表
  /// 
  /// [groupUuid] 圈子 UUID
  /// 
  /// 返回成员列表
  Future<List<GroupMember>> getGroupMembers(String groupUuid) async {
    try {
      _log.fine('Fetching group members: $groupUuid');
      final members = await _apiClient.getGroupMembers(groupUuid);
      _log.fine('Fetched ${members.length} members');
      return members;
    } catch (e) {
      _log.severe('Failed to fetch group members: $e', e);
      rethrow;
    }
  }

  /// 创建邀请码
  /// 
  /// [groupUuid] 圈子 UUID
  /// 
  /// 返回创建的邀请码信息
  Future<GroupInvite> createInvite(String groupUuid) async {
    try {
      _log.info('Creating invite for group: $groupUuid');
      final invite = await _apiClient.createInvite(groupUuid);
      _log.info('Invite created successfully: ${invite.code}');
      return invite;
    } catch (e) {
      _log.severe('Failed to create invite: $e', e);
      rethrow;
    }
  }

  /// 移除成员
  /// 
  /// [groupUuid] 圈子 UUID
  /// [userId] 要移除的用户 ID
  /// 
  /// 注意：只有管理员或所有者可以移除成员，不能移除所有者
  Future<void> removeMember(String groupUuid, int userId) async {
    try {
      _log.info('Removing member $userId from group: $groupUuid');
      await _apiClient.removeMember(groupUuid, userId);
      _log.info('Member removed successfully');
    } catch (e) {
      _log.severe('Failed to remove member: $e', e);
      rethrow;
    }
  }
}

