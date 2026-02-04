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

    final toolbarHeight = kToolbarHeight;
    // SafeArea(top: true) so the pinned circle bar stays below the status bar when scrolled up.
    final topPadding = 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: true,
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: _buildTopBar(context, appBarTitle, topPadding, toolbarHeight),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _GroupSelectorSliverDelegate(
                  groups: groups,
                  selectedGroupUuid: _selectedGroupUuid,
                  onSelectGroup: _onSelectGroup,
                ),
              ),
              ..._buildFeedSlivers(context, groups, feedAsync),
            ],
          ),
        ),
      ),
      floatingActionButton: _selectedGroupUuid != null && _isFabVisible
          ? FloatingActionButton(
              onPressed: _showCreatePost,
              tooltip: '发帖',
              shape: const CircleBorder(),
              child: const Icon(Icons.border_color),
            )
          : null,
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    String appBarTitle,
    double topPadding,
    double toolbarHeight,
  ) {
    return Container(
      height: topPadding + toolbarHeight,
      color: Colors.white,
      padding: EdgeInsets.only(top: topPadding),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  appBarTitle,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
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
    );
  }

  List<Widget> _buildFeedSlivers(
    BuildContext context,
    List<Group> groups,
    AsyncValue<List<Post>> feedAsync,
  ) {
    if (groups.isEmpty && !feedAsync.isLoading) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildNoGroupsEmpty(),
        ),
      ];
    }
    return feedAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return [
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildNoPostsEmpty(),
            ),
          ];
        }
        return [
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == posts.length && _isLoadingMore) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (index ==
                          posts.length + (_isLoadingMore ? 1 : 0) &&
                      !_hasMore &&
                      posts.isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          '没有更多内容了',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }
                  final post = posts[index];
                  return PostCard(
                    post: post,
                    onTap: () {
                      final uuid =
                          post.groupUuid ?? _selectedGroupUuid;
                      if (uuid != null) {
                        context.router.push(PostDetailRoute(
                            groupUuid: uuid, postId: post.id));
                      }
                    },
                    onCommentTap: () {
                      final uuid =
                          post.groupUuid ?? _selectedGroupUuid;
                      if (uuid != null) {
                        context.router.push(PostDetailRoute(
                            groupUuid: uuid, postId: post.id));
                      }
                    },
                    onGroupTap: post.groupUuid != null &&
                            post.groupName != null
                        ? () => _onSelectGroup(post.groupUuid)
                        : null,
                  );
                },
                childCount: posts.length +
                    (_isLoadingMore ? 1 : 0) +
                    (!_hasMore && posts.isNotEmpty ? 1 : 0),
              ),
            ),
          ),
        ];
      },
      loading: () => [
        SliverFillRemaining(
          hasScrollBody: false,
          child: const Center(child: CircularProgressIndicator()),
        ),
      ],
      error: (err, _) => [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '加载失败: $err',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    if (_selectedGroupUuid == null) {
                      ref
                          .read(allGroupsFeedProviderProvider.notifier)
                          .refresh();
                    } else {
                      ref
                          .read(groupFeedProviderProvider(
                              _selectedGroupUuid!)
                              .notifier)
                          .refresh();
                    }
                  },
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
      ],
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

/// [SliverPersistentHeaderDelegate] that paints the group selector (全部 + chips).
/// Pinned so it stays at the top when the user scrolls up.
class _GroupSelectorSliverDelegate extends SliverPersistentHeaderDelegate {
  _GroupSelectorSliverDelegate({
    required this.groups,
    required this.selectedGroupUuid,
    required this.onSelectGroup,
  });

  final List<Group> groups;
  final String? selectedGroupUuid;
  final void Function(String? uuid) onSelectGroup;

  static const double _height = 44;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: _height,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('全部'),
              selected: selectedGroupUuid == null,
              onSelected: (_) => onSelectGroup(null),
            ),
          ),
          ...groups.map<Widget>(
            (g) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(g.name),
                selected: selectedGroupUuid == g.uuid,
                onSelected: (_) => onSelectGroup(g.uuid),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _GroupSelectorSliverDelegate old) {
    return old.selectedGroupUuid != selectedGroupUuid ||
        !const ListEquality().equals(
          old.groups.map((e) => e.uuid).toList(),
          groups.map((e) => e.uuid).toList(),
        );
  }
}
