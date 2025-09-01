// lib/domain/repositories/group_repository.dart

import 'package:mobile/data/models/group/group_models.dart';
import 'package:mobile/domain/entities/group_feed_item_entity.dart';

abstract class GroupRepository {
  Future<List<GroupModel>> fetchMyGroups();

  Future<GroupModel> createGroup(String name, {String? description});

  Future<GroupModel> joinGroup(String inviteCode);

  Future<List<CommentModel>> fetchComments(int groupMediaId);

  Future<CommentModel> addComment(int groupMediaId, String content);

  Future<List<GroupMemberModel>> fetchMembers({required String groupUuid});

  Future<GroupModel> fetchGroupDetails(String groupUuid);

  Future<GroupModel> updateGroup(
    String groupUuid, {
    String? name,
    String? description,
  });

  Future<InviteCodeModel> createInviteCode(String groupUuid);

  Future<void> removeMember({
    required String groupUuid,
    required String userId,
  });

  Future<void> leaveGroup(String groupUuid);

  /// 获取指定圈子的Feed流。
  Future<List<GroupFeedItemEntity>> getGroupFeed(
    String groupId, {
    int page = 1,
    int limit = 20,
  });

  Future<void> createPost({
    required String groupUuid,
    required String content,
    required List<String> mediaUuids,
    // replyPermission 字段可以保留，如果后端支持的话
    // ReplyPermission? replyPermission,
  });
}
