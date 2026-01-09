// lib/presentation/pages/posts/post_detail_page.dart

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/data/models/post/post.dart';
import 'package:prismbox/presentation/widgets/posts/post_card.dart';
import 'package:prismbox/presentation/widgets/posts/comment_item.dart';
import 'package:prismbox/presentation/widgets/posts/comment_input.dart';
import 'package:prismbox/providers/post/comments_provider.dart';
import 'package:prismbox/providers/post/group_feed_provider.dart';
import 'package:prismbox/providers/post/post_providers.dart';

/// 帖子详情页面
@RoutePage()
class PostDetailPage extends ConsumerStatefulWidget {
  final String groupUuid;
  final int postId;

  const PostDetailPage({
    super.key,
    @PathParam('groupUuid') required this.groupUuid,
    @PathParam('postId') required this.postId,
  });

  @override
  ConsumerState<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends ConsumerState<PostDetailPage> {
  Post? _post;
  String? _replyToCommentId;
  String? _replyToUsername;
  bool _hasTriedLoad = false;
  final Logger _log = Logger('PostDetailPage');

  @override
  void initState() {
    super.initState();
    _log.info('[PostDetailPage] initState called, groupUuid: ${widget.groupUuid}, postId: ${widget.postId}');
    
    // 评论列表会在 Provider 的 build 方法中自动加载，不需要手动调用 load()
    // 如果需要刷新评论，可以调用 refresh()
    
    // 检查 Feed 流状态，如果为空且不在加载中，触发加载（只尝试一次）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasTriedLoad) {
        final feedAsync = ref.read(groupFeedProviderProvider(widget.groupUuid));
        _log.info('[PostDetailPage] Feed state check: isLoading=${feedAsync.isLoading}, hasValue=${feedAsync.hasValue}, hasError=${feedAsync.hasError}');
        if (feedAsync.hasValue) {
          _log.info('[PostDetailPage] Feed value: ${feedAsync.value?.length ?? 0} posts');
        }
        if (feedAsync.hasError) {
          _log.severe('[PostDetailPage] Feed has error: ${feedAsync.error}');
        }
        
        if (!feedAsync.isLoading && (feedAsync.value?.isEmpty ?? true)) {
          _log.info('[PostDetailPage] Condition met, triggering load()');
          _hasTriedLoad = true;
          ref.read(groupFeedProviderProvider(widget.groupUuid).notifier).load();
        } else {
          _log.info('[PostDetailPage] Condition NOT met, will NOT trigger load(). isLoading=${feedAsync.isLoading}, isEmpty=${feedAsync.value?.isEmpty}');
        }
      } else {
        _log.info('[PostDetailPage] Already tried load, skipping');
      }
    });
  }

  Future<void> _handleAddComment(String content, String? parentCommentId) async {
    try {
      final service = ref.read(commentServiceProvider);
      final comment = await service.addComment(
        postId: widget.postId,
        content: content,
        parentCommentId: parentCommentId,
      );

      // 添加评论到列表
      ref.read(commentsProviderProvider(widget.postId).notifier).addComment(comment);

      // 清除回复状态
      setState(() {
        _replyToCommentId = null;
        _replyToUsername = null;
      });

      // 更新 Feed 流中的帖子评论数
      try {
        final feedProvider = ref.read(groupFeedProviderProvider(widget.groupUuid).notifier);
        final currentPosts = ref.read(groupFeedProviderProvider(widget.groupUuid)).value ?? [];
        final currentPost = currentPosts.firstWhere(
          (p) => p.id == widget.postId,
        );
        final updatedPost = Post(
          id: currentPost.id,
          caption: currentPost.caption,
          createdAt: currentPost.createdAt,
          creator: currentPost.creator,
          media: currentPost.media,
          likesCount: currentPost.likesCount,
          commentsCount: currentPost.commentsCount + 1,
        );
        feedProvider.updatePost(widget.postId, updatedPost);
      } catch (e) {
        // 如果帖子不在 Feed 流中，忽略更新（不影响添加评论的操作）
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加评论失败: $e')),
        );
      }
    }
  }

  Future<void> _handleDeleteComment(String commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除评论'),
        content: const Text('确定要删除这条评论吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final service = ref.read(commentServiceProvider);
        await service.deleteComment(commentId: commentId);

        // 从列表中移除评论
        ref.read(commentsProviderProvider(widget.postId).notifier).removeComment(commentId);

        // 更新 Feed 流中的帖子评论数
        try {
          final feedProvider = ref.read(groupFeedProviderProvider(widget.groupUuid).notifier);
          final currentPosts = ref.read(groupFeedProviderProvider(widget.groupUuid)).value ?? [];
          final currentPost = currentPosts.firstWhere(
            (p) => p.id == widget.postId,
          );
          final updatedPost = Post(
            id: currentPost.id,
            caption: currentPost.caption,
            createdAt: currentPost.createdAt,
            creator: currentPost.creator,
            media: currentPost.media,
            likesCount: currentPost.likesCount,
            commentsCount: currentPost.commentsCount > 0 ? currentPost.commentsCount - 1 : 0,
          );
          feedProvider.updatePost(widget.postId, updatedPost);
        } catch (e) {
          // 如果帖子不在 Feed 流中，忽略更新（不影响删除评论的操作）
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除评论失败: $e')),
          );
        }
      }
    }
  }

  void _handleReplyTap(String commentId, String username) {
    setState(() {
      _replyToCommentId = commentId;
      _replyToUsername = username;
    });
  }

  void _handleCancelReply() {
    setState(() {
      _replyToCommentId = null;
      _replyToUsername = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(commentsProviderProvider(widget.postId));
    // 监听 Feed 流状态，自动查找帖子
    final feedAsync = ref.watch(groupFeedProviderProvider(widget.groupUuid));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.router.maybePop(),
        ),
        title: const Text(
          '帖子详情',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                // 帖子内容 - 从 Feed 流中查找
                feedAsync.when(
                  data: (posts) {
                    // 如果列表为空，可能是正在加载或没有数据
                    if (posts.isEmpty) {
                      // 检查是否正在加载
                      final currentState = ref.read(groupFeedProviderProvider(widget.groupUuid));
                      if (currentState.isLoading) {
                        return const SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        );
                      }
                      // 没有数据，显示错误
                      return SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '帖子未找到',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '可能在 Feed 流中不存在或已被删除',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: () {
                                    ref
                                        .read(groupFeedProviderProvider(widget.groupUuid).notifier)
                                        .refresh();
                                  },
                                  child: const Text('刷新重试'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    // 尝试查找帖子
                    try {
                      final post = posts.firstWhere(
                        (p) => p.id == widget.postId,
                      );
                      // 更新本地状态（用于评论数更新）
                      if (_post?.id != post.id) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {
                              _post = post;
                            });
                          }
                        });
                      }
                      return SliverToBoxAdapter(
                        child: PostCard(
                          post: post,
                          onCommentTap: () {
                            // 滚动到评论区域
                          },
                        ),
                      );
                    } catch (e) {
                      // 帖子未找到 - 可能在后续页面，尝试加载更多
                      return SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '帖子未找到',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '帖子可能不在当前页面，请返回刷新 Feed 流',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: () {
                                    ref
                                        .read(groupFeedProviderProvider(widget.groupUuid).notifier)
                                        .refresh();
                                  },
                                  child: const Text('刷新重试'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                  },
                  loading: () => const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                  error: (error, stackTrace) => SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
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
                                fontSize: 16,
                                color: Colors.grey.shade600,
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
                            const SizedBox(height: 16),
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
                  ),
                ),
                // 评论列表
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: const Text(
                      '评论',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                commentsAsync.when(
                  data: (comments) {
                    if (comments.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              '暂无评论',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final comment = comments[index];
                          return CommentItem(
                            comment: comment,
                            onReplyTap: () => _handleReplyTap(
                              comment.id,
                              comment.author.username,
                            ),
                            onDeleteTap: () => _handleDeleteComment(comment.id),
                            // TODO: 判断当前用户是否可以删除评论
                            canDelete: false,
                          );
                        },
                        childCount: comments.length,
                      ),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                  error: (error, stackTrace) => SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Text(
                              '加载评论失败',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                ref.read(commentsProviderProvider(widget.postId).notifier).refresh();
                              },
                              child: const Text('重试'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 评论输入框
          CommentInput(
            replyToUsername: _replyToUsername,
            onSubmit: (content, parentCommentId) {
              _handleAddComment(
                content,
                _replyToCommentId ?? parentCommentId,
              );
            },
            onCancelReply: _handleCancelReply,
          ),
        ],
      ),
    );
  }
}

