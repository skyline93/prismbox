// lib/ui/group/pages/group_post_detail_page.dart

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // [新增]
// import 'package:mobile/domain/entities/comment_entity.dart'; // [修改]
import 'package:mobile/domain/entities/group_feed_item_entity.dart';
import 'package:mobile/providers/group_providers.dart'; // [新增]
import 'package:mobile/ui/group/widgets/comment_input_field.dart';
import 'package:mobile/ui/group/widgets/comment_thread_widget.dart';
import 'package:mobile/ui/group/widgets/feed_card/post_widget.dart';

// [删除] MockComment 类定义

@RoutePage()
class GroupPostDetailPage extends ConsumerStatefulWidget {
  // [修改]
  final String groupUuid;
  final GroupFeedItemEntity post;

  const GroupPostDetailPage({
    super.key,
    required this.groupUuid,
    required this.post,
  });

  @override
  ConsumerState<GroupPostDetailPage> createState() =>
      _GroupPostDetailPageState(); // [修改]
}

class _GroupPostDetailPageState extends ConsumerState<GroupPostDetailPage> {
  // [修改]
  final ScrollController _scrollController = ScrollController();

  // [删除] 所有状态管理和业务逻辑 ( _comments, _replyingToComment, _currentUser, initState, _handleCommentSubmission 等)

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // [新增] 获取 ViewModel provider
    // 注意：我们使用 post.id 作为 family 的参数
    final viewModelProvider = postDetailViewModelProvider(widget.post.id);
    final state = ref.watch(viewModelProvider);
    final viewModel = ref.read(viewModelProvider.notifier);

    // [新增] 监听一次性事件，例如滚动
    ref.listen<bool>(
      viewModelProvider.select((s) => s.commentPostedSuccessfully),
      (previous, isSuccess) {
        if (isSuccess) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
          // 通知 ViewModel 消耗掉这个事件
          viewModel.consumePostSuccess();
        }
      },
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Post',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: BackButton(
          color: Colors.black,
          onPressed: () => AutoRouter.of(context).maybePop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade300, height: 1.0),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: state.isLoading && state.comments.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      SliverToBoxAdapter(
                        child: PostWidget(
                          groupUuid: widget.groupUuid,
                          item: widget.post,
                          isDetailView: true,
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: Divider(height: 1, thickness: 1),
                      ),
                      if (state.errorMessage != null && state.comments.isEmpty)
                        SliverFillRemaining(
                          child: Center(child: Text(state.errorMessage!)),
                        ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final comment = state.comments[index];
                          return CommentThreadWidget(
                            comment: comment,
                            depth: 0,
                            isLast: index == state.comments.length - 1,
                            onReply: viewModel.setReplyingTo,
                          );
                        }, childCount: state.comments.length),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 120)),
                    ],
                  ),
          ),
          if (state.replyingToComment != null)
            Container(
              color: Colors.grey.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Replying to ${state.replyingToComment!.author.username}',
                  ),
                  GestureDetector(
                    onTap: viewModel.cancelReply,
                    child: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
          CommentInputField(
            // 将提交操作转发给 ViewModel
            onSubmitted: viewModel.postComment,
            // 根据状态禁用输入框
            enabled: !state.isPostingComment,
          ),
        ],
      ),
    );
  }
}
