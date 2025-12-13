// lib/presentation/widgets/timeline/selectable_timeline_sliver_list.dart

import 'package:flutter/material.dart';
import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/features/local_sync/models/timeline_section.dart';
import 'package:prismbox/features/local_sync/services/asset_entity_loader.dart';
import 'package:prismbox/presentation/widgets/media/selectable_media_grid_sliver.dart';
import 'package:prismbox/presentation/widgets/timeline/timeline_section_header.dart';

/// 支持多选的时间线分组列表构建器
/// 
/// 用于构建时间线分组的 Sliver 列表，支持多选模式
/// 每个分组包含：
/// - SliverToBoxAdapter（分组标题）
/// - SelectableMediaGridSliver（可选择的媒体网格）
/// 
/// 使用方式：
/// ```dart
/// CustomScrollView(
///   slivers: [
///     ...SelectableTimelineSliverListBuilder(
///       sections: sections,
///       selectionActive: true,
///       selectedIds: {...},
///       // ... 其他参数
///     ).build(),
///   ],
/// )
/// ```
class SelectableTimelineSliverListBuilder {
  /// 时间线分组列表
  final List<TimelineSection> sections;

  /// 是否启用选择模式
  final bool selectionActive;

  /// 已选中的资产ID集合
  final Set<String> selectedIds;

  /// 点击回调（正常模式下）
  final void Function(BaseAsset asset, int index)? onTap;

  /// 选择切换回调（多选模式下）
  final void Function(BaseAsset asset)? onSelectionToggle;

  /// 长按回调（用于进入多选模式）
  final void Function(BaseAsset asset)? onLongPress;

  /// 选择整个分组的回调
  final void Function(TimelineSection section)? onSectionToggle;

  /// 每行显示的列数
  final int crossAxisCount;

  /// 子项之间的间距
  final double crossAxisSpacing;

  /// 主轴间距
  final double mainAxisSpacing;

  /// 子项的宽高比
  final double childAspectRatio;

  /// 服务器 URL
  final String? serverUrl;

  /// 预加载范围（前后各预加载多少张图片）
  final int preloadRange;

  /// 分组标题内边距
  final EdgeInsetsGeometry? headerPadding;

  /// 分组标题背景颜色
  final Color? headerBackgroundColor;

  /// 是否显示照片数量
  final bool showAssetCount;

  /// AssetEntity 加载器（可选，用于延迟获取）
  final AssetEntityLoader? assetEntityLoader;

  const SelectableTimelineSliverListBuilder({
    required this.sections,
    required this.selectionActive,
    required this.selectedIds,
    this.onTap,
    this.onSelectionToggle,
    this.onLongPress,
    this.onSectionToggle,
    this.crossAxisCount = 5,
    this.crossAxisSpacing = 2.0,
    this.mainAxisSpacing = 2.0,
    this.childAspectRatio = 1.0,
    this.serverUrl,
    this.preloadRange = 2,
    this.headerPadding,
    this.headerBackgroundColor,
    this.showAssetCount = true,
    this.assetEntityLoader,
  });

  /// 构建所有分组的 Sliver 列表
  /// 
  /// 返回一个 List<Widget>，每个 Widget 是一个 Sliver
  /// 可以在 CustomScrollView 的 slivers 参数中使用展开操作符
  List<Widget> build() {
    if (sections.isEmpty) {
      return [const SliverToBoxAdapter(child: SizedBox.shrink())];
    }

    final slivers = <Widget>[];

    for (final section in sections) {
      // 计算该分组中资产在全局列表中的起始索引
      int globalIndex = 0;
      for (int i = 0; i < section.index; i++) {
        globalIndex += sections[i].assets.length;
      }

      // 添加分组标题（使用 SliverToBoxAdapter）
      // 检查该分组是否全部选中
      final sectionAssetIds = section.assets.map((a) => a.id).toSet();
      final isSectionAllSelected = selectionActive &&
          sectionAssetIds.isNotEmpty &&
          sectionAssetIds.every((id) => selectedIds.contains(id));

      slivers.add(
        SliverToBoxAdapter(
          child: TimelineSectionHeader(
            section: section,
            showAssetCount: showAssetCount,
            padding: headerPadding,
            backgroundColor: headerBackgroundColor,
            selectionActive: selectionActive,
            isSectionAllSelected: isSectionAllSelected,
            onSectionToggle: onSectionToggle != null
                ? () => onSectionToggle!(section)
                : null,
          ),
        ),
      );

      // 添加可选择的媒体网格（使用 SelectableMediaGridSliver）
      slivers.add(
        _buildSelectableMediaGridSliver(section, globalIndex, section.index),
      );
    }

    return slivers;
  }

  /// 构建可选择的媒体网格 Sliver
  Widget _buildSelectableMediaGridSliver(
    TimelineSection section,
    int globalStartIndex,
    int sectionIndex,
  ) {
    // 创建包装的 onTap 回调，将索引转换为全局索引
    void Function(BaseAsset asset, int index)? wrappedOnTap;
    if (onTap != null) {
      wrappedOnTap = (asset, localIndex) {
        final globalIndex = globalStartIndex + localIndex;
        onTap!(asset, globalIndex);
      };
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      sliver: SelectableMediaGridSliver(
        assets: section.assets,
        selectionActive: selectionActive,
        selectedIds: selectedIds,
        onTap: wrappedOnTap,
        onSelectionToggle: onSelectionToggle,
        onLongPress: onLongPress,
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: childAspectRatio,
        serverUrl: serverUrl,
        preloadRange: preloadRange,
        assetEntityLoader: assetEntityLoader,
        sectionIndex: sectionIndex,
      ),
    );
  }
}

