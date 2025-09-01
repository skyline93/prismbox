// lib/ui/group/pages/group_post_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:mobile/domain/entities/group_feed_item_entity.dart';
import 'package:mobile/providers/group_providers.dart';
import 'package:mobile/ui/gallery/widgets/image_content.dart';
import 'package:mobile/ui/gallery/widgets/video_content.dart';
import 'package:mobile/ui/group/widgets/comment_input_field.dart';
import 'package:mobile/ui/group/widgets/comment_list.dart';

@RoutePage()
class GroupPostDetailPage extends ConsumerStatefulWidget {
  // 2. [参数变更] 构造函数现在接收一个完整的帖子实体 GroupFeedItemEntity
  final GroupFeedItemEntity post;

  const GroupPostDetailPage({super.key, required this.post});

  @override
  ConsumerState<GroupPostDetailPage> createState() =>
      _GroupPostDetailPageState();
}

class _GroupPostDetailPageState extends ConsumerState<GroupPostDetailPage> {
  // 3. [逻辑更新] 实现提交评论的逻辑，使用 postId
  Future<void> _submitComment(String text) async {
    final groupRepository = ref.read(groupRepositoryProvider);
    try {
      // 使用 widget.post.id 作为帖子的ID
      await groupRepository.addComment(widget.post.id, text);
      // 成功后，使用 post.id 来刷新对应的评论列表
      ref.invalidate(commentsProvider(widget.post.id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('发表评论失败: $e')));
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 背景色改为白色以容纳文案
      appBar: AppBar(
        // AppBar 背景色可以根据主题调整
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        // 显示帖子作者信息
        title: Text(
          '${widget.post.author.username}的帖子',
          style: const TextStyle(color: Colors.black, fontSize: 16),
        ),
      ),
      body: Column(
        children: [
          // 4. [UI 核心改造] 使用 PageView 来展示帖子中的所有媒体
          SizedBox(
            // 给PageView一个固定的高度，例如屏幕宽度
            height: MediaQuery.of(context).size.width,
            child: PageView.builder(
              itemCount: widget.post.mediaAttachments.length,
              itemBuilder: (context, index) {
                final entity = widget.post.mediaAttachments[index];
                // 根据媒体类型返回不同的Widget
                return entity.isVideo
                    ? VideoContent(entity: entity)
                    : ImageContent(entity: entity);
              },
            ),
          ),
          // 5. [UI 新增] 使用 Expanded 和 CustomScrollView 来整合文案和评论
          Expanded(
            child: CustomScrollView(
              slivers: [
                // 显示帖子文案 (Caption)
                if (widget.post.content.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      child: Text(
                        widget.post.content,
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ),
                  ),

                // 分割线
                const SliverToBoxAdapter(child: Divider(height: 1)),

                // 评论列表
                SliverToBoxAdapter(
                  // 6. [逻辑更新] CommentList 现在需要接收 postId
                  child: CommentList(postId: widget.post.id),
                ),
              ],
            ),
          ),
          // 评论输入框
          SafeArea(
            top: false, // 输入框不需要顶部的安全区域
            child: CommentInputField(onSubmitted: _submitComment),
          ),
        ],
      ),
    );
  }
}
