// lib/utils/color_extensions.dart

import 'package:flutter/material.dart';

/// 颜色扩展方法
/// 提供 lighten 和 darken 方法，用于调整颜色亮度
extension ColorExtensions on Color {
  /// 使颜色变亮
  Color lighten({double amount = 0.1}) {
    return Color.alphaBlend(Colors.white.withValues(alpha: amount), this);
  }

  /// 使颜色变暗
  Color darken({double amount = 0.1}) {
    return Color.alphaBlend(Colors.black.withValues(alpha: amount), this);
  }
}

