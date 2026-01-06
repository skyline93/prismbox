// lib/providers/selection/asset_selection_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 资产选择状态
class AssetSelectionState {
  final Set<String> selectedIds;
  final bool isActive;

  const AssetSelectionState({
    this.selectedIds = const {},
    this.isActive = false,
  });

  AssetSelectionState copyWith({
    Set<String>? selectedIds,
    bool? isActive,
  }) {
    return AssetSelectionState(
      selectedIds: selectedIds ?? this.selectedIds,
      isActive: isActive ?? this.isActive,
    );
  }

  int get count => selectedIds.length;
  bool isEmpty() => selectedIds.isEmpty;
  bool isSelected(String assetId) => selectedIds.contains(assetId);
}

/// 资产选择状态管理
class AssetSelectionNotifier extends StateNotifier<AssetSelectionState> {
  AssetSelectionNotifier() : super(const AssetSelectionState());

  /// 进入选择模式
  void activate() {
    state = state.copyWith(isActive: true);
  }

  /// 退出选择模式
  void deactivate() {
    state = state.copyWith(
      isActive: false,
      selectedIds: {},
    );
  }

  /// 切换选中状态
  void toggle(String assetId) {
    final newIds = Set<String>.from(state.selectedIds);
    if (newIds.contains(assetId)) {
      newIds.remove(assetId);
    } else {
      newIds.add(assetId);
    }
    state = state.copyWith(selectedIds: newIds);
  }

  /// 全选
  void selectAll(List<String> assetIds) {
    state = state.copyWith(selectedIds: Set.from(assetIds));
  }

  /// 取消全选
  void clear() {
    state = state.copyWith(selectedIds: {});
  }

  /// 检查是否选中
  bool isSelected(String assetId) {
    return state.selectedIds.contains(assetId);
  }
}

/// Provider 定义
final assetSelectionProvider = 
    StateNotifierProvider<AssetSelectionNotifier, AssetSelectionState>(
  (ref) => AssetSelectionNotifier(),
);

