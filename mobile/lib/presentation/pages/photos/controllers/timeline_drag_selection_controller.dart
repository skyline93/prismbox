import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/features/local_sync/models/timeline_section.dart';
import 'package:prismbox/features/local_sync/providers/timeline_provider.dart';
import 'package:prismbox/presentation/widgets/selection/drag_selection_region.dart'
    show AssetIndex, ScrollDirection;
import 'package:prismbox/providers/navigation/timeline_grid_columns_provider.dart';
import 'package:prismbox/providers/selection/asset_selection_provider.dart';

/// 时间线拖动选择控制器
///
/// 负责处理拖动选择逻辑，包括：
/// - 拖动开始、进入、结束处理
/// - 矩形/行选择算法
/// - 拖动滚动处理
class TimelineDragSelectionController {
  final WidgetRef ref;
  final ScrollController scrollController;
  final String pageId;

  /// 拖动选择相关状态
  AssetIndex? _dragAnchorIndex;
  bool _isDragging = false;
  final Set<String> _draggedAssetIds = {};

  TimelineDragSelectionController({
    required this.ref,
    required this.scrollController,
    this.pageId = 'main',
  });

  /// 处理拖动开始
  void handleDragStart(AssetIndex index) {
    final timelineSectionsAsync = ref.read(
      timelineSectionsProvider(pageId: pageId),
    );
    timelineSectionsAsync.whenData((sections) {
      if (index.sectionIndex >= 0 && index.sectionIndex < sections.length) {
        final section = sections[index.sectionIndex];
        if (index.assetIndex >= 0 && index.assetIndex < section.assets.length) {
          final asset = section.assets[index.assetIndex];

          _isDragging = true;
          _dragAnchorIndex = index;
          _draggedAssetIds.clear();

          // 选中起始项
          final selectedIds = ref.read(
            assetSelectionProvider.select((s) => s.selectedIds),
          );
          if (!selectedIds.contains(asset.id)) {
            ref.read(assetSelectionProvider.notifier).toggle(asset.id);
          }
          _draggedAssetIds.add(asset.id);
        }
      }
    });
  }

  /// 处理拖动进入资产
  void handleDragAssetEnter(AssetIndex index) {
    if (_dragAnchorIndex == null || !_isDragging) return;

    final timelineSectionsAsync = ref.read(
      timelineSectionsProvider(pageId: pageId),
    );
    timelineSectionsAsync.whenData((sections) {
      if (index.sectionIndex >= 0 && index.sectionIndex < sections.length) {
        final section = sections[index.sectionIndex];
        if (index.assetIndex >= 0 && index.assetIndex < section.assets.length) {
          // 计算选择范围（从起始索引到当前索引）
          final startIndex = _dragAnchorIndex!;
          final endIndex = index;

          // 如果起始和结束在同一分组
          if (startIndex.sectionIndex == endIndex.sectionIndex) {
            final selectedAssets = _calculateSelectedAssets(
              sections,
              startIndex,
              endIndex,
            );

            // 更新选择状态
            _updateSelection(selectedAssets);
          }
        }
      }
    });
  }

  /// 处理拖动结束
  void handleDragEnd() {
    _isDragging = false;
    _dragAnchorIndex = null;
    _draggedAssetIds.clear();
  }

  /// 处理拖动滚动
  void handleDragScroll(ScrollDirection direction) {
    if (scrollController.hasClients) {
      final offset = direction == ScrollDirection.forward ? 175.0 : -175.0;
      scrollController.animateTo(
        scrollController.offset + offset,
        duration: const Duration(milliseconds: 125),
        curve: Curves.easeOut,
      );
    }
  }

