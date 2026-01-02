import 'package:flutter/material.dart';

/// 时间线滚动位置管理器
///
/// 负责管理滚动位置的保存和恢复，包括：
/// - 保存滚动位置（长按进入选择模式时）
/// - 恢复滚动位置（使用多个 postFrameCallback 确保布局稳定）
class TimelineScrollPositionManager {
  final ScrollController scrollController;
  final bool Function() mounted;

  /// 保存长按进入选择模式时的滚动位置
  double? _savedScrollOffset;

  TimelineScrollPositionManager({
    required this.scrollController,
    required this.mounted,
  });

  /// 保存当前滚动位置
  void saveScrollOffset() {
    if (scrollController.hasClients) {
      _savedScrollOffset = scrollController.offset;
    }
  }

  /// 恢复滚动位置
  ///
  /// 使用多个 postFrameCallback 确保布局完全稳定
  /// Sliver 列表重新构建需要多个布局周期才能完全稳定
  void restoreScrollOffset() {
    if (_savedScrollOffset == null || !scrollController.hasClients) {
      return;
    }

    // 使用多个 postFrameCallback 确保布局完全稳定
    // Sliver 列表重新构建需要多个布局周期才能完全稳定
    Future.microtask(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 等待第二个 frame 确保 Sliver 布局完全稳定
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // 再等待一个 frame 确保所有布局计算完成
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted() &&
                scrollController.hasClients &&
                _savedScrollOffset != null) {
              // 确保滚动位置在有效范围内
              final maxScrollExtent = scrollController.position.maxScrollExtent;
              final targetOffset = _savedScrollOffset!.clamp(
                0.0,
                maxScrollExtent,
              );
              scrollController.jumpTo(targetOffset);
              _savedScrollOffset = null; // 清除保存的位置
            }
          });
        });
      });
    });
  }

  /// 清除保存的滚动位置
  void clearSavedOffset() {
    _savedScrollOffset = null;
  }

  /// 检查是否有保存的滚动位置
  bool get hasSavedOffset => _savedScrollOffset != null;
}

