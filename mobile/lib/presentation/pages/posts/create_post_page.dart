// lib/presentation/pages/posts/create_post_page.dart

import 'dart:io';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:prismbox/presentation/widgets/posts/post_media_selection_bottom_sheet.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/providers/infrastructure/database_provider.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/providers/post/post_providers.dart';
import 'package:prismbox/providers/post/post_task_provider.dart';
import 'package:prismbox/data/database/enums/post_task_status.dart';

/// 创建帖子页面（Threads 风格）
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
  final List<String> _selectedAssetIds = []; // 存储选中的 assetId（LocalAssetEntity 的 id）
  final Map<String, String> _assetIdToPath = {}; // 缓存 assetId 到文件路径的映射
  String? _currentTaskId;
  final Logger _log = Logger('CreatePostPage');

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  /// 检查是否可以发布（有媒体或文字）
  bool get _canPublish {
    return _selectedAssetIds.isNotEmpty || _captionController.text.trim().isNotEmpty;
  }

  /// 选择媒体（使用时间线组件在上滑抽屉中显示）
  Future<void> _handleSelectMedia() async {
    try {
      // 显示媒体选择抽屉
      final selectedAssetIds = await showModalBottomSheet<List<String>>(
        context: context,
        isScrollControlled: true,
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

        // 更新选中的 assetId 列表和路径映射
        setState(() {
          _selectedAssetIds.clear();
          _assetIdToPath.clear();
          
          for (final assetId in selectedAssetIds) {
            final localAsset = localAssets[assetId];
            if (localAsset != null) {
              _selectedAssetIds.add(assetId);
              _assetIdToPath[assetId] = localAsset.path;
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
        _assetIdToPath.remove(assetId);
      });
    }
  }

  /// 发布帖子
  Future<void> _handlePublish() async {
    if (!_canPublish) {
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
      final mediaAssetIds = <String>[]; // 存储 assetId，用于传递给 PostTaskManager
      
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
        mediaAssetIds: mediaAssetIds, // 传递 assetId 列表
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: TextButton(
          onPressed: () => context.router.maybePop(),
          child: const Text(
            '取消',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16,
            ),
          ),
        ),
        title: const Text(
          '新建串文',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.list, color: Colors.black87),
            onPressed: () {
              // TODO: 实现更多选项
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onPressed: () {
              // TODO: 实现更多选项
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 用户信息区域
                  _buildUserInfoArea(),
                  const SizedBox(height: 16),
                  // 文字输入区域
                  _buildTextInputArea(),
                  const SizedBox(height: 16),
                  // 媒体预览区域
                  if (_selectedAssetIds.isNotEmpty) _buildMediaPreviewArea(),
                  // 如果没有选择媒体，显示选择按钮
                  if (_selectedAssetIds.isEmpty)
                    GestureDetector(
                      onTap: _handleSelectMedia,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 24,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '选择图片',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // 底部操作栏
          _buildBottomActionBar(),
        ],
      ),
    );
  }

  /// 构建用户信息区域
  Widget _buildUserInfoArea() {
    return FutureBuilder(
      future: ref.read(databaseProvider.future),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        return FutureBuilder(
          future: snapshot.data!.userDao.getAllUsers(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData || userSnapshot.data!.isEmpty) {
              return const SizedBox.shrink();
            }

            final user = userSnapshot.data!.first;
            return Row(
              children: [
                // 头像（使用占位符）
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey.shade300,
                  child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            user.avatarUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.person, color: Colors.grey.shade600);
                            },
                          ),
                        )
                      : Icon(Icons.person, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 12),
                // 用户名
                Text(
                  user.name.isNotEmpty ? user.name : (user.email ?? '用户'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                // 添加话题入口
                GestureDetector(
                  onTap: () {
                    // TODO: 实现添加话题功能
                  },
                  child: const Text(
                    '> 添加话题',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 构建文字输入区域
  Widget _buildTextInputArea() {
    return TextField(
      controller: _captionController,
      maxLines: null,
      minLines: 4,
      decoration: const InputDecoration(
        hintText: '有什么新鲜事吗?',
        border: InputBorder.none,
        hintStyle: TextStyle(
          color: Colors.grey,
          fontSize: 16,
        ),
      ),
      style: const TextStyle(
        fontSize: 16,
        color: Colors.black87,
        height: 1.5,
      ),
      onChanged: (_) {
        setState(() {}); // 更新发布按钮状态
      },
    );
  }

  /// 构建媒体预览区域
  Widget _buildMediaPreviewArea() {
    return FutureBuilder<Map<String, LocalAssetEntityData>>(
      future: _loadLocalAssets(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final localAssets = snapshot.data!;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _selectedAssetIds.length,
          itemBuilder: (context, index) {
            final assetId = _selectedAssetIds[index];
            final localAsset = localAssets[assetId];
            if (localAsset == null) {
              return const SizedBox.shrink();
            }
            return _buildMediaThumbnail(localAsset, index);
          },
        );
      },
    );
  }

  /// 加载本地资产数据
  Future<Map<String, LocalAssetEntityData>> _loadLocalAssets() async {
    if (_selectedAssetIds.isEmpty) {
      return {};
    }
    final database = await ref.read(databaseProvider.future);
    return await database.localAssetDao.getAssetsByIds(_selectedAssetIds);
  }

  /// 构建媒体缩略图
  Widget _buildMediaThumbnail(LocalAssetEntityData localAsset, int index) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 缩略图
        FutureBuilder<File?>(
          future: _loadThumbnail(localAsset),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  snapshot.data!,
                  fit: BoxFit.cover,
                ),
              );
            }
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          },
        ),
        // 删除按钮
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeMedia(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 加载缩略图
  Future<File?> _loadThumbnail(LocalAssetEntityData localAsset) async {
    try {
      // 使用 photo_manager 获取缩略图
      // 注意：photo_manager 没有直接的 getAssetEntity 方法，需要通过 AssetPathEntity 获取
      // 这里简化处理：直接使用文件路径
      final asset = await _getAssetEntityById(localAsset.id);
      if (asset == null) {
        // 如果无法获取 AssetEntity，尝试直接使用文件路径
        final file = File(localAsset.path);
        if (await file.exists()) {
          return file;
        }
        return null;
      }

      final thumbnailData = await asset.thumbnailDataWithSize(
        const ThumbnailSize(200, 200),
      );
      if (thumbnailData == null) {
        // 如果无法获取缩略图，尝试直接使用文件路径
        final file = File(localAsset.path);
        if (await file.exists()) {
          return file;
        }
        return null;
      }

      // 将缩略图数据保存为临时文件用于显示
      final tempFile = File('${Directory.systemTemp.path}/thumb_${localAsset.id}.jpg');
      await tempFile.writeAsBytes(thumbnailData);
      return tempFile;
    } catch (e) {
      _log.warning('Failed to load thumbnail for ${localAsset.id}: $e');
      // 如果失败，尝试直接使用文件路径
      final file = File(localAsset.path);
      if (await file.exists()) {
        return file;
      }
      return null;
    }
  }

  /// 通过 ID 获取 AssetEntity
  Future<AssetEntity?> _getAssetEntityById(String id) async {
    try {
      // 使用 AssetEntity.fromId 获取资产
      return await AssetEntity.fromId(id);
    } catch (e) {
      _log.warning('Failed to get asset entity by id $id: $e');
      return null;
    }
  }

  /// 构建底部操作栏
  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左侧：媒体选择按钮和回复选项
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.image, size: 24, color: Colors.grey),
                onPressed: _handleSelectMedia,
                tooltip: '选择图片',
              ),
              const SizedBox(width: 4),
              const Icon(Icons.swap_vert, size: 20, color: Colors.grey),
              const SizedBox(width: 4),
              const Text(
                '回复选项',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          // 右侧：表情开关和发布按钮
          Row(
            children: [
              // 表情开关（暂时禁用）
              Switch(
                value: false,
                onChanged: null,
                activeColor: Colors.blue,
              ),
              const SizedBox(width: 12),
              // 发布按钮
              ElevatedButton(
                onPressed: _canPublish && _currentTaskId == null
                    ? _handlePublish
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canPublish && _currentTaskId == null
                      ? Colors.blue
                      : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  '发布',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 媒体选择对话框
class _MediaPickerDialog extends StatefulWidget {
  final List<AssetEntity> assets;

  const _MediaPickerDialog({required this.assets});

  @override
  State<_MediaPickerDialog> createState() => _MediaPickerDialogState();
}

class _MediaPickerDialogState extends State<_MediaPickerDialog> {
  final Set<int> _selectedIndices = {};

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 标题栏
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '选择图片',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _selectedIndices.isEmpty
                          ? null
                          : () {
                              final selected = _selectedIndices
                                  .map((i) => widget.assets[i])
                                  .toList();
                              Navigator.of(context).pop(selected);
                            },
                      child: Text('确定 (${_selectedIndices.length}/9)'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 图片网格
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: widget.assets.length,
                itemBuilder: (context, index) {
                  return _buildSelectableThumbnail(widget.assets[index], index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectableThumbnail(AssetEntity asset, int index) {
    final isSelected = _selectedIndices.contains(index);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedIndices.remove(index);
          } else {
            if (_selectedIndices.length < 9) {
              _selectedIndices.add(index);
            }
          }
        });
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          FutureBuilder<File?>(
            future: asset.thumbnailDataWithSize(
              const ThumbnailSize(200, 200),
            ).then((data) async {
              if (data == null) return null;
              final tempFile = File('${Directory.systemTemp.path}/thumb_${asset.id}.jpg');
              await tempFile.writeAsBytes(data);
              return tempFile;
            }),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return Image.file(
                  snapshot.data!,
                  fit: BoxFit.cover,
                );
              }
              return Container(color: Colors.grey.shade200);
            },
          ),
          // 选中标记
          if (isSelected)
            Container(
              color: Colors.blue.withOpacity(0.3),
              child: const Center(
                child: Icon(
                  Icons.check_circle,
                  color: Colors.blue,
                  size: 32,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
