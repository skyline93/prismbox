// lib/domain/repositories/group_repository.dart

import 'package:mobile/data/models/group/group_models.dart';

abstract class GroupRepository {
  Future<List<GroupModel>> fetchMyGroups();

  Future<GroupModel> createGroup(String name, {String? description});

  Future<GroupModel> joinGroup(String inviteCode);
  
  Future<List<GroupMediaModel>> fetchGroupFeed(String groupUuid, {int page = 1, int limit = 30});

  Future<void> shareMediaToGroup(String groupUuid, {required List<String> mediaUuids, String? caption});
  
  Future<List<CommentModel>> fetchComments(int groupMediaId);

  Future<CommentModel> addComment(int groupMediaId, String content);

  Future<List<GroupMemberModel>> fetchMembers({required String groupUuid});
}
