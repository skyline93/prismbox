// lib/providers/group/group_members_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:prismbox/data/models/group/group_member.dart';
import 'package:prismbox/providers/group/group_list_provider.dart';

part 'group_members_provider.g.dart';

/// 圈子成员列表 Provider
/// 使用 family 参数区分不同的圈子
@riverpod
class GroupMembersProvider extends _$GroupMembersProvider {
  @override
  Future<List<GroupMember>> build(String groupUuid) async {
    // 初始状态：返回空列表
    return [];
  }

  /// 加载成员列表
  Future<void> load() async {
    if (state.isLoading) return; // 防止重复加载

    state = const AsyncValue.loading();
    try {
      final service = ref.read(groupServiceProvider);
      final members = await service.getGroupMembers(groupUuid);
      state = AsyncValue.data(members);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// 刷新成员列表
  Future<void> refresh() async {
    await load();
  }
}

