// lib/providers/post/group_feed_provider.dart
//
// 设计原则参考：
// - OpenSpec: openspec/specs/riverpod-provider-design/spec.md
// - 设计指南: mobile/doc/riverpod-provider-design-principles.md

import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:prismbox/data/models/post/post.dart';
import 'package:prismbox/providers/post/post_providers.dart';

part 'group_feed_provider.g.dart';

/// 圈子 Feed 流 Provider
/// 使用 family 参数区分不同的圈子，管理 Feed 流状态（内存中）
/// 
/// 设计原则：
/// - build() 方法直接加载数据，不返回占位值
/// - 错误时抛出异常，让 Riverpod 处理错误状态
@riverpod
class GroupFeedProvider extends _$GroupFeedProvider {
  final Logger _log = Logger('GroupFeedProvider');

  @override
  Future<List<Post>> build(String groupUuid) async {
    _log.info('[GroupFeedProvider] build() called for groupUuid: $groupUuid');
    
    // 在 build() 中直接加载数据，而不是返回空列表
    // 这样可以避免时序问题，确保数据被正确加载
    try {
      _log.info('[GroupFeedProvider] Loading feed in build()');
      final service = await ref.read(postServiceProvider.future);
      final posts = await service.getGroupFeed(
        groupUuid: groupUuid,
        page: 1,
        limit: 20,
      );
      _log.info('[GroupFeedProvider] Feed loaded in build(): ${posts.length} posts');
      return posts;
    } catch (e, stackTrace) {
      _log.severe('[GroupFeedProvider] Error loading feed in build(): $e', e, stackTrace);
      // 遵循设计原则：错误时抛出异常，让 Riverpod 处理错误状态
      // 参考: openspec/specs/riverpod-provider-design/spec.md
      rethrow;
    }
  }

  /// 加载 Feed 流（第一页）
  Future<void> load({int page = 1, int limit = 20}) async {
    _log.info('[GroupFeedProvider] load() called for groupUuid: $groupUuid, page: $page, limit: $limit');
    _log.info('[GroupFeedProvider] Current state: isLoading=${state.isLoading}, hasValue=${state.hasValue}, hasError=${state.hasError}');
    
    if (state.isLoading) {
      _log.warning('[GroupFeedProvider] Already loading, skipping load() call');
      return; // 防止重复加载
    }

    _log.info('[GroupFeedProvider] Setting state to loading');
    state = const AsyncValue.loading();
    
    try {
      _log.info('[GroupFeedProvider] Reading postServiceProvider');
      final service = await ref.read(postServiceProvider.future);
      _log.info('[GroupFeedProvider] Calling service.getGroupFeed()');
      
      final posts = await service.getGroupFeed(
        groupUuid: groupUuid,
        page: page,
        limit: limit,
      );
      
      _log.info('[GroupFeedProvider] Service returned ${posts.length} posts');
      state = AsyncValue.data(posts);
      _log.info('[GroupFeedProvider] State updated to data with ${posts.length} posts');
    } catch (e, stackTrace) {
      _log.severe('[GroupFeedProvider] Error loading feed: $e', e, stackTrace);
      state = AsyncValue.error(e, stackTrace);
      _log.severe('[GroupFeedProvider] State updated to error');
    }
  }

  /// 刷新 Feed 流（重新加载第一页）
  Future<void> refresh() async {
    await load(page: 1);
  }

  /// 加载更多（下一页）
  /// 返回是否还有更多数据
  Future<bool> loadMore({int limit = 20}) async {
    if (state.isLoading) return false;

    final currentPosts = state.value ?? [];
    if (currentPosts.isEmpty) {
      // 如果当前列表为空，加载第一页
      await load(page: 1, limit: limit);
      return true;
    }

    final nextPage = (currentPosts.length ~/ limit) + 1;

    try {
      final service = await ref.read(postServiceProvider.future);
      final newPosts = await service.getGroupFeed(
        groupUuid: groupUuid,
        page: nextPage,
        limit: limit,
      );

      if (newPosts.isEmpty) {
        return false; // 没有更多数据
      }

      // 合并新数据到现有列表
      final updatedPosts = [...currentPosts, ...newPosts];
      state = AsyncValue.data(updatedPosts);
      return newPosts.length >= limit; // 如果返回的数据量等于 limit，可能还有更多
    } catch (e) {
      // 加载更多失败不影响现有数据
      return false;
    }
  }

  /// 添加新帖子到列表开头（创建帖子后调用）
  void addPost(Post post) {
    final currentPosts = state.value ?? [];
    state = AsyncValue.data([post, ...currentPosts]);
  }

  /// 更新 Feed 流中的单个帖子（例如更新评论数）
  void updatePost(int postId, Post updatedPost) {
    final currentPosts = state.value ?? [];
    final updatedPosts = currentPosts.map((post) {
      if (post.id == postId) {
        return updatedPost;
      }
      return post;
    }).toList();
    state = AsyncValue.data(updatedPosts);
  }
}

