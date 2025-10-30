// lib/providers/new_thread_provider.dart
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:flutter/services.dart';
// removed unused providers imports
import 'package:mobile/domain/entities/reply_permission.dart';
import 'package:mobile/extensions/asset_type_extensions.dart';
import 'package:workmanager/workmanager.dart';
import 'package:mobile/features/background_jobs/impl/group_post/background/create_post_runner.dart';
import 'dart:convert';

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
      // 保持按钮状态的逻辑不变
      isPostButtonEnabled:
          text.trim().isNotEmpty || state.selectedAssets.isNotEmpty,
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
      // 更新按钮状态
      isPostButtonEnabled: state.text.trim().isNotEmpty || newAssets.isNotEmpty,
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
          // 更新按钮状态
          isPostButtonEnabled:
              state.text.trim().isNotEmpty || assets.isNotEmpty,
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

  /// 创建并发布新帖子的完整实现（后台任务版）
  Future<void> post(BuildContext context) async {
    final groupId = this.groupId;

    if (!state.isPostButtonEnabled || state.isLoading) return;

    // 关键点1: 开始发布，设置isLoading为true，这将触发UI更新
    state = state.copyWith(isLoading: true, isPostButtonEnabled: false);

    try {
      // 服务端要求至少1个媒体
      if (state.selectedAssets.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('请至少选择一张图片或视频')),
          );
        }
        return;
      }
      // 准备资产参数（避免在后台使用 AssetEntity）
      final assets = <Map<String, dynamic>>[];
      for (final asset in state.selectedAssets) {
        final file = await asset.originFile;
        if (file == null) {
          throw Exception('无法获取资产文件: ${asset.id}');
        }
        assets.add({
          'localId': asset.id,
          'filePath': file.path,
          'mediaType': asset.type.toMediaType().name,
          'mediaTakenAt': asset.createDateTime.millisecondsSinceEpoch,
        });
      }

      final assetsJson = jsonEncode(assets);

      await Workmanager().registerOneOffTask(
        createPostTask,
        createPostTask,
        inputData: <String, dynamic>{
          'groupUuid': groupId,
          'content': state.text,
          'assets_json': assetsJson,
          'timeoutSeconds': 20 * 60,
        },
        constraints: Constraints(networkType: NetworkType.connected),
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 5),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('帖子正在后台发送，可关闭此页面')),
        );
        // 任务已成功创建，退出创建页面，返回帖子页面
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('发布帖子失败: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('启动后台发送失败: ${e.toString()}')));
      }
    } finally {
      // 关键点3: 无论成功与否，都要重置加载状态（如果页面没有被pop掉）
      // 同时恢复按钮的可点击状态
      if (ref.exists(newThreadProvider(groupId))) {
        state = state.copyWith(
          isLoading: false,
          isPostButtonEnabled:
              state.text.trim().isNotEmpty || state.selectedAssets.isNotEmpty,
        );
      }
    }

    // 后台发送，不在此处 pop 页面
  }
}