  /// 计算选中的资产（矩形/行选择算法）
  ///
  /// [sections] 时间线分组列表
  /// [startIndex] 起始索引
  /// [endIndex] 结束索引
  /// 返回选中的资产 ID 集合
  Set<String> _calculateSelectedAssets(
    List<TimelineSection> sections,
    AssetIndex startIndex,
    AssetIndex endIndex,
  ) {
    final startSection = sections[startIndex.sectionIndex];
    final startAssetIndex = startIndex.assetIndex;
    final endAssetIndex = endIndex.assetIndex;

    // 使用当前的网格列数
    final crossAxisCount = ref.read(timelineGridColumnsProvider);
    final startRow = startAssetIndex ~/ crossAxisCount;
    final endRow = endAssetIndex ~/ crossAxisCount;
    final startCol = startAssetIndex % crossAxisCount;
    final endCol = endAssetIndex % crossAxisCount;

    // 计算行数和列数的变化
    final rowDiff = (endRow - startRow).abs();
    final colDiff = (endCol - startCol).abs();

    final selectedAssets = <String>{};

    // 判断拖动方向：如果主要是向下拖动（行数变化大于列数变化），则选中整行
    if (rowDiff > colDiff) {
      // 向下拖动：选中整行，但起始行从起始列开始，结束行到结束列为止
      final minRow = startRow < endRow ? startRow : endRow;
      final maxRow = startRow > endRow ? startRow : endRow;
      final isDownward = startRow < endRow;

      for (int row = minRow; row <= maxRow; row++) {
        int startColForRow;
        int endColForRow;

        if (row == minRow && row == maxRow) {
          // 只有一行：从起始列到结束列
          startColForRow = (startCol < endCol ? startCol : endCol).toInt();
          endColForRow = (startCol > endCol ? startCol : endCol).toInt();
        } else if (row == minRow) {
          // 起始行：从起始列到行尾
          if (isDownward) {
            startColForRow = startCol;
            endColForRow = crossAxisCount - 1;
          } else {
            startColForRow = endCol;
            endColForRow = crossAxisCount - 1;
          }
        } else if (row == maxRow) {
          // 结束行：从行首到结束列
          if (isDownward) {
            startColForRow = 0;
            endColForRow = endCol;
          } else {
            startColForRow = 0;
            endColForRow = startCol;
          }
        } else {
          // 中间行：选中整行
          startColForRow = 0;
          endColForRow = crossAxisCount - 1;
        }

        for (int col = startColForRow; col <= endColForRow; col++) {
          final assetIndex = row * crossAxisCount + col;
          if (assetIndex >= 0 && assetIndex < startSection.assets.length) {
            selectedAssets.add(startSection.assets[assetIndex.toInt()].id);
          }
        }
      }
    } else {
      // 横向拖动：保持矩形选择
      final minRow = startRow < endRow ? startRow : endRow;
      final maxRow = startRow > endRow ? startRow : endRow;
      final minCol = startCol < endCol ? startCol : endCol;
      final maxCol = startCol > endCol ? startCol : endCol;

      for (int row = minRow; row <= maxRow; row++) {
        for (int col = minCol; col <= maxCol; col++) {
          final assetIndex = row * crossAxisCount + col;
          if (assetIndex >= 0 && assetIndex < startSection.assets.length) {
            selectedAssets.add(startSection.assets[assetIndex.toInt()].id);
          }
        }
      }
    }

    return selectedAssets;
  }

  /// 更新选择状态
  ///
  /// [selectedAssets] 当前应该选中的资产 ID 集合
  void _updateSelection(Set<String> selectedAssets) {
    // 清除之前的拖动选择
    final selectedIds = ref.read(
      assetSelectionProvider.select((s) => s.selectedIds),
    );
    for (final assetId in _draggedAssetIds) {
      if (!selectedAssets.contains(assetId) && selectedIds.contains(assetId)) {
        ref.read(assetSelectionProvider.notifier).toggle(assetId);
      }
    }

    // 添加新的拖动选择
    for (final assetId in selectedAssets) {
      if (!_draggedAssetIds.contains(assetId) &&
          !selectedIds.contains(assetId)) {
        ref.read(assetSelectionProvider.notifier).toggle(assetId);
      }
    }

    _draggedAssetIds.clear();
    _draggedAssetIds.addAll(selectedAssets);
  }
}
