//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

import 'package:prismbox/infrastructure/api/generated/lib/api.dart';
import 'package:test/test.dart';


/// tests for GroupsApi
void main() {
  // final instance = GroupsApi();

  group('tests for GroupsApi', () {
    // 获取我的圈子列表
    //
    // 获取当前用户加入的所有圈子列表（需要认证）
    //
    //Future<ResponseApiResponse> groupsGet() async
    test('test groupsGet', () async {
      // TODO
    });

    // 加入圈子
    //
    // 使用邀请码加入圈子（需要认证）
    //
    //Future<ResponseApiResponse> groupsJoinPost(DtoJoinGroupInput input) async
    test('test groupsJoinPost', () async {
      // TODO
    });

    // 创建圈子
    //
    // 创建一个新的圈子（需要认证）
    //
    //Future<ResponseApiResponse> groupsPost(DtoCreateGroupInput input) async
    test('test groupsPost', () async {
      // TODO
    });

    // 获取圈子详情
    //
    // 获取指定圈子的详细信息（需要认证，必须是圈子成员）
    //
    //Future<ResponseApiResponse> groupsUuidGet(String uuid) async
    test('test groupsUuidGet', () async {
      // TODO
    });

    // 退出圈子
    //
    // 退出指定的圈子（需要认证，所有者不能退出）
    //
    //Future<ResponseApiResponse> groupsUuidLeavePost(String uuid) async
    test('test groupsUuidLeavePost', () async {
      // TODO
    });

    // 获取圈子媒体预览图
    //
    // 获取圈子中媒体的预览图（需要认证，必须是圈子成员）
    //
    //Future groupsUuidMediaMediaUuidPreviewGet(String uuid, String mediaUuid) async
    test('test groupsUuidMediaMediaUuidPreviewGet', () async {
      // TODO
    });

    // 获取圈子媒体缩略图
    //
    // 获取圈子中媒体的缩略图（需要认证，必须是圈子成员）
    //
    //Future groupsUuidMediaMediaUuidThumbnailGet(String uuid, String mediaUuid) async
    test('test groupsUuidMediaMediaUuidThumbnailGet', () async {
      // TODO
    });

    // 获取圈子成员列表
    //
    // 获取指定圈子的所有成员列表（需要认证，必须是圈子成员）
    //
    //Future<ResponseApiResponse> groupsUuidMembersGet(String uuid) async
    test('test groupsUuidMembersGet', () async {
      // TODO
    });

    // 创建邀请码
    //
    // 为圈子创建新的邀请码（需要认证，必须是圈子管理员或所有者）
    //
    //Future<ResponseApiResponse> groupsUuidMembersInvitePost(String uuid) async
    test('test groupsUuidMembersInvitePost', () async {
      // TODO
    });

    // 移除成员
    //
    // 从圈子中移除指定成员（需要认证，必须是圈子管理员或所有者，不能移除所有者）
    //
    //Future<ResponseApiResponse> groupsUuidMembersUserIdDelete(String uuid, String userId) async
    test('test groupsUuidMembersUserIdDelete', () async {
      // TODO
    });

    // 更新圈子信息
    //
    // 更新圈子的名称和描述（需要认证，必须是圈子管理员或所有者）
    //
    //Future<ResponseApiResponse> groupsUuidPut(String uuid, DtoUpdateGroupInput input) async
    test('test groupsUuidPut', () async {
      // TODO
    });

  });
}
