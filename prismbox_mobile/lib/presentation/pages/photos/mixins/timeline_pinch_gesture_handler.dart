import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/providers/navigation/timeline_grid_columns_provider.dart';

/// 时间线捏合手势处理器 Mixin
///
/// 负责处理捏合手势来调整网格列数，包括：
/// - 手势开始、更新、结束处理
/// - 列数计算逻辑
/// - 防抖机制
mixin TimelinePinchGestureHandler<T extends StatefulWidget> on State<T> {
  /// 需要在使用此 Mixin 的 State 类中提供 WidgetRef
  WidgetRef get ref;

  /// 捏合手势相关状态
  int _lastColumnCount = 4;
  DateTime? _lastUpdateTime;

  /// 处理捏合手势开始
  void onPinchScaleStart() {
    final gridColumns = ref.read(timelineGridColumnsProvider);
    _lastColumnCount = gridColumns;
    _lastUpdateTime = null;
  }

  /// 处理捏合手势更新
  void onPinchScaleUpdate(ScaleUpdateDetails details) {
    final scale = details.scale;
    final currentColumns = ref.read(timelineGridColumnsProvider);

    // 使用累积的缩放值来计算目标列数
    // scale > 1.0 表示放大（减少列数），scale < 1.0 表示缩小（增加列数）
    final targetColumns = _calculateTargetColumns(scale, _lastColumnCount);

    // 只有当目标列数与当前列数不同时才更新
    if (targetColumns != currentColumns &&
        targetColumns >= 2 &&
        targetColumns <= 8) {
      // 添加防抖机制，避免过于频繁的更新（最小间隔 50ms）
      final now = DateTime.now();
      if (_lastUpdateTime == null ||
          now.difference(_lastUpdateTime!).inMilliseconds > 50) {
        ref.read(timelineGridColumnsProvider.notifier).setColumns(targetColumns);
        HapticFeedback.selectionClick();
        _lastUpdateTime = now;
      }
    }
  }

  /// 处理捏合手势结束
  void onPinchScaleEnd() {
    final gridColumns = ref.read(timelineGridColumnsProvider);
    _lastColumnCount = gridColumns;
    _lastUpdateTime = null;
  }

  /// 根据缩放值计算目标列数
  ///
  /// 使用平滑的映射函数，让手势更丝滑
  /// [scale]: 当前的缩放值（1.0 为基准）
  /// [baseColumns]: 手势开始时的列数
  int _calculateTargetColumns(double scale, int baseColumns) {
    // 缩放阈值：每个列数变化对应约 0.2 的缩放变化
    // 这样可以让手势更敏感，同时保持平滑
    const scaleThreshold = 0.2;

    // 计算相对于基准的缩放变化
    final scaleChange = scale - 1.0;

    // 计算应该变化的列数（使用四舍五入）
    final columnDelta = (scaleChange / scaleThreshold).round();

    // 计算目标列数
    var targetColumns = baseColumns - columnDelta; // 放大时减少列数

    // 限制在有效范围内
    targetColumns = targetColumns.clamp(2, 8);

    return targetColumns;
  }
}

