// lib/ui/group/viewmodels/group_feed_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/domain/repositories/group_repository.dart';
import 'package:mobile/providers/group_providers.dart';
import 'package:mobile/domain/entities/group_feed_item_entity.dart';
import 'group_feed_state.dart';

class GroupFeedViewModel extends StateNotifier<GroupFeedState> {
  final String uuid;
  final Ref ref;
  final GroupRepository _groupRepository;

  GroupFeedViewModel(this.uuid, this.ref)
    : _groupRepository = ref.read(groupRepositoryProvider),
      super(const GroupFeedState()) {
    _initialize();
  }

  void _initialize() {
    ref.listen<AsyncValue<List<GroupFeedItemEntity>>>(
      groupFeedFirstPageProvider(uuid),
      (previous, next) {
        next.when(
          loading: () {
            state = state.copyWith(isLoading: true, errorMessage: null);
          },
          error: (error, stackTrace) {
            state = state.copyWith(
              isLoading: false,
              errorMessage: error.toString(),
            );
          },
          data: (items) {
            state = state.copyWith(
              isLoading: false,
              feedItems: items,
              hasReachedMax: items.isEmpty,
              currentPage: 1,
            );
          },
        );
      },
      fireImmediately: true,
    );
  }

  Future<void> refresh() async {
    ref.invalidate(groupFeedFirstPageProvider(uuid));
  }

  Future<void> fetchNextPage() async {
    if (state.isLoadingNextPage || state.hasReachedMax) return;

    state = state.copyWith(isLoadingNextPage: true);

    try {
      final nextPage = state.currentPage + 1;
      final newItems = await _groupRepository.getGroupFeed(
        uuid,
        page: nextPage,
      );

      if (!mounted) return;

      state = state.copyWith(
        isLoadingNextPage: false,
        feedItems: [...state.feedItems, ...newItems],
        currentPage: nextPage,
        hasReachedMax: newItems.isEmpty,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoadingNextPage: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> createNewPost({
    required String content,
    required List<String> mediaUuids,
  }) async {
    await _groupRepository.createPostInGroup(
      groupId: uuid,
      content: content,
      mediaUuids: mediaUuids,
    );
  }
}
