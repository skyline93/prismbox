// lib/providers/group_providers.dart

import 'dart:typed_data';
import 'package:tuple/tuple.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/service_locator.dart';
import 'package:mobile/data/models/group/group_models.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/domain/repositories/group_repository.dart';
import 'package:mobile/ui/group/viewmodels/group_feed_viewmodel.dart';
import 'package:mobile/ui/group/viewmodels/group_feed_state.dart';
import 'package:mobile/domain/entities/group_feed_item_entity.dart';
import 'package:mobile/providers/providers.dart';
import 'package:mobile/ui/group/viewmodels/post_detail_state.dart';
import 'package:mobile/ui/group/viewmodels/post_detail_viewmodel.dart';
// import 'package:mobile/data/mock_feed_data.dart';

// 1. Repository Provider
// 职责：作为 Riverpod 与 GetIt/Injectable 依赖注入框架之间的桥梁。
// 它简单地从 getIt 容器中获取已注册的 GroupRepository 单例，
// 以便在 Riverpod 的生态系统中使用。
final groupRepositoryProvider = Provider<GroupRepository>(
  (ref) => getIt<GroupRepository>(),
);

// 2. 获取圈子列表的 Provider
// 类型：FutureProvider
// 职责：异步获取当前用户加入的所有圈子列表。
// 适用场景：非常适合一次性获取且不常变化的列表数据。
// 特性：`.autoDispose` 会在没有任何监听者时自动销毁状态，节省内存。
final groupListProvider = FutureProvider.autoDispose<List<GroupModel>>((ref) {
  // `ref.watch` 会监听 `groupRepositoryProvider`。如果未来 repository 有变化，
  // 这个 Provider 会自动重新执行。
  final groupRepository = ref.watch(groupRepositoryProvider);
  return groupRepository.fetchMyGroups();
});

// 3. 获取圈子成员列表的 Provider
// 类型：FutureProvider.family
// 职责：根据传入的圈子 UUID，异步获取该圈子的成员列表。
// 适用场景：当异步 Provider 需要一个外部参数来执行其逻辑时。
// 补全：已移除占位符，现在会调用真实的 repository 方法。
final groupMembersProvider = FutureProvider.autoDispose
    .family<List<GroupMemberModel>, String>((ref, String groupUuid) {
      final groupRepository = ref.watch(groupRepositoryProvider);
      // 核心修正：现在这个调用是有效的，因为它匹配了接口中新定义的方法签名
      return groupRepository.fetchMembers(groupUuid: groupUuid);
    });

// 4. 圈子 Feed 流的 ViewModel Provider
// 类型：StateNotifierProvider.family
// 职责：管理特定圈子 Feed 页面的复杂状态，包括分页加载、错误处理和刷新。
// 适用场景：当状态不是一个简单的 Future，而是需要包含业务逻辑、可以被用户交互改变的复杂对象时。
final groupFeedViewModelProvider = StateNotifierProvider.autoDispose
    .family<GroupFeedViewModel, GroupFeedState, String>(
      // --- 2. 修正构造函数参数 ---
      (ref, uuid) => GroupFeedViewModel(uuid, ref),
    );

// 5. 获取评论列表的 Provider
// 类型：FutureProvider.family
// 职责：根据传入的 groupMediaId，异步获取该媒体项下的所有评论。
// 适用场景：需要根据参数获取一次性数据列表。
final commentsProvider = FutureProvider.autoDispose
    .family<List<CommentModel>, int>((ref, int groupMediaId) {
      final groupRepository = ref.watch(groupRepositoryProvider);
      return groupRepository.fetchComments(groupMediaId);
    });

/// 6. 获取圈子详细信息的 Provider
/// 职责：提供一个圈子的完整信息，特别是包含当前用户的角色，用于权限判断。
final groupDetailsProvider = FutureProvider.autoDispose
    .family<GroupModel, String>((ref, String groupUuid) {
      final groupRepository = ref.watch(groupRepositoryProvider);
      return groupRepository.fetchGroupDetails(groupUuid);
    });

final groupFeedFirstPageProvider = FutureProvider.autoDispose
    .family<List<GroupFeedItemEntity>, String>((ref, uuid) async {
      // await Future.delayed(const Duration(milliseconds: 800));

      // 直接返回 mock 数据列表
      // return getMockFeedItems();

      final groupRepository = ref.watch(groupRepositoryProvider);
      return groupRepository.getGroupFeed(uuid, page: 1);
    });

final groupPostThumbnailProvider =
    FutureProvider.family<Uint8List?, Tuple2<UnifiedMediaEntity, String>>((
      ref,
      args,
    ) async {
      final entity = args.item1;
      final groupUuid = args.item2;

      if (entity.cloudUuid == '' || entity.cloudUuid!.isEmpty) {
        debugPrint("提供的entity不是云类型!!!");
      }

      final cache = ref.read(thumbnailCacheProvider);
      final cacheKey = '${entity.id}_${entity.localId ?? entity.cloudUuid}';

      if (cache.containsKey(cacheKey)) {
        return cache[cacheKey];
      }

      final repo = ref.read(groupRepositoryProvider);
      final thumbnailData = await repo.downloadGroupMediaThumbnail(
        groupUuid,
        entity.cloudUuid!,
      );

      ref
          .read(thumbnailCacheProvider.notifier)
          .addToCache(cacheKey, thumbnailData);

      return thumbnailData;
    });

/// Provider to get the full-resolution media attachment for a group post.
final groupPostFullImageProvider = FutureProvider.autoDispose
    .family<Uint8List?, Tuple2<UnifiedMediaEntity, String>>((
      ref,
      params,
    ) async {
      final groupRepository = ref.watch(groupRepositoryProvider);
      final entity = params.item1;
      final groupUuid = params.item2;

      return groupRepository.downloadGroupMediaPreview(
        groupUuid,
        entity.cloudUuid!,
      );
    });

final postDetailViewModelProvider = StateNotifierProvider.autoDispose
    .family<PostDetailViewModel, PostDetailState, int>((ref, postId) {
      final groupRepository = ref.watch(groupRepositoryProvider);
      return PostDetailViewModel(groupRepository, postId);
    });
