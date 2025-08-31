// lib/providers/new_thread_provider.dart
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:flutter/services.dart';

import 'package:mobile/domain/entities/reply_permission.dart';

part 'new_thread_provider.g.dart';

@immutable
class NewThreadState {
  final List<AssetEntity> selectedAssets;
  final ReplyPermission selectedPermission;
  final String text;
  final bool isPostButtonEnabled;

  const NewThreadState({
    this.selectedAssets = const [],
    this.selectedPermission = ReplyPermission.anyone,
    this.text = '',
    this.isPostButtonEnabled = false,
  });

  NewThreadState copyWith({
    List<AssetEntity>? selectedAssets,
    ReplyPermission? selectedPermission,
    String? text,
    bool? isPostButtonEnabled,
  }) {
    return NewThreadState(
      selectedAssets: selectedAssets ?? this.selectedAssets,
      selectedPermission: selectedPermission ?? this.selectedPermission,
      text: text ?? this.text,
      isPostButtonEnabled: isPostButtonEnabled ?? this.isPostButtonEnabled,
    );
  }
}

@riverpod
class NewThread extends _$NewThread {
  @override
  NewThreadState build() {
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

  void post(BuildContext context) {
    if (!state.isPostButtonEnabled) return;
    debugPrint('发布内容: ${state.text}');
    debugPrint('附带资产: ${state.selectedAssets.length} 个');
    debugPrint('回复权限: ${state.selectedPermission.title}');
    Navigator.of(context).pop();
  }
}
