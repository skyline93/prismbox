// lib/providers/group/group_list_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:prismbox/data/models/group/group.dart';
import 'package:prismbox/infrastructure/network/group_api_client.dart';
import 'package:prismbox/providers/infrastructure/api_service_provider.dart';
import 'package:prismbox/services/group/group_service.dart';

part 'group_list_provider.g.dart';

/// GroupApiClient Provider
@riverpod
GroupApiClient groupApiClient(GroupApiClientRef ref) {
  final apiService = ref.watch(apiServiceProvider);
  return GroupApiClient(apiService);
}

/// GroupService Provider
@riverpod
GroupService groupService(GroupServiceRef ref) {
  final apiClient = ref.watch(groupApiClientProvider);
  return GroupService(apiClient);
}

/// 圈子列表状态
enum GroupListState {
  initial,
  loading,
  loaded,
  error,
}

/// 圈子列表 Provider
/// 管理圈子列表的状态（内存中）
@riverpod
class GroupListProvider extends _$GroupListProvider {
  @override
  Future<List<Group>> build() async {
    // 初始状态：返回空列表
    return [];
  }

  /// 加载圈子列表
  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(groupServiceProvider);
      final groups = await service.getMyGroups();
      state = AsyncValue.data(groups);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// 刷新圈子列表
  Future<void> refresh() async {
    await load();
  }
}

