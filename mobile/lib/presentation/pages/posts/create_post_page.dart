// lib/presentation/pages/posts/create_post_page.dart

import 'dart:io';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/presentation/widgets/posts/post_media_selection_bottom_sheet.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/providers/infrastructure/database_provider.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/providers/post/post_providers.dart';
import 'package:prismbox/providers/post/post_task_provider.dart';
import 'package:prismbox/data/database/enums/post_task_status.dart';
import 'package:prismbox/presentation/widgets/posts/new_post/new_post_app_bar.dart';
import 'package:prismbox/presentation/widgets/posts/new_post/new_post_bottom_bar.dart';
import 'package:prismbox/presentation/widgets/posts/new_post/text_input_section.dart';
import 'package:prismbox/presentation/widgets/posts/new_post/image_attachment_area.dart';
import 'package:prismbox/presentation/widgets/user/user_circle_avatar.dart';
import 'package:prismbox/domain/entities/user_profile.dart';

/// 创建帖子页面（参考 Album 项目的风格）
@RoutePage()
class CreatePostPage extends ConsumerStatefulWidget {
  final String groupUuid;

  const CreatePostPage({
    super.key,
    @PathParam('groupUuid') required this.groupUuid,
  });

  @override
  ConsumerState<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends ConsumerState<CreatePostPage> {
  final TextEditingController _captionController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<String> _selectedAssetIds = []; // 存储选中的 assetId（LocalAssetEntity 的 id）
  final Map<String, LocalAssetEntityData> _assetMap = {}; // 缓存 assetId 到 LocalAssetEntityData 的映射
  String? _currentTaskId;
  bool _isLoading = false;
  final Logger _log = Logger('CreatePostPage');

  // 布局常量（参考 Album 项目的设计）
  static const double avatarRadius = 16.0;
  static const double avatarContentGap = 12.0;

  @override
  void dispose() {
    _captionController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 检查是否可以发布（有媒体或文字）
  bool get _canPublish {
    return _selectedAssetIds.isNotEmpty || _captionController.text.trim().isNotEmpty;
  }

  /// 选择媒体（使用时间线组件在上滑抽屉中显示）
  Future<void> _handleSelectMedia() async {
    try {
      // 显示媒体选择抽屉（保持现有设计）
      final selectedAssetIds = await showModalBottomSheet<List<String>>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: true,
        backgroundColor: Colors.transparent,
        builder: (context) => PostMediaSelectionBottomSheet(
          maxSelection: 9,
          initialSelectedIds: _selectedAssetIds.toSet(),
          onSelectionComplete: (ids) {
            // 选择完成回调（在用户点击确定时调用）
          },
        ),
      );

      if (selectedAssetIds != null && selectedAssetIds.isNotEmpty) {
        // 从 LocalAssetDao 获取选中的媒体信息
        final database = await ref.read(databaseProvider.future);
        final localAssets = await database.localAssetDao.getAssetsByIds(selectedAssetIds);

        // 更新选中的 assetId 列表和映射
        setState(() {
          _selectedAssetIds.clear();
          _assetMap.clear();

          for (final assetId in selectedAssetIds) {
            final localAsset = localAssets[assetId];
            if (localAsset != null) {
              _selectedAssetIds.add(assetId);
              _assetMap[assetId] = localAsset;
            }
          }
        });
      }
    } catch (e) {
      _log.severe('Failed to select media: $e', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择媒体失败: $e')),
        );
      }
    }
  }

  /// 删除选中的媒体
  void _removeMedia(int index) {
    if (index < _selectedAssetIds.length) {
      setState(() {
        final assetId = _selectedAssetIds[index];
        _selectedAssetIds.removeAt(index);
        _assetMap.remove(assetId);
      });
    }
  }

