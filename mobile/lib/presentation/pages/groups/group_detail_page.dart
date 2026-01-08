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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/presentation/routing/app_router.dart';
import 'package:prismbox/presentation/widgets/posts/post_card.dart';
import 'package:prismbox/providers/group/group_detail_provider.dart';
import 'package:prismbox/providers/post/group_feed_provider.dart';

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
  final Logger _log = Logger('GroupDetailPage');

  @override
  void initState() {
    super.initState();
    _log.info('[GroupDetailPage] initState called, groupUuid: ${widget.groupUuid}');
    
    // 圈子详情和 Feed 流都会在各自的 Provider.build() 中自动加载，不需要手动调用
    // 只需要监听滚动，实现上拉加载更多
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore) return;

    // 当滚动到底部时，加载更多
    // 注意：NestedScrollView 的滚动控制器会同时控制 header 和 body 的滚动
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final hasMore = await ref
          .read(groupFeedProviderProvider(widget.groupUuid).notifier)
          .loadMore();
      // 如果没有更多数据，可以显示提示
      if (!hasMore) {
        // 可以显示"没有更多数据"提示
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      ref.read(groupDetailProviderProvider(widget.groupUuid).notifier).refresh(),
      ref.read(groupFeedProviderProvider(widget.groupUuid).notifier).refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    // 遵循设计原则：在顶层无条件 watch 所有需要的 Provider
    // 确保并行初始化，避免条件渲染导致的依赖链断裂
    // 参考: openspec/specs/riverpod-provider-design/spec.md
    final detailAsync = ref.watch(groupDetailProviderProvider(widget.groupUuid));
    ref.watch(groupFeedProviderProvider(widget.groupUuid)); // 并行初始化

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    pinned: true,
                    floating: true,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
                      onPressed: () => context.router.maybePop(),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.people_outline, color: Colors.black, size: 24),
                        onPressed: () {
                          context.router.push(GroupMembersRoute(groupUuid: widget.groupUuid));
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ];
              },
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: detailAsync.when(
          data: (detail) {
            if (detail == null) {
              return const Center(child: CircularProgressIndicator());
            }
                    return _buildContent(context);
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => _buildErrorState(context, error),
        ),
      ),
            ),
          ),
          // 底部悬浮按钮
          Positioned(
            bottom: 20,
            right: 20,
            child: GestureDetector(
              onTap: () {
          context.router.push(CreatePostRoute(groupUuid: widget.groupUuid));
        },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Icon(Icons.add, color: Colors.black, size: 32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final feedAsync = ref.watch(groupFeedProviderProvider(widget.groupUuid));

    return feedAsync.when(
          data: (posts) {
            if (posts.isEmpty) {
          return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      '暂无帖子',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
          );
        }

        return ListView.separated(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: posts.length + (_isLoadingMore ? 1 : 0),
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
            if (index == posts.length) {
              // 加载更多指示器
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
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
      loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
      error: (error, stackTrace) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '加载 Feed 流失败',
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
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            '加载失败',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ref.read(groupDetailProviderProvider(widget.groupUuid).notifier).refresh();
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

