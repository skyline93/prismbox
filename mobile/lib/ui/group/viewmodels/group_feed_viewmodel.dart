// lib/ui/group/viewmodels/group_feed_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/domain/repositories/group_repository.dart';
import 'group_feed_state.dart';

class GroupFeedViewModel extends StateNotifier<GroupFeedState> {
  final GroupRepository _groupRepository;
  final String _groupUuid;
  int _currentPage = 1;
  final int _limit = 30; // 每页加载数量

  GroupFeedViewModel(this._groupRepository, this._groupUuid)
      : super(const GroupFeedState.initial()) {
    fetchFirstPage();
  }

  // 核心修正：添加 refresh 方法
  // RefreshIndicator 需要一个返回 Future 的 onRefresh 回调。
  // 这个方法正好满足要求。
  Future<void> refresh() async {
    // 刷新操作的逻辑与获取第一页的逻辑完全相同。
    // 我们重置页码、清空列表并获取最新数据。
    await fetchFirstPage();
  }

  Future<void> fetchFirstPage() async {
    state = const GroupFeedState.loading();
    _currentPage = 1;
    try {
      final items = await _groupRepository.fetchGroupFeed(
        _groupUuid,
        page: _currentPage,
        limit: _limit,
      );
      state = GroupFeedState.loaded(
        mediaItems: items,
        hasReachedMax: items.length < _limit,
      );
    } catch (e) {
      state = GroupFeedState.error(e.toString());
    }
  }

  Future<void> fetchNextPage() async {
    state.maybeWhen(
      loaded: (currentItems, hasReachedMax) async {
        if (hasReachedMax) {
          return;
        }

        _currentPage++;
        try {
          final newItems = await _groupRepository.fetchGroupFeed(
            _groupUuid,
            page: _currentPage,
            limit: _limit,
          );

          state = GroupFeedState.loaded(
            mediaItems: [...currentItems, ...newItems],
            hasReachedMax: newItems.length < _limit,
          );
        } catch (e) {
          _currentPage--;
        }
      },
      orElse: () {},
    );
  }
}