  /// 发布帖子
  Future<void> _handlePublish() async {
    if (!_canPublish || _isLoading) {
      return;
    }

    if (_selectedAssetIds.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请至少选择一张图片或视频')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 获取当前用户 ID
      final database = await ref.read(databaseProvider.future);
      final users = await database.userDao.getAllUsers();
      if (users.isEmpty) {
        throw Exception('未找到当前用户');
      }
      final userId = users.first.id;

      // 从 LocalAssetDao 获取媒体文件路径
      final localAssets = await database.localAssetDao.getAssetsByIds(_selectedAssetIds);
      final mediaPaths = <String>[];
      final mediaAssetIds = <String>[];

      for (final assetId in _selectedAssetIds) {
        final localAsset = localAssets[assetId];
        if (localAsset != null) {
          // 验证文件是否存在
          final file = File(localAsset.path);
          if (await file.exists()) {
            mediaPaths.add(localAsset.path);
            mediaAssetIds.add(assetId);
          } else {
            _log.warning('Media file not found: ${localAsset.path}');
          }
        }
      }

      if (mediaPaths.isEmpty) {
        throw Exception('无法获取媒体文件路径');
      }

      // 创建后台任务
      final postService = await ref.read(postServiceProvider.future);
      final taskId = await postService.createPostTask(
        userId: userId,
        groupUuid: widget.groupUuid,
        caption: _captionController.text.trim().isEmpty
            ? null
            : _captionController.text.trim(),
        mediaPaths: mediaPaths,
        mediaAssetIds: mediaAssetIds,
      );

      setState(() {
        _currentTaskId = taskId;
      });

      // 显示成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('发布任务已创建，正在后台处理...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // 等待任务完成或失败
      await _waitForTaskCompletion(taskId);

      // 任务完成后返回上一页
      if (mounted) {
        context.router.maybePop();
      }
    } catch (e) {
      _log.severe('Failed to publish post: $e', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发布失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 等待任务完成
  Future<void> _waitForTaskCompletion(String taskId) async {
    // 使用轮询方式检查任务状态（简化实现）
    while (mounted) {
      await Future.delayed(const Duration(seconds: 1));
      final taskAsync = await ref.read(postTaskProvider(taskId).future);
      if (taskAsync != null) {
        if (taskAsync.status == PostTaskStatus.completed) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('发布成功！'),
                backgroundColor: Colors.green,
              ),
            );
          }
          break;
        } else if (taskAsync.status == PostTaskStatus.failed) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('发布失败: ${taskAsync.errorMessage ?? "未知错误"}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 获取用户信息
    final userAsync = ref.watch(databaseProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: NewPostAppBar(
        onCancel: () => context.router.maybePop(),
      ),
      body: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: userAsync.when(
                  data: (database) => _buildContent(context, database),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text('加载失败: $error'),
                    ),
                  ),
                ),
              ),
            ),
            // 底部操作栏
            NewPostBottomBar(
              isPostButtonEnabled: _canPublish && _currentTaskId == null,
              isLoading: _isLoading,
              onPostTap: _handlePublish,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建主要内容区域
  Widget _buildContent(BuildContext context, AppDatabase database) {
    return FutureBuilder(
      future: database.userDao.getAllUsers(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData || userSnapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final user = userSnapshot.data!.first;
        final userProfile = UserProfile.fromEntity(user);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左侧：头像和竖线
              Column(
                children: [
                  UserCircleAvatar(
                    user: userProfile,
                    radius: avatarRadius,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.grey.shade300,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: avatarContentGap),
              // 右侧：内容区
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    // 用户名
                    Text(
                      userProfile.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 图片附件区域
                    ImageAttachmentArea(
                      assetIds: _selectedAssetIds,
                      assetMap: _assetMap,
                      onPickAssets: _handleSelectMedia,
                      onRemoveAsset: _removeMedia,
                    ),
                    const SizedBox(height: 16),
                    // 文本输入区域
                    TextInputSection(
                      controller: _captionController,
                      focusNode: _focusNode,
                      onTextChanged: (_) {
                        setState(() {}); // 更新发布按钮状态
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
