// lib/presentation/pages/groups/group_feed_page.dart
//
// 圈子 Feed 页：Tab 默认页，包含圈子选择器（全部 + 用户加入的圈子）、Feed 列表、
// 空状态；选中「全部」时用 AllGroupsFeedProvider，选中某圈时用 GroupFeedProvider。
// 发帖 FAB 仅在选中单圈时显示。

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:prismbox/data/models/group/group.dart';
import 'package:prismbox/data/models/post/post.dart';
import 'package:prismbox/presentation/routing/app_router.dart';
import 'package:prismbox/presentation/widgets/posts/post_card.dart';
import 'package:prismbox/providers/group/group_list_provider.dart';
import 'package:prismbox/providers/post/all_groups_feed_provider.dart';
import 'package:prismbox/providers/post/group_feed_provider.dart';

@RoutePage()
class GroupFeedPage extends ConsumerStatefulWidget {
  const GroupFeedPage({super.key});

  @override
  ConsumerState<GroupFeedPage> createState() => _GroupFeedPageState();
}

class _GroupFeedPageState extends ConsumerState<GroupFeedPage> {
  String? _selectedGroupUuid; // null = 全部
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _isFabVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(groupListProviderProvider.notifier).load();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.userScrollDirection ==
            ScrollDirection.reverse &&
        _isFabVisible) {
      setState(() => _isFabVisible = false);
    } else if (_scrollController.position.userScrollDirection ==
            ScrollDirection.forward &&
        !_isFabVisible) {
      setState(() => _isFabVisible = true);
    }
    if (_isLoadingMore || !_hasMore) return;
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final bool hasMore;
      if (_selectedGroupUuid == null) {
        hasMore = await ref
            .read(allGroupsFeedProviderProvider.notifier)
            .loadMore();
      } else {
        hasMore = await ref
            .read(groupFeedProviderProvider(_selectedGroupUuid!).notifier)
            .loadMore();
      }
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _hasMore = hasMore;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _onRefresh() async {
    setState(() => _hasMore = true);
    if (_selectedGroupUuid == null) {
      await ref.read(allGroupsFeedProviderProvider.notifier).refresh();
    } else {
      await ref.read(groupFeedProviderProvider(_selectedGroupUuid!).notifier).refresh();
    }
    await ref.read(groupListProviderProvider.notifier).refresh();
  }

  void _showCreatePost() {
    if (_selectedGroupUuid == null) return;
    context.router.push(CreatePostRoute(groupUuid: _selectedGroupUuid!));
  }

  void _onSelectGroup(String? uuid) {
    setState(() {
      _selectedGroupUuid = uuid;
      _hasMore = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupListProviderProvider);
    final feedAsync = _selectedGroupUuid == null
        ? ref.watch(allGroupsFeedProviderProvider)
        : ref.watch(groupFeedProviderProvider(_selectedGroupUuid!));

    final groups = groupsAsync.valueOrNull ?? <Group>[];
    final selectedGroup = _selectedGroupUuid == null
        ? null
        : groups.where((g) => g.uuid == _selectedGroupUuid).firstOrNull;
    final String appBarTitle = _selectedGroupUuid == null
        ? '全部动态'
        : (selectedGroup?.name ?? '圈子');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text(
          appBarTitle,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.list, size: 18),
            label: const Text('我的圈子'),
            style: TextButton.styleFrom(foregroundColor: Colors.black87),
            onPressed: () => context.router.push(const GroupListRoute()),
          ),
          TextButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('创建'),
            style: TextButton.styleFrom(foregroundColor: Colors.black87),
            onPressed: () => context.router.push(const CreateGroupRoute()),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGroupSelector(groups),
          Expanded(
            child: _buildBody(groups, feedAsync),
          ),
        ],
      ),
      floatingActionButton: _selectedGroupUuid != null && _isFabVisible
          ? FloatingActionButton(
              onPressed: _showCreatePost,
              tooltip: '发帖',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildGroupSelector(List<Group> groups) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _buildChip('全部', selected: _selectedGroupUuid == null, onTap: () => _onSelectGroup(null)),
          ...groups.map<Widget>((g) => _buildChip(
                g.name,
                selected: _selectedGroupUuid == g.uuid,
                onTap: () => _onSelectGroup(g.uuid),
              )),
        ],
      ),
    );
  }

  Widget _buildChip(String label, {required bool selected, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }

  Widget _buildBody(List<Group> groups, AsyncValue<List<Post>> feedAsync) {
    if (groups.isEmpty && !feedAsync.isLoading) {
      return _buildNoGroupsEmpty();
    }
    return feedAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return _buildNoPostsEmpty();
        }
        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: posts.length + (_isLoadingMore ? 1 : 0) + (!_hasMore && posts.isNotEmpty ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == posts.length && _isLoadingMore) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (index == posts.length + (_isLoadingMore ? 1 : 0) && !_hasMore && posts.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      '没有更多内容了',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                    ),
                  ),
                );
              }
              final post = posts[index];
              return PostCard(
                post: post,
                onTap: () {
                  final uuid = post.groupUuid ?? _selectedGroupUuid;
                  if (uuid != null) {
                    context.router.push(PostDetailRoute(groupUuid: uuid, postId: post.id));
                  }
                },
                onCommentTap: () {
                  final uuid = post.groupUuid ?? _selectedGroupUuid;
                  if (uuid != null) {
                    context.router.push(PostDetailRoute(groupUuid: uuid, postId: post.id));
                  }
                },
                onGroupTap: post.groupUuid != null && post.groupName != null
                    ? () => _onSelectGroup(post.groupUuid)
                    : null,
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('加载失败: $err', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                if (_selectedGroupUuid == null) {
                  ref.read(allGroupsFeedProviderProvider.notifier).refresh();
                } else {
                  ref.read(groupFeedProviderProvider(_selectedGroupUuid!).notifier).refresh();
                }
              },
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoGroupsEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            '还没有加入圈子',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.router.push(const CreateGroupRoute()),
            icon: const Icon(Icons.add),
            label: const Text('创建圈子'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.router.push(const GroupListRoute()),
            icon: const Icon(Icons.login, size: 18),
            label: const Text('加入圈子'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPostsEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '暂无帖子',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          if (_selectedGroupUuid != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showCreatePost,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('发第一条帖子'),
            ),
          ],
        ],
      ),
    );
  }
}
