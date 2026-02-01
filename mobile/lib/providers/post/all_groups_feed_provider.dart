// lib/providers/post/all_groups_feed_provider.dart
//
// 全部圈子 Feed 流 Provider（无参）
// 与 GroupFeedProvider(groupUuid) 并存，Feed 页根据选中「全部」或某圈切换数据源。

import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:prismbox/data/models/post/post.dart';
import 'package:prismbox/providers/post/post_providers.dart';

part 'all_groups_feed_provider.g.dart';

@riverpod
class AllGroupsFeedProvider extends _$AllGroupsFeedProvider {
  final Logger _log = Logger('AllGroupsFeedProvider');

  @override
  Future<List<Post>> build() async {
    _log.info('[AllGroupsFeedProvider] build() called');
    try {
      final service = await ref.read(postServiceProvider.future);
      final posts = await service.getMyFeed(page: 1, limit: 20);
      _log.info('[AllGroupsFeedProvider] Feed loaded: ${posts.length} posts');
      return posts;
    } catch (e, stackTrace) {
      _log.severe('[AllGroupsFeedProvider] Error loading feed: $e', e, stackTrace);
      rethrow;
    }
  }

  Future<void> load({int page = 1, int limit = 20}) async {
    if (state.isLoading) return;
    state = const AsyncValue.loading();
    try {
      final service = await ref.read(postServiceProvider.future);
      final posts = await service.getMyFeed(page: page, limit: limit);
      state = AsyncValue.data(posts);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> refresh() async {
    await load(page: 1);
  }

  Future<bool> loadMore({int limit = 20}) async {
    if (state.isLoading) return false;
    final currentPosts = state.value ?? [];
    if (currentPosts.isEmpty) {
      await load(page: 1, limit: limit);
      return true;
    }
    final nextPage = (currentPosts.length ~/ limit) + 1;
    try {
      final service = await ref.read(postServiceProvider.future);
      final newPosts = await service.getMyFeed(page: nextPage, limit: limit);
      if (newPosts.isEmpty) return false;
      final existingIds = currentPosts.map((p) => p.id).toSet();
      final uniqueNew = newPosts.where((p) => !existingIds.contains(p.id)).toList();
      if (uniqueNew.isEmpty) return false;
      state = AsyncValue.data([...currentPosts, ...uniqueNew]);
      return uniqueNew.length >= limit;
    } catch (e) {
      return false;
    }
  }

  void addPost(Post post) {
    final current = state.value ?? [];
    state = AsyncValue.data([post, ...current]);
  }

  void updatePost(int postId, Post updatedPost) {
    final current = state.value ?? [];
    state = AsyncValue.data(current.map((p) => p.id == postId ? updatedPost : p).toList());
  }
}
