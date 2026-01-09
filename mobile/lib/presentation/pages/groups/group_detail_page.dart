// lib/presentation/pages/groups/group_detail_page.dart
//
// 设计原则参考：
// - OpenSpec: openspec/specs/riverpod-provider-design/spec.md
// - 设计指南: mobile/doc/riverpod-provider-design-principles.md
//
// 关键实践：
// - 在顶层无条件 watch 所有需要的 Provider，确保并行初始化
// - 避免在条件渲染中 watch Provider

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/presentation/routing/app_router.dart';
import 'package:prismbox/presentation/widgets/posts/post_card.dart';
import 'package:prismbox/providers/group/group_detail_provider.dart';
import 'package:prismbox/providers/post/group_feed_provider.dart';
import 'package:prismbox/data/models/post/post.dart';
import 'package:prismbox/data/models/group/group_member.dart';

/// 圈子详情页面
@RoutePage()
class GroupDetailPage extends ConsumerStatefulWidget {
  final String groupUuid;

  const GroupDetailPage({
    super.key,
    @PathParam('groupUuid') required this.groupUuid,
  });

  @override
  ConsumerState<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends ConsumerState<GroupDetailPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _hasMore = true; // 是否还有更多数据
  bool _isUiVisible = true;
  final Logger _log = Logger('GroupDetailPage');

  @override
  void initState() {
    super.initState();
    _log.info('[GroupDetailPage] initState called, groupUuid: ${widget.groupUuid}');
    
    // 圈子详情和 Feed 流都会在各自的 Provider.build() 中自动加载，不需要手动调用
    // 只需要监听滚动，实现上拉加载更多和浮动按钮显示/隐藏
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // 浮动按钮的显示/隐藏逻辑
    if (_scrollController.position.userScrollDirection ==
            ScrollDirection.reverse &&
        _isUiVisible) {
      setState(() {
        _isUiVisible = false;
      });
    } else if (_scrollController.position.userScrollDirection ==
            ScrollDirection.forward &&
        !_isUiVisible) {
      setState(() {
        _isUiVisible = true;
      });
    }

    // 分页加载逻辑
    if (_isLoadingMore) return;

    // 检查是否还有更多数据可以加载
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final hasMore = await ref
          .read(groupFeedProviderProvider(widget.groupUuid).notifier)
          .loadMore();
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _hasMore = hasMore;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    // 刷新时重置状态
    setState(() {
      _hasMore = true;
    });
    await Future.wait([
      ref.read(groupDetailProviderProvider(widget.groupUuid).notifier).refresh(),
      ref.read(groupFeedProviderProvider(widget.groupUuid).notifier).refresh(),
    ]);
  }

  void _showCreatePostSheet() {
    // 跳转到创建帖子页面
    context.router.push(CreatePostRoute(groupUuid: widget.groupUuid));
  }

  @override
  Widget build(BuildContext context) {
    // 遵循设计原则：在顶层无条件 watch 所有需要的 Provider
    // 确保并行初始化，避免条件渲染导致的依赖链断裂
    // 参考: openspec/specs/riverpod-provider-design/spec.md
    final detailAsync = ref.watch(groupDetailProviderProvider(widget.groupUuid));
    final feedState = ref.watch(groupFeedProviderProvider(widget.groupUuid)); // 并行初始化

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              elevation: 0,
              pinned: true,
              floating: true,
              snap: true,
              automaticallyImplyLeading: false,
              toolbarHeight: 30.0,
              expandedHeight: 60.0,
              scrolledUnderElevation: 6.0,
              shadowColor: Colors.black12,
              flexibleSpace: FlexibleSpaceBar(
                background: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        BackButton(
                          onPressed: () => context.router.maybePop(),
                        ),
                        Expanded(
                          child: detailAsync.when(
                            data: (group) => Text(
                              group?.name ?? '',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18.0),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (e, s) => const SizedBox.shrink(),
                          ),
                        ),
                        detailAsync.when(
                          data: (group) {
                            if (group == null) return const SizedBox.shrink();
                            final bool isOwnerOrAdmin =
                                group.currentUserRole == GroupRole.owner ||
                                group.currentUserRole == GroupRole.admin;
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.people_alt_outlined),
                                  tooltip: 'Members',
                                  onPressed: () {
                                    context.router.push(
                                      GroupMembersRoute(groupUuid: widget.groupUuid),
                                    );
                                  },
                                ),
                                if (isOwnerOrAdmin)
                                  IconButton(
                                    icon: const Icon(Icons.settings),
                                    tooltip: 'Settings',
                                    onPressed: () {
                                      context.router.push(
                                        GroupSettingsRoute(groupUuid: widget.groupUuid),
                                      );
                                    },
                                  ),
                              ],
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (e, s) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _buildSliverContent(detailAsync, feedState),
          ],
        ),
      ),
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(child: child, scale: animation);
        },
        child: _isUiVisible
            ? FloatingActionButton(
                key: const ValueKey('fab_visible'),
                onPressed: _showCreatePostSheet,
                tooltip: 'Create a new post',
                shape: const CircleBorder(),
                elevation: 8.0,
                backgroundColor: Theme.of(context).primaryColor,
                child: const Icon(Icons.add, color: Colors.white),
              )
            : const SizedBox.shrink(key: ValueKey('fab_hidden')),
      ),
    );
  }

  Widget _buildSliverContent(
    AsyncValue<dynamic> detailAsync,
    AsyncValue<List<Post>> feedState,
  ) {
    return feedState.when(
      data: (posts) {
        if (posts.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Nothing in this group yet.'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showCreatePostSheet,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Share the first post'),
                  ),
                ],
              ),
            ),
          );
        }
        return SliverList.separated(
          itemCount: posts.length + (_isLoadingMore ? 1 : 0) + (!_hasMore && posts.isNotEmpty ? 1 : 0),
          separatorBuilder: (context, index) {
            if (index < posts.length) {
              return const Divider(
                height: 1,
                color: Color(0xFFEEEEEE),
              );
            }
            return const SizedBox.shrink();
          },
          itemBuilder: (context, index) {
            // 加载更多指示器
            if (index == posts.length && _isLoadingMore) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            
            // 没有更多内容提示
            if (index == posts.length + (_isLoadingMore ? 1 : 0) && !_hasMore && posts.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
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
                // 跳转到帖子详情页
                context.router.push(
                  PostDetailRoute(
                    groupUuid: widget.groupUuid,
                    postId: post.id,
                  ),
                );
              },
              onCommentTap: () {
                // 跳转到帖子详情页（滚动到评论区域）
                context.router.push(
                  PostDetailRoute(
                    groupUuid: widget.groupUuid,
                    postId: post.id,
                  ),
                );
              },
            );
          },
        );
      },
      loading: () {
        // 如果圈子详情也在加载，显示加载指示器
        if (detailAsync.isLoading) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        // 如果圈子详情已加载，但Feed流还在加载，显示加载指示器
        return const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        );
      },
      error: (error, stackTrace) => SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Failed to load feed: ${error.toString()}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    ref
                        .read(groupFeedProviderProvider(widget.groupUuid).notifier)
                        .refresh();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

