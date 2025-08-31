import 'package:mobile/data/models/group/group_models.dart';
import 'package:mobile/domain/entities/group_feed_item_entity.dart';

abstract class GroupRepository {
  Future<List<GroupModel>> fetchMyGroups();

  Future<GroupModel> createGroup(String name, {String? description});

  Future<GroupModel> joinGroup(String inviteCode);

  Future<List<GroupMediaModel>> fetchGroupFeed(
    String groupUuid, {
    int page = 1,
    int limit = 30,
  });

  Future<void> shareMediaToGroup(
    String groupUuid, {
    required List<String> mediaUuids,
    String? caption,
  });

  Future<List<CommentModel>> fetchComments(int groupMediaId);

  Future<CommentModel> addComment(int groupMediaId, String content);

  Future<List<GroupMemberModel>> fetchMembers({required String groupUuid});

  // === M4 新增接口 ===

  /// 获取圈子详细信息，包括当前用户的角色
  Future<GroupModel> fetchGroupDetails(String groupUuid);

  /// 更新圈子信息
  Future<GroupModel> updateGroup(
    String groupUuid, {
    String? name,
    String? description,
  });

  /// 创建邀请码
  Future<InviteCodeModel> createInviteCode(String groupUuid);

  /// 从圈子移除成员 (管理员/圈主操作)
  Future<void> removeMember({
    required String groupUuid,
    required String userId,
  });

  /// 成员主动退出圈子
  Future<void> leaveGroup(String groupUuid);

    /// 获取指定圈子的Feed流。
  Future<List<GroupFeedItemEntity>> getGroupFeed(
    String groupId, {
    int page = 1,
    int limit = 20,
  });

  /// 在圈子中创建新帖子（分享媒体）。
  Future<void> createPostInGroup({
    required String groupId,
    required String content,
    required List<String> mediaUuids,
  });
}
