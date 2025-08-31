// lib/ui/media/pages/media_item_page.dart

// +++ MODIFIED +++

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:mobile/data/models/group/group_models.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/providers/group_providers.dart';
import 'package:mobile/ui/gallery/widgets/image_content.dart';
import 'package:mobile/ui/gallery/widgets/video_content.dart';
import 'package:mobile/ui/group/widgets/comment_input_field.dart';
import 'package:mobile/ui/group/widgets/comment_list.dart';

// 1. 将 StatelessWidget 改为 ConsumerStatefulWidget 以处理状态和交互
@RoutePage()
class MediaItemPage extends ConsumerStatefulWidget {
  // 2. 修改构造函数，接收 GroupMediaModel 而不是 UnifiedMediaEntity
  // 因为我们需要 group_media_id (即 groupMedia.id) 来获取评论
  final GroupMediaModel groupMedia;

  const MediaItemPage({super.key, required this.groupMedia});

  @override
  ConsumerState<MediaItemPage> createState() => _MediaItemPageState();
}

class _MediaItemPageState extends ConsumerState<MediaItemPage> {
  late final UnifiedMediaEntity entity;

  @override
  void initState() {
    super.initState();
    // 3. 在内部构建 UnifiedMediaEntity，以复用 ImageContent/VideoContent
    final remoteMedia = widget.groupMedia.mediaDetails;
    entity = UnifiedMediaEntity.fromRemoteMedia(remoteMedia);
  }

  // 4. 实现提交评论的逻辑
  Future<void> _submitComment(String text) async {
    final groupRepository = ref.read(groupRepositoryProvider);
    try {
      await groupRepository.addComment(widget.groupMedia.group_media_id, text);
      // 提交成功后，刷新评论列表
      ref.invalidate(commentsProvider(widget.groupMedia.group_media_id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('发表评论失败: $e')));
      }
      // 将错误重新抛出，以便输入框可以处理 UI 状态
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        // 显示上传者信息
        title: Text(
          '来自 ${widget.groupMedia.uploader.username}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: Column(
        children: [
          // 媒体内容区域
          Expanded(
            child: entity.isVideo
                ? VideoContent(entity: entity)
                : ImageContent(entity: entity),
          ),
          // 评论区域
          Expanded(
            child: Container(
              color: Colors.white, // 设置评论区背景色
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    // 使用 Consumer 来监听 provider
                    child: Consumer(
                      builder: (context, ref, child) {
                        return CommentList(
                          groupMediaId: widget.groupMedia.group_media_id,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 评论输入框
          Container(
            color: Colors.white,
            child: SafeArea(
              top: false, // 输入框不需要顶部的安全区域
              child: CommentInputField(onSubmitted: _submitComment),
            ),
          ),
        ],
      ),
    );
  }
}
