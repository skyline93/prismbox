// lib/providers/post/post_detail_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:prismbox/data/models/post/post.dart';
import 'package:prismbox/providers/post/post_providers.dart';

part 'post_detail_provider.g.dart';

/// 帖子详情 Provider
/// 管理帖子详情状态（内存中）
/// 使用 family 参数，参数为 "{groupUuid}:{postId}"
@riverpod
class PostDetailProvider extends _$PostDetailProvider {
  @override
  Future<Post?> build(String key) async {
    // 初始状态：返回 null
    return null;
  }

  /// 加载帖子详情
  Future<void> load(String groupUuid, int postId) async {
    if (state.isLoading) return; // 防止重复加载

    state = const AsyncValue.loading();
    try {
      final service = await ref.read(postServiceProvider.future);
      final post = await service.getPostDetail(
        groupUuid: groupUuid,
        postId: postId,
      );
      state = AsyncValue.data(post);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// 刷新帖子详情
  Future<void> refresh(String groupUuid, int postId) async {
    await load(groupUuid, postId);
  }

  /// 更新帖子（例如，评论数增加后）
  void updatePost(Post post) {
    state = AsyncValue.data(post);
  }
}

