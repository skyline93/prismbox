// lib/providers/new_thread_provider.dart
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:flutter/services.dart';
import 'package:mobile/providers/group_providers.dart';
import 'package:mobile/providers/providers.dart';
import 'package:mobile/domain/entities/reply_permission.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';

part 'new_thread_provider.g.dart';

@immutable
class NewThreadState {
  final List<AssetEntity> selectedAssets;
  final ReplyPermission selectedPermission;
  final String text;
  final bool isPostButtonEnabled;
  final bool isLoading;

  const NewThreadState({
    this.selectedAssets = const [],
    this.selectedPermission = ReplyPermission.anyone,
    this.text = '',
    this.isPostButtonEnabled = false,
    this.isLoading = false,
  });

  NewThreadState copyWith({
    List<AssetEntity>? selectedAssets,
    ReplyPermission? selectedPermission,
    String? text,
    bool? isPostButtonEnabled,
    bool? isLoading,
  }) {
    return NewThreadState(
      selectedAssets: selectedAssets ?? this.selectedAssets,
      selectedPermission: selectedPermission ?? this.selectedPermission,
      text: text ?? this.text,
      isPostButtonEnabled: isPostButtonEnabled ?? this.isPostButtonEnabled,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

@riverpod
class NewThread extends _$NewThread {
  @override
  NewThreadState build(String groupId) {
    return const NewThreadState();
  }

  void updateText(String text) {
    state = state.copyWith(
      text: text,
      isPostButtonEnabled: state.selectedAssets.isNotEmpty,
    );
  }

  void updatePermission(ReplyPermission permission) {
    state = state.copyWith(selectedPermission: permission);
  }

  void removeAsset(int index) {
    final newAssets = List<AssetEntity>.from(state.selectedAssets)
      ..removeAt(index);
    state = state.copyWith(
      selectedAssets: newAssets,
      isPostButtonEnabled: newAssets.isNotEmpty,
    );
  }

  Future<void> pickAssets(BuildContext context) async {
    try {
      final List<AssetEntity>? assets = await AssetPicker.pickAssets(
        context,
        pickerConfig: AssetPickerConfig(
          maxAssets: 18,
          selectedAssets: state.selectedAssets,
          requestType: RequestType.image,
        ),
      );
      if (assets != null) {
        state = state.copyWith(
          selectedAssets: assets,
          isPostButtonEnabled: assets.isNotEmpty,
        );
      }
    } on PlatformException catch (e) {
      debugPrint('调用相册失败: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('无法打开相册，请检查权限设置')));
      }
    }
  }

  /// 创建并发布新帖子的完整实现
  Future<void> post(BuildContext context) async {
    // `arg` 是由 riverpod_generator 提供的，它持有 build 方法的参数，即 groupId
    final groupId = this.groupId;

    if (!state.isPostButtonEnabled || state.isLoading) return;

    state = state.copyWith(isLoading: true);

    try {
      final groupRepository = ref.read(groupRepositoryProvider);
      final mediaRepo = ref.read(mediaRepositoryProvider);

      // 1. 并行上传所有选择的图片资源，以获取它们的 UUID
      final uploadFutures = state.selectedAssets.map((asset) async {
        final file = await asset.file; // 获取文件
        if (file == null) {
          throw Exception('无法获取资产文件: ${asset.id}');
        }
        return await mediaRepo.uploadMedia(asset); // 调用上传方法
      }).toList();

      final List<UnifiedMediaEntity> uploadedMedia = await Future.wait(
        uploadFutures,
      );
      final List<String> mediaUuids = [];
      for (final media in uploadedMedia) {
        final uuid = media.cloudUuid; // 假设 UnifiedMediaEntity 类有 'uuid' 属性
        if (uuid == null || uuid.isEmpty) {
          // 如果发现任何一个无效的uuid，就立即抛出异常中断流程
          throw Exception('部分媒体上传失败，未能从服务器获取有效ID。');
        }
        mediaUuids.add(uuid);
      }

      // 2. 调用 repository 来创建帖子
      await groupRepository.createPost(
        groupUuid: groupId,
        content: state.text,
        mediaUuids: mediaUuids,
        // replyPermission: state.selectedPermission,
      );

      // 3. 如果成功，显示提示并关闭当前页面
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('帖子发布成功！')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('发布帖子失败: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('发布失败: ${e.toString()}')));
      }
    } finally {
      // 4. 无论成功与否，都要重置加载状态
      if (state.isLoading) {
        state = state.copyWith(isLoading: false);
      }
    }

    Navigator.of(context).pop();
  }
}
